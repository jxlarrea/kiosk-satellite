package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicLong

/** Low-volume lifecycle records. Disk access never runs on a camera or UI thread. */
internal object CameraDiagnostics {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val sequence = AtomicLong()
    private val run = java.lang.Long.toString(System.currentTimeMillis(), 36)
    private var journal: CameraDiagnosticJournal? = null
    private var channel: MethodChannel? = null
    private var subscribed = false
    private var previousDelivered = false

    fun session(kind: String): String = "$kind-$run-${sequence.incrementAndGet()}"

    fun attach(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        val bridge = MethodChannel(messenger, "kiosk_satellite/camera/diagnostics")
        channel = bridge
        worker.execute {
            journal = CameraDiagnosticJournal(File(app.filesDir, "last_camera_failure.txt"))
            val version = try { app.packageManager.getPackageInfo(app.packageName, 0).versionName } catch (_: Exception) { "unknown" }
            record("device", "environment", "${Build.MANUFACTURER} ${Build.MODEL}, Android ${Build.VERSION.RELEASE} " +
                "(SDK ${Build.VERSION.SDK_INT}), app $version")
        }
        bridge.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    subscribed = true
                    worker.execute {
                        val entries = journal?.entries().orEmpty().toMutableList()
                        val previous = journal?.previousFailure.orEmpty()
                        if (!previousDelivered && previous.isNotEmpty()) {
                            previousDelivered = true
                            entries.add(0, mapOf("id" to "$run-previous", "level" to "warn",
                                "message" to "Previous camera failure and its recent context (historical, not current status):\n$previous"))
                        }
                        main.post { result.success(entries) }
                    }
                }
                "stop" -> { subscribed = false; result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    fun record(session: String, event: String, details: String, failure: Boolean = false, cause: Throwable? = null) {
        worker.execute {
            try {
                val causes = generateSequence(cause) { it.cause }.take(12)
                    .joinToString("\n") { "${it.javaClass.simpleName}: ${it.message}" }
                val trace = cause?.let { "$causes\n${it.stackTraceToString()}" }
                val recorded = journal?.record(session, event, details, failure, trace) ?: return@execute
                val persistenceError = if (failure) journal?.persistenceError else null
                val entry = if (persistenceError == null) recorded else recorded +
                    ("message" to "${recorded["message"]}\nCould not save this failure across restarts: ${persistenceError.message}")
                if (failure) Log.w("CameraDiagnostics", entry["message"] as String)
                main.post { if (subscribed) channel?.invokeMethod("record", entry) }
            } catch (e: Exception) {
                Log.w("CameraDiagnostics", "Could not record camera diagnostic", e)
            }
        }
    }

    fun detach() {
        subscribed = false
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
