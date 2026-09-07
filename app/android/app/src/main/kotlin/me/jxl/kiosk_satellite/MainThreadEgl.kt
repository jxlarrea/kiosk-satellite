package me.jxl.kiosk_satellite

import android.opengl.EGL14
import android.util.Log

/**
 * Releases the EGL context that Impeller's OpenGLES backend leaves bound to
 * the main thread when an Activity is destroyed under the cached engine
 * (issue #465).
 *
 * While a hybrid-composition WebView is on screen Flutter rasterizes on the
 * main thread: the raster thread is merged into it. Tearing the surface down
 * in that state runs on the main thread too. The engine makes its context
 * current here, destroys the surface without clearing the context and only
 * then unmerges the threads, so the clear that follows runs on the raster
 * thread and misses. From then on every make-current on the raster thread
 * fails with EGL_BAD_ACCESS (the context is current to another thread) and
 * the Flutter UI never draws again while Dart and the WebView carry on: no
 * screensaver, no drawer, no settings. Skia's surface clears its context on
 * teardown, which is why the Legacy renderer never showed it, and Vulkan has
 * no per-thread binding at all. The Meta Portal rule in [RendererGuard]
 * was written against the same failure.
 *
 * A context is bound per thread, so the main thread can let go of it by
 * itself. Nothing else in the app renders GL on the main thread: HWUI and
 * the WebView draw on threads of their own, so a context found here is the
 * engine's.
 */
object MainThreadEgl {
    private const val TAG = "MainThreadEgl"

    /** Drops whatever context is current on the calling thread. */
    fun release(reason: String) {
        if (EGL14.eglGetCurrentContext() == EGL14.EGL_NO_CONTEXT) return
        val display = EGL14.eglGetCurrentDisplay()
        val ok = EGL14.eglMakeCurrent(
            display,
            EGL14.EGL_NO_SURFACE,
            EGL14.EGL_NO_SURFACE,
            EGL14.EGL_NO_CONTEXT,
        )
        Log.i(TAG, "released the EGL context left on the main thread ($reason): $ok")
    }
}
