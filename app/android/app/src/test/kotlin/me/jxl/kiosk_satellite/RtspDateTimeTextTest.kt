package me.jxl.kiosk_satellite

import android.app.Application
import android.content.Context
import android.content.res.Configuration
import android.provider.Settings
import org.junit.Assert.*
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.util.Locale
import java.util.TimeZone

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33], application = Application::class)
class RtspDateTimeTextTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()
    private lateinit var originalZone: TimeZone
    private val noon = 1_789_739_045_000L // September 18, 2026 at 13:44:05 UTC.

    @Before fun setup() {
        originalZone = TimeZone.getDefault()
        TimeZone.setDefault(TimeZone.getTimeZone("UTC"))
        Settings.System.putString(context.contentResolver, Settings.System.TIME_12_24, "24")
        kiosk("en")
    }

    @After fun cleanup() { TimeZone.setDefault(originalZone) }

    private fun device(tag: String): Context {
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(tag))
        return context.createConfigurationContext(configuration)
    }

    @Test fun usesDeviceDateOrderAndClockPreference() {
        val us = RtspDateTimeText(device("en-US")).at(noon)
        val gb = RtspDateTimeText(device("en-GB")).at(noon)
        assertTrue(us, us.startsWith("9/18/26"))
        assertTrue(gb, gb.startsWith("18/09/2026"))
        assertTrue(us, us.endsWith("13:44:05"))
        Settings.System.putString(context.contentResolver, Settings.System.TIME_12_24, "12")
        val twelve = RtspDateTimeText(device("en-US")).at(noon)
        assertTrue(twelve, twelve.contains("1:44:05"))
        assertTrue(twelve, twelve.endsWith("PM"))
    }

    @Test fun refreshesSecondsClockPreferenceAndTimezoneDuringStreaming() {
        val clock = RtspDateTimeText(device("en-US"))
        val first = clock.at(noon)
        assertSame(first, clock.at(noon + 500))
        assertTrue(clock.at(noon + 1000).endsWith("13:44:06"))
        Settings.System.putString(context.contentResolver, Settings.System.TIME_12_24, "12")
        assertTrue(clock.at(noon + 2000).endsWith("PM"))
        TimeZone.setDefault(TimeZone.getTimeZone("America/Guayaquil"))
        val local = clock.at(noon + 3000)
        assertTrue(local, local.contains("8:44:08"))
        assertTrue(local, local.endsWith("AM"))
        assertTrue(clock.at(noon - 1000).contains("8:44:04"))
    }

    private fun kiosk(language: String) {
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit().putString("flutter.ks.ui.language", language).commit()
    }

    @Test fun kioskLanguageSetsTheFormatOverTheDeviceLanguage() {
        kiosk("es")
        val spanish = RtspDateTimeText(device("en-US")).at(noon)
        assertTrue(spanish, spanish.startsWith("18/9/26"))
        kiosk("en")
        val english = RtspDateTimeText(device("de-DE")).at(noon)
        assertTrue(english, english.startsWith("9/18/26"))
    }

    @Test fun deviceRegionStaysWhenItSpeaksTheKioskLanguage() {
        kiosk("en")
        val british = RtspDateTimeText(device("en-GB")).at(noon)
        assertTrue(british, british.startsWith("18/09/2026"))
        kiosk("de")
        val german = RtspDateTimeText(device("de-DE")).at(noon)
        assertTrue(german, german.startsWith("18.09.26"))
    }
}
