package me.jxl.kiosk_satellite

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Vision Match: Ground Control's answers read the way the on-device
 * detectors' results are. Faces come as boxes in fractions of the upright
 * frame, largest first. The face sensitivity measures a face against the
 * frame's longer side.
 */
class GroundControlVisionTest {
    private fun face(width: Float, frontal: Boolean) =
        mapOf("box" to listOf(0.4, 0.2, width.toDouble(), 0.15), "score" to 0.9, "frontal" to frontal)

    @Test
    fun `the largest face looking at the kiosk counts`() {
        val faces = listOf(face(0.20f, false), face(0.10f, true), face(0.05f, true))
        assertEquals(0.10f, GroundControlVision.frontalWidth(faces, 640, 480)!!, 1e-6f)
    }

    @Test
    fun `a face turned away is not a sighting`() {
        assertNull(GroundControlVision.frontalWidth(listOf(face(0.2f, false)), 640, 480))
        assertNull(GroundControlVision.frontalWidth(emptyList<Any>(), 640, 480))
    }

    @Test
    fun `in a portrait frame the width is measured against the height`() {
        // 0.3 of a 480-wide upright frame is 144 px, against its 640 px height.
        assertEquals(0.225f, GroundControlVision.frontalWidth(listOf(face(0.3f, true)), 480, 640)!!, 1e-6f)
    }

    @Test
    fun `a gesture with a count reads as that many fingers`() {
        val (hands, read) = GroundControlVision.handReport(mapOf("gesture" to "three", "fingers" to 3, "score" to 0.9))
        assertEquals(1, hands)
        assertEquals(3, read!!.fingers)
        assertTrue(read.detail.contains("three"))
    }

    @Test
    fun `a hand without a count is a hand with no reading`() {
        val (hands, read) = GroundControlVision.handReport(mapOf("gesture" to "no_gesture", "fingers" to null))
        assertEquals(1, hands)
        assertNull(read)
        assertEquals(0 to null, GroundControlVision.handReport(null))
    }

    @Test
    fun `Ground Control's looks a second set the pacing`() {
        val vision = GroundControlVision()
        assertTrue(!vision.busy(0L))
        vision.setMaxLooks(4.0, 2.0)
        assertEquals(250_000_000L, vision.faceIntervalNs)
        assertEquals(500_000_000L, vision.handIntervalNs)
    }
}
