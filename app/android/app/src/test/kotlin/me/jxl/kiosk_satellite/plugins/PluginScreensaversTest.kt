package me.jxl.kiosk_satellite.plugins

import org.junit.Assert.*
import org.junit.Test

class PluginScreensaversTest {
    @Test fun documentsAreBoundedAndRevoked() {
        var now = 1L
        val renderers = PluginScreensavers { now }
        fun rejects(block: () -> Unit) {
            try { block(); fail("Expected rejection") } catch (_: IllegalArgumentException) {}
        }
        rejects { renderers.publish("../dvd", "DVD", "html") }
        rejects { renderers.publish("dvd", " ", "html") }
        rejects { renderers.publish("dvd", "DVD", "é".repeat(131073)) }
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
