package me.jxl.kiosk_satellite

import org.junit.Assert.*
import org.junit.Test

class RtspFramePacerTest {
    @Test fun cameraFramesAreLimitedToTheRequestedVideoRate() {
        val pacer = RtspFramePacer(10)
        val accepted = (0 until 300).count { pacer.accept(it * 1_000_000_000L / 30) }
        assertEquals(100, accepted)
    }

    @Test fun smallCameraJitterDoesNotHalveTheFrameRate() {
        val pacer = RtspFramePacer(10)
        repeat(100) { frame ->
            val jitter = if (frame % 2 == 0) 0 else -2_000_000L
            assertTrue(pacer.accept(frame * 100_000_000L + jitter))
        }
    }

    @Test fun aPausedCameraResumesWithoutCatchingUpInABurst() {
        val pacer = RtspFramePacer(5)
        assertTrue(pacer.accept(1_000_000_000))
        assertTrue(pacer.accept(10_000_000_000))
        assertFalse(pacer.accept(10_001_000_000))
        assertTrue(pacer.accept(10_200_000_000))
    }

    @Test fun duplicateFramesAreSkippedAndAResetTimestampCanRecover() {
        val pacer = RtspFramePacer(10)
        assertTrue(pacer.accept(10_000_000_000))
        assertFalse(pacer.accept(10_000_000_000))
        assertTrue(pacer.accept(1_000_000_000))
        assertFalse(pacer.accept(1_010_000_000))
        assertTrue(pacer.accept(1_100_000_000))
    }
}
