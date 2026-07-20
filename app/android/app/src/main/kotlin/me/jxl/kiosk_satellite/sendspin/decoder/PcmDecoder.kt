package me.jxl.kiosk_satellite.sendspin.decoder

/**
 * Pass-through decoder for PCM audio.
 *
 * Since PCM data is already uncompressed, this decoder simply returns
 * the input data unchanged. It exists to provide a uniform interface
 * for all audio formats.
 */
class PcmDecoder : AudioDecoder {

    private var _isConfigured = false

    override val isConfigured: Boolean
        get() = _isConfigured

    override fun configure(
        sampleRate: Int,
        channels: Int,
        bitDepth: Int,
        codecHeader: ByteArray?
    ) {
        // PCM requires no configuration - just mark as ready
        _isConfigured = true
    }

    override fun decode(compressedData: ByteArray): ByteArray {
        // PCM is already decoded - pass through unchanged
        return compressedData
    }

    override fun flush() {
        // No internal state to flush for PCM
    }

    override fun release() {
        _isConfigured = false
    }
}
