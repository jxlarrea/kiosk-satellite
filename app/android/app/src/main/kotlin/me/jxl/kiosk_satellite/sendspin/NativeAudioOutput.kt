package me.jxl.kiosk_satellite.sendspin

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTimestamp
import android.media.AudioTrack
import android.os.SystemClock
import android.util.Log
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicLong

/**
 * AudioTrack output for the native SendSpin engine.
 *
 * sendspin-cpp owns all scheduling; this class only writes the PCM it is
 * handed and reports Android's estimated presentation position. Advancing
 * AudioTrack timestamps provide that reference. Drivers with unusable timestamps
 * use a smoothed playback head with latency compensation instead. Feedback
 * stays non-negative across either source and is timed at the position sample.
 */
class NativeAudioOutput {

    companion object {
        private const val TAG = "NativeAudioOutput"

        // Target writable depth. Large enough to ride out UI jank, small
        // enough that volume/duck changes stay responsive.
        private const val BUFFER_FLOOR_MS = 250

        // When the HAL's own minimum buffer is already deep, inflating it
        // further (the usual 4x safety multiplier) can push the track onto
        // Android's deep-buffer output path, which adds hundreds of ms of
        // poorly reported hardware latency. Keep the multiplier low there.
        private const val DEEP_BUFFER_THRESHOLD_MS = 40

        // Short gain ramp on every (re)start so a flush never pops.
        private const val SOFT_START_MS = 35L
    }

    private val lock = Any()

    @Volatile private var track: AudioTrack? = null
    @Volatile private var started = false

    private var sampleRate = 48000
    private var channels = 2
    private var bitDepth = 16

    private val bytesPerFrame: Int
        get() = channels * (bitDepth / 8)

    private val framesWritten = AtomicLong(0)
    private var lastReportedFrames = 0L
    private var lastFeedbackNs = 0L

    @Volatile private var halBufferUs = 0L
    @Volatile private var sinkLatencyUs = 0L

    private val headClock = PlaybackClock()
    private val presentationClock = PresentationClock()
    private val audioTimestamp = AudioTimestamp()

    @Volatile private var mediaGain = 1f
    @Volatile private var duckGain = 1f
    @Volatile private var softStartBeganMs = 0L

    val isStarted: Boolean get() = started

    fun start(sampleRate: Int, channels: Int, bitDepth: Int): Boolean {
        synchronized(lock) {
            val existing = track
            if (existing != null &&
                this.sampleRate == sampleRate &&
                this.channels == channels &&
                this.bitDepth == bitDepth &&
                existing.state == AudioTrack.STATE_INITIALIZED
            ) {
                try {
                    existing.pause()
                    existing.flush()
                    sinkLatencyUs = measureSinkLatencyUs(
                        existing, existing.bufferSizeInFrames * bytesPerFrame, bytesPerFrame,
                    )
                    resetProgressLocked()
                    beginSoftStartLocked(existing)
                    existing.play()
                    started = true
                    Log.i(TAG, "AudioTrack reused for new stream")
                    return true
                } catch (e: Exception) {
                    Log.w(TAG, "AudioTrack reuse failed, recreating", e)
                }
            }
            releaseLocked()

            val encoding = when (bitDepth) {
                16 -> AudioFormat.ENCODING_PCM_16BIT
                32 -> AudioFormat.ENCODING_PCM_32BIT
                else -> {
                    Log.e(TAG, "Unsupported bit depth $bitDepth")
                    return false
                }
            }
            val channelMask = when (channels) {
                1 -> AudioFormat.CHANNEL_OUT_MONO
                2 -> AudioFormat.CHANNEL_OUT_STEREO
                else -> {
                    Log.e(TAG, "Unsupported channel count $channels")
                    return false
                }
            }
            val frameBytes = channels * (bitDepth / 8)
            val minBuf = AudioTrack.getMinBufferSize(sampleRate, channelMask, encoding)
            if (minBuf <= 0) {
                Log.e(TAG, "Unsupported format sr=$sampleRate ch=$channels bd=$bitDepth")
                return false
            }
            val minBufMs = minBuf * 1000L / (sampleRate.toLong() * frameBytes)
            val multiplier = if (minBufMs > DEEP_BUFFER_THRESHOLD_MS) 2 else 4
            val floorBytes = sampleRate * BUFFER_FLOOR_MS / 1000 * frameBytes
            val bufferBytes = maxOf(minBuf * multiplier, floorBytes)
            halBufferUs = minBufMs * 1000

            val newTrack = try {
                AudioTrack(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelMask)
                        .setEncoding(encoding)
                        .build(),
                    bufferBytes,
                    AudioTrack.MODE_STREAM,
                    AudioManager.AUDIO_SESSION_ID_GENERATE,
                )
            } catch (e: Exception) {
                Log.e(TAG, "AudioTrack create failed", e)
                return false
            }
            if (newTrack.state != AudioTrack.STATE_INITIALIZED) {
                Log.e(TAG, "AudioTrack init failed (state=${newTrack.state})")
                runCatching { newTrack.release() }
                return false
            }

            this.sampleRate = sampleRate
            this.channels = channels
            this.bitDepth = bitDepth
            sinkLatencyUs = measureSinkLatencyUs(
                newTrack, newTrack.bufferSizeInFrames * frameBytes, frameBytes,
            )
            resetProgressLocked()
            beginSoftStartLocked(newTrack)
            newTrack.play()
            track = newTrack
            started = true
            Log.i(
                TAG,
                "AudioTrack started sr=$sampleRate ch=$channels bd=$bitDepth " +
                    "minBuf=$minBuf (${minBufMs}ms) buffer=$bufferBytes " +
                    "sinkLatency=${sinkLatencyUs / 1000}ms",
            )
            return true
        }
    }

    /**
     * Write up to [length] bytes from [buffer], blocking at most [timeoutMs].
     * Returns bytes consumed, always a whole number of frames; the buffer
     * position is advanced by the same amount so the native side resends
     * the remainder.
     */
    fun write(buffer: ByteBuffer, length: Int, timeoutMs: Int): Int {
        if (!started || length <= 0) return 0
        val t = track ?: return 0
        val frameBytes = bytesPerFrame
        val startPos = buffer.position()
        val end = startPos + length.coerceAtMost(buffer.remaining())
        buffer.limit(end)

        val deadline = SystemClock.elapsedRealtime() + timeoutMs.coerceIn(1, 2000)
        var zeroWrites = 0
        while (buffer.position() < end && started) {
            updateSoftStart(t)
            val n = try {
                t.write(buffer, end - buffer.position(), AudioTrack.WRITE_NON_BLOCKING)
            } catch (e: Exception) {
                Log.e(TAG, "AudioTrack write failed", e)
                markDead(t)
                break
            }
            if (n < 0) {
                Log.w(TAG, "AudioTrack write error $n")
                markDead(t)
                break
            }
            if (n == 0) {
                if (SystemClock.elapsedRealtime() >= deadline) break
                zeroWrites++
                try {
                    Thread.sleep(if (zeroWrites > 4) 4 else 2)
                } catch (_: InterruptedException) {
                    break
                }
                continue
            }
            zeroWrites = 0
            framesWritten.addAndGet((n / frameBytes).toLong())
        }

        // Frame-align the report: the native sync task counts played frames
        // from this value, so a mid-frame count would drift its clock.
        var consumed = buffer.position() - startPos
        val remainder = consumed % frameBytes
        if (remainder != 0) {
            consumed -= remainder
            framesWritten.addAndGet(-(remainder / frameBytes).toLong())
            buffer.position(startPos + consumed)
        }
        return consumed
    }

    class Progress(
        /** Frames presented since the previous poll, clamped non-negative. */
        @JvmField val frames: Long,
        /** Monotonic time of the position sample, before any thread handoff. */
        @JvmField val sampledAtUs: Long,
    )

    /**
     * Frames presented since the previous call, clamped non-negative.
     * Returns null when the position source reports nothing new (including
     * a frozen or retrograde HAL timestamp).
     */
    fun takePresentedFramesDelta(): Progress? {
        synchronized(lock) {
            if (!started) return null
            val sampledAtNs = System.nanoTime()
            val presented = presentedFramesLocked(sampledAtNs)
            val delta = (presented - lastReportedFrames).coerceAtLeast(0)
            if (delta <= 0) return null
            lastReportedFrames = presented
            lastFeedbackNs = sampledAtNs
            return Progress(delta, sampledAtNs / 1000)
        }
    }

    /** Written-but-unpresented depth in ms, for diagnostics. */
    fun outputQueueMs(): Long {
        synchronized(lock) {
            if (!started || sampleRate <= 0) return 0
            val queued = (framesWritten.get() - presentedFramesLocked()).coerceAtLeast(0)
            return queued * 1000 / sampleRate
        }
    }

    /** Total frames handed to the AudioTrack this stream, for diagnostics. */
    fun totalFramesWritten(): Long = framesWritten.get()

    /** The platform's underrun counter for the live track, for diagnostics. */
    fun underrunCount(): Int = try {
        track?.underrunCount ?: 0
    } catch (_: Exception) {
        0
    }

    /** Estimated delay from the smoothed head to Android's presentation reference. */
    fun sinkLatencyMs(): Long = synchronized(lock) { presentationClock.latencyUs / 1000 }

    /** Raw driver reports alongside the selected clock, for sync investigations. */
    fun timingDiagnostics(): Map<String, Any?> = synchronized(lock) {
        val t = track ?: return@synchronized emptyMap()
        val timestamp = AudioTimestamp()
        val valid = runCatching { t.getTimestamp(timestamp) }.getOrDefault(false)
        val nowNs = System.nanoTime()
        val latencyMs = runCatching {
            AudioTrack::class.java.getMethod("getLatency").invoke(t) as Int
        }.getOrNull()
        mapOf(
            "clockSource" to presentationClock.source,
            "fallbackReason" to presentationClock.fallbackReason,
            "sampleTimeNs" to nowNs,
            "playbackHeadFrames" to (t.playbackHeadPosition.toLong() and 0xFFFF_FFFFL),
            "reportedFrames" to lastReportedFrames,
            "feedbackSampleTimeNs" to lastFeedbackNs,
            "minimumBufferMs" to halBufferUs / 1000,
            "trackBufferFrames" to t.bufferSizeInFrames,
            "platformLatencyMs" to latencyMs,
            "timestampFrames" to if (valid) timestamp.framePosition else null,
            "timestampNs" to if (valid) timestamp.nanoTime else null,
        )
    }

    fun setMediaGain(gain: Float) {
        mediaGain = gain.coerceIn(0f, 1f)
        applyGain()
    }

    fun setDuckGain(gain: Float) {
        duckGain = gain.coerceIn(0f, 1f)
        applyGain()
    }

    /** Pause and flush but keep the track for reuse across streams. */
    fun pause() {
        synchronized(lock) {
            started = false
            val t = track ?: return
            try {
                t.pause()
                t.flush()
                resetProgressLocked()
            } catch (e: Exception) {
                Log.w(TAG, "AudioTrack pause failed, releasing", e)
                releaseLocked()
            }
        }
    }

    fun release() {
        synchronized(lock) {
            started = false
            releaseLocked()
        }
    }

    // ------------------------------------------------------------------

    private fun presentedFramesLocked(nowNs: Long = System.nanoTime()): Long {
        val t = track ?: return 0
        if (t.state != AudioTrack.STATE_INITIALIZED) return 0
        val written = framesWritten.get()
        val head = headClock.position(
            t.playbackHeadPosition.toLong(), nowNs, written, sampleRate,
            halBufferUs * sampleRate / 1_000_000,
        )
        val valid = presentationClock.canPollTimestamp &&
            runCatching { t.getTimestamp(audioTimestamp) }.getOrDefault(false)
        val previousSource = presentationClock.source
        val presented = presentationClock.position(
            nowNs, head, written, sampleRate,
            if (valid) audioTimestamp.framePosition else null,
            if (valid) audioTimestamp.nanoTime else null,
        )
        if (presentationClock.source != previousSource) {
            Log.i(
                TAG,
                "Playback clock=${presentationClock.source} " +
                    "sinkLatency=${presentationClock.latencyUs / 1000}ms " +
                    "reason=${presentationClock.fallbackReason ?: "validated"}",
            )
        }
        return presented
    }

    private fun resetProgressLocked() {
        framesWritten.set(0)
        headClock.reset()
        presentationClock.reset(System.nanoTime(), sinkLatencyUs)
        lastReportedFrames = 0
        lastFeedbackNs = 0
    }

    /**
     * Initial estimate for devices without usable presentation timestamps.
     * getLatency includes the track buffer, so subtract its actual capacity.
     * The minimum buffer is only a last-resort estimate, never a lower bound
     * on a successful measurement. Valid timestamps calibrate this further.
     */
    private fun measureSinkLatencyUs(t: AudioTrack, bufferBytes: Int, frameBytes: Int): Long {
        val bufferUs = bufferBytes.toLong() * 1_000_000 / (sampleRate.toLong() * frameBytes)
        val fallback = halBufferUs
        return try {
            val method = AudioTrack::class.java.getMethod("getLatency")
            val totalUs = (method.invoke(t) as Int).toLong() * 1000
            (totalUs - bufferUs).takeIf { it in 0..1_000_000L } ?: fallback
        } catch (e: Exception) {
            Log.i(TAG, "getLatency unavailable, using HAL buffer (${e.javaClass.simpleName})")
            fallback
        }
    }

    private fun beginSoftStartLocked(t: AudioTrack) {
        softStartBeganMs = SystemClock.elapsedRealtime()
        runCatching { t.setVolume(0f) }
    }

    private fun updateSoftStart(t: AudioTrack) {
        val began = softStartBeganMs
        if (began == 0L) return
        val elapsed = SystemClock.elapsedRealtime() - began
        if (elapsed >= SOFT_START_MS) {
            softStartBeganMs = 0L
            applyGain()
        } else {
            val ramp = elapsed.toFloat() / SOFT_START_MS
            runCatching { t.setVolume(mediaGain * duckGain * ramp) }
        }
    }

    private fun applyGain() {
        if (softStartBeganMs != 0L) return
        val t = track ?: return
        runCatching { t.setVolume(mediaGain * duckGain) }
    }

    private fun markDead(t: AudioTrack) {
        synchronized(lock) {
            if (track === t) {
                started = false
                releaseLocked()
            }
        }
    }

    private fun releaseLocked() {
        val t = track ?: return
        track = null
        runCatching { t.pause() }
        runCatching { t.flush() }
        runCatching { t.stop() }
        runCatching { t.release() }
    }
}
