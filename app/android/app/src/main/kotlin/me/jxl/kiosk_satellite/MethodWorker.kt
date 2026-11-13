package me.jxl.kiosk_satellite

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/** Serializes device reads and answers excess callers without retaining their requests. */
internal class MethodWorker(name: String) {
    private val worker = BoundedWorker(name, capacity = 1)
    private val main = Handler(Looper.getMainLooper())

    fun read(result: MethodChannel.Result, operation: () -> Any?) {
        if (!worker.execute {
            val value = try {
                operation()
            } catch (e: Exception) {
                main.post { result.error("read_failed", e.message, null) }
                return@execute
            }
            main.post { result.success(value) }
        }) {
            result.error("busy", "Device read worker is unavailable. Try again later.", null)
        }
    }

    fun shutdown() = worker.shutdown()
}

/**
 * One device read shared by every caller waiting on it, for reads the Dart
 * side asks for in bursts (each battery broadcast is a cue to read again).
 * A caller that arrives while a read runs is answered by the read that
 * starts after it, never by the one in flight, so no answer is older than
 * its request. However many callers pile up behind a stalled read, one read
 * runs and one waits, and nobody is turned away as busy.
 *
 * A read that throws, or one the worker cannot take, answers null: the
 * platform would not say. Call [read] on the main thread only.
 */
internal class SharedRead(name: String, private val operation: () -> Any?) {
    private val worker = BoundedWorker(name, capacity = 1)
    private val main = Handler(Looper.getMainLooper())
    private val waiting = ArrayList<MethodChannel.Result>()
    private var running = false

    fun read(result: MethodChannel.Result) {
        waiting.add(result)
        if (!running) start()
    }

    private fun start() {
        val batch = ArrayList(waiting)
        waiting.clear()
        running = true
        val accepted = worker.execute {
            val value = try {
                operation()
            } catch (_: Exception) {
                null
            }
            main.post { finish(batch, value) }
        }
        if (!accepted) finish(batch, null)
    }

    private fun finish(batch: List<MethodChannel.Result>, value: Any?) {
        running = false
        for (result in batch) result.success(value)
        if (waiting.isNotEmpty()) start()
    }

    fun shutdown() = worker.shutdown()
}
