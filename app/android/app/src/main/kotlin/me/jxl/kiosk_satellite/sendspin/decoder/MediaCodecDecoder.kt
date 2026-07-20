package me.jxl.kiosk_satellite.sendspin.decoder

import android.media.MediaCodec
import android.media.MediaFormat
import android.util.Log
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

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
 */
abstract class MediaCodecDecoder(
    protected val mimeType: String
) : AudioDecoder {

    companion object {
        private const val TAG = "MediaCodecDecoder"
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

    override fun decode(compressedData: ByteArray): ByteArray {
        val codec = mediaCodec
            ?: throw IllegalStateException("Decoder not configured")

        val outputBuffer = ByteArrayOutputStream()

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
                    codec.queueInputBuffer(inputIndex, 0, compressedData.size, 0, 0)
                    submitted = true
                }
                break
            }

            // No input buffer available -- drain output to free a slot, then retry.
            if (attempt < MAX_INPUT_RETRIES) {
                drainOutput(codec, outputBuffer)
            }
        }

        if (!submitted) {
            Log.e(TAG, "Failed to submit input after ${MAX_INPUT_RETRIES + 1} attempts, " +
                    "frame dropped (${compressedData.size} bytes)")
        }

        // Drain all available output
        drainOutput(codec, outputBuffer)

        return outputBuffer.toByteArray()
    }

    /**
     * Drain all available output buffers from the codec.
     *
     * Handles all dequeueOutputBuffer status codes correctly:
     * - >= 0: Valid output buffer with PCM data to collect
     * - INFO_OUTPUT_FORMAT_CHANGED: Update cached format, continue draining
     * - INFO_OUTPUT_BUFFERS_CHANGED: Deprecated but harmless, continue draining
     * - INFO_TRY_AGAIN_LATER: No more output available, stop draining
     */
    private fun drainOutput(codec: MediaCodec, outputBuffer: ByteArrayOutputStream) {
        val bufferInfo = MediaCodec.BufferInfo()

        while (true) {
            val outputIndex = codec.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)

            when {
                outputIndex >= 0 -> {
                    val outBuffer = codec.getOutputBuffer(outputIndex)
                    if (outBuffer != null && bufferInfo.size > 0) {
                        val pcmData = ByteArray(bufferInfo.size)
                        outBuffer.position(bufferInfo.offset)
                        outBuffer.get(pcmData, 0, bufferInfo.size)
                        outputBuffer.write(pcmData)
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
