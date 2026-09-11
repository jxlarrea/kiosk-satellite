package me.jxl.kiosk_satellite.plugins

import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.util.concurrent.atomic.AtomicBoolean

/** Plain argument vectors, bounded output and a deadline even when a child holds a pipe open. */
internal object PluginShizukuCommand {
    const val OUTPUT_LIMIT = 32768
    fun validate(command: Array<String>, timeoutMs: Int) {
        require(command.size in 1..32 && command[0].startsWith("/")) { "Use an absolute executable path and at most 32 arguments" }
        require(command.all { it.length <= 4096 && '\u0000' !in it } && command.sumOf { it.length } <= 16384) { "Command arguments are too long or contain a null character" }
        require(timeoutMs in 100..30000) { "Command timeout must be between 100 and 30000 ms" }
    }

    fun run(command: Array<String>, timeoutMs: Int, cancelled: AtomicBoolean): Map<String, Any> {
        validate(command, timeoutMs)
        check(!cancelled.get()) { "Shizuku session has ended" }
        val process = ProcessBuilder(command.toList()).start()
        process.outputStream.close()
        val stdout = Capture(process.inputStream)
        val stderr = Capture(process.errorStream)
        val deadline = System.nanoTime() + timeoutMs * 1_000_000L
        var exitCode: Int? = null
        try {
            while (!cancelled.get() && System.nanoTime() < deadline) {
                try { exitCode = process.exitValue(); break } catch (_: IllegalThreadStateException) { Thread.sleep(10) }
            }
            val timedOut = exitCode == null && !cancelled.get()
            if (exitCode == null) process.destroy()
            stdout.thread.join(200); stderr.thread.join(200)
            check(!cancelled.get()) { "Shizuku session has ended" }
            return mapOf("exitCode" to (exitCode ?: -1), "stdout" to stdout.text(), "stderr" to stderr.text(),
                "timedOut" to timedOut, "truncated" to (stdout.truncated || stderr.truncated))
        } finally {
            process.destroy()
            stdout.close(); stderr.close()
        }
    }

    private class Capture(private val input: InputStream) {
        private val bytes = ByteArrayOutputStream()
        @Volatile var truncated = false
        val thread = Thread({
            try {
                val buffer = ByteArray(4096)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    synchronized(bytes) {
                        val keep = minOf(count, OUTPUT_LIMIT - bytes.size())
                        if (keep > 0) bytes.write(buffer, 0, keep)
                        if (keep < count) truncated = true
                    }
                }
            } catch (_: Exception) { /* Cancellation closes the pipe. */ }
        }, "plugin-shizuku-output").apply { isDaemon = true; start() }
        fun text(): String = synchronized(bytes) { bytes.toString("UTF-8") }
        fun close() { try { input.close() } catch (_: Exception) {} }
    }
}
