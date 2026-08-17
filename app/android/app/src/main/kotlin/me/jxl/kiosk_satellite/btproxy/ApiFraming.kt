package me.jxl.kiosk_satellite.btproxy

import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.DataInputStream
import java.io.EOFException
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream

/**
 * Framing for the ESPHome native API socket, both flavors:
 *
 *   plaintext:  0x00 | varint payload_len | varint msg_type | payload
 *   noise:      0x01 | u16be frame_len    | ciphertext
 *               where the ciphertext decrypts to
 *               u16be msg_type | u16be payload_len | payload
 *
 * Every write assembles the complete frame into one buffer and flushes it as
 * a single stream write. The tempting shortcut: writing preamble, length,
 * type, and payload as separate stream calls: turns each frame into four-
 * plus syscalls, and with TCP_NODELAY set (which the API needs for latency)
 * potentially four-plus wire segments per advertisement batch. On a tablet
 * that is measurable Wi-Fi airtime and battery for zero benefit.
 *
 * Threading contract: [readFrame] is only called by the session's reader
 * thread and [writeFrame] only by its writer thread; the handshake runs on
 * the reader thread before the writer starts. Nothing here locks.
 */
internal class ApiFrame(val type: Int, val payload: ByteArray)

internal interface ApiTransport {
    /** Blocking. Throws on any protocol or crypto failure. */
    fun handshake()

    /** Blocking. Null on clean EOF (peer closed between frames). */
    fun readFrame(): ApiFrame?

    /** Blocking. One buffered stream write + flush per frame. */
    fun writeFrame(type: Int, payload: ByteArray)
}

/** The peer opened a plaintext session against a Noise-only endpoint. */
internal class RequiresEncryptionException : IOException("plaintext client on encrypted endpoint")

/** The peer sent bytes that are not ESPHome API framing at all. */
internal class BadPreambleException(preamble: Int) :
    IOException("unrecognized preamble 0x%02x".format(preamble))

private const val MAX_FRAME = 65535

internal class PlaintextTransport(input: InputStream, output: OutputStream) : ApiTransport {
    private val inStream = DataInputStream(BufferedInputStream(input, 4096))
    private val outStream = BufferedOutputStream(output, 4096)

    override fun handshake() = Unit // plaintext has none

    override fun readFrame(): ApiFrame? {
        val preamble = inStream.read()
        if (preamble < 0) return null
        if (preamble != 0x00) throw BadPreambleException(preamble)
        val length = readVarint()
        val type = readVarint()
        if (length > MAX_FRAME) throw IOException("frame too large ($length)")
        val payload = ByteArray(length)
        inStream.readFully(payload)
        return ApiFrame(type, payload)
    }

    override fun writeFrame(type: Int, payload: ByteArray) {
        val header = ByteArray(11)
        var i = 0
        header[i++] = 0x00
        i = putVarint(header, i, payload.size)
        i = putVarint(header, i, type)
        outStream.write(header, 0, i)
        outStream.write(payload)
        outStream.flush()
    }

    private fun readVarint(): Int {
        var shift = 0
        var result = 0
        while (shift < 32) {
            val b = inStream.read()
            if (b < 0) throw EOFException("EOF inside varint")
            result = result or ((b and 0x7F) shl shift)
            if (b and 0x80 == 0) return result
            shift += 7
        }
        throw IOException("oversized varint")
    }
}

/**
 * Noise transport, server side. Wire sequence implemented here:
 *
 *  1. client -> `01 00 00`                      (empty "client hello" frame)
 *  2. server -> frame: 0x01 | name NUL | mac NUL (server hello: chosen proto)
 *  3. client -> frame: 0x00 | noise msg 1        (psk, e)
 *  4. server -> frame: 0x00 | noise msg 2        (e, ee)
 *  5. both   -> encrypted data frames
 *
 * A handshake-stage failure answers with a frame whose first byte is 0x01
 * followed by a UTF-8 reason before closing. The exact string "Handshake
 * MAC failure" matters: aioesphomeapi pattern-matches it into its
 * invalid-key error, which is what makes Home Assistant re-prompt for the
 * key instead of retrying a dead session forever.
 */
internal class NoiseTransport(
    input: InputStream,
    output: OutputStream,
    private val psk: ByteArray,
    private val serverName: String,
    private val serverMac: String,
) : ApiTransport {
    private val inStream = DataInputStream(BufferedInputStream(input, 4096))
    private val outStream = BufferedOutputStream(output, 4096)
    private var encryptCipher: NoiseCipher? = null
    private var decryptCipher: NoiseCipher? = null

    override fun handshake() {
        // The prologue commits both sides to the "NoiseAPIInit" context; the
        // two NULs are part of the constant, not a length.
        val responder = NoiseResponder(
            psk,
            "NoiseAPIInit".toByteArray(Charsets.US_ASCII) + byteArrayOf(0x00, 0x00),
        )

        val clientHello = readRawFrame() ?: throw EOFException("EOF before client hello")
        if (clientHello.isNotEmpty()) {
            // Not the empty hello: either a plaintext client (0x00 preamble
            // already rejected in readRawFrame) or garbage.
            throw IOException("unexpected client hello payload (${clientHello.size} bytes)")
        }

        // Server hello: 0x01 = Noise_NNpsk0 chosen, then name and MAC so the
        // client can pin the device identity before any crypto.
        writeRawFrame(
            byteArrayOf(0x01) +
                serverName.toByteArray(Charsets.UTF_8) + byteArrayOf(0x00) +
                serverMac.toByteArray(Charsets.UTF_8) + byteArrayOf(0x00)
        )

        val message1 = readRawFrame() ?: throw EOFException("EOF during handshake")
        if (message1.isEmpty() || message1[0].toInt() != 0x00) {
            throw IOException("malformed handshake frame")
        }
        val round = try {
            responder.readMessageAndRespond(message1.copyOfRange(1, message1.size))
        } catch (e: NoiseHandshakeException) {
            // Wrong PSK lands here (payload MAC mismatch).
            writeRawFrame(byteArrayOf(0x01) + "Handshake MAC failure".toByteArray(Charsets.UTF_8))
            outStream.flush()
            throw IOException("noise handshake failed: ${e.message}")
        }
        writeRawFrame(byteArrayOf(0x00) + round.response)

        val (decrypt, encrypt) = responder.split()
        decryptCipher = decrypt
        encryptCipher = encrypt
    }

    override fun readFrame(): ApiFrame? {
        val cipher = decryptCipher ?: throw IOException("read before handshake")
        val frame = readRawFrame() ?: return null
        val plain = try {
            cipher.decrypt(frame)
        } catch (e: NoiseHandshakeException) {
            throw IOException("transport decrypt failed: ${e.message}")
        }
        if (plain.size < 4) throw IOException("short data frame")
        val type = ((plain[0].toInt() and 0xFF) shl 8) or (plain[1].toInt() and 0xFF)
        val length = ((plain[2].toInt() and 0xFF) shl 8) or (plain[3].toInt() and 0xFF)
        if (plain.size - 4 != length) throw IOException("data frame length mismatch")
        return ApiFrame(type, plain.copyOfRange(4, plain.size))
    }

    override fun writeFrame(type: Int, payload: ByteArray) {
        val cipher = encryptCipher ?: throw IOException("write before handshake")
        val plain = ByteArray(4 + payload.size)
        plain[0] = ((type ushr 8) and 0xFF).toByte()
        plain[1] = (type and 0xFF).toByte()
        plain[2] = ((payload.size ushr 8) and 0xFF).toByte()
        plain[3] = (payload.size and 0xFF).toByte()
        payload.copyInto(plain, 4)
        writeRawFrame(cipher.encrypt(plain))
    }

    private fun readRawFrame(): ByteArray? {
        val preamble = inStream.read()
        if (preamble < 0) return null
        if (preamble == 0x00) throw RequiresEncryptionException()
        if (preamble != 0x01) throw BadPreambleException(preamble)
        val hi = inStream.read()
        val lo = inStream.read()
        if (hi < 0 || lo < 0) throw EOFException("EOF inside frame header")
        val length = (hi shl 8) or lo
        if (length > MAX_FRAME) throw IOException("frame too large ($length)")
        val payload = ByteArray(length)
        inStream.readFully(payload)
        return payload
    }

    private fun writeRawFrame(payload: ByteArray) {
        val frame = ByteArray(3 + payload.size)
        frame[0] = 0x01
        frame[1] = ((payload.size ushr 8) and 0xFF).toByte()
        frame[2] = (payload.size and 0xFF).toByte()
        payload.copyInto(frame, 3)
        outStream.write(frame)
        outStream.flush()
    }
}

private fun putVarint(buf: ByteArray, offset: Int, value: Int): Int {
    var v = value
    var i = offset
    while (true) {
        val bits = v and 0x7F
        v = v ushr 7
        if (v == 0) {
            buf[i++] = bits.toByte()
            return i
        }
        buf[i++] = (bits or 0x80).toByte()
    }
}

/**
 * The plaintext hint sent when a plaintext client reaches a Noise endpoint:
 * an empty Noise hello. The 0x01 preamble is enough for aioesphomeapi's
 * plaintext helper to raise its requires-encryption error, so Home
 * Assistant's config flow asks for the key instead of showing a timeout.
 */
internal val REQUIRES_ENCRYPTION_HINT = byteArrayOf(0x01, 0x00, 0x00)
