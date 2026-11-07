package me.jxl.kiosk_satellite

import android.content.Context
import android.util.Log

/**
 * A thread budget for cameras that Android runs through its HAL1
 * compatibility layer (CameraDeviceUserShim, Android 5 to 11).
 *
 * That layer starts two threads for every open, a "LegacyCameraCallback"
 * HandlerThread and a looper thread, and only then checks whether the camera
 * opened. A failed open throws past both and nothing ever stops them, so each
 * failed open leaves two threads behind for the life of the process. A camera
 * that kept failing on Android 7.1 Echo Shows took the app past 1,500 threads
 * in under an hour, where pthread_create failed and the app crashed, and
 * again after every restart. Reproduced on the Android 7.1 emulator with its
 * camera on HAL1: every failed open added one callback thread and one looper
 * thread, and neither ever ended.
 *
 * The callback threads count that leak directly: a HAL3 camera never starts
 * one, and an open HAL1 camera holds one. Once [LEAK_LIMIT] of them exist,
 * the next camera open restarts the app instead, the way the main thread
 * watchdog does, since only a new process lets go of them. The first one
 * seen (at the first frame or before an open) also marks the device, so the
 * next start caps CameraX's own reopen retries ([RETRY_CAP_MS]), which would
 * otherwise spend up to 15 opens on every bind and bring the restart closer.
 */
internal class LegacyCameraShim(
    private val threadNames: () -> List<String>,
    private val marked: () -> Boolean,
    private val mark: () -> Unit,
) {
    fun callbackThreads(): Int = threadNames().count { it == CALLBACK_THREAD }

    /** Marks the device once a callback thread exists. */
    fun markIfShim() {
        if (callbackThreads() > 0 && !marked()) mark()
    }

    /** The callback thread count once the budget is spent, else null. */
    fun spent(): Int? {
        val threads = callbackThreads()
        if (threads > 0 && !marked()) mark()
        return threads.takeIf { it >= LEAK_LIMIT }
    }

    companion object {
        private const val TAG = "LegacyCameraShim"
        private const val PREFS = "camera_legacy_shim"
        private const val KEY = "seen"

        /** The shim's HandlerThread name. */
        const val CALLBACK_THREAD = "LegacyCameraCallback"

        /** Callback threads, so twice as many leaked threads, before the app
         *  restarts: about 900 threads in all with the app's usual 100. The
         *  field crash came at about 1,500, and no device has run out below
         *  about 1,000. */
        const val LEAK_LIMIT = 400

        /** CameraX's reopen window on a marked device: about 3 opens per bind
         *  instead of 15 in 10 seconds, or up to 30 minutes of them while
         *  another app holds the camera. */
        const val RETRY_CAP_MS = 2_000L

        /** The journal's word for this restart. analytics/crash_journal.dart
         *  reports deliberate restarts that name a watchdog. */
        internal fun restartReason(threads: Int) =
            "the camera watchdog found $threads leaked camera threads; each failed " +
                "open of this device's HAL1 camera leaves 2 threads running until the app restarts"

        fun of(context: Context): LegacyCameraShim {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            return LegacyCameraShim(
                ::liveThreadNames,
                { prefs.getBoolean(KEY, false) },
                {
                    Log.i(TAG, "camera runs through the HAL1 compatibility layer; capping CameraX reopen retries from the next start")
                    prefs.edit().putBoolean(KEY, true).apply()
                },
            )
        }

        /** Whether an earlier run saw this device's camera on the shim. */
        fun marked(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY, false)

        /** Before a camera open: restarts the app when the budget is spent.
         *  Only returns when it is not. */
        fun restartIfSpent(context: Context) {
            val threads = of(context).spent() ?: return
            val reason = restartReason(threads)
            Log.w(TAG, "$reason; restarting")
            CrashJournal.note(context, reason)
            // Same as MainThreadWatchdog: bring the kiosk back only if it was
            // on screen, else the sticky service restarts the process behind
            // the app in front.
            val foreground = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getBoolean("flutter.ks.crash.was_foreground", false)
            if (foreground) BackgroundBridge.prepareRelaunch(context)
            me.jxl.kiosk_satellite.plugins.PluginBridge.noteDeliberateExit(context)
            android.os.Process.killProcess(android.os.Process.myPid())
        }

        /** Every live thread's name. Thread.enumerate walks the Java thread
         *  table, so it stays cheap with 1,500 threads, unlike reading each
         *  /proc task. */
        internal fun liveThreadNames(): List<String> {
            var group = Thread.currentThread().threadGroup ?: return emptyList()
            while (true) group = group.parent ?: break
            var threads = arrayOfNulls<Thread>(group.activeCount() + 32)
            var count = group.enumerate(threads, true)
            while (count == threads.size) {
                threads = arrayOfNulls(threads.size * 2)
                count = group.enumerate(threads, true)
            }
            return (0 until count).mapNotNull { threads[it]?.name }
        }
    }
}
