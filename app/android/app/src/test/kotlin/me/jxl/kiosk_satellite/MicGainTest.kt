package me.jxl.kiosk_satellite

import kotlin.math.log10
import org.junit.Assert.assertEquals
import org.junit.Test

class MicGainTest {
    private fun db(factor: Double) = 20 * log10(factor)

    @Test
    fun noGainIsExactlyOne() {
        assertEquals(1.0, MicRecorder.gainFactor(0.0, 0.0), 0.0)
    }

    @Test
    fun baseGainAboveTheSliderRangeIsKept() {
        // The Echo Dot (3rd gen): a 27 dB base with the slider at 0 dB.
        assertEquals(27.0, db(MicRecorder.gainFactor(0.0, 27.0)), 1e-9)
    }

    @Test
    fun sliderMovesFromTheBaseGain() {
        assertEquals(30.0, db(MicRecorder.gainFactor(3.0, 27.0)), 1e-9)
        assertEquals(21.0, db(MicRecorder.gainFactor(-6.0, 27.0)), 1e-9)
    }

    @Test
    fun sliderStaysInItsRange() {
        assertEquals(24.0, db(MicRecorder.gainFactor(60.0)), 1e-9)
        assertEquals(-24.0, db(MicRecorder.gainFactor(-60.0)), 1e-9)
        assertEquals(29.0, db(MicRecorder.gainFactor(60.0, 5.0)), 1e-9)
    }

    @Test
    fun baseGainIsBoundedOnItsOwn() {
        assertEquals(48.0, db(MicRecorder.gainFactor(0.0, 100.0)), 1e-9)
        assertEquals(1.0, MicRecorder.gainFactor(0.0, -10.0), 0.0)
    }
}
