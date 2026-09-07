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

    /** Who turned the setting on, when the app did it itself ("crashes"
     *  for the crash net). Absent when a person set it, or when it is off:
     *  the Dart settings manager drops it on every change a person makes,
     *  so a later automatic revert can single out the app's own flips and
     *  leave deliberate choices alone. */
    private const val DISABLED_BY = "flutter.ks.render.disabled_by"

    /** Written by a rule that ran on Meta Portals from 2026.8.9x up to
     *  2026.9.22: Impeller's OpenGLES backend lost its context when the
     *  Activity was destroyed and re-created under the cached engine and
     *  never drew again, so the rule switched every Portal to Skia on its
     *  first start. That was this app's own teardown ordering (fixed in
     *  [MainThreadEgl]), not the Portal's GPU, so the rule is gone and
     *  [PORTAL_RULE_REVERTED] marks the one-time switch back it earned. */
    private const val PORTAL_RULE_APPLIED = "flutter.ks.render.portal_rule_applied"
    private const val PORTAL_RULE_REVERTED = "flutter.ks.render.portal_rule_reverted"

    /** The engine's shell arguments, or null for the defaults. Also runs
     *  the crash accounting, so call it exactly once per process. */
    fun engineArgs(context: Context): Array<String>? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        var disabled = prefs.getBoolean(DISABLED, false)
        // A Portal the old rule put on Skia goes back to Impeller exactly
        // once. After that the setting is a person's, whichever way it
        // points, and the crash net below still stands behind Impeller.
        if (prefs.getBoolean(PORTAL_RULE_APPLIED, false) &&
            !prefs.getBoolean(PORTAL_RULE_REVERTED, false)
        ) {
            disabled = false
            prefs.edit().putBoolean(DISABLED, false)
                .putBoolean(PORTAL_RULE_REVERTED, true)
                .remove(DISABLED_BY).commit()
            Log.i(TAG, "Meta Portal: the re-creation wedge that put this " +
                "device on Skia is fixed; Impeller is back on")
        }
        // Off means whoever put it on has been overruled since; a stale
        // provenance would misfile the next deliberate flip as the app's.
        if (!disabled && prefs.contains(DISABLED_BY)) {
            prefs.edit().remove(DISABLED_BY).commit()
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
            val edit = prefs.edit().putLong(EARLY_CRASHES, crashes)
                .putBoolean(DISABLED, disabled)
            if (disabled) edit.putString(DISABLED_BY, "crashes")
            edit.commit()
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
