package me.jxl.kiosk_satellite

import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.log10
import kotlin.math.sin
import kotlin.math.sqrt

class EqualizerTest {
    @After
    fun off() {
        Equalizer.set(false, emptyList(), true)
    }

    private fun tone(frequency: Double, rate: Int, frames: Int, amplitude: Double = 8000.0): ByteArray {
        val pcm = ByteArray(frames * 2)
        for (i in 0 until frames) {
            val v = (amplitude * sin(2 * PI * frequency * i / rate)).toInt()
            pcm[i * 2] = v.toByte()
            pcm[i * 2 + 1] = (v shr 8).toByte()
        }
        return pcm
    }

    /** RMS of the second half, past the filters' start and the fade. */
    private fun level(pcm: ByteArray): Double {
        var sum = 0.0
        val from = pcm.size / 4 * 2
        var n = 0
        var i = from
        while (i + 1 < pcm.size) {
            val v = ((pcm[i].toInt() and 0xFF) or (pcm[i + 1].toInt() shl 8)).toShort().toDouble()
            sum += v * v
            n++
            i += 2
        }
        return sqrt(sum / n)
    }

    private fun gainDb(frequency: Double, rate: Int = 48000): Double {
        val pcm = tone(frequency, rate, rate)
        val before = level(pcm)
        Equalizer.Stream(rate, 1).process(pcm, 0, pcm.size)
        return 20 * log10(level(pcm) / before)
    }

    @Test
    fun offOrFlatLeavesTheSamplesAlone() {
        val original = tone(440.0, 48000, 4800)
        for (set in listOf(
            { Equalizer.set(false, listOf(6.0, 0.0, 0.0, 0.0, 0.0), true) },
            { Equalizer.set(true, listOf(0.0, 0.0, 0.0, 0.0, 0.0), true) },
        )) {
            set()
            assertNull(Equalizer.setup)
            val stream = Equalizer.Stream(48000, 1)
            assertTrue(stream.idle())
            val pcm = original.copyOf()
            stream.process(pcm, 0, pcm.size)
            assertArrayEquals(original, pcm)
        }
    }

    @Test
    fun aBandMovesItsOwnFrequencies() {
        Equalizer.set(true, listOf(6.0, 0.0, 0.0, 0.0, 0.0), false)
        assertEquals(6.0, gainDb(30.0), 0.5)
        assertEquals(0.0, gainDb(2000.0), 0.3)

        Equalizer.set(true, listOf(0.0, 0.0, -9.0, 0.0, 0.0), false)
        assertEquals(-9.0, gainDb(1000.0), 0.3)
        assertEquals(0.0, gainDb(60.0), 0.5)
        assertEquals(0.0, gainDb(12000.0), 0.5)

        Equalizer.set(true, listOf(0.0, 0.0, 0.0, 0.0, 8.0), false)
        assertEquals(8.0, gainDb(18000.0), 0.6)
        assertEquals(0.0, gainDb(300.0), 0.3)
    }

    @Test
    fun theAutomaticPreampTakesOffTheLargestBoost() {
        Equalizer.set(true, listOf(6.0, 0.0, 0.0, 0.0, 0.0), true)
        // The boosted bass comes out where it went in and the rest 6 dB down.
        assertEquals(0.0, gainDb(30.0), 0.5)
        assertEquals(-6.0, gainDb(2000.0), 0.3)

        // Bands next to each other add up to more than either.
        val both = Equalizer.peakDb(doubleArrayOf(0.0, 6.0, 6.0, 0.0, 0.0))
        assertTrue("peak $both", both > 6.5)
        Equalizer.set(true, listOf(0.0, 6.0, 6.0, 0.0, 0.0), true)
        for (f in listOf(200.0, 300.0, 550.0, 1000.0, 1500.0)) {
            assertTrue("$f Hz", gainDb(f) <= 0.05)
        }

        // Cuts alone need no preamp.
        Equalizer.set(true, listOf(-6.0, -3.0, 0.0, 0.0, -4.0), true)
        assertEquals(1.0, Equalizer.setup!!.preamp, 1e-9)
    }

    @Test
    fun aBandAboveTheStreamIsLeftOut() {
        Equalizer.set(true, listOf(0.0, 0.0, 0.0, 0.0, 9.0), false)
        // A 16 kHz voice has nothing at 10 kHz: the stream stays as it is.
        assertEquals(0.0, gainDb(3000.0, rate = 16000), 0.05)
        assertTrue(Equalizer.bands(doubleArrayOf(0.0, 0.0, 0.0, 0.0, 9.0), 16000).isEmpty())
    }

    @Test
    fun aLoudBoostSaturatesInsteadOfWrapping() {
        Equalizer.set(true, listOf(12.0, 0.0, 0.0, 0.0, 0.0), false)
        val pcm = tone(40.0, 48000, 48000, amplitude = 30000.0)
        Equalizer.Stream(48000, 1).process(pcm, 0, pcm.size)
        var previous = 0
        var i = pcm.size / 2
        while (i + 1 < pcm.size) {
            val v = ((pcm[i].toInt() and 0xFF) or (pcm[i + 1].toInt() shl 8)).toShort().toInt()
            // A wrapped sample would jump from one rail to the other.
            assertTrue(Math.abs(v - previous) < 40000 || i == pcm.size / 2)
            previous = v
            i += 2
        }
    }

    @Test
    fun aChangeWhilePlayingFadesOver() {
        val stream = Equalizer.Stream(48000, 1)
        assertTrue(stream.idle())
        Equalizer.set(true, listOf(0.0, 0.0, -12.0, 0.0, 0.0), false)
        assertFalse(stream.idle())
        val pcm = tone(1000.0, 48000, 4800)
        stream.process(pcm, 0, pcm.size)
        fun peak(from: Int, to: Int): Int {
            var max = 0
            for (i in from until to) {
                val v = ((pcm[i * 2].toInt() and 0xFF) or (pcm[i * 2 + 1].toInt() shl 8)).toShort().toInt()
                if (Math.abs(v) > max) max = Math.abs(v)
            }
            return max
        }
        // The first cycle is still nearly whole, the end is 12 dB down.
        assertTrue(peak(0, 48) > 6000)
        assertEquals(8000 * 0.251, peak(4000, 4800).toDouble(), 250.0)
        // Off again: back to untouched samples once the fade is over.
        Equalizer.set(false, emptyList(), true)
        val after = tone(1000.0, 48000, 4800)
        stream.process(after, 0, after.size)
        assertTrue(stream.idle())
        val whole = tone(1000.0, 48000, 4800)
        assertArrayEquals(whole.copyOfRange(4000, 9600), after.copyOfRange(4000, 9600))
    }

    @Test
    fun rewindingGivesTheSameSamplesAsOnePass() {
        Equalizer.set(true, listOf(5.0, -3.0, 2.0, 4.0, -6.0), true)
        val rate = 44100
        val frames = 3000
        val input = ByteBuffer.allocate(frames * 8).order(ByteOrder.LITTLE_ENDIAN)
        for (i in 0 until frames) {
            input.putInt((1e9 * sin(2 * PI * 220.0 * i / rate)).toInt())
            input.putInt((8e8 * sin(2 * PI * 3100.0 * i / rate)).toInt())
        }
        val whole = ByteBuffer.allocate(frames * 8).order(ByteOrder.LITTLE_ENDIAN)
        Equalizer.Stream(rate, 2).process(input, 0, whole, 0, frames * 8, 4)

        // The same stream in slices, where the track takes only part of some.
        val stream = Equalizer.Stream(rate, 2)
        val pieces = ByteBuffer.allocate(frames * 8).order(ByteOrder.LITTLE_ENDIAN)
        val scratch = ByteBuffer.allocate(frames * 8).order(ByteOrder.LITTLE_ENDIAN)
        var at = 0
        var turn = 0
        while (at < frames) {
            val slice = minOf(700, frames - at)
            stream.mark()
            stream.process(input, at * 8, scratch, 0, slice * 8, 4)
            val taken = if (turn++ % 2 == 0) slice else slice / 3
            for (i in 0 until taken * 8) pieces.put(at * 8 + i, scratch.get(i))
            if (taken < slice) {
                stream.rewind()
                stream.process(input, at * 8, scratch, 0, taken * 8, 4)
            }
            at += taken
        }
        assertArrayEquals(whole.array(), pieces.array())
    }
}
