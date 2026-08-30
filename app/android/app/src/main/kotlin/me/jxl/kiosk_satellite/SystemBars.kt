package me.jxl.kiosk_satellite

import android.app.Activity
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.WindowInsets

/**
 * Re-asserts the kiosk's immersive mode from the native side when a window
 * gains focus.
 *
 * Dart asks for immersive-sticky at launch and on every resume, but that
 * request reaches the window that exists when it lands. An Activity
 * destroyed and re-created under the process-wide engine (Back on a Meta
 * Portal's own system bar finishes it, a tile tap re-creates it) gets a
 * fresh window, and on the Portal the bar service shows its bars for a new
 * Activity until the window reports otherwise: a resume that raced that
 * report left Meta's bar over the dashboard until the next focus change.
 * Applying the same flags here, at focus and again a beat later, closes
 * that gap on every device, and repeating an already-applied mode is free.
 */
object SystemBars {
    private val main = Handler(Looper.getMainLooper())

    /** The legacy flags Flutter's immersiveSticky sets, for Android 10 and
     *  older, where the insets controller does not exist. */
    @Suppress("DEPRECATION")
    private const val LEGACY_FLAGS =
        View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_FULLSCREEN

    /** Hide the bars now and again shortly after, for a window that just
     *  gained focus. */
    fun reassertOnFocus(activity: Activity) {
        hide(activity)
        for (delay in longArrayOf(500L, 2500L)) {
            main.postDelayed({
                if (!activity.isFinishing && !activity.isDestroyed) hide(activity)
            }, delay)
        }
    }

    fun hide(activity: Activity) {
        val window = activity.window ?: return
        if (Build.VERSION.SDK_INT >= 30) {
            val insets = window.decorView.rootWindowInsets
            val visible = insets == null ||
                insets.isVisible(WindowInsets.Type.statusBars()) ||
                insets.isVisible(WindowInsets.Type.navigationBars())
            if (!visible) return
            window.insetsController?.hide(
                WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars(),
            )
        } else {
            @Suppress("DEPRECATION")
            val decor = window.decorView
            @Suppress("DEPRECATION")
            if (decor.systemUiVisibility and LEGACY_FLAGS != LEGACY_FLAGS) {
                @Suppress("DEPRECATION")
                decor.systemUiVisibility = decor.systemUiVisibility or LEGACY_FLAGS
            }
        }
    }
}
