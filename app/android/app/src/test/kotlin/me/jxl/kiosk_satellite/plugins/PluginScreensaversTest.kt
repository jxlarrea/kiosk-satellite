package me.jxl.kiosk_satellite.plugins

import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.nio.file.Files
import org.json.JSONObject

class PluginScreensaversTest {
    @Test fun assetEntryIsAReferenceAndNotALimitedInlineDocument() {
        val root = Files.createTempDirectory("screensaver-assets").toFile()
        try {
            File(root, "assets/dvd").mkdirs()
            File(root, "assets/dvd/index.html").writeText("<html>" + " ".repeat(600000) + "</html>")
            val renderers = PluginScreensavers<String>(root)
            val data = mutableMapOf<String, Any?>("color" to "#00D4FF")
            renderers.publishAsset("dvd", "DVD", "dvd/index.html", data)
            data["color"] = "changed"
            val snapshot = renderers.snapshot().single()
            assertFalse(snapshot.containsKey("html"))
            assertEquals("dvd/index.html", snapshot["entry"])
            assertEquals("#00D4FF", JSONObject(snapshot["dataJson"] as String).getString("color"))
            for (path in listOf("../index.html", "/dvd/index.html", "dvd/%2e%2e/index.html", "dvd/missing.html", "dvd/index.js")) {
                try { renderers.publishAsset("dvd", "DVD", path, emptyMap()); fail("Unsafe entry accepted: $path") } catch (_: IllegalArgumentException) {}
            }
            try { renderers.publishAsset("dvd", "DVD", "dvd/index.html", mapOf("nested" to listOf(1))); fail("Non-scalar data accepted") } catch (_: IllegalArgumentException) {}
            renderers.close()
            try { renderers.publishAsset("dvd", "DVD", "dvd/index.html", emptyMap()); fail("Revoked session published") } catch (_: IllegalStateException) {}
        } finally { root.deleteRecursively() }
    }

    @Test fun inlineLimitCountsUtf8BytesAndAcceptsExactly512KiB() {
        val renderers = PluginScreensavers<String>()
        val exact = "é".repeat(262144)
        renderers.publish("dvd", "DVD", exact)
        assertEquals(exact, renderers.snapshot().single()["html"])
        try {
            renderers.publish("dvd", "DVD", exact + "x")
            fail("Accepted more than 512 KiB")
        } catch (_: IllegalArgumentException) {}
        assertEquals(exact, renderers.snapshot().single()["html"])
    }

    @Test fun viewsShareKeysAndLimitsWithDocuments() {
        var now = 1L
        val renderers = PluginScreensavers<String> { now }
        renderers.publishView("monitor", "Monitor", "first")
        val first = renderers.snapshot().single()
        assertEquals(true, first["view"])
        assertEquals(false, first["touch"])
        assertEquals("Monitor", first["title"])
        assertFalse(first.containsKey("html"))
        val generation = first["generation"] as Int
        assertEquals("first", renderers.view("monitor", generation))
        // A republication is a new generation, and the old one is gone.
        renderers.publishView("monitor", "Monitor", "second", touch = true)
        assertEquals(true, renderers.snapshot().single()["touch"])
        val next = renderers.snapshot().single()["generation"] as Int
        assertNotEquals(generation, next)
        assertNull(renderers.view("monitor", generation))
        assertEquals("second", renderers.view("monitor", next))
        // HTML under the same key replaces the view, and the other way round.
        renderers.publish("monitor", "Monitor", "<svg/>")
        assertNull(renderers.view("monitor", next))
        assertFalse(renderers.snapshot().single().containsKey("view"))
        renderers.publish("monitor", "Monitor", "<canvas/>")
        try { renderers.publishView("monitor", "Monitor", "third"); fail("Unbounded updates") } catch (_: IllegalStateException) {}
        now += 1_000_000_000L
        renderers.publishView("monitor", "Monitor", "third")
        assertFalse(renderers.snapshot().single().containsKey("html"))
        try { renderers.publishView("Bad", "Monitor", "x"); fail("Invalid key accepted") } catch (_: IllegalArgumentException) {}
        try { renderers.publishView("bad", " ", "x"); fail("Blank title accepted") } catch (_: IllegalArgumentException) {}
        renderers.publish("two", "Two", "html")
        renderers.publish("three", "Three", "html")
        now += 1_000_000_000L
        renderers.publish("four", "Four", "html")
        try { renderers.publishView("five", "Five", "x"); fail("Fifth renderer accepted") } catch (_: IllegalArgumentException) {}
        val third = renderers.snapshot().first()["generation"] as Int
        renderers.remove("monitor")
        assertNull(renderers.view("monitor", third))
        now += 1_000_000_000L
        renderers.publishView("monitor", "Monitor", "fourth")
        val last = renderers.snapshot().last()["generation"] as Int
        renderers.close()
        assertNull(renderers.view("monitor", last))
        try { renderers.publishView("monitor", "Monitor", "x"); fail("Revoked session published") } catch (_: IllegalStateException) {}
    }

    @Test fun documentsAreBoundedAndRevoked() {
        var now = 1L
        val renderers = PluginScreensavers<String> { now }
        fun rejects(block: () -> Unit) {
            try { block(); fail("Expected rejection") } catch (_: IllegalArgumentException) {}
        }
        rejects { renderers.publish("../dvd", "DVD", "html") }
        rejects { renderers.publish("dvd", " ", "html") }
        rejects { renderers.publish("dvd", "DVD", "é".repeat(262145)) }
        renderers.publish("dvd", "DVD", "<svg/>")
        val first = renderers.snapshot()
        renderers.publish("dvd", "DVD", "<canvas/>")
        assertEquals("<svg/>", first.single()["html"])
        assertEquals("<canvas/>", renderers.snapshot().single()["html"])
        renderers.publish("two", "Two", "html")
        renderers.publish("three", "Three", "html")
        try { renderers.remove("dvd"); fail("Unbounded updates") } catch (_: IllegalStateException) {}
        now += 1_000_000_000L
        renderers.publish("four", "Four", "html")
        rejects { renderers.publish("five", "Five", "html") }
        renderers.remove("dvd")
        assertEquals(3, renderers.snapshot().size)
        renderers.close()
        assertTrue(renderers.snapshot().isEmpty())
        try { renderers.publish("dvd", "DVD", "html"); fail("Revoked session published") } catch (_: IllegalStateException) {}
    }
}
