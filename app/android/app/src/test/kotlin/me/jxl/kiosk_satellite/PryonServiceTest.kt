package me.jxl.kiosk_satellite

import android.app.Application
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowDisplay

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30], manifest = Config.NONE, application = Application::class)
class PryonServiceTest {
    @Test
    fun detectsTheServiceWithAScreen() = detectsOnEveryDevice(headless = false)

    @Test
    fun detectsTheServiceWithoutAScreen() = detectsOnEveryDevice(headless = true)

    private fun detectsOnEveryDevice(headless: Boolean) {
        setScreen(headless)
        assertEquals(headless, Headless.active(RuntimeEnvironment.getApplication()))
        // The Echo Dot and Echo Show images.
        assertTrue(PryonService.detect(props("ro.kiosk_satellite.pryon" to "1")))
        // Any other device keeps the engine hidden.
        assertFalse(PryonService.detect(props()))
        assertFalse(PryonService.detect(props("ro.kiosk_satellite.pryon" to "0")))
        // The old images' properties, from before pryond, do not count.
        assertFalse(PryonService.detect(props("ro.biscuit.pryon" to "1")))
        assertFalse(PryonService.detect(props("ro.echo.pryon" to "1")))
        // The other features of the images do not make the service.
        assertFalse(PryonService.detect(props("ro.echo.ota" to "1", "ro.biscuit.ota" to "1")))
    }

    private fun props(vararg set: Pair<String, String>): (String) -> String =
        { name -> set.toMap()[name] ?: "" }

    // A 1x1 stub display is what a device without a panel reports.
    private fun setScreen(headless: Boolean) {
        val shadow = shadowOf(ShadowDisplay.getDefaultDisplay())
        shadow.setRealWidth(if (headless) 1 else 1080)
        shadow.setRealHeight(if (headless) 1 else 1920)
        Headless::class.java.getDeclaredField("cached").apply { isAccessible = true }
            .set(Headless, null)
    }
}
