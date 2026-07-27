package me.jxl.kiosk_satellite.sendspin.decoder

import android.media.MediaCodec
import android.media.MediaFormat
import android.util.Log

/**
 * Base class for MediaCodec-based audio decoders.
 *
 * Provides synchronous decoding using Android's MediaCodec API.
 * Subclasses implement codec-specific format configuration.
 *
 * This decoder operates MediaCodec in synchronous mode, where:
 * - Input buffers are submitted via dequeueInputBuffer/queueInputBuffer
 * - Output buffers are drained via dequeueOutputBuffer/releaseOutputBuffer
 * - flush() returns to the Flushed sub-state without needing start()
 *
 * The codec is a queue, not a function: on a slow device the PCM for an
 * input can surface a decode() call or two later. The server timestamp
 * therefore travels through the codec as presentationTimeUs, and every
 * output span is stamped with the time the codec reports for it — never
 * with "the timestamp of whatever input happened to be submitted last".
 */
abstract class MediaCodecDecoder(
    protected val mimeType: String
) : AudioDecoder {

    companion object {
        // The shared sendspin tag: a "logcat -s sendspin" capture (what issue
        // templates ask for) must include decoder drops, not hide them.
        private const val TAG = "sendspin"
        private const val TIMEOUT_US = 10_000L  // 10ms timeout for buffer operations

        /**
         * Maximum number of retry attempts when no input buffer is available.
         * Each retry waits TIMEOUT_US (10ms), so 3 retries = up to 40ms total
         * (initial attempt + 3 retries). This keeps latency bounded while giving
         * the codec time to free a buffer by processing output.
         */
        private const val MAX_INPUT_RETRIES = 3
    }

    protected var mediaCodec: MediaCodec? = null
    protected var outputFormat: MediaFormat? = null
    private var _isConfigured = false

    // Reused across decode() calls to avoid per-call allocation churn on the
    // hot audio path. decode() is single-threaded.
    private val bufferInfo = MediaCodec.BufferInfo()

    /** Frames thrown away because the codec refused input; see interface. */
    private var _inputFramesDropped = 0L
    override val inputFramesDropped: Long get() = _inputFramesDropped

    /**
     * Where the next output span should start if the codec reports no usable
     * presentation time of its own (some decoders zero it out). Follows the
     * emitted spans; re-seeded from the input timestamp on flush/start.
     */
    private var fallbackPtsUs = -1L

    override val isConfigured: Boolean
        get() = _isConfigured

    override fun configure(
        sampleRate: Int,
        channels: Int,
        bitDepth: Int,
        codecHeader: ByteArray?
    ) {
        try {
            // Create base MediaFormat
            val format = MediaFormat.createAudioFormat(mimeType, sampleRate, channels)

            // Apply codec-specific configuration (template method)
            configureFormat(format, sampleRate, channels, bitDepth, codecHeader)

            // Create and configure decoder
            mediaCodec = MediaCodec.createDecoderByType(mimeType)
            mediaCodec?.configure(format, null, null, 0)
            mediaCodec?.start()

            _isConfigured = true
            Log.d(TAG, "Decoder configured: $mimeType, ${sampleRate}Hz, ${channels}ch")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to configure decoder", e)
            release()
            throw e
        }
    }

    /**
     * Template method for codec-specific format configuration.
     *
     * Subclasses override this to set codec-specific parameters like
     * CSD (Codec Specific Data) buffers.
     */
    protected abstract fun configureFormat(
        format: MediaFormat,
        sampleRate: Int,
        channels: Int,
        bitDepth: Int,
        codecHeader: ByteArray?
    )

    override fun decode(
        serverTimeMicros: Long,
        compressedData: ByteArray
    ): List<DecodedAudio> {
        val codec = mediaCodec
            ?: throw IllegalStateException("Decoder not configured")

        if (fallbackPtsUs < 0) fallbackPtsUs = serverTimeMicros
        val spans = ArrayList<DecodedAudio>(2)

        // Submit input with retry.
        // When all input buffers are occupied (codec backpressure), we drain
        // output to free slots, then retry. This prevents silent frame drops
        // that would corrupt stateful codecs like Opus.
        var submitted = false
        for (attempt in 0..MAX_INPUT_RETRIES) {
            val inputIndex = codec.dequeueInputBuffer(TIMEOUT_US)
            if (inputIndex >= 0) {
                val inputBuffer = codec.getInputBuffer(inputIndex)
                if (inputBuffer != null) {
                    inputBuffer.clear()
                    inputBuffer.put(compressedData)
                    codec.queueInputBuffer(
                        inputIndex, 0, compressedData.size, serverTimeMicros, 0)
                    submitted = true
                }
                break
            }

            // No input buffer available -- drain output to free a slot, then retry.
            if (attempt < MAX_INPUT_RETRIES) {
                drainOutput(codec, spans)
            }
        }

        if (!submitted) {
            _inputFramesDropped++
            Log.e(TAG, "Failed to submit input after ${MAX_INPUT_RETRIES + 1} attempts, " +
                    "frame dropped (${compressedData.size} bytes, " +
                    "total dropped: $_inputFramesDropped)")
        }

        // Drain all available output
        drainOutput(codec, spans)

        return spans
    }

    /**
     * Drain all available output buffers from the codec into [spans].
     *
     * Handles all dequeueOutputBuffer status codes correctly:
     * - >= 0: Valid output buffer with PCM data to collect
     * - INFO_OUTPUT_FORMAT_CHANGED: Update cached format, continue draining
     * - INFO_OUTPUT_BUFFERS_CHANGED: Deprecated but harmless, continue draining
     * - INFO_TRY_AGAIN_LATER: No more output available, stop draining
     */
    private fun drainOutput(codec: MediaCodec, spans: MutableList<DecodedAudio>) {
        while (true) {
            val outputIndex = codec.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)

            when {
                outputIndex >= 0 -> {
                    val outBuffer = codec.getOutputBuffer(outputIndex)
                    if (outBuffer != null && bufferInfo.size > 0) {
                        // A fresh array per span: the caller owns it
                        // (SyncAudioPlayer queues and mutates it in place).
                        val pcm = ByteArray(bufferInfo.size)
                        outBuffer.position(bufferInfo.offset)
                        outBuffer.get(pcm, 0, bufferInfo.size)
                        // The codec echoes the input's presentationTimeUs;
                        // fall back to the running continuation for the odd
                        // decoder that reports none.
                        val pts = if (bufferInfo.presentationTimeUs > 0) {
                            bufferInfo.presentationTimeUs
                        } else {
                            fallbackPtsUs
                        }
                        spans.add(DecodedAudio(pts, pcm))
                        fallbackPtsUs = pts + pcmDurationUs(pcm.size)
                    }
                    codec.releaseOutputBuffer(outputIndex, false)
                }

                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    outputFormat = codec.outputFormat
                    Log.d(TAG, "Output format changed: $outputFormat")
                    // Continue draining -- there may be more output buffers
                }

                @Suppress("DEPRECATION")
                outputIndex == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED -> {
                    // Deprecated since API 21, but some devices still return it.
                    // No action needed; continue draining.
                }

                else -> {
                    // INFO_TRY_AGAIN_LATER or any unknown negative value: done
                    break
                }
            }
        }
    }

    /** Duration of [bytes] of output PCM, from the codec's reported format. */
    private fun pcmDurationUs(bytes: Int): Long {
        val format = outputFormat
        val sampleRate = format?.getInteger(MediaFormat.KEY_SAMPLE_RATE) ?: 48000
        val channels = format?.getInteger(MediaFormat.KEY_CHANNEL_COUNT) ?: 2
        val bytesPerFrame = channels * 2  // MediaCodec outputs 16-bit PCM
        if (sampleRate <= 0 || bytesPerFrame <= 0) return 0
        return (bytes.toLong() / bytesPerFrame) * 1_000_000L / sampleRate
    }

    /**
     * Flush the decoder to reset internal state.
     *
     * In synchronous mode (no callback set), flush() moves the codec to the
     * Flushed sub-state within the Executing state. The codec automatically
     * resumes to the Running sub-state on the next dequeueInputBuffer() call.
     * Calling start() here would be an illegal state transition (start() is
     * only valid from the Configured state, or after flush() in async mode).
     */
    override fun flush() {
        try {
            mediaCodec?.flush()
            fallbackPtsUs = -1L
            Log.d(TAG, "Decoder flushed")
        } catch (e: Exception) {
            Log.e(TAG, "Error flushing decoder", e)
        }
    }

    override fun release() {
        try {
            mediaCodec?.stop()
            mediaCodec?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing decoder", e)
        } finally {
            mediaCodec = null
            _isConfigured = false
            Log.d(TAG, "Decoder released")
        }
    }
}
