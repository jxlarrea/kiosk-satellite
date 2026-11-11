package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The realtime voice session's playback sink: one streaming AudioTrack
 * played as media, fed the model's voice as raw mono PCM16 at the
 * provider's rate (24 kHz for OpenAI and xAI). What it plays goes to the
 * software echo canceller through a [TrackTap].
 *
 * It plays only while there is an answer. Feeding it silence between
 * answers, as a call's downlink does, made the echo canceller worse on a
 * Galaxy Tab S8, twice: a median of 388 against 59 in the microphone
 * while an answer played with the old reference clock, and 39 leaked
 * frames against 2 over a story with the new one. See RealtimeSession's
 * echo settling for what helps.
 *
 * It never drops a backlog. A realtime model sends its answer
 * faster than it plays, so the whole answer can sit in the queue, and
 * [flush] throws it away at once when the user talks over it. The frames
 * of the answer the listener has heard are counted apart from the
 * silence, so the Dart side can tell the model how much was heard.
 *
 * Methods (channel `kiosk_satellite/realtime_audio`):
 *  - start {sampleRate}: opens the track. The rate it plays at, 0 when
 *    it could not open.
 *  - write <bytes>: one chunk, queued to the writer thread.
 *  - flush: drops everything queued and buffered, returns the answer
 *    frames played so far.
 *  - status: {played, written} in answer frames.
 *  - stop: releases the track.
 *
 * The volume is the assistant fader, like every Voice Satellite sound.
 */
class RealtimeAudio(context: Context, messenger: BinaryMessenger) {
    companion object {
        private const val TAG = "RealtimeAudio"
        /**
         * The track's own buffer. Generous: the answer arrives several
         * times faster than it plays, so this is headroom against the
         * writer being held up, not latency, and a flush empties it.
         */
        private const val BUFFER_MS = 600

        /** Answer audio goes to the track in slices, so a flush lands between them. */
        private const val SLICE_MS = 40

    }

    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, "kiosk_satellite/realtime_audio")
    private val mainHandler = Handler(Looper.getMainLooper())
    private val lock = Object()
    private var queue = PlaybackPcmQueue(lock)

    @Volatile private var track: AudioTrack? = null
    @Volatile private var output: AudioDeviceInfo? = null
    @Volatile private var writer: Thread? = null

    /** What the track plays, for the software echo canceller. */
    @Volatile private var tap: TrackTap? = null
    private var rate = 24000

    // Guarded by [lock]. Stream frames count everything written to the
    // track, silence included; answer frames only what the model said.
    private var headBefore = 0L
    private var headOffset = 0L
    private var streamWritten = 0L
    private var answerWritten = 0L

    /** Answer pieces not yet fully played: [stream start, frames]. */
    private val pieces = ArrayDeque<LongArray>()

    /** Answer frames of the pieces already played and dropped from [pieces]. */
    private var answerDone = 0L

    private val volumeListener: () -> Unit = { applyVolume() }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val rate = call.argument<Int>("sampleRate") ?: 24000
                    result.success(if (start(rate)) rate else 0)
                }
                "write" -> {
                    val bytes = call.arguments as? ByteArray
                    if (bytes != null && track != null) {
                        synchronized(lock) {
                            answerWritten += bytes.size / 2
                            queue.offer(bytes)
                        }
                    }
                    result.success(null)
                }
                "flush" -> result.success(flush())
                "status" -> result.success(synchronized(lock) {
                    mapOf("played" to answerPlayed(), "written" to answerWritten)
                })
                "stop" -> { stop(); result.success(null) }
                else -> result.notImplemented()
            }
        }
        VolumeController.addListener(volumeListener)
    }

    private fun start(sampleRate: Int): Boolean {
        stop()
        rate = sampleRate
        val target = AudioRouting.currentOutput()
        val minBuf = AudioTrack.getMinBufferSize(
            sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minBuf <= 0) {
            Log.e(TAG, "unsupported format at $sampleRate Hz")
            return false
        }
        val bufferBytes = maxOf(minBuf * 2, sampleRate * 2 * BUFFER_MS / 1000)
        val newTrack = try {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        // Media, like the chimes and text to speech: Android
                        // puts the master on it.
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build(),
                )
                .setTransferMode(AudioTrack.MODE_STREAM)
                .setBufferSizeInBytes(bufferBytes)
                .build()
        } catch (e: Exception) {
            Log.e(TAG, "AudioTrack create failed", e)
            return false
        }
        if (newTrack.state != AudioTrack.STATE_INITIALIZED) {
            Log.e(TAG, "AudioTrack init failed (state=${newTrack.state})")
            runCatching { newTrack.release() }
            return false
        }
        if (Build.VERSION.SDK_INT >= 28 && target != null) {
            runCatching { newTrack.preferredDevice = target }
        }
        queue = PlaybackPcmQueue(lock)
        synchronized(lock) {
            headBefore = 0L
            streamWritten = 0L
            answerWritten = 0L
            answerDone = 0L
            pieces.clear()
        }
        track = newTrack
        output = target
        tap = TrackTap(newTrack, sampleRate, 1)
        val equalizer = Equalizer.Stream(sampleRate, 1)
        SoftwareEcho.setMode(this, ResidualEchoGate.Mode.REALTIME)
        applyVolume()
        newTrack.play()
        synchronized(lock) { headOffset = head(newTrack) }
        val pending = queue
        val thread = Thread({ feed(newTrack, pending, equalizer) }, "ks-realtime")
        writer = thread
        thread.start()
        Log.i(TAG, "playback started at $sampleRate Hz (buffer=${bufferBytes}b)")
        return true
    }

    private fun head(t: AudioTrack): Long =
        runCatching { t.playbackHeadPosition.toLong() and 0xFFFFFFFFL }.getOrDefault(0L)

    /** Stream frames played since start, across flushes. Under [lock]. */
    private fun streamPlayed(): Long {
        val t = track ?: return headBefore
        return headBefore + maxOf(0L, head(t) - headOffset)
    }

    /** Answer frames played since start: silence does not count. Under [lock]. */
    private fun answerPlayed(): Long {
        val played = streamPlayed()
        while (pieces.isNotEmpty() && pieces.first()[0] + pieces.first()[1] <= played) {
            answerDone += pieces.removeFirst()[1]
        }
        var total = answerDone
        for (piece in pieces) {
            if (piece[0] >= played) break
            total += minOf(piece[1], played - piece[0])
        }
        return total
    }

    /** The writer thread: the model's voice as it arrives. */
    private fun feed(t: AudioTrack, pending: PlaybackPcmQueue, equalizer: Equalizer.Stream) {
        // At normal priority, a device busy starting up (the app after a
        // restart, a reopened microphone) held this thread up long enough
        // for the track to run dry every second, with half a minute of the
        // answer waiting in the queue.
        runCatching { Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO) }
        val slice = rate * 2 * SLICE_MS / 1000
        while (track === t) {
            val chunk = try {
                pending.poll()
            } catch (_: InterruptedException) {
                break
            }
            if (track !== t) break
            if (chunk != null) {
                // Equalized as a whole before any of it is written, so the
                // tap below hands the canceller what the speaker plays.
                equalizer.process(chunk.pcm, 0, chunk.pcm.size)
                var offset = 0
                while (offset < chunk.pcm.size && track === t) {
                    val n = try {
                        pending.write(chunk) { pcm ->
                            if (track !== t) return@write -1
                            val length = minOf(slice, pcm.size - offset)
                            // A nonblocking write and the tap stay inside
                            // the flush lock. Only accepted bytes enter the
                            // reference, with no wait for speaker playback.
                            val accepted = t.write(pcm, offset, length, AudioTrack.WRITE_NON_BLOCKING)
                            if (accepted > 0) {
                                tap?.wrote(pcm, offset, accepted)
                                pieces.addLast(longArrayOf(streamWritten, accepted / 2L))
                                streamWritten += accepted / 2
                            }
                            accepted
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "write failed: ${e.message}")
                        -1
                    }
                    if (n == null || n < 0) break
                    if (n == 0) {
                        try {
                            Thread.sleep(10)
                        } catch (_: InterruptedException) {
                            return
                        }
                    } else {
                        offset += n
                    }
                }
                continue
            }
        }
    }

    /**
     * The user talked over the answer: whatever is queued or in the track's
     * buffer goes, now. Returns the answer frames played up to this moment.
     */
    private fun flush(): Long {
        val t = track ?: return 0L
        synchronized(lock) {
            queue.clear()
            // Writes are nonblocking and share this lock, so no old
            // slice can arrive between the flush and the next play.
            tap?.stopping()
            runCatching { t.pause() }
            val stream = streamPlayed()
            val heard = answerPlayed()
            runCatching { t.flush() }
            // Whatever was not played is gone: cut the pieces there.
            val kept = ArrayDeque<LongArray>()
            for (piece in pieces) {
                if (piece[0] >= stream) break
                kept.addLast(longArrayOf(piece[0], minOf(piece[1], stream - piece[0])))
            }
            pieces.clear()
            pieces.addAll(kept)
            headBefore = stream
            streamWritten = stream
            answerWritten = heard
            runCatching { t.play() }
            headOffset = head(t)
            tap?.flushed()
            return heard
        }
    }

    private fun applyVolume() {
        val t = track ?: return
        val level = PlaybackVolume.level(1f, VolumeController.assistGain, 1f)
        runCatching { t.setVolume(level) }
        tap?.gain = level
    }

    private fun stop() {
        val t = track ?: return
        synchronized(lock) {
            track = null
            queue.clear()
        }
        SoftwareEcho.setMode(this, null)
        tap?.close()
        tap = null
        val thread = writer
        writer = null
        output = null
        runCatching { t.pause() }
        thread?.interrupt()
        Thread {
            runCatching { thread?.join(500) }
            runCatching { t.flush() }
            runCatching { t.release() }
            Log.i(TAG, "playback stopped")
        }.start()
    }
}
