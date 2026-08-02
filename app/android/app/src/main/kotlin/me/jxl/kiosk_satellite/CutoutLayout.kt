package me.jxl.kiosk_satellite

import android.app.Activity
import android.graphics.Insets
import android.os.Build
import android.view.WindowInsets
import android.view.WindowManager

/**
 * Applies the "Display cutout" setting (browser.cutout_mode) to an
 * Activity's window.
 *
 * Two knobs move together per mode:
 *
 *  - layoutInDisplayCutoutMode, which decides whether the window may occupy
 *    the screen row holding a punch-hole camera or notch.
 *  - whether the cutout inset is stripped from the inset dispatch. When the
 *    window claims the cutout row, the modern dispatch (enabled by the
 *    edge-to-edge fix for discussion #102) would carry the cutout inset down
 *    to the dashboard WebView, Chromium would republish it to the page as
 *    env(safe-area-inset-top), and Home Assistant's frontend would pad its
 *    header by it: the gap the mode exists to remove. So the fill modes
 *    withhold it. The avoid modes leave the dispatch alone: either the
 *    window is out of the cutout row and the inset is zero anyway (never),
 *    or the system and the page are being left to negotiate (default).
 *
 * Bar and IME insets always pass through for Flutter's own padding and
 * keyboard handling.
 *
 * Some ROMs overrule the mode: One UI forces the window into the cutout row
 * regardless of a NEVER request (verified on One UI 8: the window-level
 * attribute reads NEVER post-set, yet the relayout the WindowManager receives
 * says always). The avoid modes still do their job there through the inset
 * half: un-stripped, the cutout inset reaches the page and Home Assistant
 * pads its header below the camera.
 *
 * Called from MainActivity.onCreate with the SharedPreferences mirror of
 * the setting (right from the first frame), and from KioskLock.apply when
 * the setting changes at runtime.
 */
object CutoutLayout {
    /** Read by the listener on every dispatch; apply() flips it per mode. */
    @Volatile private var strip = true

    fun apply(activity: Activity, mode: String) {
        if (Build.VERSION.SDK_INT < 28) return
        strip = mode == "always" || mode == "short_edges"
        // A fresh copy, not an in-place mutation: getAttributes returns the
        // window's own instance, and setAttributes copies the argument onto
        // that instance to compute what changed. Handing it back itself makes
        // the diff empty and the new mode never reaches the WindowManager
        // (it only worked before attach, where addView takes the attrs as-is).
        val lp = WindowManager.LayoutParams()
        lp.copyFrom(activity.window.attributes)
        activity.window.attributes = lp.apply {
            layoutInDisplayCutoutMode = when (mode) {
                "never" -> WindowManager.LayoutParams
                    .LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER
                "default" -> WindowManager.LayoutParams
                    .LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT
                "short_edges" -> WindowManager.LayoutParams
                    .LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                // "always" needs API 30; short edges is the closest below.
                else -> if (Build.VERSION.SDK_INT >= 30) {
                    WindowManager.LayoutParams
                        .LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                } else {
                    WindowManager.LayoutParams
                        .LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                }
            }
        }
        // Idempotent: a second apply() replaces the previous listener.
        activity.window.decorView.setOnApplyWindowInsetsListener { view, insets ->
            view.onApplyWindowInsets(if (strip) stripped(insets) else insets)
        }
        // Re-dispatch so a runtime mode change reaches the page immediately;
        // the WebView re-evaluates env(safe-area-inset-*) on the spot.
        activity.window.decorView.requestApplyInsets()
    }

    private fun stripped(insets: WindowInsets): WindowInsets =
        if (Build.VERSION.SDK_INT >= 30) {
            WindowInsets.Builder(insets)
                .setInsets(WindowInsets.Type.displayCutout(), Insets.NONE)
                .setDisplayCutout(null)
                .build()
        } else {
            @Suppress("DEPRECATION")
            insets.consumeDisplayCutout()
        }
}
