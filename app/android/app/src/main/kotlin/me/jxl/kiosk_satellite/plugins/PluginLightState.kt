package me.jxl.kiosk_satellite.plugins

/** Validated RGB state shared by plugin UI and the ESPHome entity surface. */
internal object PluginLightState {
    fun validate(state: Map<String, Any>, effects: List<String>): Map<String, Any> {
        require(state.keys.all { it in setOf("on", "brightness", "red", "green", "blue", "effect") }) { "Unknown light state field" }
        require(state["on"] is Boolean) { "Light state needs on" }
        val result = mutableMapOf<String, Any>("on" to state["on"]!!)
        for (key in listOf("brightness", "red", "green", "blue")) {
            val value = (state[key] as? Number)?.toDouble() ?: throw IllegalArgumentException("Missing light $key")
            require(value.isFinite() && value in 0.0..1.0) { "Invalid light $key" }
            result[key] = value
        }
        val effect = state["effect"] as? String ?: "None"
        require(effect == "None" || effect in effects) { "Unknown light effect" }
        result["effect"] = effect
        return result
    }
}
