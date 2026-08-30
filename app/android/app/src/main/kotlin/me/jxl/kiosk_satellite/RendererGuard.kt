package me.jxl.kiosk_satellite

import android.content.Context
import android.util.Log

/**
 * Decides, before the Flutter engine exists, whether this device may render
 * with Impeller (issue #127).
 *
 * Old GPU drivers (the Galaxy Tab Pro 8.4's 2016 Adreno 330 build) SIGSEGV
 * in the raster thread the moment Impeller's OpenGLES backend draws the
 * first frame, and Flutter does not fall back to Skia on its own — the app
 * just dies at every launch. The manifest opt-out is all-or-nothing, so the
 * choice is made here, per device, when the engine is created:
 *
 *  - the `render.disable_impeller` setting turns Impeller off explicitly
 *    (a person, the remote admin, or adb provisioning);
 *  - the crash net turns it off automatically: two consecutive process
 *    deaths within [BOOT_WINDOW_MS] of engine creation without ever
 *    showing a frame read as "the renderer kills this device". The crash
 *    self-heal relaunches after each native crash, so an affected device
 *    converges to the working renderer on its own — two quick crashes,
 *    once in its life — and the setting is flipped along the way so both
 *    settings UIs tell the truth about what the device is doing.
 */
object RendererGuard {
    private const val TAG = "RendererGuard"
    private const val PREFS = "FlutterSharedPreferences"
    private const val DISABLED = "flutter.ks.render.disable_impeller"
    private const val PENDING_SINCE = "flutter.ks.render.boot_pending_since"
    private const val EARLY_CRASHES = "flutter.ks.render.early_crashes"

    /** A death later than this after engine creation is the OS reclaiming a
     *  headless process, not the renderer crashing the boot. */
    private const val BOOT_WINDOW_MS = 90_000L
    private const val TRIP_AFTER = 2L

    /** Set once the Meta Portal rule below has written the setting, so a
     *  person who later turns Legacy renderer off on purpose is obeyed. */
    private const val PORTAL_RULE_APPLIED = "flutter.ks.render.portal_rule_applied"

    /** The engine's shell arguments, or null for the defaults. Also runs
     *  the crash accounting, so call it exactly once per process. */
    fun engineArgs(context: Context): Array<String>? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        var disabled = prefs.getBoolean(DISABLED, false)
        // Meta Portal (Adreno 615, Android 10): Impeller rejects the Vulkan
        // driver and runs its OpenGLES backend, which does not survive the
        // Activity being destroyed and re-created under the cached engine
        // (the home app restarting, a permission dialog on some builds):
        // from the re-attach on, every frame fails with EGL_BAD_ACCESS and
        // the Flutter UI is gone for good while Dart and the WebView carry
        // on, which no watchdog can tell from a healthy kiosk. Skia has no
        // such failure, so the setting is flipped once, the way the crash
        // net flips it, so both settings UIs tell the truth.
        if (!disabled && !prefs.getBoolean(PORTAL_RULE_APPLIED, false) &&
            android.os.Build.MANUFACTURER.equals("Facebook", ignoreCase = true)
        ) {
            disabled = true
            prefs.edit().putBoolean(DISABLED, true)
                .putBoolean(PORTAL_RULE_APPLIED, true).commit()
            Log.w(TAG, "Meta Portal: Impeller's OpenGLES backend wedges on " +
                "Activity re-creation; disabling Impeller for this device")
        }
        val pendingSince = prefs.getLong(PENDING_SINCE, 0L)
        if (!disabled && pendingSince > 0L &&
            System.currentTimeMillis() - pendingSince < BOOT_WINDOW_MS
        ) {
            val crashes = prefs.getLong(EARLY_CRASHES, 0L) + 1
            if (crashes >= TRIP_AFTER) {
                disabled = true
                Log.w(TAG, "$crashes boots died before the first frame; " +
                    "disabling Impeller for this device")
            }
            prefs.edit().putLong(EARLY_CRASHES, crashes)
                .putBoolean(DISABLED, disabled).commit()
        }
        // commit(), not apply(): if the renderer takes the process down,
        // this marker is the only witness the next boot has.
        prefs.edit().putLong(PENDING_SINCE, System.currentTimeMillis()).commit()
        if (disabled) Log.i(TAG, "Impeller disabled; rendering with Skia")
        return if (disabled) arrayOf("--enable-impeller=false") else null
    }

    /** The first frame is on screen: the renderer works, stand the net down. */
    fun noteFirstFrame(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(PENDING_SINCE)
            .remove(EARLY_CRASHES)
            .apply()
    }
}
