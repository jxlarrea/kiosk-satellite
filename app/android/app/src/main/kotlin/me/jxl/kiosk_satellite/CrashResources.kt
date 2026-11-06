package me.jxl.kiosk_satellite

import android.os.Debug
import android.os.SystemClock
import java.io.File

/** Small process measurements without allocating stack traces for every thread. */
internal object CrashResources {
    private val startedAt = SystemClock.elapsedRealtime()
    private val statusFields = setOf("Threads", "VmPeak", "VmSize", "VmRSS", "VmData", "VmStk", "VmSwap")
    private val families = listOf(
        "fleet-mdns", "btproxy-mdns", "btproxy-r-", "btproxy-w-", "btproxy-tick", "btproxy-accept",
        "ks-backgroundRead", "ks-cpu", "ks-sound", "ks-intercom",
        "camera-rtsp", "camera-video", "screen-capture", "vsww", "Sendspin", "CameraX",
        "Chrome", "Cr", "RenderThread", "Dart", "flutter", "io.flutter", "tflite", "TfLite",
        "NNAPI", "Binder:", "HwBinder:", "pool-", "Thread-", "HeapTaskDaemon",
        "Finalizer", "ReferenceQueue", "Jit thread", "Signal Catcher",
    )

    /** Enough for the 1,700 thread leaks seen in the field. */
    private const val THREAD_LIMIT = 2048

    /** A crash handler should not sit reading files for long. */
    private const val THREAD_BUDGET_MS = 500L

    /** How many threads must share a name before the name itself is reported. */
    private const val REPEATED_NAME_MIN = 8
    private const val REPEATED_NAME_ROWS = 12
    private val ADDRESS_MARKS = setOf('.', ':', '/', '@')

    fun initialize() { /* Set the uptime origin at journal installation. */ }

    /**
     * The leading letters of a kernel thread name, or null if it has none
     * worth keeping. It stops at the first digit or space, so what follows
     * `OkHttp ` never leaves the device. Letters that run into a dot, colon,
     * slash or at sign look like an address (`kitchen.local`, `ws://`), so
     * nothing of those names is kept.
     */
    internal fun repeatedNameStem(name: String): String? {
        val letters = name.takeWhile { it in 'a'..'z' || it in 'A'..'Z' || it == '_' || it == '-' }
        if (name.getOrNull(letters.length) in ADDRESS_MARKS) return null
        return letters.trimEnd('-', '_').takeIf { it.length >= 3 }
    }

    fun snapshot(
        proc: File = File("/proc/self"),
        limit: Int = THREAD_LIMIT,
    ): String = buildString {
        append("Resource snapshot (best effort):\n")
        append("journal_uptime_ms=${SystemClock.elapsedRealtime() - startedAt}\n")
        val runtime = Runtime.getRuntime()
        append("java_heap_bytes: used=${runtime.totalMemory() - runtime.freeMemory()}")
        append(" committed=${runtime.totalMemory()} max=${runtime.maxMemory()}\n")
        append("native_heap_bytes: allocated=${Debug.getNativeHeapAllocatedSize()}\n")
        try {
            File(proc, "status").bufferedReader().useLines { lines ->
                lines.take(100).forEach { line ->
                    if (line.substringBefore(':') in statusFields) append(line).append('\n')
                }
            }
        } catch (_: Exception) {
            append("process_status=unavailable\n")
        }
        // Kernel names are short but can contain user data: a WebSocket
        // thread is named after its URL. Emit known families. An unknown
        // name goes out only as its leading letters and only when many
        // threads share them, which is what a leak looks like and what a
        // name supplied by a plugin or a server does not.
        val tasks = File(proc, "task").listFiles()
        val counts = sortedMapOf<String, Int>()
        val unknown = mutableMapOf<String, Int>()
        val readUntil = SystemClock.elapsedRealtime() + THREAD_BUDGET_MS
        var sampled = 0
        // Newest first: a leak's threads are the ones to reach in time.
        val newest = tasks.orEmpty().sortedByDescending { it.name.toIntOrNull() ?: 0 }
        for (task in newest.take(limit)) {
            if (SystemClock.elapsedRealtime() > readUntil) break
            val name = try {
                File(task, "comm").bufferedReader().use { it.readLine()?.take(16) }
            } catch (_: Exception) { null } ?: continue
            val family = families.firstOrNull { name.startsWith(it.take(15)) }
            if (family != null) {
                counts[family] = (counts[family] ?: 0) + 1
            } else {
                val stem = repeatedNameStem(name) ?: ""
                unknown[stem] = (unknown[stem] ?: 0) + 1
            }
            sampled++
        }
        val repeated = unknown
            .filter { (stem, count) -> stem.isNotEmpty() && count >= REPEATED_NAME_MIN }
            .entries.sortedByDescending { it.value }
            .take(REPEATED_NAME_ROWS)
        val other = unknown.values.sum() - repeated.sumOf { it.value }
        if (other > 0) counts["other"] = other
        append("native_thread_sample: read=$sampled listed=${tasks?.size ?: -1} limit=$limit\n")
        counts.forEach { (family, count) -> append("  $family: $count\n") }
        repeated.forEach { (stem, count) -> append("  ~$stem: $count\n") }
    }
}
