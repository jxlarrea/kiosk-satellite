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
            val renderers = PluginScreensavers(root)
            val data = mutableMapOf<String, Any?>("color" to "#00D4FF")
            renderers.publishAsset("dvd", "DVD", "dvd/index.html", data)
            data["color"] = "changed"
            val snapshot = renderers.snapshot().single()
            assertFalse(snapshot.containsKey("html"))
            assertEquals("dvd/index.html", snapshot["entry"])
            assertEquals("#00D4FF", JSONObject(snapshot["dataJson"]!!).getString("color"))
            for (path in listOf("../index.html", "/dvd/index.html", "dvd/%2e%2e/index.html", "dvd/missing.html", "dvd/index.js")) {
                try { renderers.publishAsset("dvd", "DVD", path, emptyMap()); fail("Unsafe entry accepted: $path") } catch (_: IllegalArgumentException) {}
            }
            try { renderers.publishAsset("dvd", "DVD", "dvd/index.html", mapOf("nested" to listOf(1))); fail("Non-scalar data accepted") } catch (_: IllegalArgumentException) {}
            renderers.close()
            try { renderers.publishAsset("dvd", "DVD", "dvd/index.html", emptyMap()); fail("Revoked session published") } catch (_: IllegalStateException) {}
        } finally { root.deleteRecursively() }
    }

    @Test fun inlineLimitCountsUtf8BytesAndAcceptsExactly512KiB() {
        val renderers = PluginScreensavers()
        val exact = "é".repeat(262144)
        renderers.publish("dvd", "DVD", exact)
        assertEquals(exact, renderers.snapshot().single()["html"])
        try {
            renderers.publish("dvd", "DVD", exact + "x")
            fail("Accepted more than 512 KiB")
        } catch (_: IllegalArgumentException) {}
        assertEquals(exact, renderers.snapshot().single()["html"])
    }

    @Test fun documentsAreBoundedAndRevoked() {
        var now = 1L
        val renderers = PluginScreensavers { now }
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
