package me.jxl.kiosk_satellite

import kotlin.test.Test
import kotlin.test.assertEquals

class ReadableCamerasTest {
    /** A HAL entry whose lens facing getter throws exactly as CameraX's
     *  Camera2CameraInfoImpl does for a facing of 255. */
    private class Cam(val id: String, val facing: Int?)

    private fun read(cam: Cam): Int =
        cam.facing ?: throw IllegalArgumentException(
            "The given lens facing integer: 255 can not be recognized.",
        )

    @Test
    fun dropsOnlyTheCamerasWhoseFacingThrows() {
        val real = Cam("0", 0)
        val phantom = Cam("1", null)
        assertEquals(listOf(real), withReadableFacing(listOf(real, phantom), ::read))
        assertEquals(listOf(real), withReadableFacing(listOf(phantom, real), ::read))
    }

    @Test
    fun keepsEveryReadableCameraInOrder() {
        val cams = listOf(Cam("0", 1), Cam("1", 0))
        assertEquals(cams, withReadableFacing(cams, ::read))
    }

    @Test
    fun emptyWhenNothingReadsOrNothingIsListed() {
        assertEquals(emptyList<Cam>(), withReadableFacing(listOf(Cam("1", null)), ::read))
        assertEquals(emptyList<Cam>(), withReadableFacing(emptyList(), ::read))
    }
}
