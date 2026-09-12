package me.jxl.kiosk_satellite.plugins

/** Rendering documents belong to one live session. Animation stays in the renderer. */
internal class PluginScreensavers(private val clock: () -> Long = System::nanoTime) {
    private val items = linkedMapOf<String, Map<String, String>>()
    private var closed = false
    private var window = clock()
    private var changes = 0

    private fun budget() {
        check(!closed) { "Plugin session has ended" }
        val now = clock()
        if (now - window >= 1_000_000_000L) { window = now; changes = 0 }
        check(changes < 4) { "At most four screensaver changes per second are supported" }
        changes++
    }

    @Synchronized fun publish(key: String, title: String, html: String) {
        require(key.matches(Regex("[a-z][a-z0-9_]{0,39}"))) { "Invalid screensaver key" }
        require(title.isNotBlank() && title.length <= 80) { "Invalid screensaver title" }
        require(html.isNotBlank() && html.toByteArray(Charsets.UTF_8).size <= 262144) { "Screensaver HTML must be at most 256 KB" }
        require(items.containsKey(key) || items.size < 4) { "At most four screensavers are supported" }
        budget()
        items[key] = mapOf("key" to key, "title" to title, "html" to html)
    }

    @Synchronized fun remove(key: String) { budget(); items.remove(key) }
    @Synchronized fun snapshot(): List<Map<String, String>> = items.values.toList()
    @Synchronized fun close() { closed = true; items.clear() }
}
