package me.jxl.kiosk_satellite.plugins

import org.json.JSONObject

/** Host-owned action placements survive updates only for retained command IDs. */
internal object PluginActionOptions {
    fun retain(manifest: PluginManifest, previous: JSONObject?): JSONObject {
        val result = JSONObject()
        previous?.keys()?.asSequence()?.filter { manifest.hasCommand(it) }?.forEach { id ->
            previous.optJSONObject(id)?.let { result.put(id, JSONObject(it.toString())) }
        }
        return result
    }

    fun configure(manifest: PluginManifest, previous: JSONObject?, args: Map<String, Any?>): JSONObject {
        val command = args["command"] as? String ?: throw IllegalArgumentException("Missing command")
        require(manifest.hasCommand(command)) { "Unknown plugin command" }
        require(args["drawer"] is Boolean && args["homeAssistant"] is Boolean) { "Action placements must be booleans" }
        return retain(manifest, previous).put(command, JSONObject()
            .put("drawer", args["drawer"]).put("homeAssistant", args["homeAssistant"]))
    }
}
