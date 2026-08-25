package me.jxl.kiosk_satellite

import android.content.Context
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager

/**
 * The App Launcher's idle clock's eyes (issue #317): a one-pixel,
 * transparent, untouchable draw-over-apps window whose only job is to be
 * told about touches that land anywhere else.
 *
 * Android has no "when was the screen last touched" API, and while
 * another app is in front the kiosk sees none of its touches. What it
 * does offer is FLAG_WATCH_OUTSIDE_TOUCH: a window that asks for it gets
 * one ACTION_OUTSIDE event per gesture that starts outside it. The
 * coordinates come zeroed (another app's touches are its own business),
 * which is fine: "a touch happened" is all the auto-return timer needs to
 * restart from. The window is FLAG_NOT_TOUCHABLE, so it obscures nothing
 * and the other app keeps every touch, and it is added with the
 * application context so it survives the kiosk Activity going behind.
 *
 * Rides the same draw-over-apps grant auto-return already needs for
 * bringToFront, so a kiosk that can come back can also tell when to.
 * Where the window cannot be added (grant gone, or an app that hides
 * overlays with setHideOverlayWindows) the caller falls back to the plain
 * clock, which is what auto-return was before this.
 */
object TouchWatchOverlay {
    private const val TAG = "TouchWatchOverlay"
    private val main = Handler(Looper.getMainLooper())
    private var view: View? = null

    /** Add the window; true when it is up and watching. */
    fun start(context: Context, onTouch: () -> Unit): Boolean {
        if (view != null) return true
        val v = View(context)
        v.setOnTouchListener { _, ev ->
            if (ev.actionMasked == MotionEvent.ACTION_OUTSIDE) onTouch()
            false
        }
        val params = WindowManager.LayoutParams(
            1,
            1,
            overlayWindowType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT,
        )
        params.gravity = Gravity.TOP or Gravity.START
        params.alpha = 0f
        return try {
            context.getSystemService(WindowManager::class.java).addView(v, params)
            view = v
            true
        } catch (e: Exception) {
            // No grant, or a WindowManager that refuses the type (a racing
            // revocation): the plain clock still runs.
            Log.w(TAG, "touch watch refused: $e")
            false
        }
    }

    fun stop(context: Context) {
        val v = view ?: return
        view = null
        try {
            context.getSystemService(WindowManager::class.java).removeViewImmediate(v)
        } catch (_: Exception) {
        }
    }

    fun isWatching(): Boolean = view != null

    /** Both entry points hop to the main thread: window operations must. */
    fun post(block: () -> Unit) = main.post(block)
}
