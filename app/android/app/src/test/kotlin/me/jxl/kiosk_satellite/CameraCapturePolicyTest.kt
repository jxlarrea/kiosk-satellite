package me.jxl.kiosk_satellite

import org.junit.Assert.*
import org.junit.Test

class CameraCapturePolicyTest {
    @Test fun variableSensorRangeIsNotTurnedIntoUnsupportedFixedRate() {
        val ranges = listOf(5..30, 15..30, 30..30)
        assertEquals(5..30, streamingFpsRange(ranges, 10))
        assertEquals(30..30, streamingFpsRange(ranges, 30))
        assertEquals(15..30, streamingFpsRange(ranges, 20))
    }

    @Test fun unavailableTargetStillSelectsAnAdvertisedRange() {
        assertEquals(15..15, streamingFpsRange(listOf(15..30, 15..15), 5))
        assertNull(streamingFpsRange(emptyList(), 10))
    }

    @Test fun fallbackIsBoundedAndDoesNotDegradeTheOtherCamera() {
        val policy = CameraCapturePolicy()
        assertTrue(policy.advance("front"))
        assertEquals(1, policy.level("front"))
        assertEquals(0, policy.level("back"))
        assertTrue(policy.advance("front"))
        assertTrue(policy.advance("front"))
        assertFalse(policy.advance("front"))
        assertEquals(3, policy.level("front"))
        policy.reset()
        assertEquals(0, policy.level("front"))
    }
}
