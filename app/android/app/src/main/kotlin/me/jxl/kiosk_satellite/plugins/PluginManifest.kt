package me.jxl.kiosk_satellite.plugins

import org.json.JSONArray
import org.json.JSONObject

/** The SDK 1 package contract. Unknown capabilities never silently succeed. */
class PluginManifest(val json: JSONObject) {
    val apiVersion = json.getInt("apiVersion")
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
        require(apiVersion == 1) { "This plugin needs a different SDK version" }
        require(minAndroidSdk >= 24) { "Minimum Android SDK must be at least 24" }
        require(capabilities.all { it in setOf("overlay", "native", "entities", "host.read", "host.control", "shizuku", "screensaver") }) { "Unsupported plugin capability" }
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
            if (setting.has("description")) text(setting, "description", 400)
            if (setting.has("group")) text(setting, "group", 80)
            validateValue(setting, setting.get("default"))
        }
        require(!json.has("groups") || json.opt("groups") is JSONArray) { "Display groups must be an array" }
        val groups = json.optJSONArray("groups") ?: JSONArray()
        require(groups.length() <= 20) { "Too many display groups" }
        val groupNames = mutableSetOf<String>()
        val readingKeys = mutableSetOf<String>()
        val chartKeys = mutableSetOf<String>()
        val settingGroups = (0 until settings.length()).map { settings.getJSONObject(it).optString("group", "Settings") }.toSet()
        for (i in 0 until groups.length()) {
            val group = groups.getJSONObject(i)
            val title = text(group, "title", 80)
            require(title in settingGroups && groupNames.add(title)) { "Display groups must name unique settings groups" }
            if (group.has("readingsTitle")) text(group, "readingsTitle", 80)
            for ((kind, used, pattern, maximum) in listOf(
                GroupReferences("readings", readingKeys, "(sensor|text_sensor|binary_sensor|select|switch)\\.[a-z][a-z0-9_]{0,39}", 32),
                GroupReferences("charts", chartKeys, "[a-z][a-z0-9_]{0,39}", 4)
            )) {
                if (!group.has(kind)) continue
                val references = group.getJSONArray(kind)
                require(references.length() <= maximum) { "Too many group references" }
                for (j in 0 until references.length()) {
                    val reference = references.getString(j)
                    require(reference.matches(Regex(pattern)) && used.add(reference)) { "Invalid or duplicate group reference" }
                }
            }
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
            "entity" -> require(value is String && (value.isEmpty() || (value.length <= 255 && value.matches(Regex("[a-z0-9_]+\\.[a-z0-9_]+"))))) { "Expected a Home Assistant entity ID" }
            "boolean" -> require(value is Boolean) { "Expected a boolean setting" }
            "color" -> require(value is String && value.matches(Regex("#[a-fA-F0-9]{6}"))) { "Expected an RGB hex color" }
            "number" -> {
                require(value is Number) { "Expected a numeric setting" }
                val min = setting.getDouble("min")
                val max = setting.getDouble("max")
                val step = setting.optDouble("step", 1.0)
                val number = (value as Number).toDouble()
                require(min.isFinite() && max.isFinite() && min < max && step.isFinite() && step > 0 &&
                    (max - min) / step in 1.0..10000.0 && kotlin.math.abs((max - min) / step - kotlin.math.round((max - min) / step)) < 0.00001 && number.isFinite() && number in min..max) { "Numeric setting is outside its range" }
                require(kotlin.math.abs((number - min) / step - kotlin.math.round((number - min) / step)) < 0.00001) { "Numeric setting does not match its step" }
            }
            "select" -> {
                val options = setting.getJSONArray("options")
                require(options.length() in 1..32 && value is String) { "Invalid selection setting" }
                val choices = (0 until options.length()).map { options.getString(it) }
                require(choices.all { it.isNotBlank() && it.length <= 80 } && choices.toSet().size == choices.size && value in choices) { "Unknown selection option" }
            }
            else -> throw IllegalArgumentException("Unsupported setting type")
        }
    }

    private data class GroupReferences(val kind: String, val used: MutableSet<String>, val pattern: String, val maximum: Int)

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
