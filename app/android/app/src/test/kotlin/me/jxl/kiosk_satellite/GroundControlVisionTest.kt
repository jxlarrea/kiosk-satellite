package me.jxl.kiosk_satellite

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
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

    private val ms = 1_000_000L

    @Test
    fun `an answer names nobody only with Face Recognition on`() {
        val guest = mapOf("id" to null, "name" to null, "score" to 0.21)
        val known = mapOf("id" to "p1", "name" to "Ana", "score" to 0.52)
        // Face Recognition off: the answer says nothing about people.
        assertFalse(GroundControlVision.nobodyNamed(mapOf("faces" to emptyList<Any>())))
        assertTrue(GroundControlVision.nobodyNamed(mapOf("person" to null, "people" to emptyList<Any>())))
        assertTrue(GroundControlVision.nobodyNamed(mapOf("person" to guest, "people" to emptyList<Any>())))
        assertFalse(GroundControlVision.nobodyNamed(mapOf("person" to known, "people" to listOf(known))))
        // Someone named in view while the face at the kiosk is a guest's.
        assertFalse(GroundControlVision.nobodyNamed(mapOf("person" to guest, "people" to listOf(known))))
        // A Ground Control from before several faces says the person only.
        assertTrue(GroundControlVision.nobodyNamed(mapOf("person" to null)))
        assertFalse(GroundControlVision.nobodyNamed(mapOf("person" to known)))
    }

    @Test
    fun `a face not named yet is looked at faster for two seconds`() {
        val vision = GroundControlVision()
        assertFalse(vision.hurried(0L))
        vision.faceLook(faces = true, unnamed = true, now = 1000 * ms)
        assertTrue(vision.hurried(1000 * ms))
        // The looks keep finding the face without a name: a guest.
        var now = 1000 * ms
        while (now < 2900 * ms) {
            now += 200 * ms
            vision.faceLook(faces = true, unnamed = true, now = now)
        }
        assertTrue(vision.hurried(3000 * ms))
        vision.faceLook(faces = true, unnamed = true, now = 3200 * ms)
        assertFalse(vision.hurried(3200 * ms))
        // Still there a minute later: the usual pace, not another round.
        now = 3200 * ms
        while (now < 60_000 * ms) {
            now += 600 * ms
            vision.faceLook(faces = true, unnamed = true, now = now)
            assertFalse(vision.hurried(now))
        }
    }

    @Test
    fun `a name ends the faster looks`() {
        val vision = GroundControlVision()
        vision.faceLook(faces = true, unnamed = true, now = 1000 * ms)
        assertTrue(vision.hurried(1100 * ms))
        vision.faceLook(faces = true, unnamed = false, now = 1200 * ms)
        assertFalse(vision.hurried(1200 * ms))
        // Face Recognition off never starts them.
        val plain = GroundControlVision()
        plain.faceLook(faces = true, unnamed = false, now = 1000 * ms)
        assertFalse(plain.hurried(1000 * ms))
    }

    @Test
    fun `a face that left stops the faster looks and one that returns starts them again`() {
        val vision = GroundControlVision()
        vision.faceLook(faces = true, unnamed = true, now = 1000 * ms)
        // Looks without a face: nothing to hurry for after a second.
        vision.faceLook(faces = false, unnamed = true, now = 1600 * ms)
        assertTrue(vision.hurried(1900 * ms))
        assertFalse(vision.hurried(2100 * ms))
        // Back ten seconds later, long after the first round ran out.
        vision.faceLook(faces = true, unnamed = true, now = 11_000 * ms)
        assertTrue(vision.hurried(11_000 * ms))
        assertTrue(vision.hurried(12_000 * ms))
        vision.reset()
        assertFalse(vision.hurried(12_000 * ms))
    }
}
