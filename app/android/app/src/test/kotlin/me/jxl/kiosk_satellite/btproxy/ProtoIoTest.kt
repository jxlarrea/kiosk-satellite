package me.jxl.kiosk_satellite.btproxy

import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ProtoIoTest {
    @Test
    fun varintRoundTrip() {
        val w = ProtoWriter()
        w.varint(1, 0) // omitted (proto3 default)
        w.varint(2, 1)
        w.varint(3, 300)
        w.varint(4, Long.MAX_VALUE)
        val r = ProtoReader(w.toByteArray())
        assertTrue(r.next()); assertEquals(2, r.field); assertEquals(1L, r.asLong())
        assertTrue(r.next()); assertEquals(3, r.field); assertEquals(300, r.asInt())
        assertTrue(r.next()); assertEquals(4, r.field); assertEquals(Long.MAX_VALUE, r.asLong())
        assertFalse(r.next())
    }

    @Test
    fun sint32EncodesNegativeRssiCompactly() {
        val w = ProtoWriter()
        w.sint32(2, -63)
        val bytes = w.toByteArray()
        // tag 0x10, zigzag(-63) = 125: two bytes total, not ten.
        assertContentEquals(byteArrayOf(0x10, 125), bytes)
        val r = ProtoReader(bytes)
        assertTrue(r.next())
        // ZigZag decode.
        val raw = r.asLong()
        assertEquals(-63L, (raw ushr 1) xor -(raw and 1))
    }

    @Test
    fun stringAndBytesRoundTrip() {
        val w = ProtoWriter()
        w.string(2, "kiosk-satellite")
        w.bytes(4, byteArrayOf(0x02, 0x01, 0x06))
        val r = ProtoReader(w.toByteArray())
        assertTrue(r.next()); assertEquals("kiosk-satellite", r.asString())
        assertTrue(r.next()); assertContentEquals(byteArrayOf(0x02, 0x01, 0x06), r.asBytes())
    }

    @Test
    fun readerSkipsUnknownWireTypes() {
        // A message containing varint, fixed64, length-delimited, fixed32:
        // the reader must be able to walk past every one of them, because HA
        // adds fields (of any wire type) to existing messages routinely.
        val w = ProtoWriter()
        w.varint(1, 7)
        w.fixed32(9, 12345)
        w.string(10, "future field")
        val r = ProtoReader(w.toByteArray())
        var fields = 0
        while (r.next()) fields++
        assertEquals(3, fields)
    }

    @Test
    fun truncatedInputThrowsInsteadOfLooping() {
        val w = ProtoWriter()
        w.string(1, "hello")
        val bytes = w.toByteArray()
        assertFailsWith<ProtoException> {
            val r = ProtoReader(bytes.copyOfRange(0, bytes.size - 2))
            while (r.next()) Unit
        }
    }

    @Test
    fun emptyNestedMessageStillWritesField() {
        val w = ProtoWriter()
        w.message(1, ByteArray(0))
        assertContentEquals(byteArrayOf(0x0A, 0x00), w.toByteArray())
    }
}
