package me.jxl.kiosk_satellite

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CrashSelfHealTest {
    private fun check(
        activityUp: Boolean = false,
        exiting: Boolean = false,
        autoReload: Boolean = true,
        wasForeground: Boolean = true,
        foregroundBoot: Long = 7L,
        boot: Long = 7L,
    ) = CrashSelfHeal.startedWithoutScreen(
        activityUp, exiting, autoReload, wasForeground, foregroundBoot, boot,
    )

    @Test
    fun aProcessWithNoScreenOnAKioskThatWasOnScreenComesBack() {
        assertTrue(check())
    }

    @Test
    fun aKioskAlreadyUpIsLeftAlone() {
        assertFalse(check(activityUp = true))
    }

    @Test
    fun aDeliberateExitStaysOut() {
        assertFalse(check(exiting = true))
    }

    @Test
    fun autoReloadOffStaysOut() {
        assertFalse(check(autoReload = false))
    }

    @Test
    fun aKioskThePersonLeftStaysOut() {
        assertFalse(check(wasForeground = false))
    }

    @Test
    fun aRebootLeavesItToStartOnBoot() {
        assertFalse(check(foregroundBoot = 6L, boot = 7L))
        // An install from before the boot was recorded.
        assertFalse(check(foregroundBoot = -1L, boot = 7L))
    }
}
