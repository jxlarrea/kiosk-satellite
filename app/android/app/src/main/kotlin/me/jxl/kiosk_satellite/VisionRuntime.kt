package me.jxl.kiosk_satellite

import android.os.Build
import android.util.Log

/**
 * Whether the on-device vision runtimes can load on this device: LiteRT
 * behind the screensaver's face detection ([FaceDetector]) and MediaPipe
 * Tasks behind the Show fingers gesture ([HandTracker]).
 *
 * Two facts decide it, both consequences of issue #331. Some releases of
 * each runtime import `strtod_l`, a libc call bionic only grew at API 26,
 * and never link on Android 7 (API 24 and 25, the app's floor): that was
 * the crash in the issue, with LiteRT 1.4.0 and tasks-vision 0.10.29. The
 * app pins releases without the import (build.gradle.kts has the list and
 * the readelf check), so on Android 7 both features run; the load probe
 * below is the guard for the next bad bump. The MediaPipe release that
 * pin lands on ships no x86 or x86_64 library at all (those only appear
 * from 0.10.28, the strtod_l releases), so on x86 devices (ChromeOS,
 * FydeOS and BlissOS containers) the hand landmarker has nothing to load
 * and Show fingers is not available; LiteRT ships every ABI.
 *
 * Where a flag is false the Dart side keeps the leg off and both settings
 * surfaces render the rows disabled with the hint. On Android 8 and
 * newer arm devices nothing is loaded to answer; on Android 7 each
 * library is loaded once, the exact operation that would fail, and the
 * answer is cached with the linker's reason in the log.
 */
object VisionRuntime {
    private const val TAG = "VisionRuntime"

    /** The first API level whose bionic exports strtod_l. */
    private const val SAFE_SDK = 26

    private const val HINT_VERSION = "Not available on this Android version."
    private const val HINT_X86 = "Not available on x86 devices."

    /** LiteRT's JNI library, the one [FaceDetector]'s Interpreter loads. */
    private const val LITERT = "tensorflowlite_jni"

    /** MediaPipe Tasks' JNI library, the one [HandTracker]'s landmarker loads. */
    private const val MEDIAPIPE = "mediapipe_tasks_vision_jni"

    @Volatile private var cached: Map<String, Any?>? = null

    /** What the Dart side reads: one flag per runtime, and the reason to
     *  show when a flag is false. */
    @Synchronized
    fun describe(): Map<String, Any?> {
        cached?.let { return it }
        val x86 = Build.SUPPORTED_ABIS.firstOrNull()?.startsWith("x86") == true
        val legacy = Build.VERSION.SDK_INT < SAFE_SDK
        val faces = !legacy || loads(LITERT)
        val hands = !x86 && (!legacy || loads(MEDIAPIPE))
        val hint = when {
            faces && hands -> null
            !hands && x86 -> HINT_X86
            else -> HINT_VERSION
        }
        return mapOf("faces" to faces, "hands" to hands, "hint" to hint)
            .also { cached = it }
    }

    private fun loads(library: String): Boolean = try {
        System.loadLibrary(library)
        true
    } catch (e: Throwable) {
        Log.e(TAG, "$library does not load on this device: $e")
        false
    }
}
