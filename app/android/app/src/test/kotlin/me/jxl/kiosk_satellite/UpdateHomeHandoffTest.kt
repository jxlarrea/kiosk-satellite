package me.jxl.kiosk_satellite

import android.app.Application
import android.content.ComponentName
import android.content.pm.ActivityInfo
import android.content.pm.ResolveInfo
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [29], manifest = Config.NONE, application = Application::class)
class UpdateHomeHandoffTest {
    private val self = "me.jxl.kiosk_satellite"

    private fun home(
        pkg: String,
        name: String,
        priority: Int = 0,
        exported: Boolean = true,
    ) = ResolveInfo().apply {
        this.priority = priority
        activityInfo = ActivityInfo().apply {
            packageName = pkg
            this.name = name
            this.exported = exported
        }
    }

    @Test
    fun picksTheOtherLauncherOnAPortal() {
        val meta = "com.facebook.alohaapps.launcher"
        val activity = "com.facebook.aloha.app.home.touch.HomeActivity"
        assertEquals(
            ComponentName(meta, activity),
            UpdateHomeHandoff.pickLauncher(
                listOf(
                    home(self, "$self.HomeAlias"),
                    home(meta, activity),
                    home("com.android.settings", "com.android.settings.FallbackHome", -1001),
                ),
                self,
            ),
        )
    }

    @Test
    fun fallbackHomeDoesNotCount() {
        assertNull(
            UpdateHomeHandoff.pickLauncher(
                listOf(
                    home(self, "$self.HomeAlias"),
                    home("com.android.settings", "com.android.settings.FallbackHome", -1001),
                ),
                self,
            ),
        )
    }

    @Test
    fun aLauncherThatCannotBeStartedDoesNotCount() {
        assertNull(
            UpdateHomeHandoff.pickLauncher(
                listOf(home("com.example.launcher", "Home", exported = false)),
                self,
            ),
        )
    }

    @Test
    fun recognizesTheMissingUidRecord() {
        assertTrue(
            KioskSatelliteService.isOrphanedUid(
                NullPointerException(
                    "Attempt to invoke virtual method 'int " +
                        "com.android.server.am.UidRecord.getCurProcState()' " +
                        "on a null object reference",
                ),
            ),
        )
    }

    @Test
    fun otherForegroundRefusalsAreNotAnOrphan() {
        assertFalse(KioskSatelliteService.isOrphanedUid(NullPointerException("something else")))
        assertFalse(KioskSatelliteService.isOrphanedUid(NullPointerException()))
        assertFalse(KioskSatelliteService.isOrphanedUid(SecurityException("UidRecord")))
    }

    @Test
    fun anOrphanRestartWaitsOutTheWindow() {
        val minute = 60_000L
        val last = 1_000_000_000L
        assertTrue(KioskSatelliteService.orphanRestartAllowed(0L, last))
        assertFalse(KioskSatelliteService.orphanRestartAllowed(last, last))
        assertFalse(KioskSatelliteService.orphanRestartAllowed(last, last + 9 * minute))
        assertTrue(KioskSatelliteService.orphanRestartAllowed(last, last + 10 * minute))
    }

    @Test
    fun aClockThatMovedBackDoesNotBlockARestart() {
        assertTrue(KioskSatelliteService.orphanRestartAllowed(2_000_000L, 1_000_000L))
    }
}
