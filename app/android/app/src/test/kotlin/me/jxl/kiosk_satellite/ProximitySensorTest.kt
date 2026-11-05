package me.jxl.kiosk_satellite

import java.io.File
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ProximitySensorTest {
    @Test
    fun px30ReadingsAlternateBetweenFarAndNear() {
        val threshold = proximityNearThreshold(9f, 9f)
        val readings = listOf(1f, 0f, 1f, 0f, 1f, 0f)
        assertEquals(
            listOf(false, true, false, true, false, true),
            readings.map { it < threshold },
        )
    }

    @Test
    fun binarySensorsRecognizeNearAndFarAcrossRanges() {
        for (range in listOf(9f, 5f, 1f, 0.4f)) {
            val threshold = proximityNearThreshold(range, range)
            assertTrue(0f < threshold, "near at range $range")
            assertFalse(range < threshold, "far at range $range")
            assertFalse(1f < threshold, "far flag at range $range")
        }
    }

    @Test
    fun continuousSensorsKeepTheirDistanceRange() {
        val threshold = proximityNearThreshold(5f, 0.1f)
        assertTrue(2f < threshold)
        assertTrue(4.9f < threshold)
        assertFalse(5f < threshold)
        assertFalse(6f < threshold)
    }

    @Test
    fun missingRangeStillDistinguishesBinaryFlags() {
        for (range in listOf(0f, -1f)) {
            val threshold = proximityNearThreshold(range, 0f)
            assertTrue(0f < threshold)
            assertFalse(1f < threshold)
        }
    }

    /** Feeds readings 200 ms apart, the rate the app registers at. */
    private class Feed(maximumRange: Float, resolution: Float, risingCounts: Boolean = false) {
        private val c = ProximityClassifier(maximumRange, resolution, risingCounts)
        var nanos = 0L

        fun read(value: Float): Boolean {
            nanos += 200_000_000L
            return c.near(value, nanos)
        }

        fun readAll(values: List<Float>) = values.map(::read)
    }

    @Test
    fun rawCountsRisingWithProximityReadAsNear() {
        // NSPanel Pro (#980): range 9, resolution 9, about 50 at rest.
        val f = Feed(9f, 9f)
        val rest = listOf(50f, 48f, 49f, 50f, 48f)
        assertEquals(List(rest.size) { false }, f.readAll(rest))
        // A hand waved in from 20 cm and back out again.
        val wave = listOf(53f, 63f, 92f, 150f, 272f, 789f, 531f, 70f, 52f, 49f)
        assertEquals(
            listOf(false, false, true, true, true, true, true, true, false, false),
            f.readAll(wave),
        )
    }

    @Test
    fun rawCountsIgnoreRestingBlipsAndDips() {
        val f = Feed(9f, 9f)
        f.readAll(listOf(47f, 46f, 48f, 47f, 50f, 47f))
        // The odd blip to 60 the reporter saw is noise, not an approach.
        assertFalse(f.read(60f))
        assertFalse(f.read(47f))
        // A low dip must not drag the resting level down so far that the
        // usual resting readings read as near afterwards.
        assertFalse(f.read(30f))
        assertEquals(List(6) { false }, f.readAll(listOf(47f, 48f, 50f, 46f, 49f, 47f)))
        assertTrue(f.read(150f))
    }

    @Test
    fun rawCountsFollowSlowDriftWithoutTriggering() {
        val f = Feed(9f, 9f)
        var value = 1000f
        repeat(2000) {
            value += 0.2f
            assertFalse(f.read(value), "drift at $value")
        }
        assertTrue(f.read(value * 1.4f))
    }

    @Test
    fun rawCountsLearnALiftedCoverWithinSeconds() {
        val f = Feed(9f, 9f)
        f.readAll(List(5) { 300f })
        // The cover comes off: the resting level drops to about 50.
        assertEquals(List(50) { false }, f.readAll(List(50) { if (it % 2 == 0) 50f else 48f }))
        assertTrue(f.read(150f))
    }

    @Test
    fun aNearThatNeverEndsBecomesTheRestingLevel() {
        val f = Feed(9f, 9f)
        f.readAll(listOf(47f, 48f, 47f))
        assertTrue(f.read(120f))
        // The readings settle on a new level with nothing in front.
        var near = true
        repeat(299) { near = f.read(if (it % 2 == 0) 119f else 121f) }
        assertTrue(near, "still near before a minute")
        assertFalse(f.read(120f), "released after a minute")
        assertFalse(f.read(121f))
        assertTrue(f.read(400f))
    }

    @Test
    fun rawCountsFirstJumpFromALowRestingLevelIsNear() {
        val f = Feed(9f, 9f)
        assertFalse(f.read(5f))
        assertTrue(f.read(150f))
        assertFalse(f.read(6f))
    }

    @Test
    fun px30FlagsKeepTheirDistanceMeaning() {
        assertEquals(
            listOf(false, true, false, true),
            Feed(9f, 9f).readAll(listOf(1f, 0f, 1f, 0f)),
        )
    }

    @Test
    fun aFarReadingJustPastTheRangeIsStillADistance() {
        assertEquals(
            listOf(false, true, false),
            Feed(5f, 1f).readAll(listOf(6f, 0f, 6f)),
        )
    }

    @Test
    fun sensortekCountsRestingAtZeroIgnoreSmallBlips() {
        // #980 follow-up: an 86P resting at 0 that blips to 3.
        val f = Feed(9f, 9f, risingCounts = true)
        val rest = listOf(0f, 3f, 0f, 3f, 0f, 2f, 0f, 3f, 0f)
        assertEquals(List(rest.size) { false }, f.readAll(rest))
        assertEquals(listOf(true, true, false), f.readAll(listOf(120f, 300f, 2f)))
    }

    @Test
    fun sensortekCountsTakeTheFirstReadingAsTheRestingLevel() {
        val f = Feed(9f, 9f, risingCounts = true)
        assertFalse(f.read(47f))
        assertFalse(f.read(60f))
        assertTrue(f.read(70f))
    }

    @Test
    fun highRestingCountsNeedNoMoreThanFiftyOver() {
        // Some panels rest at 1000 to 4000 counts. A quarter of that would
        // miss a hand the 120P's own driver calls near at 50 over.
        val f = Feed(9f, 9f, risingCounts = true)
        f.readAll(List(10) { if (it % 2 == 0) 4000f else 4010f })
        assertFalse(f.read(4040f))
        assertTrue(f.read(4080f))
        assertTrue(f.read(4040f), "held until the reading drops below half the rise")
        assertFalse(f.read(4010f))
    }

    @Test
    fun theSmartClockSensorIsMatchedByExactNameAndVendor() {
        assertTrue(isRawCountSensor("Ltr578 Ambient Light Sensor", "Liteon"))
        assertFalse(isRawCountSensor("Ltr578 Proximity Sensor", "Liteon"))
        assertFalse(isRawCountSensor("Ltr578 Ambient Light Sensor", "AOSP"))
        assertFalse(isRawCountSensor("Palm Proximity Sensor version 2", "Samsung"))
    }

    @Test
    fun smartClockCountsReadAsNearWithNoUsableRange() {
        // Lenovo Smart Clock (#1315): readings from its sensor dump.
        val f = Feed(0f, 0f, risingCounts = true)
        val rest = listOf(73f, 74f, 73f)
        assertEquals(List(rest.size) { false }, f.readAll(rest))
        val approach = listOf(158f, 121f, 112f, 117f, 116f, 120f, 169f, 78f, 74f, 73f)
        assertEquals(
            listOf(true, true, true, true, true, true, true, false, false, false),
            f.readAll(approach),
        )
    }

    @Test
    fun aMissingRangeWithoutRisingCountsStaysAFlag() {
        // Only a listed sensor reads as counts. Any other sensor with no
        // range keeps the flag test, whatever it reports.
        val f = Feed(0f, 0f)
        assertEquals(
            listOf(false, false, true, false),
            f.readAll(listOf(5f, 3.2f, 0f, 73f)),
        )
    }

    @Test
    fun theRestingLevelIsOnlyKnownInCountMode() {
        val flags = ProximityClassifier(9f, 9f)
        flags.near(1f, 0L)
        assertNull(flags.restingLevel)
        val counts = ProximityClassifier(9f, 9f, risingCounts = true)
        counts.near(47f, 0L)
        assertEquals(47f, counts.restingLevel)
    }

    private fun i2cDevices(vararg devices: Pair<String, Boolean>): File {
        val root = Files.createTempDirectory("i2c").toFile()
        for ((i, device) in devices.withIndex()) {
            val dir = File(root, "2-004$i").apply { mkdirs() }
            File(dir, "name").writeText("${device.first}\n")
            if (device.second) File(dir, "driver").mkdirs()
        }
        return root
    }

    private fun rawFile(): File =
        File.createTempFile("psensor_value", null).apply { writeText("48\n") }

    @Test
    fun findsTheBoundSensortekDriverAndItsRawFile() {
        val raw = rawFile()
        val found = findSensortekDriver(
            i2cDevices("rk809" to true, "ps_stk3a5x" to true, "ls_stk3a5x" to true),
            raw,
        )
        assertEquals(SensortekDriver("ps_stk3a5x", raw), found)
    }

    @Test
    fun anUnboundSensortekNodeIsNotADriver() {
        // The 86P's tree lists both chips. Only the one that answered binds.
        val found = findSensortekDriver(
            i2cDevices("ps_stk3a5x" to false, "ps_stk3x3x" to true),
            rawFile(),
        )
        assertEquals("ps_stk3x3x", found?.name)
        assertNull(findSensortekDriver(i2cDevices("ps_stk3a5x" to false), rawFile()))
    }

    @Test
    fun aSensortekDriverWithoutTheRawFileStillCounts() {
        // The 86P on 3.x firmware has no raw file but reports raw counts.
        val found = findSensortekDriver(
            i2cDevices("ps_stk3x3x" to true),
            File("/nonexistent/psensor_value"),
        )
        assertEquals(SensortekDriver("ps_stk3x3x", null), found)
    }

    @Test
    fun otherDevicesHaveNoSensortekDriver() {
        assertNull(findSensortekDriver(i2cDevices("stk3x3x" to true, "ltr559" to true), rawFile()))
        assertNull(findSensortekDriver(File("/nonexistent/i2c"), rawFile()))
    }

    @Test
    fun rawCountsParseFromTheSysfsText() {
        assertEquals(48f, parseRawCount("48\n"))
        assertEquals(0f, parseRawCount("0"))
        assertFailsWith<IllegalArgumentException> { parseRawCount("") }
        assertFailsWith<IllegalArgumentException> { parseRawCount("-1\n") }
        assertFailsWith<IllegalArgumentException> { parseRawCount("near\n") }
    }
}
