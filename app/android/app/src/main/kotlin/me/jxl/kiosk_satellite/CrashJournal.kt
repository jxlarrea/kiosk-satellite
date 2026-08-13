package me.jxl.kiosk_satellite

import android.content.Context
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Persists fatal crashes so they survive the restart that follows them.
 *
 * Every crash report against this app has started with the same dance:
 * logcat rotates within minutes on a busy device, the reporter copies the
 * log after the app has come back, and the FATAL EXCEPTION block is gone
 * (issue #21, twice). The journal ends that: the uncaught-exception handler
 * writes the full stack to a file before the process dies, and the next
 * start reads it back into the app's own log, where every reporting surface
 * (the Logs screen, the remote admin, /api/logs) already looks.
 *
 * The handler delegates to whatever handler was installed before it, so
 * Android's own crash flow — and the sticky-service restart that
 * [CrashSelfHeal] rides — is untouched.
 */
object CrashJournal {
    private const val FILE = "last_crash.txt"

    /** Keep the journal from growing without bound: the newest crashes
     *  matter, and one trace is a few KB. */
    private const val MAX_BYTES = 64 * 1024

    fun install(context: Context) {
        val app = context.applicationContext
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                record(app, thread, throwable)
            } catch (_: Throwable) {
                // A failing journal must never mask the crash itself.
            }
            previous?.uncaughtException(thread, throwable)
        }
    }

    private fun record(context: Context, thread: Thread, throwable: Throwable) {
        val file = File(context.filesDir, FILE)
        val stamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
            .format(Date())
        val version = try {
            val info = context.packageManager
                .getPackageInfo(context.packageName, 0)
            "${info.versionName}"
        } catch (_: Exception) {
            "unknown"
        }
        val entry = buildString {
            append("=== crash at $stamp (app $version, thread ${thread.name}) ===\n")
            append(android.util.Log.getStackTraceString(throwable))
            append('\n')
        }
        val existing = if (file.exists()) file.readText() else ""
        var combined = existing + entry
        if (combined.length > MAX_BYTES) {
            combined = combined.substring(combined.length - MAX_BYTES)
        }
        file.writeText(combined)
    }

    /** A deliberate abnormal end (the frame watchdog's process restart):
     *  no exception fires, so without this entry the death is invisible
     *  after the restart — the very gap the journal exists to close. */
    fun note(context: Context, reason: String) {
        try {
            val thread = Thread.currentThread()
            record(
                context.applicationContext,
                thread,
                RuntimeException("process restarted deliberately: $reason"),
            )
        } catch (_: Throwable) {
        }
    }

    /** The journal's contents, empty when no crash has ever been recorded. */
    fun read(context: Context): String = try {
        val file = File(context.filesDir, FILE)
        if (file.exists()) file.readText() else ""
    } catch (_: Exception) {
        ""
    }

    /** Forget recorded crashes (the Logs screen's clear action). */
    fun clear(context: Context) {
        try {
            File(context.filesDir, FILE).delete()
        } catch (_: Exception) {
        }
    }
}
