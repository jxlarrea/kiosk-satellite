package me.jxl.kiosk_satellite.plugins

/** Session-owned sensor, select, switch and number declarations with bounded state publication. */
internal class PluginEntities(private val clock: () -> Long = System::nanoTime) {
    private val entries = linkedMapOf<String, Map<String, Any?>>()
    private var closed = false
    private var window = clock()
    private var updates = 0

    @Synchronized fun publish(type: String, key: String, name: String, metadata: Map<String, Any>, state: Any?) {
        check(!closed) { "Plugin session has ended" }
        require(type in setOf("sensor", "text_sensor", "binary_sensor", "select", "switch", "number")) { "Unknown entity type" }
        require(key.matches(Regex("[a-z][a-z0-9_]{0,39}")) && name.length in 1..80) { "Invalid entity key or name" }
        val id = "$type.$key"
        require(id in entries || entries.size < 32) { "At most 32 sensor, select, switch and number entities are supported" }
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
            "switch" -> {
                require(metadata.isEmpty()) { "Unknown switch metadata" }
                require(state is Boolean) { "Switch state must be boolean" }
                entity["state"] = state
            }
            "select" -> {
                require(metadata.keys == setOf("options")) { "A select requires options" }
                val options = metadata["options"] as? List<*> ?: error("Missing select options")
                require(options.size in 1..32 && options.all { it is String && it.length in 1..80 } && options.toSet().size == options.size) { "Invalid select options" }
                require(state == null || (state is String && state in options)) { "Selection is not an advertised option" }
                entity.putAll(mapOf("options" to options.toList(), "state" to state))
            }
            "number" -> {
                require(metadata.keys.all { it in setOf("min", "max", "step", "unit", "mode") }) { "Unknown number metadata" }
                fun bound(name: String, default: Double): Double {
                    val value = metadata[name] ?: default
                    require(value is Number && fitsFloat(value.toDouble())) { "Number $name must be finite and fit an ESPHome float" }
                    return value.toDouble()
                }
                val min = bound("min", 0.0)
                val max = bound("max", 100.0)
                val step = bound("step", 1.0)
                require(min < max) { "Number min must be below max" }
                require(step > 0 && step <= max - min) { "Number step must be above 0 and at most max minus min" }
                val unit = metadata["unit"] ?: ""
                require(unit is String && unit.length <= 32) { "Invalid number unit" }
                val modes = mapOf("auto" to 0, "box" to 1, "slider" to 2)
                val mode = metadata["mode"] ?: "auto"
                require(mode is String && mode in modes) { "Number mode must be auto, slider or box" }
                require(state == null || (state is Number && fitsFloat(state.toDouble()) && inRange(state.toDouble(), min, max))) { "Number state must be between min and max, or null" }
                entity.putAll(mapOf("min" to min, "max" to max, "step" to step, "unit" to unit, "mode" to modes[mode],
                    "accuracyDecimals" to decimals(step), "state" to (state as? Number)?.toDouble()))
            }
        }
        budget()
        entries[id] = entity
    }

    private fun fitsFloat(value: Double) = value.isFinite() && value.toFloat().isFinite()

    /** Compared as ESPHome floats, so a value that made the round trip still counts as in range. */
    private fun inRange(value: Double, min: Double, max: Double) = value.toFloat() in min.toFloat()..max.toFloat()

    /** The decimals a step needs, so 0.5 shows one and 0.05 two. */
    private fun decimals(step: Double): Int =
        java.math.BigDecimal(step.toFloat().toString()).stripTrailingZeros().scale().coerceIn(0, 6)

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

    /**
     * A value from Home Assistant arrives as a float, so it is handed over at
     * float precision: 0.3 stays 0.3 instead of 0.30000001192092896.
     */
    @Synchronized fun number(key: String, value: Any?): Map<String, Any> {
        check(!closed) { "Plugin session has ended" }
        val entity = entries["number.$key"] ?: error("Plugin number is not available")
        require(value is Number && fitsFloat(value.toDouble())) { "Number command must be a finite number" }
        val requested = value.toFloat().toString().toDouble()
        require(inRange(requested, entity["min"] as Double, entity["max"] as Double)) { "Number is outside its min and max" }
        return mapOf("value" to requested)
    }

    @Synchronized fun switchCommand(key: String, on: Any?): Map<String, Any> {
        check(!closed) { "Plugin session has ended" }
        check("switch.$key" in entries) { "Plugin switch is not available" }
        require(on is Boolean) { "Switch command must be boolean" }
        return mapOf("on" to on)
    }

    @Synchronized fun remove(type: String, key: String) {
        check(!closed) { "Plugin session has ended" }
        budget()
        entries.remove("$type.$key")
    }
    @Synchronized fun snapshot(): List<Map<String, Any?>> = entries.values.toList()
    @Synchronized fun close() { closed = true; entries.clear() }
}
