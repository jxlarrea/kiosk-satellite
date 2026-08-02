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
 * Anything that survives the inset dispatch reaches the dashboard WebView,
 * Chromium republishes it to the page as env(safe-area-inset-*), and Home
 * Assistant's frontend pads its layout by it. Two independent rules decide
 * what survives:
 *
 *  - Status and navigation bar insets are withheld ALWAYS, on every mode.
 *    The app keeps the bars permanently hidden, so a page padding for them
 *    is never right; on healthy ROMs their insets are zero while hidden and
 *    this is a no-op. Lenovo's ZUI reports the status bar inset as occupied
 *    even while immersive mode has the bar hidden, which put a bar-height
 *    gap inside the page on a device with no cutout at all (discussion #102:
 *    the reporter's photos show the page background full-bleed with the
 *    content padded down one bar height, and with Home Assistant's header
 *    shown the gap sits above the header, its own safe-area padding). Kept
 *    out of the cutout setting deliberately: that device has nothing to
 *    gain from any cutout choice, and no choice should reopen the gap.
 *  - The cutout inset follows the mode: the fill modes (always,
 *    short_edges) withhold it, along with claiming the cutout row via
 *    layoutInDisplayCutoutMode; the avoid modes (default, never) let it
 *    through, so the page can pad below a punch-hole camera.
 *
 * IME insets always pass through for Flutter's keyboard handling.
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
    /** Read by the listener on every dispatch; apply() flips it per mode.
     *  Governs only the cutout inset; bars are stripped unconditionally. */
    @Volatile private var stripCutout = true

    fun apply(activity: Activity, mode: String) {
        if (Build.VERSION.SDK_INT < 28) return
        stripCutout = mode == "always" || mode == "short_edges"
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
            view.onApplyWindowInsets(stripped(insets))
        }
        // Re-dispatch so a runtime mode change reaches the page immediately;
        // the WebView re-evaluates env(safe-area-inset-*) on the spot.
        activity.window.decorView.requestApplyInsets()
    }

    private fun stripped(insets: WindowInsets): WindowInsets =
        if (Build.VERSION.SDK_INT >= 30) {
            var types = WindowInsets.Type.statusBars() or
                WindowInsets.Type.navigationBars()
            if (stripCutout) types = types or WindowInsets.Type.displayCutout()
            WindowInsets.Builder(insets)
                .setInsets(types, Insets.NONE)
                .setInsetsIgnoringVisibility(types, Insets.NONE)
                .setVisible(types, false)
                .apply { if (stripCutout) setDisplayCutout(null) }
                .build()
        } else if (stripCutout) {
            // Only the cutout on the legacy dispatch: the pre-30 systemWindow
            // insets fold the keyboard in with the bars, so consuming them
            // would leave text fields covered by the IME.
            @Suppress("DEPRECATION")
            insets.consumeDisplayCutout()
        } else {
            insets
        }
}
