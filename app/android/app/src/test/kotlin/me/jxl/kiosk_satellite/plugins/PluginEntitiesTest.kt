package me.jxl.kiosk_satellite.plugins

import org.junit.Assert.*
import org.junit.Test

class PluginEntitiesTest {
    private fun rejects(action: () -> Unit) {
        try { action(); fail("Expected rejection") } catch (_: IllegalArgumentException) {} catch (_: IllegalStateException) {}
    }
    @Test fun numericMetadataAndUnknownStatesAreValidated() {
        val store = PluginEntities()
        store.publish("sensor", "rssi", "RSSI", mapOf("unit" to "dBm", "deviceClass" to "signal_strength", "stateClass" to "measurement", "accuracyDecimals" to 1), -65.0)
        val entity = store.snapshot().single()
        assertEquals(1, entity["stateClass"])
        assertEquals(1, entity["accuracyDecimals"])
        assertEquals(-65.0, entity["state"])
        for (value in listOf(Double.NaN, Double.POSITIVE_INFINITY, Double.MAX_VALUE, "-65", true)) {
            rejects { store.publish("sensor", "rssi", "RSSI", emptyMap(), value) }
        }
        for (metadata in listOf(mapOf("stateClass" to "invalid"), mapOf("accuracyDecimals" to 1.5), mapOf("accuracyDecimals" to 7), mapOf("unit" to "x".repeat(33)), mapOf("deviceClass" to "bad class"), mapOf("extra" to true))) {
            rejects { store.publish("sensor", "rssi", "RSSI", metadata, 1.0) }
        }
        assertEquals(entity, store.snapshot().single())
        store.publish("sensor", "rssi", "RSSI", emptyMap(), null)
        assertNull(store.snapshot().single()["state"])
        store.publish("sensor", "rssi", "RSSI", emptyMap(), 0.0)
        assertEquals(0.0, store.snapshot().single()["state"])
    }
    @Test fun textBinaryAndSelectHaveDistinctKeysAndTypedStates() {
        val store = PluginEntities()
        store.publish("text_sensor", "same", "Link", emptyMap(), "WiFi")
        store.publish("binary_sensor", "same", "Connected", mapOf("deviceClass" to "connectivity"), false)
        val options = mutableListOf("Auto", "Performance")
        store.publish("select", "same", "Mode", mapOf("options" to options), "Auto")
        options[0] = "Changed"
        assertEquals(mapOf("option" to "Auto"), store.select("same", "Auto"))
        assertEquals("Auto", store.snapshot().last()["state"])
        rejects { store.select("same", "Changed") }
        rejects { store.select("same", null) }
        rejects { store.select("missing", "Auto") }
        rejects { store.publish("text_sensor", "same", "Link", emptyMap(), "x".repeat(513)) }
        rejects { store.publish("text_sensor", "same", "Link", emptyMap(), 1) }
        rejects { store.publish("binary_sensor", "same", "Link", emptyMap(), 1) }
        for (choices in listOf(emptyList<String>(), listOf("Auto", "Auto"), List(33) { "$it" }, listOf(""))) {
            rejects { store.publish("select", "same", "Mode", mapOf("options" to choices), null) }
        }
        rejects { store.publish("select", "same", "Mode", mapOf("options" to listOf("Auto")), "Other") }
        store.remove("text_sensor", "same")
        assertEquals(2, store.snapshot().size)
        store.remove("select", "same")
        rejects { store.select("same", "Auto") }
        assertEquals(false, store.snapshot().single()["state"])
    }
    @Test fun capacityRateAndSessionRevocationAreBounded() {
        var now = 0L
        val store = PluginEntities { now }
        repeat(32) { store.publish("sensor", "s$it", "Sensor", emptyMap(), it) }
        rejects { store.publish("sensor", "extra", "Sensor", emptyMap(), 0) }
        repeat(32) { store.publish("sensor", "s$it", "Sensor", emptyMap(), null) }
        rejects { store.remove("sensor", "s0") }
        now += 1_000_000_000L
        store.remove("sensor", "s0")
        store.publish("sensor", "replacement", "Sensor", emptyMap(), 1)
        store.close()
        assertTrue(store.snapshot().isEmpty())
        rejects { store.publish("sensor", "late", "Sensor", emptyMap(), 1) }
        rejects { store.remove("sensor", "s1") }
    }
}
