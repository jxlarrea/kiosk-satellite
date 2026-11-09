package me.jxl.kiosk_satellite.plugins

/**
 * Bounded, session-owned native overlays: the placement and factory per
 * key. The views themselves are built by [PluginOverlayViews] when Flutter
 * lays the overlay out. A replaced overlay gets a new generation, so Flutter
 * builds a fresh view from the new factory instead of keeping the old one.
 */
internal class PluginOverlays<F : Any>(private val clock: () -> Long = System::nanoTime) {
    class Entry<F>(val key: String, val placement: Map<String, Any>, val factory: F, val generation: Int)

    /** Where and how one overlay shows. Lengths are dp, insets left, top, right, bottom, the duration ms. */
    data class Placement(
        val anchor: String,
        val width: Int,
        val height: Int,
        val insets: List<Int> = listOf(0, 0, 0, 0),
        val offsetX: Int = 0,
        val offsetY: Int = 0,
        val closeOnBack: Boolean = true,
        val layer: String = DASHBOARD,
        val touchable: Boolean = true,
        val closeOnOutsideTouch: Boolean = false,
        val passOutsideTouch: Boolean = false,
        val enter: String = NONE,
        val exit: String = NONE,
        val duration: Int = 200,
    )

    private val entries = linkedMapOf<String, Entry<F>>()
    private var closed = false
    private var generation = 0
    private var window = clock()
    private var changes = 0

    @Synchronized fun show(key: String, placement: Placement, factory: F): Entry<F> {
        check(!closed) { "Plugin session has ended" }
        require(key.matches(Regex("[a-z][a-z0-9_]{0,39}"))) { "Invalid overlay key" }
        require(entries.containsKey(key) || entries.size < MAX_OVERLAYS) { "At most four overlays are supported" }
        val p = placement
        require(p.anchor in ANCHORS) { "Unknown overlay anchor" }
        require(p.layer in LAYERS) { "Unknown overlay layer" }
        require(validSize(p.width) && validSize(p.height)) { "Overlay sizes must be WRAP, FILL or 1 to 4096 dp" }
        require(p.insets.size == 4 && p.insets.all { it in 0..MAX_INSET }) { "Overlay insets must be 0 to 4096 dp" }
        require(p.offsetX in -MAX_OFFSET..MAX_OFFSET && p.offsetY in -MAX_OFFSET..MAX_OFFSET) { "Overlay offsets must be -4096 to 4096 dp" }
        require(p.enter in TRANSITIONS && p.exit in TRANSITIONS) { "Unknown overlay transition" }
        require(p.duration in 50..1000) { "Overlay transitions must last 50 to 1000 ms" }
        require(p.closeOnOutsideTouch || !p.passOutsideTouch) { "passOutsideTouch needs closeOnOutsideTouch" }
        val now = clock()
        if (now - window >= 1_000_000_000L) { window = now; changes = 0 }
        check(changes < 8) { "At most eight overlay changes per second are supported" }
        changes++
        val entry = Entry(key, mapOf(
            "anchor" to p.anchor, "width" to p.width, "height" to p.height, "insets" to p.insets,
            "offsetX" to p.offsetX, "offsetY" to p.offsetY,
            "closeOnBack" to p.closeOnBack, "layer" to p.layer, "touchable" to p.touchable,
            "closeOnOutsideTouch" to p.closeOnOutsideTouch, "passOutsideTouch" to p.passOutsideTouch,
            "enter" to p.enter, "exit" to p.exit, "duration" to p.duration,
        ), factory, ++generation)
        // A replacement moves to the top, like a new overlay.
        entries.remove(key)
        entries[key] = entry
        return entry
    }

    /** Ignored once the session ends, so a plugin may hide its overlays in stop(). */
    @Synchronized fun hide(key: String): Boolean = !closed && entries.remove(key) != null

    /** Removes the overlay only if it is still the generation Flutter showed. */
    @Synchronized fun closed(key: String, generation: Int): Boolean =
        !closed && entries[key]?.generation == generation && entries.remove(key) != null

    @Synchronized fun get(key: String, generation: Int): Entry<F>? = entries[key]?.takeIf { it.generation == generation }

    @Synchronized fun snapshot(): List<Map<String, Any>> =
        entries.values.map { it.placement + mapOf("key" to it.key, "generation" to it.generation) }

    @Synchronized fun close() { closed = true; entries.clear() }

    companion object {
        const val MAX_OVERLAYS = 4
        const val MAX_INSET = 4096
        const val MAX_OFFSET = 4096
        const val NONE = "none"
        val TRANSITIONS = setOf(NONE, "fade", "slide", "scale")
        const val DASHBOARD = "dashboard"
        val LAYERS = setOf(DASHBOARD, "views", "top")
        const val WRAP = -1
        const val FILL = -2
        val ANCHORS = setOf("top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right")
        private fun validSize(value: Int) = value == WRAP || value == FILL || value in 1..4096
    }
}
