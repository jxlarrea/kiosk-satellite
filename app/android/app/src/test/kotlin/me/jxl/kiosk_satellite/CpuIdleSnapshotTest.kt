package me.jxl.kiosk_satellite

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class CpuIdleSnapshotTest {
    private fun snapshot(
        awakeSeconds: Long,
        idleUs: Map<String, Long>,
        elapsedSeconds: Long = awakeSeconds,
        online: Map<String, Boolean> = idleUs.mapValues { true },
    ) = CpuIdleSnapshot(
        elapsedSeconds * 1_000_000_000L,
        awakeSeconds * 1_000_000_000L,
        idleUs,
        idleUs.mapValues { 0L },
        online,
    )

    @Test
    fun measuresLoadWithoutSuspend() {
        val before = snapshot(0, mapOf("cpu0" to 0L))
        val now = snapshot(12, mapOf("cpu0" to 11_400_000L))
        assertEquals(5.0, now.usageSince(before)!!, 0.0001)
    }

    @Test
    fun sleepingForMostOfTheIntervalDoesNotLookBusy() {
        val before = snapshot(0, mapOf("cpu0" to 0L))
        // Twelve seconds awake at 5% load and 48 seconds suspended.
        // Dividing idle residency by elapsed time used to report 81%.
        val now = snapshot(12, mapOf("cpu0" to 11_400_000L), elapsedSeconds = 60)
        assertEquals(5.0, now.usageSince(before)!!, 0.0001)
    }

    @Test
    fun replaysTheTabS8SuspendMeasurement() {
        fun reading(elapsed: Long, awake: Long, vararg idle: Long) = CpuIdleSnapshot(
            elapsed, awake, idle.mapIndexed { i, value -> "cpu$i" to value }.toMap(),
            emptyMap(), (0..7).associate { "cpu$it" to true },
        )
        // Read from .5 with its screen off on battery. This interval
        // includes 0.829 seconds suspended and used to calculate 31.46%.
        val before = reading(
            166_864_135_305_404L, 166_863_026_630_147L,
            108_557_641_084L, 112_818_631_643L, 115_257_210_066L, 115_658_230_525L,
            147_670_846_893L, 155_080_028_084L, 154_946_913_514L, 164_815_528_826L,
        )
        val now = reading(
            166_869_121_975_347L, 166_867_184_562_489L,
            108_560_520_546L, 112_821_737_913L, 115_260_222_710L, 115_661_322_335L,
            147_674_755_304L, 155_083_577_606L, 154_950_736_248L, 164_819_501_224L,
        )
        assertEquals(17.80, now.usageSince(before)!!, 0.01)
    }

    @Test
    fun aBusyCoreStillReportsFullLoadAfterSuspend() {
        val before = snapshot(0, mapOf("cpu0" to 100L))
        val now = snapshot(12, mapOf("cpu0" to 100L), elapsedSeconds = 60)
        assertEquals(100.0, now.usageSince(before))
    }

    @Test
    fun parkedCoresRemainFreeCapacityAtEitherEdge() {
        val idle = mapOf("cpu0" to 0L, "cpu1" to 0L, "cpu2" to 0L)
        val before = snapshot(0, idle, online = mapOf("cpu0" to true, "cpu1" to false, "cpu2" to true))
        val now = snapshot(12, idle, elapsedSeconds = 60,
            online = mapOf("cpu0" to true, "cpu1" to true, "cpu2" to false))
        assertEquals(100.0 / 3, now.usageSince(before)!!, 0.0001)
    }

    @Test
    fun noAwakeTimeDoesNotInventAUsageValue() {
        val before = snapshot(10, mapOf("cpu0" to 100L))
        val now = snapshot(10, mapOf("cpu0" to 100L), elapsedSeconds = 60)
        assertNull(now.usageSince(before))
    }

    @Test
    fun counterResetsAndNewCoresDoNotLookBusy() {
        val before = snapshot(0, mapOf("cpu0" to 100L, "cpu1" to 0L))
        val now = snapshot(1, mapOf("cpu0" to 0L, "cpu1" to 900_000L, "cpu2" to 0L))
        assertEquals(10.0, now.usageSince(before)!!, 0.0001)
        assertNull(snapshot(1, mapOf("cpu0" to 0L)).usageSince(before))
    }

    @Test
    fun idleCounterRoundingCannotProduceNegativeLoad() {
        val before = snapshot(0, mapOf("cpu0" to 0L))
        val now = snapshot(1, mapOf("cpu0" to 1_000_001L))
        assertEquals(0.0, now.usageSince(before))
    }
}
