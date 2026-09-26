package me.jxl.kiosk_satellite

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * The status bar icon as pixels, not as a resource id: for a moment around
 * an update the system could not load this app's icon resource and answered
 * a notification with "Bad notification", which kills the app (two
 * processes in three seconds on a Galaxy Tab A, a fresh Xperia install on
 * its first update). A bitmap needs nothing looked up on the system's side.
 * Drawn once per process at 24 dp.
 */
internal object StatusBarIcon {
    private const val TAG = "StatusBarIcon"

    @Volatile private var cached: Bitmap? = null

    /** Null when the drawable cannot be drawn; the resource id is the fallback. */
    fun bitmap(context: Context): Bitmap? {
        cached?.let { return it }
        return try {
            val drawable = ContextCompat.getDrawable(context, R.drawable.ic_stat_service) ?: return null
            val px = (24 * context.resources.displayMetrics.density).toInt().coerceAtLeast(24)
            val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, px, px)
            drawable.draw(canvas)
            bitmap.also { cached = it }
        } catch (e: Exception) {
            Log.w(TAG, "status bar icon not drawable, using the resource: $e")
            null
        }
    }
}
