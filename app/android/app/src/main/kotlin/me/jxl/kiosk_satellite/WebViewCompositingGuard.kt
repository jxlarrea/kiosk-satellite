package me.jxl.kiosk_satellite

import android.content.Context
import android.graphics.PixelFormat
import android.media.ImageReader
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLSurface
import android.opengl.GLES20
import android.os.Build
import android.util.Log

/**
 * Decides, before the dashboard exists, whether this device may draw the
 * WebView into the Android view hierarchy (issue #302).
 *
 * With hybrid composition Flutter stops drawing to the window and takes its
 * own frames back through an [ImageReader] instead. Below Android 10 that
 * reader is created as plain RGBA_8888, with no usage flags to tell the
 * driver what the producer will write, and a driver that answers in BGRA
 * (the Mali T628 in the 2014 Galaxy Note 10.1) makes every acquire throw
 * inside the engine, which aborts the process. The dashboard is the first
 * thing the app draws, so the result is a launch loop with no way in.
 *
 * The mismatch is a property of the GPU driver, not of anything the app
 * does, so it can be asked once instead of crashed into: this reproduces
 * the engine's own setup - the same EGL configuration, a window surface on
 * an identical reader - and acquires one frame. A driver that throws here
 * is a driver that would abort the app, so the `render.legacy_webview`
 * setting is turned on for it and the dashboard is drawn through a texture
 * instead. Both settings UIs then tell the truth about what the device is
 * doing, and a person can flip it themselves either way.
 *
 * The probe stamp is committed *before* the probe runs: EGL on a driver
 * this old can take the process down by itself, and one such crash at the
 * first launch after an update is survivable (the crash self-heal brings
 * the app back) where a loop of them would not be.
 */
object WebViewCompositingGuard {
    private const val TAG = "WebViewCompositing"
    private const val PREFS = "FlutterSharedPreferences"
    private const val LEGACY = "flutter.ks.render.legacy_webview"
    private const val PROBED = "flutter.ks.render.webview_probe"

    /** Bumped when the probe itself changes, to ask the device again. */
    private const val PROBE_VERSION = 1L

    private const val PROBE_SIZE = 64
    private const val ACQUIRE_TRIES = 10
    private const val ACQUIRE_WAIT_MS = 5L

    /** Runs the probe once per device. Call before the engine is created. */
    fun check(context: Context) {
        // Android 10 and up build the same reader with GPU usage flags, which
        // settles the format with the driver up front; only the older path
        // can end up mismatched.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getLong(PROBED, 0L) == PROBE_VERSION) return
        prefs.edit().putLong(PROBED, PROBE_VERSION).commit()
        val mismatched =
            try {
                producerFormatMismatches()
            } catch (e: Throwable) {
                // An unhappy driver is not evidence either way; the app has
                // always run hybrid composition here.
                Log.w(TAG, "overlay format probe failed", e)
                false
            }
        if (mismatched) {
            Log.w(
                TAG,
                "this GPU writes overlay frames in a format the reader " +
                    "rejects; drawing the WebView through a texture",
            )
            prefs.edit().putBoolean(LEGACY, true).commit()
        }
    }

    /**
     * True when a frame drawn the way the engine draws it cannot be read
     * back the way the engine reads it.
     */
    private fun producerFormatMismatches(): Boolean {
        val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        if (display == EGL14.EGL_NO_DISPLAY) return false
        val version = IntArray(2)
        if (!EGL14.eglInitialize(display, version, 0, version, 1)) return false
        // No eglTerminate: the display is process-wide and the engine will
        // want it initialized a moment from now.
        val config = chooseConfig(display) ?: return false
        val reader =
            ImageReader.newInstance(
                PROBE_SIZE,
                PROBE_SIZE,
                PixelFormat.RGBA_8888,
                3,
            )
        var surface = EGL14.EGL_NO_SURFACE
        var eglContext = EGL14.EGL_NO_CONTEXT
        try {
            surface =
                EGL14.eglCreateWindowSurface(
                    display,
                    config,
                    reader.surface,
                    intArrayOf(EGL14.EGL_NONE),
                    0,
                )
            if (surface == EGL14.EGL_NO_SURFACE) return false
            eglContext =
                EGL14.eglCreateContext(
                    display,
                    config,
                    EGL14.EGL_NO_CONTEXT,
                    intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE),
                    0,
                )
            if (eglContext == EGL14.EGL_NO_CONTEXT) return false
            if (!EGL14.eglMakeCurrent(display, surface, surface, eglContext)) return false
            GLES20.glClearColor(0f, 0f, 0f, 1f)
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
            if (!EGL14.eglSwapBuffers(display, surface)) return false
            return acquireThrows(reader)
        } finally {
            release(display, surface, eglContext)
            reader.close()
        }
    }

    /** The engine's own choice of EGL configuration, attribute for attribute. */
    private fun chooseConfig(display: EGLDisplay): EGLConfig? {
        val attributes =
            intArrayOf(
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT,
                EGL14.EGL_RED_SIZE, 8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_DEPTH_SIZE, 0,
                EGL14.EGL_STENCIL_SIZE, 0,
                EGL14.EGL_NONE,
            )
        val configs = arrayOfNulls<EGLConfig>(1)
        val count = IntArray(1)
        val ok =
            EGL14.eglChooseConfig(display, attributes, 0, configs, 0, 1, count, 0) &&
                count[0] > 0
        return if (ok) configs[0] else null
    }

    /**
     * What [io.flutter.embedding.android.FlutterImageView] does on every
     * frame: a mismatched format surfaces as an exception out of the reader,
     * and the first buffer may need a moment to reach the consumer.
     */
    private fun acquireThrows(reader: ImageReader): Boolean {
        repeat(ACQUIRE_TRIES) {
            try {
                val image = reader.acquireLatestImage()
                if (image != null) {
                    image.close()
                    return false
                }
            } catch (e: UnsupportedOperationException) {
                Log.w(TAG, "overlay frame rejected by the reader", e)
                return true
            }
            Thread.sleep(ACQUIRE_WAIT_MS)
        }
        // Nothing arrived and nothing complained: leave the device alone.
        return false
    }

    private fun release(display: EGLDisplay, surface: EGLSurface, context: EGLContext) {
        EGL14.eglMakeCurrent(
            display,
            EGL14.EGL_NO_SURFACE,
            EGL14.EGL_NO_SURFACE,
            EGL14.EGL_NO_CONTEXT,
        )
        if (context != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(display, context)
        if (surface != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(display, surface)
    }
}
