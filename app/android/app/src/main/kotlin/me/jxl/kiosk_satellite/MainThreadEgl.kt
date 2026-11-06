package me.jxl.kiosk_satellite

import android.opengl.EGL14
import android.util.Log
import io.flutter.embedding.engine.FlutterJNI
import java.io.File

/**
 * Releases the EGL context that Impeller's OpenGLES backend leaves bound to
 * the main thread when its surface is torn down there, first seen when an
 * Activity is destroyed under the cached engine (issue #465), then without
 * one (issue #830).
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

    /** Drops whatever context is current on the calling thread. True when
     *  one was current. */
    fun release(reason: String): Boolean {
        if (EGL14.eglGetCurrentContext() == EGL14.EGL_NO_CONTEXT) return false
        val display = EGL14.eglGetCurrentDisplay()
        val ok = EGL14.eglMakeCurrent(
            display,
            EGL14.EGL_NO_SURFACE,
            EGL14.EGL_NO_SURFACE,
            EGL14.EGL_NO_CONTEXT,
        )
        Log.i(TAG, "released the EGL context left on the main thread ($reason): $ok")
        return true
    }

    /** Contexts released after a surface teardown, for the frame
     *  watchdog's log. */
    @Volatile
    var teardownReleases = 0
        private set

    /**
     * Releases the context after every surface teardown, not only the
     * Activity's destroy (issue #830 hit the wedge with no Activity
     * destroyed).
     *
     * This has to happen before anything else on the main thread. The
     * embedding can replace a surface in one call, teardown and creation
     * back to back, and the new surface's make-current on the raster thread
     * then fails against the context still held here. Impeller carries on
     * after that failure: it creates its GL objects with no context, keeps
     * the name 0 it gets for a buffer and never creates that buffer again.
     * The next draw that uses it reads an offset as a pointer and crashes
     * in the driver (issue #921).
     *
     * Nothing can be using the context on the main thread by then. A
     * merged teardown unmerges the threads on its way out, and they only
     * merge again after the raster thread gets a frame past make-current,
     * which a context held here prevents. So a context still current here
     * is the stale one, and a teardown on the raster thread leaves nothing
     * to release.
     */
    internal fun afterSurfaceTeardown() {
        if (release("after a surface teardown")) teardownReleases++
    }

    /** Whether a context is current on the calling thread. */
    fun held(): Boolean =
        EGL14.eglGetCurrentContext() != EGL14.EGL_NO_CONTEXT

    private var rasterTid: String? = null

    /**
     * How many times the engine's raster thread has been scheduled since it
     * started, or -1 when it cannot be found.
     *
     * The wedge has more than one way in (issue #830 hit it with no
     * Activity destroyed), so the frame watchdog looks for the state
     * itself: a context current on the main thread while the raster thread
     * keeps waking up to draw. With a WebView on screen the raster thread
     * is merged into the main thread, its own thread sits idle and the
     * main thread legitimately holds the context between frames. Unmerged,
     * the merge callback clears the main thread first, so a context still
     * there while the raster thread works is the one locking it out.
     */
    fun rasterSwitches(): Long {
        val tid = rasterTid?.takeIf { File("/proc/self/task/$it").exists() }
            ?: findRasterThread()?.also { rasterTid = it }
            ?: return -1
        return try {
            File("/proc/self/task/$tid/status").readLines()
                .filter { it.contains("ctxt_switches:") }
                .sumOf { it.substringAfter(':').trim().toLongOrNull() ?: 0L }
        } catch (_: Exception) {
            -1
        }
    }

    /** The engine names its raster thread `<engine number>.raster`. */
    private fun findRasterThread(): String? = try {
        File("/proc/self/task").listFiles()?.firstOrNull { task ->
            try {
                File(task, "comm").readText().trim().endsWith(".raster")
            } catch (_: Exception) {
                false
            }
        }?.name
    } catch (_: Exception) {
        null
    }
}

/**
 * The one place that runs between the engine dropping a surface and the
 * embedding creating the next one. Every teardown goes through here, and a
 * listener or a posted task would run too late (see
 * [MainThreadEgl.afterSurfaceTeardown]).
 */
class SurfaceTeardownJni : FlutterJNI() {
    override fun onSurfaceDestroyed() {
        super.onSurfaceDestroyed()
        MainThreadEgl.afterSurfaceTeardown()
    }
}
