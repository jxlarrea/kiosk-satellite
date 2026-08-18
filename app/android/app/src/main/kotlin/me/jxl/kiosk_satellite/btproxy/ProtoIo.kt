package me.jxl.kiosk_satellite.btproxy

import java.io.ByteArrayOutputStream

/**
 * Minimal protobuf wire-format reader/writer for the ESPHome native API.
 *
 * The Bluetooth proxy speaks a fixed, small subset of the ESPHome message
 * schema (see [ApiMessages]), so hand-rolled varint encoding beats pulling in
 * a protobuf runtime plus generated classes: no codegen step, no library on
 * the APK, and every field this code emits is visible at the call site next
 * to the api.proto field number it implements.
 *
 * Only the wire types the subset needs exist here: varint (0), length-
 * delimited (2), and fixed32 (5, for GetTimeResponse.epoch_seconds). Unknown
 * fields on the read side are skipped, not rejected: Home Assistant adds
 * fields to existing messages routinely, and a proxy that drops the session
 * over a new field breaks on every HA upgrade (the strict-parse failure mode
 * of prior Android proxies).
 */
internal class ProtoWriter {
    private val out = ByteArrayOutputStream(64)

    fun toByteArray(): ByteArray = out.toByteArray()

    fun varint(field: Int, value: Long) {
        // Proto3 default: zero-valued scalar fields are omitted entirely.
        if (value == 0L) return
        tag(field, 0)
        raw(value)
    }

    fun varint(field: Int, value: Int) = varint(field, value.toLong() and 0xFFFF_FFFFL)

    fun bool(field: Int, value: Boolean) = varint(field, if (value) 1L else 0L)

    /** ZigZag-encoded sint32 (used by BluetoothLERawAdvertisement.rssi). */
    fun sint32(field: Int, value: Int) =
        varint(field, ((value shl 1) xor (value shr 31)).toLong() and 0xFFFF_FFFFL)

    fun fixed32(field: Int, value: Int) {
        tag(field, 5)
        out.write(value and 0xFF)
        out.write((value ushr 8) and 0xFF)
        out.write((value ushr 16) and 0xFF)
        out.write((value ushr 24) and 0xFF)
    }

    /** IEEE-754 float as fixed32; proto3 zero-omission applies. */
    fun float(field: Int, value: Float) {
        if (value == 0f) return
        fixed32(field, value.toRawBits())
    }

    fun string(field: Int, value: String) {
        if (value.isEmpty()) return
        bytes(field, value.toByteArray(Charsets.UTF_8))
    }

    fun bytes(field: Int, value: ByteArray) {
        tag(field, 2)
        raw(value.size.toLong())
        out.write(value)
    }

    /** Nested messages are just length-delimited bytes; empty ones still count. */
    fun message(field: Int, value: ByteArray) = bytes(field, value)

    private fun tag(field: Int, wireType: Int) = raw(((field shl 3) or wireType).toLong())

    private fun raw(v: Long) {
        var value = v
        while (true) {
            val bits = (value and 0x7F).toInt()
            value = value ushr 7
            if (value == 0L) {
                out.write(bits)
                return
            }
            out.write(bits or 0x80)
        }
    }
}

/**
 * Field-walking reader. Callers loop with [next] and pick out the field
 * numbers they know; everything else is skipped by wire type.
 */
internal class ProtoReader(private val data: ByteArray) {
    private var pos = 0

    var field: Int = 0
        private set
    private var wireType: Int = 0
    private var varintValue: Long = 0
    private var chunkStart: Int = 0
    private var chunkLength: Int = 0

    /** Advances to the next field; false at end of message. Throws on malformed input. */
    fun next(): Boolean {
        if (pos >= data.size) return false
        val tag = readRawVarint()
        field = (tag ushr 3).toInt()
        wireType = (tag and 0x7).toInt()
        if (field == 0) throw ProtoException("field 0")
        when (wireType) {
            0 -> varintValue = readRawVarint()
            2 -> {
                chunkLength = readRawVarint().toInt()
                chunkStart = pos
                if (chunkLength < 0 || pos + chunkLength > data.size) {
                    throw ProtoException("length-delimited field overruns message")
                }
                pos += chunkLength
            }
            5 -> {
                if (pos + 4 > data.size) throw ProtoException("fixed32 overruns message")
                chunkStart = pos
                chunkLength = 4
                pos += 4
            }
            1 -> {
                if (pos + 8 > data.size) throw ProtoException("fixed64 overruns message")
                chunkStart = pos
                chunkLength = 8
                pos += 8
            }
            else -> throw ProtoException("unsupported wire type $wireType")
        }
        return true
    }

    fun asLong(): Long = varintValue
    fun asInt(): Int = varintValue.toInt()
    fun asBool(): Boolean = varintValue != 0L
    fun asString(): String = String(data, chunkStart, chunkLength, Charsets.UTF_8)
    fun asBytes(): ByteArray = data.copyOfRange(chunkStart, chunkStart + chunkLength)

    /** Little-endian fixed32 (wire type 5). */
    fun asFixed32(): Int =
        (data[chunkStart].toInt() and 0xFF) or
            ((data[chunkStart + 1].toInt() and 0xFF) shl 8) or
            ((data[chunkStart + 2].toInt() and 0xFF) shl 16) or
            ((data[chunkStart + 3].toInt() and 0xFF) shl 24)

    fun asFloat(): Float = Float.fromBits(asFixed32())

    private fun readRawVarint(): Long {
        var shift = 0
        var result = 0L
        while (shift < 64) {
            if (pos >= data.size) throw ProtoException("varint overruns message")
            val b = data[pos++].toInt()
            result = result or ((b and 0x7F).toLong() shl shift)
            if (b and 0x80 == 0) return result
            shift += 7
        }
        throw ProtoException("varint too long")
    }
}

internal class ProtoException(message: String) : Exception(message)
