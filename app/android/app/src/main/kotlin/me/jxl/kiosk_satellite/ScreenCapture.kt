package me.jxl.kiosk_satellite

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.view.PixelCopy
import android.view.Surface
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

/**
 * Captures the composed Android window via [PixelCopy], including the
 * WebView, its video, menus and screensaver, with the SurfaceViews
 * underneath wherever the window is transparent. The GPU copy never draws
 * on the main thread. The WebView plugin's takeScreenshot renders
 * the view hierarchy into a bitmap *on* the UI thread, which the remote
 * admin's auto-refresh turned into a visible stutter every few seconds.
 *
 * The copy lands directly in a bitmap of the requested size (PixelCopy
 * scales on the way), so a 720px preview never allocates a full-resolution
 * frame, and the JPEG encode runs on this helper's own thread.
 *
 * Activity-scoped (a window is required): registered and torn down by
 * MainActivity alongside the other Activity bridges. Returns null rather
 * than failing when there is nothing to capture. The Dart side falls back
 * to the WebView's own page capture.
 */
class ScreenCapture(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/screen_capture")
    private val thread = HandlerThread("screen-capture").also { it.start() }
    private val handler = Handler(thread.looper)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "capture" -> capture(
                    (call.argument<Number>("width"))?.toInt() ?: 1280,
                    (call.argument<Number>("quality"))?.toInt() ?: 80,
                    call.argument<Boolean>("raw") == true,
                    result,
                )
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        thread.quitSafely()
    }

    /**
     * [raw] answers with the pixels themselves, RGBA in a map with the
     * width and height, for a frame that goes straight back on screen
     * (Compass navigation's swipe): no JPEG encode here and no decode in
     * Flutter, which on an Echo Show cost more than the copy.
     */
    private fun capture(width: Int, quality: Int, raw: Boolean, result: MethodChannel.Result) {
        // Window PixelCopy is API 26; older devices use the WebView fallback.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(null)
            return
        }
        val window = activity.window
        val view = window?.decorView
        if (window == null || view == null || view.width == 0 || view.height == 0) {
            result.success(null)
            return
        }
        val w = width.coerceIn(16, view.width)
        val h = (view.height.toLong() * w / view.width).toInt().coerceAtLeast(16)
        // The window copy holds the WebView, its video and Flutter while
        // hybrid composition draws Flutter into the window. Once Weather Mood
        // hides the dashboard, Flutter draws into its own SurfaceView and the
        // window copy is transparent there, so that surface fills it in. A
        // video on a platform view (issue #894) is another SurfaceView that
        // punches a hole in the window, filled in the same way, above
        // Flutter's own surface.
        val scale = w.toFloat() / view.width
        val under = surfaceLayers(view).mapNotNull { surface ->
            val holder = surface.holder.surface
            if (!holder.isValid) return@mapNotNull null
            val at = IntArray(2).also(surface::getLocationInWindow)
            val left = (at[0] * scale).toInt()
            val top = (at[1] * scale).toInt()
            SurfaceLayer(
                holder,
                Rect(
                    left,
                    top,
                    left + (surface.width * scale).toInt().coerceAtLeast(1),
                    top + (surface.height * scale).toInt().coerceAtLeast(1),
                ),
            )
        }
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val main = Handler(Looper.getMainLooper())
        // On the capture thread: encode here, answer on the platform thread
        // (MethodChannel results must come from there).
        fun finish(frame: Bitmap?) {
            if (frame == null) {
                main.post { result.success(null) }
                return
            }
            if (raw) {
                // ARGB_8888 is laid out R, G, B, A in memory: the order
                // Flutter's rgba8888 decode expects.
                val buffer = ByteBuffer.allocate(frame.byteCount)
                frame.copyPixelsToBuffer(buffer)
                val answer = mapOf(
                    "width" to frame.width,
                    "height" to frame.height,
                    "rowBytes" to frame.rowBytes,
                    "pixels" to buffer.array(),
                )
                frame.recycle()
                main.post { result.success(answer) }
                return
            }
            val out = ByteArrayOutputStream()
            frame.compress(Bitmap.CompressFormat.JPEG, quality.coerceIn(1, 100), out)
            frame.recycle()
            main.post { result.success(out.toByteArray()) }
        }
        try {
            PixelCopy.request(window, bitmap, { status ->
                if (status != PixelCopy.SUCCESS) {
                    bitmap.recycle()
                    finish(null)
                } else if (under.isEmpty() || !hasTransparency(bitmap, if (raw) 8 else 1)) {
                    finish(bitmap)
                } else {
                    underlay(bitmap, under, ::finish)
                }
            }, handler)
        } catch (_: Exception) {
            bitmap.recycle()
            result.success(null)
        }
    }

    /**
     * Copy each surface in turn, bottom first, and draw the window copy over
     * them all. A surface that will not copy is left out rather than costing
     * the whole picture.
     */
    private fun underlay(window: Bitmap, layers: List<SurfaceLayer>, finish: (Bitmap?) -> Unit) {
        val frame = Bitmap.createBitmap(window.width, window.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(frame).apply { drawColor(Color.BLACK) }
        fun next(index: Int) {
            if (index == layers.size) {
                canvas.drawBitmap(window, 0f, 0f, null)
                window.recycle()
                finish(frame)
                return
            }
            val layer = layers[index]
            val surface = Bitmap.createBitmap(
                layer.bounds.width(),
                layer.bounds.height(),
                Bitmap.Config.ARGB_8888,
            )
            try {
                PixelCopy.request(layer.surface, surface, { status ->
                    if (status == PixelCopy.SUCCESS) {
                        canvas.drawBitmap(surface, null, layer.bounds, null)
                    }
                    surface.recycle()
                    next(index + 1)
                }, handler)
            } catch (_: Exception) {
                surface.recycle()
                next(index + 1)
            }
        }
        next(0)
    }

    private class SurfaceLayer(val surface: Surface, val bounds: Rect)
}

/**
 * The SurfaceViews on screen, in drawing order: Flutter's own first, then
 * any platform view's (a video on a SurfaceView) above it. Whether one
 * supplies any of the picture shows in the window copy: hybrid composition
 * covers Flutter's with an opaque window, a hidden dashboard leaves the
 * window transparent, and a platform view's surface punches its own hole.
 */
internal fun surfaceLayers(root: View): List<SurfaceView> {
    val found = mutableListOf<SurfaceView>()
    fun walk(view: View) {
        if (view.visibility != View.VISIBLE || view.alpha <= 0f) return
        if (view is SurfaceView) {
            if (view.width > 0 && view.height > 0) found.add(view)
            return
        }
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) walk(view.getChildAt(index))
        }
    }
    if (root.isShown) walk(root)
    return found
}

/**
 * True when any pixel of [bitmap] lets a layer below it show through.
 * [step] samples every step-th row and column: a transparent region is a
 * whole surface's worth of pixels, never a lone one, and a swipe's
 * snapshot cannot wait on a full scan of a tablet-sized frame.
 */
internal fun hasTransparency(bitmap: Bitmap, step: Int = 1): Boolean {
    val row = IntArray(bitmap.width)
    var y = 0
    while (y < bitmap.height) {
        bitmap.getPixels(row, 0, bitmap.width, 0, y, bitmap.width, 1)
        var x = 0
        while (x < row.size) {
            if (row[x] ushr 24 != 0xFF) return true
            x += step
        }
        y += step
    }
    return false
}
