package me.jxl.kiosk_satellite.plugins

import java.io.File
import org.json.JSONObject

/**
 * Rendering documents belong to one live session. Animation stays in the renderer. A native renderer is a view
 * factory instead of a document. Each publication of one gets a new generation, so Flutter builds a fresh view.
 */
internal class PluginScreensavers<F : Any>(private val directory: File? = null, private val clock: () -> Long = System::nanoTime) {
    private val items = linkedMapOf<String, Map<String, Any>>()
    private val factories = hashMapOf<String, F>()
    private var closed = false
    private var generation = 0
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
        require(html.isNotBlank() && html.toByteArray(Charsets.UTF_8).size <= 524288) { "Screensaver HTML must be at most 512 KiB" }
        require(items.containsKey(key) || items.size < 4) { "At most four screensavers are supported" }
        budget()
        factories.remove(key)
        items[key] = mapOf("key" to key, "title" to title, "html" to html)
    }

    @Synchronized fun publishAsset(key: String, title: String, entry: String, data: Map<String, Any?>) {
        require(key.matches(Regex("[a-z][a-z0-9_]{0,39}"))) { "Invalid screensaver key" }
        require(title.isNotBlank() && title.length <= 80) { "Invalid screensaver title" }
        require(entry.endsWith(".html") || entry.endsWith(".htm")) { "Screensaver entry must be an HTML asset" }
        PluginPackage.assetFile(requireNotNull(directory), entry)
        require(data.keys.all { it.matches(Regex("[a-zA-Z][a-zA-Z0-9_]{0,39}")) } && data.values.all {
            it == null || it is String || it is Boolean || (it is Number && it.toDouble().isFinite())
        }) { "Screensaver data must contain scalar JSON values" }
        val json = JSONObject(data).toString()
        require(json.toByteArray(Charsets.UTF_8).size <= 32768) { "Screensaver data exceeds 32 KB" }
        require(items.containsKey(key) || items.size < 4) { "At most four screensavers are supported" }
        budget()
        factories.remove(key)
        items[key] = mapOf("key" to key, "title" to title, "entry" to entry, "dataJson" to json)
    }

    /** With [touch], single taps reach the view and the kiosk closes the screensaver on a double tap. */
    @Synchronized fun publishView(key: String, title: String, factory: F, touch: Boolean = false) {
        require(key.matches(Regex("[a-z][a-z0-9_]{0,39}"))) { "Invalid screensaver key" }
        require(title.isNotBlank() && title.length <= 80) { "Invalid screensaver title" }
        require(items.containsKey(key) || items.size < 4) { "At most four screensavers are supported" }
        budget()
        factories[key] = factory
        items[key] = mapOf("key" to key, "title" to title, "view" to true, "touch" to touch, "generation" to ++generation)
    }

    /** The factory of a native renderer, only while it is still the generation Flutter asked for. */
    @Synchronized fun view(key: String, generation: Int): F? =
        factories[key]?.takeIf { !closed && items[key]?.get("generation") == generation }

    @Synchronized fun remove(key: String) { budget(); items.remove(key); factories.remove(key) }
    @Synchronized fun snapshot(): List<Map<String, Any>> = items.values.toList()
    @Synchronized fun close() { closed = true; items.clear(); factories.clear() }
}
