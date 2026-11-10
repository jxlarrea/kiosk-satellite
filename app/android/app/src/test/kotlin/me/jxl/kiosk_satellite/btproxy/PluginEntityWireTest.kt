package me.jxl.kiosk_satellite.btproxy

import me.jxl.kiosk_satellite.plugins.PluginEntities
import org.junit.Assert.*
import org.junit.Test

class PluginEntityWireTest {
    @Test fun switchStatesAndCommandsPreserveBothBooleans() {
        val store = PluginEntities()
        for (on in listOf(true, false)) {
            store.publish("switch", "power", "Power", emptyMap(), on)
            val entry = store.snapshot().single()
            val entity = EspEntity.fromMap(entry + ("objectId" to "plugin_demo____switch_power"))
            assertTrue(entity is EspEntity.Switch)
            assertEquals(Msg.LIST_ENTITIES_SWITCH_RESPONSE, EntityCodec.describe(entity, "demo").first)
            val frame = EntityCodec.state(entity, entry["state"])!!
            assertEquals(Msg.SWITCH_STATE_RESPONSE, frame.first)
            var state = false
            var key = 0
            ProtoReader(frame.second).let { r -> while (r.next()) when (r.field) {
                1 -> key = r.asFixed32()
                2 -> state = r.asBool()
            } }
            assertEquals(on, state)
            assertEquals(entity.key, key)
            assertNull(EntityCodec.state(entity, null))
            val request = EntityCodec.parseCommand(Msg.SWITCH_COMMAND_REQUEST,
                ProtoWriter().apply { fixed32(1, entity.key); bool(2, !on) }.toByteArray())!!
            assertEquals(entity.key, request.key)
            assertEquals(mapOf("on" to !on), store.switchCommand("power", request.value))
            assertEquals(on, store.snapshot().single()["state"])
        }
    }
    @Test fun numbersDescribeTheirRangeAndCarryHomeAssistantValues() {
        val store = PluginEntities()
        store.publish("number", "volume", "Volume", mapOf("min" to 0.1, "max" to 1, "step" to 0.05, "unit" to "%", "mode" to "slider"), 0.3)
        val entry = store.snapshot().single()
        val entity = EspEntity.fromMap(entry + ("objectId" to "plugin_demo____number_volume"))
        assertTrue(entity is EspEntity.Number)
        val (type, description) = EntityCodec.describe(entity, "demo")
        assertEquals(Msg.LIST_ENTITIES_NUMBER_RESPONSE, type)
        val fields = mutableMapOf<Int, Any>()
        ProtoReader(description).let { r -> while (r.next()) when (r.field) {
            6, 7, 8 -> fields[r.field] = r.asFloat()
            11 -> fields[r.field] = r.asString()
            12 -> fields[r.field] = r.asInt()
        } }
        assertEquals(mapOf(6 to 0.1f, 7 to 1f, 8 to 0.05f, 11 to "%", 12 to 2), fields)
        var state: Float? = null
        ProtoReader(EntityCodec.state(entity, entry["state"])!!.second).let { r -> while (r.next()) if (r.field == 2) state = r.asFloat() }
        assertEquals(0.3f, state)
        var missing = false
        ProtoReader(EntityCodec.state(entity, null)!!.second).let { r -> while (r.next()) if (r.field == 3) missing = r.asBool() }
        assertTrue(missing)
        val request = EntityCodec.parseCommand(Msg.NUMBER_COMMAND_REQUEST,
            ProtoWriter().apply { fixed32(1, entity.key); float(2, 0.7f) }.toByteArray())!!
        assertEquals(entity.key, request.key)
        assertEquals(mapOf("value" to 0.7), store.number("volume", request.value))
        assertEquals(0.3, store.snapshot().single()["state"])
    }
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
