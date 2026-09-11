package me.jxl.kiosk_satellite.plugins

/** Session-owned sensor and select declarations with bounded state publication. */
internal class PluginEntities(private val clock: () -> Long = System::nanoTime) {
    private val entries = linkedMapOf<String, Map<String, Any?>>()
    private var closed = false
    private var window = clock()
    private var updates = 0

    @Synchronized fun publish(type: String, key: String, name: String, metadata: Map<String, Any>, state: Any?) {
        check(!closed) { "Plugin session has ended" }
        require(type in setOf("sensor", "text_sensor", "binary_sensor", "select")) { "Unknown entity type" }
        require(key.matches(Regex("[a-z][a-z0-9_]{0,39}")) && name.length in 1..80) { "Invalid entity key or name" }
        val id = "$type.$key"
        require(id in entries || entries.size < 32) { "At most 32 sensor and select entities are supported" }
        val entity = linkedMapOf<String, Any?>("type" to type, "key" to key, "name" to name)
        when (type) {
            "sensor" -> {
                require(metadata.keys.all { it in setOf("unit", "deviceClass", "stateClass", "accuracyDecimals") }) { "Unknown sensor metadata" }
                val unit = metadata["unit"] ?: ""
                val deviceClass = metadata["deviceClass"] ?: ""
                val stateClass = metadata["stateClass"] ?: "none"
                val decimals = metadata["accuracyDecimals"] ?: 0
                require(unit is String && unit.length <= 32) { "Invalid sensor unit" }
                validateDeviceClass(deviceClass)
                val classes = mapOf("none" to 0, "measurement" to 1, "total_increasing" to 2, "total" to 3)
                require(stateClass is String && stateClass in classes) { "Invalid sensor state class" }
                require(decimals is Number && decimals.toDouble() in 0.0..6.0 && decimals.toDouble() == decimals.toInt().toDouble()) { "Invalid display precision" }
                require(state == null || (state is Number && state.toDouble().isFinite() && state.toDouble().toFloat().isFinite())) { "Sensor state must be finite and fit an ESPHome float, or null" }
                entity.putAll(mapOf("unit" to unit, "deviceClass" to deviceClass, "stateClass" to classes[stateClass], "accuracyDecimals" to decimals.toInt(), "state" to (state as? Number)?.toDouble()))
            }
            "text_sensor" -> {
                require(metadata.isEmpty()) { "Unknown text sensor metadata" }
                require(state == null || (state is String && state.length <= 512)) { "Text sensor state must be at most 512 characters or null" }
                entity["state"] = state
            }
            "binary_sensor" -> {
                require(metadata.keys.all { it == "deviceClass" }) { "Unknown binary sensor metadata" }
                val deviceClass = metadata["deviceClass"] ?: ""
                validateDeviceClass(deviceClass)
                require(state == null || state is Boolean) { "Binary sensor state must be boolean or null" }
                entity.putAll(mapOf("deviceClass" to deviceClass, "state" to state))
            }
            "select" -> {
                require(metadata.keys == setOf("options")) { "A select requires options" }
                val options = metadata["options"] as? List<*> ?: error("Missing select options")
                require(options.size in 1..32 && options.all { it is String && it.length in 1..80 } && options.toSet().size == options.size) { "Invalid select options" }
                require(state == null || (state is String && state in options)) { "Selection is not an advertised option" }
                entity.putAll(mapOf("options" to options.toList(), "state" to state))
            }
        }
        budget()
        entries[id] = entity
    }

    private fun validateDeviceClass(value: Any) {
        require(value is String && (value.isEmpty() || value.matches(Regex("[a-z][a-z0-9_]{0,39}")))) { "Invalid device class" }
    }

    private fun budget() {
        val now = clock()
        if (now - window >= 1_000_000_000L) { window = now; updates = 0 }
        check(updates < 64) { "At most 64 entity changes per second are supported" }
        updates++
    }

    @Synchronized fun select(key: String, option: Any?): Map<String, Any> {
        check(!closed) { "Plugin session has ended" }
        val entity = entries["select.$key"] ?: error("Plugin select is not available")
        require(option is String && option in entity["options"] as List<*>) { "Selection is not an advertised option" }
        return mapOf("option" to option)
    }

    @Synchronized fun remove(type: String, key: String) {
        check(!closed) { "Plugin session has ended" }
        budget()
        entries.remove("$type.$key")
    }
    @Synchronized fun snapshot(): List<Map<String, Any?>> = entries.values.toList()
    @Synchronized fun close() { closed = true; entries.clear() }
}
