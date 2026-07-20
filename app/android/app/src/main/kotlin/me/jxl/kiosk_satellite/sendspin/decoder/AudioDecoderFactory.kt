package me.jxl.kiosk_satellite.sendspin.decoder

import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Build
import android.media.MediaCodecList
import android.media.MediaFormat
import android.util.Log
import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocol

/**
 * Factory for creating audio decoders based on codec type.
 *
 * Provides methods to create decoders and check codec support on the device.
 */
object AudioDecoderFactory {

    private const val TAG = "AudioDecoderFactory"

    /**
     * Create a decoder for the specified codec.
     *
     * @param codec The codec identifier ("pcm", "flac", "opus")
     * @return An appropriate AudioDecoder implementation
     */
    fun create(codec: String): AudioDecoder {
        return when (codec.lowercase()) {
            "pcm" -> PcmDecoder()
            "flac" -> {
                if (isCodecSupported("flac")) {
                    FlacDecoder()
                } else {
                    Log.w(TAG, "FLAC not supported on this device, falling back to PCM")
                    PcmDecoder()
                }
            }
            "opus" -> {
                if (isCodecSupported("opus")) {
                    OpusDecoder()
                } else {
                    Log.w(TAG, "OPUS not supported on this device, falling back to PCM")
                    PcmDecoder()
                }
            }
            else -> {
                Log.w(TAG, "Unknown codec: $codec, falling back to PCM")
                PcmDecoder()
            }
        }
    }

    /**
     * Check if a codec is supported on this device.
     *
     * @param codec The codec identifier ("pcm", "flac", "opus")
     * @return true if the codec is supported
     */
    fun isCodecSupported(codec: String): Boolean {
        return when (codec.lowercase()) {
            "pcm" -> true  // Always supported
            "flac" -> isMediaCodecSupported(MediaFormat.MIMETYPE_AUDIO_FLAC)
            "opus" -> isMediaCodecSupported(MediaFormat.MIMETYPE_AUDIO_OPUS)
            else -> false
        }
    }

    /**
     * Get list of all supported codecs on this device.
     *
     * @return List of supported codec identifiers
     */
    fun getSupportedCodecs(): List<String> {
        return listOf("pcm", "flac", "opus").filter { isCodecSupported(it) }
    }

    /**
     * Get list of PCM bit depths supported by the device's AudioTrack hardware.
     *
     * Probes AudioTrack.getMinBufferSize for each encoding to detect support.
     * 16-bit is always included. 24-bit packed (ENCODING_PCM_24BIT_PACKED) and
     * 32-bit integer (ENCODING_PCM_32BIT) require API 31+.
     *
     * @return Sorted list of supported bit depths (e.g., [16, 24, 32])
     */
    fun getSupportedPcmBitDepths(): List<Int> {
        val depths = mutableListOf(16)

        // 32-bit integer PCM (ENCODING_PCM_32BIT) - API 31+
        if (Build.VERSION.SDK_INT >= 31) {
            try {
                val minBuf = AudioTrack.getMinBufferSize(
                    SendSpinProtocol.AudioFormat.SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_32BIT
                )
                if (minBuf > 0) depths.add(32)
            } catch (e: Exception) {
                Log.d(TAG, "32-bit integer PCM not supported: ${e.message}")
            }
        }

        // 24-bit packed (ENCODING_PCM_24BIT_PACKED) - API 31+
        if (Build.VERSION.SDK_INT >= 31) {
            try {
                val minBuf = AudioTrack.getMinBufferSize(
                    SendSpinProtocol.AudioFormat.SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_24BIT_PACKED
                )
                if (minBuf > 0) depths.add(24)
            } catch (e: Exception) {
                Log.d(TAG, "24-bit packed PCM not supported: ${e.message}")
            }
        }

        return depths.sorted()
    }

    private fun isMediaCodecSupported(mimeType: String): Boolean {
        val format = MediaFormat().apply { setString(MediaFormat.KEY_MIME, mimeType) }
        val codecName = MediaCodecList(MediaCodecList.REGULAR_CODECS)
            .findDecoderForFormat(format)
        if (codecName == null) {
            Log.d(TAG, "No decoder available for $mimeType")
        }
        return codecName != null
    }
}
