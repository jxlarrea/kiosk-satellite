package me.jxl.kiosk_satellite.airplay

import java.io.DataInputStream
import java.util.concurrent.CyclicBarrier
import java.util.concurrent.atomic.AtomicInteger
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec
import kotlin.concurrent.thread
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Live packets and resent ones reach the decoder from two threads. Both
 * must come out as they would alone.
 */
class PayloadDecoderTest {
    private val key = ByteArray(16) { (it * 17).toByte() }
    private val iv = ByteArray(16) { (15 - it).toByte() }
    private val format = StreamFormat(
        alac = true,
        fmtp = intArrayOf(96, FRAME_LENGTH, 0, 16, 40, 10, 14, 2, 255, 0, 0, 44100),
        aesKey = key,
        aesIv = iv,
    )

    @Test
    fun decryptsAndDecodesLikeTheDecoderAlone() {
        val packets = packets()
        val expected = reference(packets)
        val decoder = PayloadDecoder(format)
        for ((i, p) in packets.withIndex()) {
            val buf = encrypt(p)
            val pcm = ShortArray(FRAME_LENGTH * 2)
            assertEquals(expected[i].size / 2, decoder.decode(buf, 0, buf.size, pcm))
            assertArrayEquals(expected[i], pcm.copyOf(expected[i].size))
        }
    }

    @Test
    fun twoThreadsDecodeWithoutGarblingEachOther() {
        val packets = packets()
        val expected = reference(packets)
        val encrypted = packets.map(::encrypt)
        val decoder = PayloadDecoder(format)
        val wrong = AtomicInteger()
        val start = CyclicBarrier(2)
        val threads = List(2) {
            thread {
                val pcm = ShortArray(FRAME_LENGTH * 2)
                start.await()
                repeat(ROUNDS) {
                    for ((i, e) in encrypted.withIndex()) {
                        val buf = e.copyOf()
                        val ok = try {
                            val n = decoder.decode(buf, 0, buf.size, pcm)
                            n * 2 == expected[i].size && pcm.copyOf(n * 2).contentEquals(expected[i])
                        } catch (e: Exception) {
                            false
                        }
                        if (!ok) wrong.incrementAndGet()
                    }
                }
            }
        }
        threads.forEach { it.join() }
        assertEquals(0, wrong.get())
    }

    /** What each packet decodes to, by a decoder used from one thread. */
    private fun reference(packets: List<ByteArray>): List<ShortArray> {
        val decoder = AlacDecoder(frameLength = FRAME_LENGTH)
        val out = ShortArray(FRAME_LENGTH * 2)
        return packets.map { p -> out.copyOf(decoder.decode(p, 0, p.size, out) * 2) }
    }

    /** As the sender does it: whole 16-byte blocks, the tail in the clear. */
    private fun encrypt(plain: ByteArray): ByteArray {
        val out = plain.copyOf()
        val whole = plain.size and 15.inv()
        val cipher = Cipher.getInstance("AES/CBC/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), IvParameterSpec(iv))
        cipher.doFinal(plain, 0, whole, out, 0)
        return out
    }

    private fun packets(): List<ByteArray> {
        val stream = javaClass.classLoader!!.getResourceAsStream("airplay/alac_default.bin")!!
        DataInputStream(stream).use { input ->
            val magic = ByteArray(4).also { input.readFully(it) }
            assertEquals("ALAC", String(magic))
            return List(input.readInt()) { ByteArray(input.readInt()).also { input.readFully(it) } }
        }
    }

    private companion object {
        const val FRAME_LENGTH = 4096
        const val ROUNDS = 200
    }
}
