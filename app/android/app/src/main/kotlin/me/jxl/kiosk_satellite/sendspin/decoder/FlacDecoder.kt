package me.jxl.kiosk_satellite.sendspin.decoder

import android.media.MediaFormat
import android.util.Log
import java.nio.ByteBuffer

/**
 * FLAC audio decoder using Android MediaCodec.
 *
 * FLAC is a lossless compression codec. Each frame can be decoded independently,
 * making it well-suited for streaming applications.
 *
 * The codec_header from stream/start should contain the FLAC STREAMINFO metadata
 * block, which is required by MediaCodec as CSD-0 (Codec Specific Data).
 */
class FlacDecoder : MediaCodecDecoder(MediaFormat.MIMETYPE_AUDIO_FLAC) {

    companion object {
        private const val TAG = "FlacDecoder"
    }

    override fun configureFormat(
        format: MediaFormat,
        sampleRate: Int,
        channels: Int,
        bitDepth: Int,
        codecHeader: ByteArray?
    ) {
        // FLAC requires the STREAMINFO metadata block as CSD-0
        // This 34-byte block contains:
        // - Minimum/maximum block size
        // - Minimum/maximum frame size
        // - Sample rate, channels, bits per sample
        // - Total samples
        // - MD5 signature
        if (codecHeader != null && codecHeader.isNotEmpty()) {
            format.setByteBuffer("csd-0", ByteBuffer.wrap(codecHeader))
            Log.d(TAG, "Set FLAC STREAMINFO from codec_header (${codecHeader.size} bytes)")
        } else {
            // Some servers may not send codec_header - MediaCodec may still work
            // if it can parse the STREAMINFO from the first frame
            Log.w(TAG, "No codec_header provided for FLAC - decoder may fail")
        }
    }
}
