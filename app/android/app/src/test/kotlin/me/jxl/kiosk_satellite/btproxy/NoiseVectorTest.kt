package me.jxl.kiosk_satellite.btproxy

import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertFailsWith

/**
 * Validates the Noise responder against the official cacophony test vector
 * for Noise_NNpsk0_25519_ChaChaPoly_SHA256 (the one pattern the ESPHome API
 * uses), byte for byte, including the post-handshake transport ciphers.
 *
 * This matters because a Noise implementation tested only against itself
 * proves nothing: a mirrored mistake (a missed MixKey on the "e" token, a
 * wrong HKDF chain) passes self-tests and then fails against every real
 * Home Assistant. The vector pins us to the spec, not to ourselves.
 */
class NoiseVectorTest {
    // Vector "Noise_NNpsk0_25519_ChaChaPoly_SHA256" from
    // haskell-cryptography/cacophony vectors/cacophony.txt.
    private val prologue = hex("4a6f686e2047616c74")
    private val psk = hex("54686973206973206d7920417573747269616e20706572737065637469766521")
    private val respEphemeral =
        hex("bbdb4cdbd309f1a1f2e1456967fe288cadd6f712d65dc7b7793d5e63da6b375b")

    private val msg0Payload = hex("4c756477696720766f6e204d69736573")
    private val msg0Cipher = hex(
        "ca35def5ae56cec33dc2036731ab14896bc4c75dbb07a61f879f8e3afa4c7944" +
            "79b962b8aff8485742ac32f905ba45369e2465fb59e138a93d67a0d1266b6a54")
    private val msg1Payload = hex("4d757272617920526f746862617264")
    private val msg1Cipher = hex(
        "95ebc60d2b1fa672c1f46a8aa265ef51bfe38e7ccb39ec5be34069f144808843" +
            "d6062704d5a9c422a8e834423f8c1feada7e8d0d910a1a2cd030fb584221e3")

    // Transport messages alternate initiator, responder, initiator, ...
    private val transport = listOf(
        hex("462e20412e20486179656b") to hex("e632c3763d7669067383433197a3baddf146e9e70ad4b4e9e59e0f"),
        hex("4361726c204d656e676572") to hex("64c6bee32ea91c8474bb4c21d7a700109ad45af77b29764ba5eb1e"),
        hex("4a65616e2d426170746973746520536179") to
            hex("e2fa0bed0603b62d3ccac2ecabbf3fe33f3e86514909b323361626266cb2471cc8"),
        hex("457567656e2042f6686d20766f6e2042617765726b") to
            hex("0c01dc9cec1fe4ddd692e8dd32188aa351088dc91183639a53b57aa4692b5ebdef8b8ca111"),
    )

    @Test
    fun handshakeMatchesVector() {
        val responder = NoiseResponder(psk, prologue, respEphemeral)
        val round = responder.readMessageAndRespond(msg0Cipher, msg1Payload)
        assertContentEquals(msg0Payload, round.initiatorPayload)
        assertContentEquals(msg1Cipher, round.response)

        val (decrypt, encrypt) = responder.split()
        // Even indices: initiator to responder (we decrypt); odd: we encrypt.
        transport.forEachIndexed { index, (payload, cipher) ->
            if (index % 2 == 0) {
                assertContentEquals(payload, decrypt.decrypt(cipher))
            } else {
                assertContentEquals(cipher, encrypt.encrypt(payload))
            }
        }
    }

    @Test
    fun wrongPskFailsTheHandshake() {
        val badPsk = psk.copyOf().also { it[0] = (it[0] + 1).toByte() }
        val responder = NoiseResponder(badPsk, prologue, respEphemeral)
        assertFailsWith<NoiseHandshakeException> {
            responder.readMessageAndRespond(msg0Cipher, msg1Payload)
        }
    }

    @Test
    fun truncatedHandshakeMessageFails() {
        val responder = NoiseResponder(psk, prologue, respEphemeral)
        assertFailsWith<NoiseHandshakeException> {
            responder.readMessageAndRespond(msg0Cipher.copyOfRange(0, 40))
        }
    }

    private fun hex(s: String): ByteArray =
        ByteArray(s.length / 2) { ((s[it * 2].digitToInt(16) shl 4) or s[it * 2 + 1].digitToInt(16)).toByte() }
}
