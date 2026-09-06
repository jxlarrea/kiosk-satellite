package me.jxl.kiosk_satellite.sendspin

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PlaybackClockTest {
    private val clock = PlaybackClock()

    private fun position(head: Long, ms: Long, written: Long = 480_000): Long =
        clock.position(head, ms * 1_000_000, written, 48_000, 4_800)

    @Test fun queuedPrimingSilenceIsNotPlayedUntilTheHeadMoves() {
        for (ms in 0L..500L step 5) {
            assertEquals(0, position(0, ms, written = 1_200))
        }
        assertEquals(768, position(768, 505, written = 1_200))
    }

    @Test fun progressNeverExceedsWrittenFrames() {
        position(240, 0, written = 1_200)
        for (ms in 5L..100L step 5) {
            assertTrue(position(240, ms, written = 1_200) <= 1_200)
        }
    }

    @Test fun resetWaitsForTheNewStreamsPlaybackHead() {
        position(48_000, 1_000)
        clock.reset()
        assertEquals(0, position(0, 2_000))
        assertEquals(0, position(0, 2_005))
        assertEquals(240, position(240, 2_010))
    }

    @Test fun aBackwardReportDoesNotBecomeAnEntireCounterWrap() {
        position(48_000, 1_000)
        val next = position(47_000, 1_005)
        assertTrue(next in 48_000..48_240)
    }

    @Test fun aRealUnsignedCounterWrapKeepsItsPosition() {
        clock.position(0xFFFF_FF00L, 0, 0x1_0001_0000L, 48_000, 4_800)
        val next = clock.position(224, 10_000_000, 0x1_0001_0000L, 48_000, 4_800)
        assertEquals(0x1_0000_00E0L, next)
    }

    @Test fun aStationaryHeadCannotAdvanceForever() {
        position(48_000, 1_000)
        val early = position(48_000, 1_200)
        val stalled = position(48_000, 2_000)
        assertTrue(stalled <= early)
        assertTrue(stalled <= 52_800)
    }

    @Test fun extraReadsDoNotChangeTheServoTimeConstant() {
        fun run(step: Long): Long {
            val c = PlaybackClock()
            c.position(48_000, 0, 480_000, 48_000, 4_800)
            var result = 0L
            for (ms in step..200L step step) {
                result = c.position(48_000 + (ms / 20) * 960, ms * 1_000_000, 480_000, 48_000, 4_800)
            }
            return result
        }
        assertTrue(kotlin.math.abs(run(1) - run(5)) < 100)
    }
}
