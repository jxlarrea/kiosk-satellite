package me.jxl.kiosk_satellite

import java.io.File

/** Accessed only by the diagnostics worker. No image data or settings maps. */
internal class CameraDiagnosticJournal(private val file: File) {
    private val recent = ArrayDeque<Map<String, Any>>()
    private var nextId = 0L
    private val run = java.util.UUID.randomUUID().toString().take(8)
    private val timestamp = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
        timeZone = java.util.TimeZone.getTimeZone("UTC")
    }
    private var environment = ""
    var persistenceError: Exception? = null
        private set
    val previousFailure: String = try { file.readText().takeLast(MAX_HISTORY) } catch (_: Exception) { "" }

    fun record(session: String, event: String, details: String, failure: Boolean, cause: String?): Map<String, Any> {
        val message = redact("$session $event: $details" + if (cause == null) "" else "\n$cause")
            .take(MAX_ENTRY)
        val entry = mapOf<String, Any>(
            "id" to "$run-${++nextId}", "time" to timestamp.format(java.util.Date()),
            "level" to if (failure) "warn" else "info", "message" to message,
        )
        recent.addLast(entry)
        if (event == "environment") environment = message
        while (recent.size > 48) recent.removeFirst()
        if (failure) {
            val history = environment + "\n" + recent.joinToString("\n") {
                "${it["time"]} ${it["message"]}"
            }.takeLast(MAX_HISTORY - environment.length - 1)
            try {
                val temporary = File(file.parentFile, file.name + ".tmp")
                temporary.writeText(history)
                check(temporary.renameTo(file)) { "Could not save camera failure" }
                persistenceError = null
            } catch (e: Exception) {
                // Storage failure must not hide the live diagnostic.
                persistenceError = e
            }
        }
        return entry
    }

    fun entries(): List<Map<String, Any>> = recent.toList()

    companion object {
        private const val MAX_ENTRY = 8 * 1024
        private const val MAX_HISTORY = 32 * 1024
        private fun redact(text: String): String = text.replace(
            Regex("(?i)(rtsps?://)[^\\s/]*@"), "$1[redacted]@",
        )
    }
}
