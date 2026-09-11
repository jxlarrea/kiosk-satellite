package me.jxl.kiosk_satellite.btproxy

import me.jxl.kiosk_satellite.plugins.PluginEntities
import org.junit.Assert.*
import org.junit.Test

class PluginEntityWireTest {
    @Test fun pluginReadingsAndSelectsUseNativeEntityDescriptionsAndMissingStates() {
        val store = PluginEntities()
        store.publish("sensor", "latency", "Latency", mapOf("unit" to "ms", "stateClass" to "measurement", "accuracyDecimals" to 2), 12.5)
        store.publish("text_sensor", "link", "Link", emptyMap(), "WiFi")
        store.publish("binary_sensor", "connected", "Connected", mapOf("deviceClass" to "connectivity"), false)
        store.publish("select", "mode", "Mode", mapOf("options" to listOf("Auto", "Fast")), "Auto")
        val types = listOf(Msg.SENSOR_STATE_RESPONSE, Msg.TEXT_SENSOR_STATE_RESPONSE, Msg.BINARY_SENSOR_STATE_RESPONSE, Msg.SELECT_STATE_RESPONSE)
        for ((index, entry) in store.snapshot().withIndex()) {
            val entity = EspEntity.fromMap(entry + ("objectId" to "plugin_demo____${entry["type"]}_${entry["key"]}"))
            val missing = EntityCodec.state(entity, null)!!
            assertEquals(types[index], missing.first)
            var flag = false
            ProtoReader(missing.second).let { r -> while (r.next()) if (r.field == 3) flag = r.asBool() }
            assertTrue(flag)
            val state = EntityCodec.state(entity, entry["state"])!!
            var key = 0
            var value: Any? = if (entity is EspEntity.BinarySensor) false else null
            ProtoReader(state.second).let { r -> while (r.next()) when (r.field) {
                1 -> key = r.asFixed32()
                2 -> value = when (entity) {
                    is EspEntity.Sensor -> r.asFloat()
                    is EspEntity.BinarySensor -> r.asBool()
                    else -> r.asString()
                }
            } }
            assertEquals(entity.key, key)
            assertEquals(listOf(12.5f, "WiFi", false, "Auto")[index], value)
            if (entity is EspEntity.Sensor) {
                assertEquals("ms", entity.unit); assertEquals(1, entity.stateClass); assertEquals(2, entity.accuracyDecimals)
            }
            if (entity is EspEntity.Select) {
                val requested = EntityCodec.parseCommand(Msg.SELECT_COMMAND_REQUEST, ProtoWriter().apply { fixed32(1, entity.key); string(2, "Fast") }.toByteArray())!!
                assertEquals(entity.key, requested.key)
                assertEquals(mapOf("option" to "Fast"), store.select("mode", requested.value))
                assertEquals("Auto", store.snapshot().last()["state"])
            }
        }
    }
}
