package me.jxl.kiosk_satellite

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class BrightnessScaleTest {
    @Test
    fun mapsLevelsOntoTheHistoricalScale() {
        val scale = BrightnessScale.default
        assertEquals(255, scale.toRaw(1.0))
        assertEquals(128, scale.toRaw(0.5))
        assertEquals(0, scale.toRaw(0.0))
        assertEquals(1.0, scale.toLevel(255))
        assertEquals(0.0, scale.toLevel(0))
    }

    @Test
    fun mapsLevelsOntoAWiderPanel() {
        // The realme panel of issue #270: full brightness is 2047, and the
        // 255 the app used to write is a tenth of what the caller asked for.
        val scale = BrightnessScale(0, 2047)
        assertEquals(2047, scale.toRaw(1.0))
        assertEquals(1535, scale.toRaw(0.75))
        assertEquals(0, scale.toRaw(0.0))
        assertEquals(1.0, scale.toLevel(2047))
        assertEquals(0.125, scale.toLevel(255), 0.001)
    }

    @Test
    fun readsAndWritesAreInverses() {
        for (scale in listOf(
            BrightnessScale.default, BrightnessScale(0, 2047), BrightnessScale(4, 1023),
        )) {
            for (level in listOf(0.0, 0.01, 0.25, 0.5, 0.75, 1.0)) {
                assertEquals(level, scale.toLevel(scale.toRaw(level)), 0.002)
            }
        }
    }

    @Test
    fun clampsOutOfRangeValues() {
        val scale = BrightnessScale(10, 1023)
        assertEquals(1023, scale.toRaw(2.0))
        assertEquals(10, scale.toRaw(-1.0))
        // Below the panel's own minimum, including the zero the black
        // screensaver writes: dark, not a level.
        assertEquals(0.0, scale.toLevel(0))
        assertEquals(1.0, scale.toLevel(4096))
    }

    @Test
    fun zeroStopsAtThePanelFloor() {
        // Never under the floor: the panel cannot show it and the framework
        // wedges on the attempt.
        assertEquals(20, BrightnessScale(20, 255).toRaw(0.0))
    }

    @Test
    fun takesTheRangeADeviceReports() {
        assertEquals(BrightnessScale(0, 2047), BrightnessScale.of(0, 2047))
        assertEquals(BrightnessScale(4, 1023), BrightnessScale.of(4, 1023))
    }

    @Test
    fun fallsBackWhenADeviceReportsNonsense() {
        assertEquals(BrightnessScale.default, BrightnessScale.of(null, null))
        assertEquals(BrightnessScale.default, BrightnessScale.of(0, 0))
        assertEquals(BrightnessScale.default, BrightnessScale.of(0, -1))
        assertEquals(BrightnessScale.default, BrightnessScale.of(0, 1_000_000))
        // A minimum that swallows most of the scale is not a minimum.
        assertEquals(BrightnessScale(0, 255), BrightnessScale.of(200, 255))
    }

    @Test
    fun widensToAValueTheScaleCallsImpossible() {
        assertEquals(
            BrightnessScale(0, 1400), BrightnessScale.default.widenedTo(1400),
        )
        assertNull(BrightnessScale.default.widenedTo(255))
        assertNull(BrightnessScale(0, 2047).widenedTo(1024))
    }
}
