package me.jxl.kiosk_satellite.sendspin.decoder

/**
 * A span of decoded PCM together with the server timestamp it belongs to.
 *
 * Timestamps ride through the decoder instead of being re-attached by the
 * caller: a MediaCodec is a queue, and on a slow device the PCM for an
 * input frame routinely comes out one or more decode() calls later. If the
 * caller stamped "whatever came out now" with the current chunk's time,
 * delayed output would be mis-stamped (shifting the whole stream) and a
 * chunk whose output was not ready yet would lose its audio entirely —
 * the periodic stutter of issue #59.
 */
class DecodedAudio(
    val serverTimeMicros: Long,
    val pcm: ByteArray,
)

/**
 * Interface for audio decoders that convert compressed audio to PCM.
 *
 * Implementations handle specific codecs (PCM pass-through, FLAC, OPUS)
 * and are created via [AudioDecoderFactory].
 */
interface AudioDecoder {

    /**
     * Configure the decoder with stream parameters.
     *
     * @param sampleRate Audio sample rate in Hz (e.g., 48000)
     * @param channels Number of audio channels (1 = mono, 2 = stereo)
     * @param bitDepth Bits per sample (typically 16)
     * @param codecHeader Optional codec-specific header data (e.g., FLAC STREAMINFO, Opus header)
     */
    fun configure(
        sampleRate: Int,
        channels: Int,
        bitDepth: Int,
        codecHeader: ByteArray? = null
    )

    /**
     * Decode a compressed audio chunk to PCM.
     *
     * May return zero spans (the codec has not produced output yet) or
     * several (output from earlier inputs became ready); each span carries
     * the server timestamp of the input frame it was decoded from.
     *
     * @param serverTimeMicros Server timestamp of [compressedData]
     * @param compressedData The compressed audio data from the server
     * @return Decoded PCM spans (16-bit signed, little-endian, interleaved)
     * @throws IllegalStateException if decoder is not configured
     */
    fun decode(serverTimeMicros: Long, compressedData: ByteArray): List<DecodedAudio>

    /**
     * Flush the decoder state.
     *
     * Call this on stream/clear or when seeking to reset internal buffers.
     * After flush, the decoder remains configured and ready to decode.
     */
    fun flush()

    /**
     * Release decoder resources.
     *
     * After release, the decoder cannot be used. Create a new instance if needed.
     */
    fun release()

    /**
     * Check if the decoder is properly configured and ready to decode.
     */
    val isConfigured: Boolean

    /**
     * Compressed frames discarded because the codec would not accept input
     * (sustained backpressure). Diagnostic; zero for pass-through decoders.
     */
    val inputFramesDropped: Long get() = 0
}
