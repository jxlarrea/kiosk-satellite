package me.jxl.kiosk_satellite.plugins

import org.json.JSONArray
import org.json.JSONObject

/** The SDK 1 package contract. Unknown capabilities never silently succeed. */
class PluginManifest(val json: JSONObject) {
    val id: String = text(json, "id", 64).also {
        require(it.matches(Regex("[a-z][a-z0-9]*(?:-[a-z0-9]+)*"))) { "Invalid plugin ID" }
    }
    val name = text(json, "name", 80)
    val version = text(json, "version", 40).also {
        require(it.matches(Regex("[0-9]+\\.[0-9]+\\.[0-9]+(?:-[a-zA-Z0-9.-]+)?"))) { "Invalid version" }
    }
    val entryClass = text(json, "entryClass", 200).also {
        require(it.matches(Regex("[a-zA-Z_$][a-zA-Z0-9_$]*(?:\\.[a-zA-Z_$][a-zA-Z0-9_$]*)+"))) { "Invalid entry class" }
    }
    val minAndroidSdk = json.getInt("minAndroidSdk")
    val settings = json.optJSONArray("settings") ?: JSONArray()
    val commands = json.optJSONArray("commands") ?: JSONArray()
    val capabilities = json.getJSONArray("capabilities").let { array ->
        (0 until array.length()).map { array.getString(it) }.toSet()
    }

    init {
        require(json.getInt("schemaVersion") == 1) { "Unsupported manifest schema" }
        require(json.getInt("apiVersion") == 1) { "This plugin needs a different SDK version" }
        require(minAndroidSdk >= 24) { "Minimum Android SDK must be at least 24" }
        require(capabilities.all { it == "overlay" }) { "Unsupported plugin capability" }
        text(json, "description", 1000)
        text(json, "author", 120)
        text(json, "license", 120)
        require(settings.length() <= 20 && commands.length() <= 20) { "Too many settings or commands" }
        val keys = mutableSetOf<String>()
        for (i in 0 until settings.length()) {
            val setting = settings.getJSONObject(i)
            val key = text(setting, "key", 64)
            require(key.matches(Regex("[a-zA-Z][a-zA-Z0-9_]*")) && keys.add(key)) { "Invalid or duplicate setting key" }
            text(setting, "title", 80)
            validateValue(setting, setting.get("default"))
        }
        val ids = mutableSetOf<String>()
        for (i in 0 until commands.length()) {
            val command = commands.getJSONObject(i)
            val commandId = text(command, "id", 64)
            require(commandId.matches(Regex("[a-z][a-zA-Z0-9]*")) && ids.add(commandId)) { "Invalid or duplicate command ID" }
            text(command, "title", 80)
        }
    }

    fun config(overrides: JSONObject): Map<String, Any> {
        val allowed = (0 until settings.length()).map { settings.getJSONObject(it).getString("key") }.toSet()
        require(overrides.keys().asSequence().all { it in allowed }) { "Unknown plugin setting" }
        return (0 until settings.length()).associate { i ->
            val setting = settings.getJSONObject(i)
            val key = setting.getString("key")
            val value = if (overrides.has(key)) overrides.get(key) else setting.get("default")
            validateValue(setting, value)
            key to value
        }
    }

    fun hasCommand(id: String) = (0 until commands.length()).any { commands.getJSONObject(it).getString("id") == id }

    private fun validateValue(setting: JSONObject, value: Any) {
        when (setting.getString("type")) {
            "string" -> require(value is String && value.length <= 512) { "Text settings must be at most 512 characters" }
            "boolean" -> require(value is Boolean) { "Expected a boolean setting" }
            else -> throw IllegalArgumentException("Unsupported setting type")
        }
    }

    companion object {
        fun text(json: JSONObject, key: String, limit: Int): String {
            val value = json.get(key)
            require(value is String && value.isNotBlank() && value.length <= limit) { "Invalid $key" }
            return value
        }
    }
}

fun jsonValue(value: Any?): Any? = when (value) {
    JSONObject.NULL, null -> null
    is JSONObject -> value.keys().asSequence().associateWith { jsonValue(value.get(it)) }
    is JSONArray -> (0 until value.length()).map { jsonValue(value.get(it)) }
    else -> value
}
