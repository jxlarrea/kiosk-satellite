package me.jxl.kiosk_satellite

import android.os.Build
import android.util.Log

/**
 * Whether the on-device vision runtimes can load on this device: LiteRT
 * behind the screensaver's face detection ([FaceDetector]) and MediaPipe
 * Tasks behind the Show fingers gesture ([HandTracker]).
 *
 * Both ship native libraries, and some releases of each import
 * `strtod_l`, a libc call bionic only grew at API 26, so on Android 7
 * (API 24 and 25, the app's floor) those releases never link: `dlopen`
 * fails with "cannot locate symbol strtod_l". Issue #331 was that
 * failure surfacing as a process crash the first time the face detector
 * loaded on a Galaxy Tab A running 7.1.1, with LiteRT 1.4.0 and
 * tasks-vision 0.10.29. The app now pins releases without the import
 * (build.gradle.kts has the list and the readelf check), so Android 7
 * runs both features; this probe is the guard for the next bad bump.
 *
 * On Android 8 and newer the answer is yes without loading anything. On
 * Android 7 each library is loaded once, the exact operation that fails,
 * and a failure is cached: the detectors then never try (the Dart side
 * keeps their legs off and both settings surfaces render the rows
 * disabled with [HINT]), and the log carries the linker's reason.
 */
object VisionRuntime {
    private const val TAG = "VisionRuntime"

    /** The first API level whose bionic exports strtod_l. */
    private const val SAFE_SDK = 26

    private const val HINT = "Needs Android 8 or newer."

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
        val faces: Boolean
        val hands: Boolean
        if (Build.VERSION.SDK_INT >= SAFE_SDK) {
            faces = true
            hands = true
        } else {
            faces = loads(LITERT)
            hands = loads(MEDIAPIPE)
        }
        return mapOf(
            "faces" to faces,
            "hands" to hands,
            "hint" to if (faces && hands) null else HINT,
        ).also { cached = it }
    }

    private fun loads(library: String): Boolean = try {
        System.loadLibrary(library)
        true
    } catch (e: Throwable) {
        Log.e(TAG, "$library does not load on this device: $e")
        false
    }
}
