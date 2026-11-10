package me.jxl.kiosk_satellite

import android.media.AudioTimestamp
import android.media.AudioTrack
import android.os.SystemClock
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.CopyOnWriteArrayList

/**
 * What the kiosk is playing, for [SoftwareEcho]: every player that writes
 * its own PCM taps it here, and the canceller takes the mix of what each
 * one's speaker has presented since it last asked. Everything is kept as
 * 16 kHz mono, the rate the microphone runs at.
 *
 * Players Android decodes on its own (the dashboard's web pages, the DLNA
 * video player) cannot be tapped, so their sound is not cancelled.
 */
object EchoReference {
    const val RATE = 16000

    /** A player's contribution: its presented voice since the last call. */
    interface Source {
        /** 16 kHz mono samples presented since the last call, volume applied. */
        fun take(): ShortArray?
    }

    private val sources = CopyOnWriteArrayList<Source>()

    /** When a source last had something playing, for the canceller's tail. */
    @Volatile private var lastAudibleMs = 0L

    fun add(source: Source) {
        sources.addIfAbsent(source)
    }

    fun remove(source: Source) {
        sources.remove(source)
    }

    /**
     * A copy, read in one step. The mic thread must not walk the live list:
     * Kotlin's toSet reads a one item list by size and then get(0), and a
     * player stopping between the two threw on that thread.
     */
    fun sources(): List<Source> = ArrayList(sources)

    fun audible() {
        lastAudibleMs = SystemClock.elapsedRealtime()
    }

    /** The output device the last tapped track played to, 0 before the first. */
    @Volatile private var outputDevice = 0

    /**
     * A tapped track plays to the output device [id]. When that is another
     * one than the last track's, the echo arrives at another delay and the
     * canceller has to find it again ([SoftwareEcho.outputMoved]).
     */
    fun routed(id: Int) {
        if (id == 0) return
        val last = outputDevice
        outputDevice = id
        if (last != 0 && last != id) SoftwareEcho.outputMoved()
    }

    /** Whether anything played recently enough to still be echoing. */
    fun playedWithin(ms: Long): Boolean =
        SystemClock.elapsedRealtime() - lastAudibleMs < ms
}

/**
 * The part of a tap both kinds share: 16 kHz mono samples queued as the
 * player writes them, handed to the canceller once the speaker has
 * presented them. Positions count 16 kHz samples from the start of the
 * stream, derived from absolute frame counts so rounding never adds up.
 */
abstract class PresentedQueue(rate: Int) : EchoReference.Source {
    protected val lock = Object()

    /** The source's sample rate. Under [lock] once it plays. */
    protected var rate = rate
        private set
    private var resampler = ReferenceResampler(rate, EchoReference.RATE)

    /**
     * The volume the player applies after the tap. It is applied here as the
     * samples are handed out, not as they are written: Android changes a
     * track's volume for what it plays from then on, while a player writes
     * a quarter of a second ahead, so a music duck applied at write time
     * reached the reference that much before the speaker, at the start of
     * every answer.
     */
    @Volatile var gain = 1f

    private var queued = ShortArray(EchoReference.RATE)
    private var queuedLength = 0

    /** The 16 kHz position of queued[0]. */
    private var queuedFrom = 0L

    /**
     * What the speaker still plays after the player stopped or flushed its
     * track: the samples the mixer had already taken. Android drops what
     * sits in the track's buffer and plays these out, 110 to 180 ms of sound
     * on a Galaxy Tab S8 and an Echo Show 5. Dropped from the reference with
     * the rest, the microphone heard them with nothing to cancel them
     * against, at the end of every stopped song and of every answer the user
     * talked over. Up to [tailReady] they had played when the player
     * stopped, at [tailNs], and the rest plays from then on.
     */
    private var tail = ShortArray(0)
    private var tailLength = 0
    private var tailGiven = 0
    private var tailReady = 0
    private var tailNs = 0L

    /** Closed by its player: it leaves [EchoReference] once its tail is handed out. */
    @Volatile private var closed = false

    /** Source frames written since the stream (re)started. */
    protected var written = 0L

    /**
     * Source frames the speaker has presented since the stream (re)started.
     * Called outside [lock]: a player's own clock may take its own lock,
     * which the player also holds while it writes here.
     */
    protected abstract fun presented(): Long

    /** Queue [frames] frames of PCM from [view], at its position. */
    protected fun queue(view: ByteBuffer, frames: Int, channels: Int, bytesPerSample: Int) {
        if (frames <= 0) return
        if (!SoftwareEcho.enabled) {
            // Nothing listens: count the frames, keep nothing.
            synchronized(lock) {
                written += frames
                queuedLength = 0
                queuedFrom = written * EchoReference.RATE / rate
                tailLength = 0
                tailGiven = 0
                resampler.reset()
            }
            return
        }
        val mono = FloatArray(frames)
        var at = view.position()
        for (i in 0 until frames) {
            var sum = 0f
            for (c in 0 until channels) {
                sum += if (bytesPerSample == 4) {
                    view.getInt(at) / 2147483648f
                } else {
                    view.getShort(at) / 32768f
                }
                at += bytesPerSample
            }
            mono[i] = sum / channels
        }
        val out = resampler.process(mono)
        synchronized(lock) {
            if (queuedLength == 0) queuedFrom = written * EchoReference.RATE / rate
            if (queuedLength + out.size > queued.size) {
                queued = queued.copyOf(maxOf(queued.size * 2, queuedLength + out.size))
            }
            for (i in out.indices) {
                queued[queuedLength + i] = (out[i].coerceIn(-1f, 1f) * 32767f).toInt().toShort()
            }
            queuedLength += out.size
            written += frames
        }
        if (gain > 0f) EchoReference.audible()
    }

    /** Start over: nothing queued, nothing written, at [newRate]. */
    protected fun restart(newRate: Int = rate) {
        synchronized(lock) {
            queuedLength = 0
            queuedFrom = 0
            written = 0
            if (newRate != rate) {
                rate = newRate
                resampler = ReferenceResampler(newRate, EchoReference.RATE)
            } else {
                resampler.reset()
            }
        }
    }

    /**
     * The player is about to pause, flush or release its track, with
     * [presented] source frames at the speaker and [mixed] taken by the
     * mixer: what lies between still plays and stays in the reference,
     * handed out as it plays. Call it before the track stops; the flush
     * that follows drops the rest.
     */
    protected fun keepPlaying(presented: Long, mixed: Long, nowNs: Long = System.nanoTime()) {
        synchronized(lock) {
            if (queuedLength == 0) return
            val length = queuedLength.toLong()
            val played = (presented * EchoReference.RATE / rate - queuedFrom).coerceIn(0L, length)
            val playing = (mixed * EchoReference.RATE / rate - queuedFrom)
                .coerceIn(played, minOf(length, played + MAX_TAIL)).toInt()
            if (playing == 0) return
            // A tail still on its way out goes first, and counts as played.
            val pending = dueLocked(Long.MAX_VALUE)
            val next = ShortArray(pending + playing)
            System.arraycopy(tail, tailGiven, next, 0, pending)
            System.arraycopy(queued, 0, next, pending, playing)
            tail = next
            tailLength = next.size
            tailGiven = 0
            tailReady = pending + played.toInt()
            tailNs = nowNs
            System.arraycopy(queued, playing, queued, 0, queuedLength - playing)
            queuedLength -= playing
            queuedFrom += playing
        }
    }

    /** How many tail samples have played by [nowNs] and are not handed out yet. Under [lock]. */
    private fun dueLocked(nowNs: Long): Int {
        if (tailGiven >= tailLength) return 0
        if (nowNs == Long.MAX_VALUE) return tailLength - tailGiven
        val played = tailReady + (nowNs - tailNs).coerceAtLeast(0L) * EchoReference.RATE / 1_000_000_000L
        return (minOf(played, tailLength.toLong()) - tailGiven).coerceAtLeast(0L).toInt()
    }

    /**
     * The player is gone. Its tail is still playing, so the source stays
     * with [EchoReference] until the canceller has taken it, and a moment
     * longer: the canceller reads what it takes a few milliseconds later,
     * and drops a source's samples with the source.
     */
    protected fun closeAfterTail() {
        synchronized(lock) {
            closed = true
            queuedLength = 0
            if (tailGiven >= tailLength) tailNs = System.nanoTime()
        }
        if (!SoftwareEcho.enabled) EchoReference.remove(this)
    }

    override fun take(): ShortArray? = take(System.nanoTime())

    internal fun take(nowNs: Long): ShortArray? {
        val presented = if (closed) 0L else presented()
        val (out, done) = synchronized(lock) {
            taken(presented, nowNs) to (closed && tailGiven >= tailLength && nowNs - tailNs > LINGER_NS)
        }
        if (done) EchoReference.remove(this)
        return out
    }

    private fun taken(presented: Long, nowNs: Long): ShortArray? {
        val due = dueLocked(nowNs)
        val presented16 = presented * EchoReference.RATE / rate
        val upto = if (queuedLength == 0) 0 else (presented16 - queuedFrom).coerceIn(0L, queuedLength.toLong()).toInt()
        if (due + upto == 0) return null
        val out = ShortArray(due + upto)
        System.arraycopy(tail, tailGiven, out, 0, due)
        tailGiven += due
        System.arraycopy(queued, 0, out, due, upto)
        val g = gain
        if (g != 1f) for (i in out.indices) out[i] = (out[i] * g).toInt().toShort()
        System.arraycopy(queued, upto, queued, 0, queuedLength - upto)
        queuedLength -= upto
        queuedFrom += upto
        return out
    }

    private companion object {
        /** The longest tail kept, 300 ms: more than any output holds past its mixer. */
        const val MAX_TAIL = EchoReference.RATE * 3L / 10

        /** How long a closed source stays after its player stopped. */
        const val LINGER_NS = 1_000_000_000L
    }
}

/**
 * Where an AudioTrack's speaker is, in the track's frames since [reset]:
 * the track's timestamp while it is fresh and agrees with the playback
 * head, and otherwise the head minus the latency those timestamps last
 * measured. A timestamp alone is not enough: on a Galaxy Tab S8 it goes
 * wrong the moment a second stream starts, and a reference late by a
 * quarter of a second cancels nothing. Every tap places its reference by
 * this one rule, so the canceller sees the same delay whichever player is
 * talking and keeps the echo path it learned across a chime, an answer
 * and a song.
 */
class TrackClock(private val track: AudioTrack) {
    val rate = track.sampleRate
    private val timestamp = AudioTimestamp()
    private val headClock = me.jxl.kiosk_satellite.sendspin.PlaybackClock()
    private val lock = Object()
    private var headBase = 0L

    /**
     * The latency the track's timestamps last measured, kept across resets:
     * a talked-over answer flushes the track, and Android's own estimate
     * (109 ms against a measured 85 on a Galaxy Tab S8) put the next
     * answer's reference out of step with its echo just as it started.
     */
    private var measuredLatencyUs = measuredByRate[rate] ?: -1L

    private companion object {
        /** The last measured latency per sample rate, for the next track at that rate. */
        val measuredByRate = java.util.concurrent.ConcurrentHashMap<Int, Long>()

        /** How old a timestamp may be and still place the speaker. */
        const val FRESH_NS = 500_000_000L
    }

    private val bufferFrames = runCatching { track.bufferSizeInFrames.toLong() }.getOrDefault(0L)

    /**
     * Whether the track has given a timestamp since [reset]. Until then the
     * speaker's place comes from the playback head, which runs ahead of
     * the speaker by a different amount at every track's start (27 to
     * 133 ms measured on a Galaxy Tab S8 against 75 settled), so a sound
     * that starts before it is placed wrong and then snaps into place,
     * which makes the canceller relearn. Players keep the first few
     * hundred milliseconds silent until this is true ([LeadInProcessor]).
     */
    @Volatile var settled = false
        private set

    init {
        reset()
        // Where the track plays, now and whenever Android moves it.
        runCatching {
            track.routedDevice?.let { EchoReference.routed(it.id) }
            track.addOnRoutingChangedListener(
                android.media.AudioRouting.OnRoutingChangedListener { router ->
                    runCatching { router.routedDevice }.getOrNull()?.let { EchoReference.routed(it.id) }
                },
                android.os.Handler(android.os.Looper.getMainLooper()),
            )
        }
    }

    /** The track's frames start over from its head now. */
    fun reset() {
        synchronized(lock) {
            headBase = head()
            headClock.reset()
            settled = false
        }
    }

    private fun latencyUs(): Long =
        if (measuredLatencyUs >= 0) measuredLatencyUs else estimatedLatencyUs()

    private fun head(): Long =
        runCatching { track.playbackHeadPosition.toLong() and 0xFFFFFFFFL }.getOrDefault(0L)

    /** Android's own figure for the track's latency past its buffer, when it gives one. */
    private fun estimatedLatencyUs(): Long {
        val bufferUs = bufferFrames * 1_000_000L / rate
        return runCatching {
            val total = (AudioTrack::class.java.getMethod("getLatency").invoke(track) as Int) * 1000L
            (total - bufferUs).coerceIn(0L, 1_000_000L)
        }.getOrDefault(0L)
    }

    /** Frames the mixer has taken since [reset]: the speaker still plays those past [presented]. */
    fun mixed(): Long = synchronized(lock) { (head() - headBase).coerceAtLeast(0L) }

    /** Frames presented since [reset], never past [written]. */
    fun presented(written: Long): Long = synchronized(lock) {
        val now = System.nanoTime()
        val head = headClock.position(head() - headBase, now, written, rate, bufferFrames)
        // A timestamp is taken whenever it is fresh and agrees with the
        // head: a stream fed in bursts (the realtime voice) stops its
        // timestamps between them, and the head alone moves in mixer
        // steps a few milliseconds apart, which on speech costs the
        // canceller half of what it takes out.
        val ok = runCatching { track.getTimestamp(timestamp) }.getOrDefault(false)
        if (ok && now - timestamp.nanoTime in 0..FRESH_NS) {
            val at = (timestamp.framePosition and 0xFFFFFFFFL) - headBase +
                (now - timestamp.nanoTime) * rate / 1_000_000_000L
            if (at in 0..head && head - at < rate / 4) {
                val lagUs = (head - at) * 1_000_000L / rate
                settled = true
                measuredLatencyUs = if (measuredLatencyUs < 0) lagUs else (measuredLatencyUs * 7 + lagUs) / 8
                measuredByRate[rate] = measuredLatencyUs
                return@synchronized at.coerceAtMost(written)
            }
        }
        (head - latencyUs() * rate / 1_000_000L).coerceIn(0L, written)
    }
}

/**
 * One AudioTrack's tap into [EchoReference]. The player hands over what it
 * writes ([wrote]) and says when it drops what is queued ([flushed]). The
 * speaker's position comes from a [TrackClock] on the track, or from a
 * player's own validated clock (Sendspin) passed as [clock].
 */
class TrackTap(
    track: AudioTrack,
    rate: Int,
    private val channels: Int,
    private val bytesPerSample: Int = 2,
    private val clock: (() -> Long)? = null,
) : PresentedQueue(rate) {
    private val trackClock = TrackClock(track)

    /** See [TrackClock.settled]. */
    val settled: Boolean get() = clock != null || trackClock.settled

    init {
        EchoReference.add(this)
    }

    /** The track is about to be released: call it while the track still plays. */
    fun close() {
        stopping()
        closeAfterTail()
    }

    /**
     * The track is about to be paused or flushed: what the mixer already
     * took still plays and stays in the reference ([keepPlaying]).
     */
    fun stopping() {
        keepPlaying(presented(), trackClock.mixed())
    }

    fun wrote(bytes: ByteArray, offset: Int, length: Int) {
        wrote(ByteBuffer.wrap(bytes, offset, length), length)
    }

    /** [length] bytes of PCM from [buffer]'s position, left where it was. */
    fun wrote(buffer: ByteBuffer, length: Int) {
        val view = buffer.duplicate().order(ByteOrder.LITTLE_ENDIAN)
        queue(view, length / (channels * bytesPerSample), channels, bytesPerSample)
    }

    /** The track dropped what it had not played: start over from its head. */
    fun flushed() {
        restart()
        trackClock.reset()
    }

    override fun presented(): Long {
        clock?.let { return it() }
        val written = synchronized(lock) { written }
        return trackClock.presented(written)
    }
}

/**
 * A Media3 player's tap into [EchoReference]: the PCM its audio processors
 * see ([TeeAudioProcessor]), timed by a [TrackClock] on the AudioTrack the
 * sink plays it through, which the sink hands over as it makes it
 * ([trackProvider]). The sink flushes its processors and its track
 * together, so the tee's frames and the track's start over as one.
 */
class SinkTap : PresentedQueue(48000), androidx.media3.exoplayer.audio.TeeAudioProcessor.AudioBufferSink {
    private var channels = 2
    private var pcm16 = true
    @Volatile private var trackClock: TrackClock? = null

    /** See [TrackClock.settled]. */
    val settled: Boolean get() = trackClock?.settled == true

    init {
        EchoReference.add(this)
    }

    fun close() {
        closeAfterTail()
    }

    /** For the sink's builder: the tracks it makes, clocked here. */
    fun trackProvider(): androidx.media3.exoplayer.audio.DefaultAudioSink.AudioTrackProvider =
        object : androidx.media3.exoplayer.audio.DefaultAudioSink.AudioTrackProvider {
            private val inner = androidx.media3.exoplayer.audio.DefaultAudioTrackProvider()

            override fun getAudioTrack(
                config: androidx.media3.exoplayer.audio.AudioSink.AudioTrackConfig,
                attributes: androidx.media3.common.AudioAttributes,
                sessionId: Int,
                context: android.content.Context?,
            ): AudioTrack = inner.getAudioTrack(config, attributes, sessionId, context).also {
                trackClock = TrackClock(it)
            }
        }

    override fun flush(sampleRate: Int, channelCount: Int, encoding: Int) {
        // The sink flushes its processors before it stops its track, so the
        // track still says where the speaker and the mixer are.
        trackClock?.let { clock ->
            val rate = synchronized(lock) { rate }
            keepPlaying(presented(), clock.mixed() * rate / clock.rate)
        }
        restart(sampleRate)
        synchronized(lock) {
            channels = channelCount
            pcm16 = encoding == androidx.media3.common.C.ENCODING_PCM_16BIT
        }
        trackClock?.reset()
    }

    override fun handleBuffer(buffer: ByteBuffer) {
        if (!pcm16) return
        val view = buffer.duplicate().order(ByteOrder.LITTLE_ENDIAN)
        queue(view, buffer.remaining() / (channels * 2), channels, 2)
    }

    override fun presented(): Long {
        val clock = trackClock ?: return 0L
        val (written, rate) = synchronized(lock) { written to rate }
        // The track plays at its own rate: the same as the tee's unless
        // the sink resamples in between.
        val frames = clock.presented(written * clock.rate / rate)
        return frames * rate / clock.rate
    }
}

/**
 * Silence ahead of a sound until its track's clock has settled
 * ([TrackClock.settled]), at most [MAX_MS]: the echo canceller then hears
 * every audible frame from a reference placed right, instead of
 * relearning the echo path over the first third of a second of every
 * answer. The sound starts 80 to 250 ms later for it. Chime clips skip
 * it: a late chime is what the user notices, and what follows a chime
 * places itself.
 */
class LeadInProcessor(private val settled: () -> Boolean) :
    androidx.media3.common.audio.BaseAudioProcessor() {
    companion object {
        const val MAX_MS = 300
    }

    private var frameBytes = 2
    private var stepFrames = 160
    private var leadFrames = 0

    override fun onConfigure(
        inputAudioFormat: androidx.media3.common.audio.AudioProcessor.AudioFormat,
    ): androidx.media3.common.audio.AudioProcessor.AudioFormat {
        if (inputAudioFormat.encoding != androidx.media3.common.C.ENCODING_PCM_16BIT) {
            throw androidx.media3.common.audio.AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
        }
        frameBytes = inputAudioFormat.channelCount * 2
        stepFrames = inputAudioFormat.sampleRate / 100
        leadFrames = inputAudioFormat.sampleRate * MAX_MS / 1000
        return inputAudioFormat
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        if (leadFrames > 0 && !settled()) {
            // A step of silence, and the input waits: the sink queues it
            // again once this output is taken.
            val n = minOf(leadFrames, stepFrames)
            leadFrames -= n
            val out = replaceOutputBuffer(n * frameBytes)
            for (i in 0 until n * frameBytes) out.put(0)
            out.flip()
            return
        }
        leadFrames = 0
        val remaining = inputBuffer.remaining()
        if (remaining == 0) return
        replaceOutputBuffer(remaining).put(inputBuffer).flip()
    }

    override fun onFlush() {
        leadFrames = if (stepFrames > 0) stepFrames * 100 * MAX_MS / 1000 else 0
    }
}

/** A Media3 audio sink whose PCM and track both go to [tap], after a lead-in. */
fun tappedSink(
    context: android.content.Context,
    tap: SinkTap,
    vararg before: androidx.media3.common.audio.AudioProcessor,
): androidx.media3.exoplayer.audio.AudioSink =
    androidx.media3.exoplayer.audio.DefaultAudioSink.Builder(context)
        .setAudioProcessors(
            arrayOf(
                LeadInProcessor { tap.settled },
                *before,
                androidx.media3.exoplayer.audio.TeeAudioProcessor(tap),
            ),
        )
        .setAudioTrackProvider(tap.trackProvider())
        .build()

/** Renderers for a Media3 player whose audio also goes to [tap]. */
fun tappedRenderers(context: android.content.Context, tap: SinkTap) =
    object : androidx.media3.exoplayer.DefaultRenderersFactory(context) {
        override fun buildAudioSink(
            context: android.content.Context,
            enableFloatOutput: Boolean,
            enableAudioTrackPlaybackParams: Boolean,
        ): androidx.media3.exoplayer.audio.AudioSink = tappedSink(context, tap)
    }.setEnableDecoderFallback(true)
