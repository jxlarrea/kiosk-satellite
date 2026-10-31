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

    fun sources(): List<Source> = sources

    fun audible() {
        lastAudibleMs = SystemClock.elapsedRealtime()
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

    override fun take(): ShortArray? {
        val presented = presented()
        return synchronized(lock) { taken(presented) }
    }

    private fun taken(presented: Long): ShortArray? {
        if (queuedLength == 0) return null
        val presented16 = presented * EchoReference.RATE / rate
        val upto = (presented16 - queuedFrom).coerceIn(0L, queuedLength.toLong()).toInt()
        if (upto == 0) return null
        val out = queued.copyOf(upto)
        val g = gain
        if (g != 1f) for (i in out.indices) out[i] = (out[i] * g).toInt().toShort()
        System.arraycopy(queued, upto, queued, 0, queuedLength - upto)
        queuedLength -= upto
        queuedFrom += upto
        return out
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

    fun close() {
        EchoReference.remove(this)
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
        EchoReference.remove(this)
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
