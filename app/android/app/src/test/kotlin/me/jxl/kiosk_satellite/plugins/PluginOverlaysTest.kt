package me.jxl.kiosk_satellite.plugins

import org.junit.Assert.*
import org.junit.Test

class PluginOverlaysTest {
    private fun rejects(action: () -> Unit) {
        try { action(); fail("Expected overlay rejection") } catch (_: IllegalArgumentException) {} catch (_: IllegalStateException) {}
    }

    private fun PluginOverlays<String>.bar(key: String = "bar", factory: String = "first", width: Int = PluginOverlays.WRAP) =
        show(key, PluginOverlays.Placement("top", width, PluginOverlays.WRAP, listOf(12, 12, 12, 12)), factory)

    private fun PluginOverlays<String>.placed(placement: PluginOverlays.Placement) = show("menu", placement, "f")

    @Test fun snapshotCarriesPlacementKeyAndGeneration() {
        val overlays = PluginOverlays<String>()
        val entry = overlays.show("full", PluginOverlays.Placement(
            "center", PluginOverlays.FILL, PluginOverlays.FILL, listOf(0, 8, 0, 96), offsetX = -40, offsetY = 12,
            closeOnBack = false, layer = "views", touchable = false, closeOnOutsideTouch = true, passOutsideTouch = true,
            enter = "slide", exit = "fade", duration = 300,
        ), "factory")
        assertEquals(listOf(mapOf(
            "anchor" to "center", "width" to PluginOverlays.FILL, "height" to PluginOverlays.FILL, "insets" to listOf(0, 8, 0, 96),
            "offsetX" to -40, "offsetY" to 12, "closeOnBack" to false, "layer" to "views", "touchable" to false,
            "closeOnOutsideTouch" to true, "passOutsideTouch" to true, "enter" to "slide", "exit" to "fade", "duration" to 300,
            "key" to "full", "generation" to entry.generation,
        )), overlays.snapshot())
        assertEquals("factory", overlays.get("full", entry.generation)?.factory)
    }

    @Test fun rejectsBadPlacements() {
        val overlays = PluginOverlays<String>()
        rejects { overlays.bar(key = "Bar") }
        val wrap = PluginOverlays.WRAP
        rejects { overlays.placed(PluginOverlays.Placement("middle", wrap, wrap)) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, layer = "above")) }
        rejects { overlays.bar(width = 0) }
        rejects { overlays.bar(width = 4097) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, listOf(0, 0, 0, 4097))) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, listOf(0, -1, 0, 0))) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, listOf(0, 0, 0))) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, offsetX = 4097)) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, enter = "spin")) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, exit = "")) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, duration = 49)) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, duration = 1001)) }
        rejects { overlays.placed(PluginOverlays.Placement("top", wrap, wrap, passOutsideTouch = true)) }
        overlays.bar(width = 4096)
        overlays.placed(PluginOverlays.Placement("bottom-left", wrap, wrap, listOf(0, 0, 0, 4096), offsetX = -4096, offsetY = 4096,
            closeOnOutsideTouch = true, passOutsideTouch = true, enter = "scale", exit = "slide", duration = 1000))
    }

    @Test fun limitsEachSessionToFourOverlays() {
        val overlays = PluginOverlays<String>()
        repeat(PluginOverlays.MAX_OVERLAYS) { overlays.bar(key = "o$it") }
        rejects { overlays.bar(key = "o9") }
        // Replacing an existing key is not a new overlay.
        overlays.bar(key = "o0")
    }

    @Test fun replacingMovesToTheTopWithANewGeneration() {
        val overlays = PluginOverlays<String>()
        val first = overlays.bar(factory = "first")
        overlays.bar(key = "other")
        val second = overlays.bar(factory = "second")
        assertNotEquals(first.generation, second.generation)
        assertEquals(listOf("other", "bar"), overlays.snapshot().map { it["key"] })
        assertNull(overlays.get("bar", first.generation))
        assertEquals("second", overlays.get("bar", second.generation)?.factory)
    }

    @Test fun backClosesOnlyTheGenerationFlutterShowed() {
        val overlays = PluginOverlays<String>()
        val first = overlays.bar()
        val second = overlays.bar(factory = "second")
        assertFalse(overlays.closed("bar", first.generation))
        assertTrue(overlays.closed("bar", second.generation))
        assertTrue(overlays.snapshot().isEmpty())
    }

    @Test fun dropsABurstPastTheBudget() {
        var now = 0L
        val overlays = PluginOverlays<String> { now }
        repeat(8) { overlays.bar() }
        rejects { overlays.bar() }
        now += 1_000_000_000L
        overlays.bar()
    }

    @Test fun hidingAfterTheSessionEndsIsANoOp() {
        val overlays = PluginOverlays<String>()
        overlays.bar()
        overlays.close()
        assertFalse(overlays.hide("bar"))
        assertTrue(overlays.snapshot().isEmpty())
        rejects { overlays.bar() }
    }

    /** Defines one class itself, the way a plugin's DexClassLoader does. */
    private class OwningLoader(parent: ClassLoader, private val owned: String) : ClassLoader(parent) {
        override fun loadClass(name: String, resolve: Boolean): Class<*> {
            if (name != owned) return super.loadClass(name, resolve)
            findLoadedClass(name)?.let { return it }
            val bytes = parent.getResourceAsStream(name.replace('.', '/') + ".class")!!.readBytes()
            return defineClass(name, bytes, 0, bytes.size)
        }
    }

    class Victim

    @Test fun blamesThePluginWhoseLoaderDefinedAFrame() {
        val owned = Victim::class.java.name
        val loaders = listOf(
            "other" to OwningLoader(javaClass.classLoader!!, "nothing.Here"),
            "hello" to OwningLoader(javaClass.classLoader!!, owned),
        )
        fun crash(vararg classes: String) = RuntimeException("boom").apply {
            stackTrace = classes.map { StackTraceElement(it, "onDraw", null, 1) }.toTypedArray()
        }
        assertEquals("hello", PluginBridge.culprit(crash("android.view.View", owned), loaders))
        // KS and SDK classes resolve through the parent and never take the blame.
        assertNull(PluginBridge.culprit(crash("android.view.View", PluginOverlays::class.java.name), loaders))
        // Found through the cause too.
        val wrapped = RuntimeException("outer", crash(owned)).apply { stackTrace = emptyArray() }
        assertEquals("hello", PluginBridge.culprit(wrapped, loaders))
        assertNull(PluginBridge.culprit(crash(owned), emptyList()))
    }
}
