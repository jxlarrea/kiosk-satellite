package me.jxl.kiosk_satellite

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ColorSpace
import android.graphics.Matrix
import android.graphics.Paint
import android.media.ExifInterface
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.nio.ByteBuffer
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

/**
 * Downscales images on the CPU for Flutter when Impeller renders with
 * OpenGL ES.
 *
 * Impeller shrinks a decoded image on the GPU by attaching the uploaded
 * texture to a framebuffer on the IO thread. On the Mali-T720 driver that
 * attachment can come up incomplete while the main thread re-creates the
 * window surface for a hybrid composition WebView, and Impeller then
 * aborts the whole process (blit_pass_gles.cc). Handing Flutter pixels that
 * are already the drawn size leaves it only an upload, which never builds a
 * framebuffer.
 */
class ImageScaler(context: Context, messenger: BinaryMessenger) {
    companion object {
        private const val TAG = "ImageScaler"

        // A whole decode of a non-JPEG up to this size (64 MB of pixels)
        // before sampling has to skip pixels to keep memory in bounds.
        private const val MAX_WHOLE_PIXELS = 16_000_000L
    }

    private val app = context.applicationContext
    private val main = Handler(Looper.getMainLooper())

    // Covers, thumbnails and photos come in small bursts. Two threads keep a
    // queue row fling moving without letting decodes crowd out the UI.
    private val pool = ThreadPoolExecutor(
        0, 2, 30, TimeUnit.SECONDS, LinkedBlockingQueue(),
    ) { runnable ->
        Thread {
            Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)
            runnable.run()
        }.apply { name = "ks-imageScaler"; isDaemon = true }
    }

    init {
        MethodChannel(messenger, "kiosk_satellite/image").setMethodCallHandler { call, result ->
            when (call.method) {
                "gpuResizeRisky" -> result.success(ImpellerBackend.gpuResizeRisky(app))
                "downscale" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val width = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    val png = call.argument<Boolean>("png") ?: false
                    val sourceWidth = call.argument<Int>("sourceWidth") ?: 0
                    val sourceHeight = call.argument<Int>("sourceHeight") ?: 0
                    if (bytes == null || width <= 0 || height <= 0) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    pool.execute {
                        val value = try {
                            downscale(bytes, width, height, png, sourceWidth, sourceHeight)
                        } catch (e: Throwable) {
                            // OutOfMemoryError included: the caller falls
                            // back to Flutter's own decode.
                            Log.w(TAG, "downscale failed: ${e.javaClass.simpleName}")
                            null
                        }
                        main.post { result.success(value) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Decodes [bytes] upright at exactly [width] x [height]. Returns raw
     * premultiplied RGBA, or PNG bytes when [png] is set. Null leaves the
     * decode to Flutter: animated images, formats Android cannot read, and
     * anything whose upright size this side would not agree on. A nonzero
     * [sourceWidth] x [sourceHeight] is Flutter's upright size, which
     * Android must read the same before its pixels stand in for Flutter's.
     */
    private fun downscale(
        bytes: ByteArray,
        width: Int,
        height: Int,
        png: Boolean,
        sourceWidth: Int,
        sourceHeight: Int,
    ): Map<String, Any>? {
        if (isAnimated(bytes)) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        val rawWidth = bounds.outWidth
        val rawHeight = bounds.outHeight
        if (rawWidth <= 0 || rawHeight <= 0) return null
        val orientation = orientationOf(bytes)
        val swaps = orientation in 5..8
        val uprightWidth = if (swaps) rawHeight else rawWidth
        val uprightHeight = if (swaps) rawWidth else rawHeight
        // Flutter only asks for a smaller image. An upscale or a mismatched
        // upright size means the two sides disagree, so let Flutter decode.
        if (sourceWidth > 0 && (sourceWidth != uprightWidth || sourceHeight != uprightHeight)) {
            return null
        }
        if (width > uprightWidth || height > uprightHeight) return null

        // The target in the stored orientation.
        val storedWidth = if (swaps) height else width
        val storedHeight = if (swaps) width else height
        // A JPEG decoder samples by averaging, down to an eighth. Other
        // formats sample by skipping pixels, which drops fine patterns, so
        // they decode whole unless that would be enormous.
        val jpeg = bytes.size > 2 && bytes[0] == 0xFF.toByte() && bytes[1] == 0xD8.toByte()
        var sample = 1
        fun fits(next: Int) = rawWidth / next >= storedWidth && rawHeight / next >= storedHeight
        if (jpeg) {
            while (sample < 8 && fits(sample * 2)) sample *= 2
        } else {
            while (rawWidth.toLong() * rawHeight / (sample.toLong() * sample) > MAX_WHOLE_PIXELS &&
                fits(sample * 2)
            ) {
                sample *= 2
            }
        }
        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
            // Flutter decodes to sRGB, so a wide gamut photo keeps its colors.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                inPreferredColorSpace = ColorSpace.get(ColorSpace.Named.SRGB)
            }
        }
        var decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options) ?: return null
        // Halve with filtering, which averages each 2x2 block, until one
        // filtered step under 2x reaches the target.
        while (decoded.width >= storedWidth * 2 && decoded.height >= storedHeight * 2) {
            val half = Bitmap.createScaledBitmap(decoded, decoded.width / 2, decoded.height / 2, true)
            if (half !== decoded) decoded.recycle()
            decoded = half
        }
        val matrix = Matrix()
        orient(matrix, orientation)
        val decodedUprightWidth = if (swaps) decoded.height else decoded.width
        val decodedUprightHeight = if (swaps) decoded.width else decoded.height
        matrix.postScale(
            width.toFloat() / decodedUprightWidth,
            height.toFloat() / decodedUprightHeight,
        )
        val scaled = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        try {
            val canvas = android.graphics.Canvas(scaled)
            // Move the oriented image back into the canvas: rotations and
            // flips land it in negative coordinates.
            val box = android.graphics.RectF(0f, 0f, decoded.width.toFloat(), decoded.height.toFloat())
            matrix.mapRect(box)
            matrix.postTranslate(-box.left, -box.top)
            canvas.drawBitmap(decoded, matrix, Paint(Paint.FILTER_BITMAP_FLAG))
        } finally {
            decoded.recycle()
        }
        return output(scaled, png)
    }

    /** The answer for Flutter: PNG bytes, or raw premultiplied RGBA. */
    private fun output(bitmap: Bitmap, png: Boolean): Map<String, Any> {
        try {
            if (png) {
                val out = java.io.ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                return mapOf("png" to out.toByteArray())
            }
            val buffer = ByteBuffer.allocate(bitmap.byteCount)
            bitmap.copyPixelsToBuffer(buffer)
            return mapOf("width" to bitmap.width, "height" to bitmap.height, "pixels" to buffer.array())
        } finally {
            bitmap.recycle()
        }
    }

    private fun orientationOf(bytes: ByteArray): Int = try {
        ExifInterface(ByteArrayInputStream(bytes))
            .getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
    } catch (_: Exception) {
        ExifInterface.ORIENTATION_NORMAL
    }

    /** The EXIF orientations, as the transform that stands the image upright. */
    private fun orient(matrix: Matrix, orientation: Int) {
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> { matrix.postRotate(90f); matrix.postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> { matrix.postRotate(270f); matrix.postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
        }
    }

    /** GIF, or a WebP carrying an animation chunk. */
    private fun isAnimated(bytes: ByteArray): Boolean {
        if (bytes.size >= 4 && bytes[0] == 'G'.code.toByte() && bytes[1] == 'I'.code.toByte() &&
            bytes[2] == 'F'.code.toByte()
        ) {
            return true
        }
        if (bytes.size >= 21 && String(bytes, 0, 4, Charsets.US_ASCII) == "RIFF" &&
            String(bytes, 8, 4, Charsets.US_ASCII) == "WEBP" &&
            String(bytes, 12, 4, Charsets.US_ASCII) == "VP8X"
        ) {
            return bytes[20].toInt() and 0x02 != 0
        }
        return false
    }
}

/**
 * Which backend Impeller picked on this build of this device. The engine
 * chooses Vulkan or OpenGL ES deep inside its own driver checks, so the
 * answer comes from the line it logs at startup, read back from this
 * process's own logcat after the first frame and kept for the next start.
 */
object ImpellerBackend {
    private const val TAG = "ImpellerBackend"
    private const val PREFS = "ks_render"
    private const val BACKEND = "impeller_backend"
    private const val STAMP = "impeller_backend_stamp"

    @Volatile private var thisProcess: String? = null

    /**
     * Whether Impeller may downscale images on the GPU through OpenGL ES.
     * True until a start on this build has shown otherwise.
     */
    fun gpuResizeRisky(context: Context): Boolean {
        if (!RendererGuard.impellerOn) return false
        val backend = thisProcess ?: context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .takeIf { it.getString(STAMP, null) == stamp(context) }
            ?.getString(BACKEND, null)
        return backend != "vulkan"
    }

    /** Reads the engine's backend line once the first frame is up. */
    fun noteFirstFrame(context: Context) {
        if (!RendererGuard.impellerOn || thisProcess != null) return
        val app = context.applicationContext
        Thread {
            val backend = read() ?: return@Thread
            thisProcess = backend
            app.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(BACKEND, backend)
                .putString(STAMP, stamp(app))
                .apply()
            Log.i(TAG, "Impeller backend: $backend")
        }.apply { name = "ks-impellerBackend"; isDaemon = true }.start()
    }

    private fun read(): String? = try {
        val process = ProcessBuilder(
            "logcat", "-d", "-s", "flutter:I", "--pid=${Process.myPid()}",
        ).redirectErrorStream(true).start()
        // A driver that fails Impeller's Vulkan checks logs the Vulkan line
        // and then the OpenGL ES one it falls back to, so the last one counts.
        val line = process.inputStream.bufferedReader().useLines { lines ->
            lines.lastOrNull { it.contains("Using the Impeller rendering backend") }
        }
        process.destroy()
        when {
            line == null -> null
            line.contains("(Vulkan") -> "vulkan"
            line.contains("(OpenGLES") -> "opengles"
            else -> null
        }
    } catch (e: Exception) {
        Log.w(TAG, "could not read the backend line: ${e.javaClass.simpleName}")
        null
    }

    // The engine can pick differently after any install of the app or a
    // system update, so the first start after either asks again.
    private fun stamp(context: Context): String {
        val installed = try {
            context.packageManager.getPackageInfo(context.packageName, 0).lastUpdateTime
        } catch (_: Exception) {
            0L
        }
        return "$installed|${Build.FINGERPRINT}"
    }
}
