package me.jxl.kiosk_satellite.plugins

/** Bounded, session-owned chart snapshots. Never persisted or included in fleet settings. */
internal class PluginCharts(private val clock: () -> Long = System::nanoTime) {
    private val charts = linkedMapOf<String, Map<String, Any>>()
    private var closed = false
    private var window = clock()
    private var changes = 0

    @Synchronized fun publish(key: String, chart: Map<String, Any>) {
        check(!closed) { "Plugin session has ended" }
        require(key.matches(Regex("[a-z][a-z0-9_]{0,39}"))) { "Invalid chart key" }
        require(charts.containsKey(key) || charts.size < 4) { "At most four charts are supported" }
        require(chart.keys.all { it in setOf("title", "unit", "compact", "timestamps", "series") }) { "Unknown chart field" }
        val title = chart["title"] as? String ?: error("Missing chart title")
        require(!chart.containsKey("unit") || chart["unit"] is String) { "Invalid chart unit" }
        require(!chart.containsKey("compact") || chart["compact"] is Boolean) { "Invalid compact flag" }
        val compact = chart["compact"] == true
        val unit = chart["unit"] as? String ?: ""
        require(title.length in 1..80 && unit.length <= 16) { "Invalid chart label" }
        val timestamps = chart["timestamps"] as? List<*> ?: error("Missing timestamps")
        require(timestamps.size <= 240) { "At most 240 samples are supported" }
        val times = timestamps.map {
            require(it is Number && it.toDouble().isFinite() && it.toDouble() == it.toLong().toDouble() && it.toLong() in 0..253402300799999L) { "Invalid timestamp" }
            it.toLong()
        }
        require(times.zipWithNext().all { (a, b) -> b > a }) { "Timestamps must increase strictly" }
        val input = chart["series"] as? List<*> ?: error("Missing series")
        require(input.size in 1..4) { "A chart needs one to four series" }
        val series = input.map { raw ->
            require(raw is Map<*, *> && raw.keys.all { it in setOf("name", "color", "values") }) { "Invalid series" }
            val name = raw["name"] as? String ?: error("Missing series name")
            require(name.length in 1..80) { "Invalid series name" }
            val color = raw["color"] as? String
            require(!raw.containsKey("color") || (color != null && color.matches(Regex("#[a-fA-F0-9]{6}")))) { "Invalid series color" }
            val values = raw["values"] as? List<*> ?: error("Missing series values")
            require(values.size == times.size) { "Each series must match the timestamps" }
            val copied = values.map {
                require(it == null || (it is Number && it.toDouble().isFinite() && kotlin.math.abs(it.toDouble()) <= 1e12)) { "Values must be finite numbers within +/-1e12 or null" }
                it?.toDouble()
            }
            mutableMapOf<String, Any>("name" to name, "values" to copied).apply {
                if (color != null) put("color", color.uppercase())
            }
        }
        require(series.map { it["name"] }.toSet().size == series.size) { "Series names must be unique" }
        budget()
        charts[key] = mapOf("key" to key, "title" to title, "unit" to unit, "compact" to compact, "timestamps" to times, "series" to series)
    }

    private fun budget() {
        val now = clock()
        if (now - window >= 1_000_000_000L) { window = now; changes = 0 }
        check(changes < 8) { "At most eight chart changes per second are supported" }
        changes++
    }

    @Synchronized fun remove(key: String) {
        check(!closed) { "Plugin session has ended" }
        budget()
        charts.remove(key)
    }

    @Synchronized fun snapshot(): List<Map<String, Any>> = charts.values.toList()
    @Synchronized fun close() { closed = true; charts.clear() }
}
