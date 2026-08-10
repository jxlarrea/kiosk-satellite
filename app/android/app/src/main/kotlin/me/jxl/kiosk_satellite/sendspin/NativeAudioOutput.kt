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
 * handed and answers "how many frames have actually been presented since the
 * last poll". That progress feedback is deliberately delta-based and clamped
 * non-negative: on devices whose HAL freezes or rewinds AudioTrack timestamps
 * (Meta Portal, issue #163) a bad clock then degrades into a missed poll
 * instead of a false sync error.
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
    private var headRaw = 0L
    private var headWraps = 0L
    private var lastReportedFrames = 0L

    @Volatile private var halBufferUs = 0L

    // Position-reference latch. The reference is chosen once per stream and
    // never flipped mid-stream: on devices whose getTimestamp is
    // intermittent (SM-X710) or mixer-referenced (Echo Show 8), every
    // reference flip is a ~90ms step in the reported timeline that the
    // library audibly corrects. A constant offset, by contrast, costs one
    // correction at stream start and then stays consistent.
    private var refDecided = false
    private var refIsTimestamp = false
    private var refFramePosition = 0L
    private var refNanoTime = 0L
    private var pollsWithoutTimestamp = 0

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
            resetProgressLocked()
            beginSoftStartLocked(newTrack)
            newTrack.play()
            track = newTrack
            started = true
            Log.i(
                TAG,
                "AudioTrack started sr=$sampleRate ch=$channels bd=$bitDepth " +
                    "minBuf=$minBuf (${minBufMs}ms) buffer=$bufferBytes",
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
        /**
         * Microseconds until those frames actually exit the DAC: the HAL
         * buffer depth, since the count is taken at the mixer head, which
         * leads the speaker by exactly that. Without it the library sees a
         * phantom lead and audibly corrects it every few seconds.
         */
        @JvmField val finishBiasUs: Long,
    )

    /**
     * Frames presented since the previous call, clamped non-negative.
     * Returns null when the position source reports nothing new (including
     * a frozen or retrograde HAL timestamp).
     */
    fun takePresentedFramesDelta(): Progress? {
        synchronized(lock) {
            if (!started) return null
            val presented = presentedFramesLocked()
            val delta = (presented - lastReportedFrames).coerceAtLeast(0)
            if (delta <= 0) return null
            lastReportedFrames = presented
            return Progress(delta, if (refIsTimestamp) 0L else halBufferUs)
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

    private fun presentedFramesLocked(): Long {
        val t = track ?: return 0
        if (t.state != AudioTrack.STATE_INITIALIZED) return 0

        val nowNs = System.nanoTime()
        if (!refDecided || refIsTimestamp) {
            val ts = AudioTimestamp()
            if (t.getTimestamp(ts) && ts.nanoTime != 0L) {
                // Fresh timestamp: latch it as the reference (first success
                // decides the mode for the whole stream).
                refDecided = true
                refIsTimestamp = true
                refFramePosition = ts.framePosition
                refNanoTime = ts.nanoTime
            } else if (!refDecided && ++pollsWithoutTimestamp > 100) {
                // ~0.5s of polls with no timestamp: this device does not do
                // timestamps; count at the head for the rest of the stream.
                refDecided = true
                refIsTimestamp = false
            }
            if (refIsTimestamp) {
                // Extrapolate from the latched timestamp. A HAL that stops
                // producing fresh timestamps mid-stream (frozen clock,
                // issue #106/#163 hardware) would make this run away at
                // nominal rate forever, so 2s without a fresh one demotes
                // the stream to head counting.
                val ageNs = nowNs - refNanoTime
                if (ageNs > 2_000_000_000L) {
                    refIsTimestamp = false
                } else {
                    val extrapolated = ageNs.coerceAtLeast(0) * sampleRate / 1_000_000_000L
                    return refFramePosition + extrapolated
                }
            }
        }
        return headPositionLocked()
    }

    private fun headPositionLocked(): Long {
        val t = track ?: return 0
        val raw = t.playbackHeadPosition.toLong() and 0xFFFF_FFFFL
        if (raw < headRaw) headWraps++
        headRaw = raw
        return raw + (headWraps shl 32)
    }

    private fun resetProgressLocked() {
        framesWritten.set(0)
        headRaw = 0
        headWraps = 0
        refDecided = false
        refIsTimestamp = false
        pollsWithoutTimestamp = 0
        lastReportedFrames = presentedFramesLocked()
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
