package me.jxl.kiosk_satellite

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test

class CameraRotationTest {
    @After fun reset() = CameraRotation.apply(0)

    @Test fun theSettingAddsToTheReportedRotation() {
        for (extra in listOf(0, 90, 180, 270)) {
            CameraRotation.apply(extra)
            for (reported in listOf(0, 90, 180, 270)) {
                assertEquals((reported + extra) % 360, CameraRotation.turned(reported))
            }
        }
    }

    @Test fun aMissingOrOddArgumentLeavesTheRotationAsReported() {
        CameraRotation.apply(90)
        CameraRotation.apply(null)
        assertEquals(270, CameraRotation.turned(270))
        CameraRotation.apply("90")
        assertEquals(0, CameraRotation.extraDegrees)
        CameraRotation.apply(-90)
        assertEquals(270, CameraRotation.extraDegrees)
        CameraRotation.apply(450)
        assertEquals(90, CameraRotation.extraDegrees)
    }

    @Test fun aSidewaysWebcamTurnsUprightForTheStream() {
        // Issue #1616: the HAL reports 270 for an upright USB webcam on a
        // portrait display, so the stream needs 90 more to come out right.
        CameraRotation.apply(90)
        val transform = RtspVideoTransform(CameraRotation.turned(270), 270, false, true)
        assertEquals(0, transform.rotationDegrees)
        assertEquals(1280 to 720, transform.outputDimensions(1280, 720))
    }
}
