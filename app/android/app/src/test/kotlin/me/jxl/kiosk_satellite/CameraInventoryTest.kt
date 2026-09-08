package me.jxl.kiosk_satellite

import kotlin.test.Test
import kotlin.test.assertEquals

class CameraInventoryTest {
    @Test
    fun namesTheFactsCameraXFiltersOn() {
        assertEquals(
            "id 0: front, legacy, backward compatible",
            describeCamera("0", 0, 2, intArrayOf(0, 1)),
        )
        assertEquals(
            "id 2: external, external level, not backward compatible",
            describeCamera("2", 2, 4, intArrayOf(1)),
        )
    }

    @Test
    fun spellsOutWhatItCannotRead() {
        assertEquals(
            "id 1: facing 255, level unknown, no capability list",
            describeCamera("1", 255, null, null),
        )
        assertEquals(
            "id 1: facing unknown, level 7, backward compatible",
            describeCamera("1", null, 7, intArrayOf(0)),
        )
    }

    @Test
    fun namesTheCameraStateErrorCodes() {
        assertEquals(
            "another app or a closing session still holds the camera",
            cameraStateErrorName(2),
        )
        assertEquals("the camera service failed", cameraStateErrorName(6))
        assertEquals("an unknown camera error", cameraStateErrorName(42))
    }
}
