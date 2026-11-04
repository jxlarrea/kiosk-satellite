package me.jxl.kiosk_satellite

import org.junit.Assert.*
import org.junit.Test

class CameraJpegHangsTest {
    private var stored: String? = null
    private fun hangs(build: String) = CameraJpegHangs(build, { stored }, { stored = it })

    @Test fun nothingIsHungUntilACameraIsRemembered() {
        assertFalse(hangs("a").hung("1"))
        hangs("a").remember("1")
        assertTrue(hangs("a").hung("1"))
        assertFalse(hangs("a").hung("0"))
    }

    @Test fun eachCameraIsRememberedOnce() {
        hangs("a").remember("1")
        hangs("a").remember("0")
        hangs("a").remember("1")
        assertEquals("a\n1\n0", stored)
    }

    @Test fun aNewSystemBuildStartsClean() {
        hangs("a").remember("1")
        assertFalse(hangs("b").hung("1"))
        hangs("b").remember("0")
        assertEquals("b\n0", stored)
        assertFalse(hangs("a").hung("1"))
    }
}
