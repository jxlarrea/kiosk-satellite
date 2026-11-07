package me.jxl.kiosk_satellite

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

/** Uses the same saved preference as Flutter, including before Flutter starts. */
internal object NativeMessages {
    fun forKiosk(context: Context): Context = withLocale(context, Locale.forLanguageTag(language(context)))

    /**
     * The kiosk language for dates and numbers. When the device speaks the same
     * language its region is kept, so English on a British device still writes
     * 18/09/2026. The language always comes from the app, as in Flutter.
     */
    fun formatLocale(context: Context): Locale {
        val app = Locale.forLanguageTag(language(context))
        val device = context.resources.configuration.locales[0]
        return if (app.country.isEmpty() && device.language == app.language) device else app
    }

    fun withLocale(context: Context, locale: Locale): Context {
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(locale)
        return context.createConfigurationContext(configuration)
    }

    private fun language(context: Context): String {
        val saved = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.ks.ui.language", "en")
        val available = context.resources.getStringArray(R.array.ks_message_languages)
        return saved?.takeIf { it in available } ?: "en"
    }
}
