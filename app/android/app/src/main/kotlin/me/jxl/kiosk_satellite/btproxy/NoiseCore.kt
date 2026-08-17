package me.jxl.kiosk_satellite.btproxy

import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import org.bouncycastle.crypto.modes.ChaCha20Poly1305
import org.bouncycastle.crypto.params.AEADParameters
import org.bouncycastle.crypto.params.KeyParameter
import org.bouncycastle.math.ec.rfc7748.X25519

/**
 * Responder side of Noise_NNpsk0_25519_ChaChaPoly_SHA256, the only pattern
 * the ESPHome native API speaks.
 *
 * Implemented directly from the Noise Protocol Framework spec (revision 34)
 * rather than a library: the platform JCA has no X25519 until API 33, the
 * one maintained JVM Noise library is unmaintained on Android, and the
 * handshake is two messages with no branching: small enough that the spec
 * text maps line-for-line onto this file. BouncyCastle's lightweight API
 * supplies the two primitives (X25519, ChaCha20-Poly1305) that the platform
 * lacks; hashing and HMAC come from the JCA, which every supported API level
 * has.
 *
 * NNpsk0 message sequence, responder view:
 *   <- psk, e          (client: mix PSK, send ephemeral, encrypted payload)
 *   -> e, ee           (server: send ephemeral, DH, encrypted payload)
 * followed by Split() into the two one-way transport ciphers.
 *
 * Because the pattern uses a psk token, the "e" token additionally calls
 * MixKey(e.public) on both sides (spec section 9.1): forgetting that one
 * line produces a handshake that fails only against real clients, not
 * against a mirror-image of itself.
 */
internal class NoiseResponder(
    psk32: ByteArray,
    prologue: ByteArray,
    /**
     * Tests only: a fixed ephemeral private key so the official cacophony
     * test vector can validate this implementation byte-for-byte. Production
     * always passes null and gets a fresh SecureRandom key per handshake.
     */
    private val ephemeralOverride: ByteArray? = null,
) {
    companion object {
        private val PROTOCOL_NAME =
            "Noise_NNpsk0_25519_ChaChaPoly_SHA256".toByteArray(Charsets.US_ASCII)
        const val DH_LEN = 32
        const val TAG_LEN = 16
    }

    init {
        require(psk32.size == 32) { "psk must be 32 bytes" }
    }

    private val psk = psk32.copyOf()

    // SymmetricState: h chains every byte of the handshake so the final
    // transport keys authenticate the whole transcript; ck feeds HKDF.
    private var h: ByteArray = sha256(PROTOCOL_NAME) // name > 32 bytes -> hashed
    private var ck: ByteArray = h.copyOf()
    private var k: ByteArray? = null
    private var n: Long = 0

    init {
        mixHash(prologue)
    }

    /** Result of the one handshake round: what the initiator said, what to send back. */
    class Round(val initiatorPayload: ByteArray, val response: ByteArray)

    /**
     * Consumes the initiator's handshake message (psk, e + encrypted payload)
     * and produces our response message (e, ee + encrypted [responsePayload],
     * empty on the wire in production). Throws [NoiseHandshakeException] on
     * any mismatch: a wrong PSK surfaces here as a MAC failure on the
     * initiator payload.
     */
    fun readMessageAndRespond(
        message: ByteArray,
        responsePayload: ByteArray = ByteArray(0),
    ): Round {
        if (message.size < DH_LEN + TAG_LEN) {
            throw NoiseHandshakeException("handshake message too short (${message.size})")
        }

        // psk
        mixKeyAndHash(psk)

        // e (remote): MixHash always, MixKey additionally in psk handshakes.
        val re = message.copyOfRange(0, DH_LEN)
        mixHash(re)
        mixKey(re)

        // Initiator payload (empty in practice, but must authenticate).
        val initiatorPayload = decryptAndHash(message.copyOfRange(DH_LEN, message.size))

        // e (local)
        val privateKey = ephemeralOverride?.copyOf() ?: ByteArray(DH_LEN).also {
            X25519.generatePrivateKey(SecureRandom(), it)
        }
        val publicKey = ByteArray(DH_LEN)
        X25519.generatePublicKey(privateKey, 0, publicKey, 0)
        mixHash(publicKey)
        mixKey(publicKey)

        // ee
        val shared = ByteArray(DH_LEN)
        if (!X25519.calculateAgreement(privateKey, 0, re, 0, shared, 0)) {
            throw NoiseHandshakeException("X25519 agreement produced an all-zero point")
        }
        mixKey(shared)
        privateKey.fill(0)

        val payload = encryptAndHash(responsePayload)
        return Round(initiatorPayload, publicKey + payload)
    }

    /**
     * Split(): call once after [readMessageAndRespond]. Initiator-to-
     * responder traffic uses the first derived key, so for the server the
     * pair is (decrypt = first, encrypt = second).
     */
    fun split(): Pair<NoiseCipher, NoiseCipher> {
        val (k1, k2) = hkdf2(ck, ByteArray(0))
        return NoiseCipher(k1) to NoiseCipher(k2)
    }

    // --- SymmetricState operations, straight from the spec ---

    private fun mixHash(data: ByteArray) {
        h = sha256(h + data)
    }

    private fun mixKey(input: ByteArray) {
        val (newCk, tempK) = hkdf2(ck, input)
        ck = newCk
        k = tempK
        n = 0
    }

    private fun mixKeyAndHash(input: ByteArray) {
        val (newCk, tempH, tempK) = hkdf3(ck, input)
        ck = newCk
        mixHash(tempH)
        k = tempK
        n = 0
    }

    private fun encryptAndHash(plaintext: ByteArray): ByteArray {
        val key = k ?: throw NoiseHandshakeException("encrypt before key established")
        val ciphertext = chaChaPoly(true, key, n++, h, plaintext)
        mixHash(ciphertext)
        return ciphertext
    }

    private fun decryptAndHash(ciphertext: ByteArray): ByteArray {
        val key = k ?: throw NoiseHandshakeException("decrypt before key established")
        val plaintext = chaChaPoly(false, key, n++, h, ciphertext)
        mixHash(ciphertext)
        return plaintext
    }
}

/**
 * One direction of post-handshake transport encryption: ChaCha20-Poly1305
 * with the Noise nonce layout (4 zero bytes + 64-bit little-endian counter).
 * TCP delivers in order or not at all, so a counter mismatch can only mean
 * corruption or a wrong key: both are session-fatal, never recoverable.
 */
internal class NoiseCipher(private val key: ByteArray) {
    private var n: Long = 0

    fun encrypt(plaintext: ByteArray): ByteArray = chaChaPoly(true, key, n++, ByteArray(0), plaintext)

    fun decrypt(ciphertext: ByteArray): ByteArray = chaChaPoly(false, key, n++, ByteArray(0), ciphertext)
}

internal class NoiseHandshakeException(message: String) : Exception(message)

private fun sha256(data: ByteArray): ByteArray =
    MessageDigest.getInstance("SHA-256").digest(data)

private fun hmac(key: ByteArray, data: ByteArray): ByteArray =
    Mac.getInstance("HmacSHA256").run {
        init(SecretKeySpec(key, "HmacSHA256"))
        doFinal(data)
    }

private fun hkdf2(chainingKey: ByteArray, input: ByteArray): Pair<ByteArray, ByteArray> {
    val tempKey = hmac(chainingKey, input)
    val out1 = hmac(tempKey, byteArrayOf(0x01))
    val out2 = hmac(tempKey, out1 + byteArrayOf(0x02))
    return out1 to out2
}

private fun hkdf3(chainingKey: ByteArray, input: ByteArray): Triple<ByteArray, ByteArray, ByteArray> {
    val tempKey = hmac(chainingKey, input)
    val out1 = hmac(tempKey, byteArrayOf(0x01))
    val out2 = hmac(tempKey, out1 + byteArrayOf(0x02))
    val out3 = hmac(tempKey, out2 + byteArrayOf(0x03))
    return Triple(out1, out2, out3)
}

private fun chaChaPoly(
    encrypt: Boolean,
    key: ByteArray,
    counter: Long,
    associatedData: ByteArray,
    input: ByteArray,
): ByteArray {
    val nonce = ByteArray(12)
    for (i in 0 until 8) nonce[4 + i] = ((counter ushr (8 * i)) and 0xFF).toByte()
    val cipher = ChaCha20Poly1305()
    cipher.init(encrypt, AEADParameters(KeyParameter(key), 128, nonce, associatedData))
    val out = ByteArray(cipher.getOutputSize(input.size))
    val len = cipher.processBytes(input, 0, input.size, out, 0)
    try {
        cipher.doFinal(out, len)
    } catch (e: Exception) {
        // BC throws InvalidCipherTextException on MAC mismatch; normalize so
        // the transport can answer with the exact "Handshake MAC failure" /
        // close behavior each stage requires.
        throw NoiseHandshakeException("AEAD failure: ${e.message}")
    }
    return out
}
