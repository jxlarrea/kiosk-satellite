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
    val triggers = json.optJSONArray("triggers") ?: JSONArray()
    /** Settings page buttons. Older apps ignore the key, so a plugin with buttons still installs there. */
    val buttons = json.optJSONArray("buttons") ?: JSONArray()
    val capabilities = json.getJSONArray("capabilities").let { array ->
        (0 until array.length()).map { array.getString(it) }.toSet()
    }
    /** The plugin runs on a device without a screen: it checks isHeadless() and skips its overlays and screensavers there. */
    val headless = json.opt("headless").let { value ->
        require(value == null || value is Boolean) { "Invalid headless" }
        value == true
    }
    /** The voice skin's picture in the Skin picker: an image under assets/, or null for the plugin mark. */
    val voiceSkinThumbnail: String? = json.opt("voiceSkinThumbnail").let { value ->
        if (value == null) return@let null
        require(value is String && PluginPackage.validAssetPath(value) && value.lowercase().substringAfterLast('.') in setOf("png", "jpg", "jpeg", "webp")) { "Invalid voiceSkinThumbnail" }
        require("voice.skin" in capabilities) { "voiceSkinThumbnail needs the voice.skin capability" }
        value
    }
    /** The plugin's icon: a 256 by 256 PNG under assets/ that Community Plugins shows, or null for the plugin mark. */
    val icon: String? = json.opt("icon").let { value ->
        if (value == null) return@let null
        require(value is String && PluginPackage.validAssetPath(value) && value.lowercase().endsWith(".png")) { "Invalid icon" }
        value
    }
    /** The oldest Kiosk Satellite release the plugin works on, such as 2026.10.40, or null for any release with SDK 1. */
    val minAppVersion: String? = json.opt("minAppVersion").let { value ->
        if (value == null) return@let null
        require(value is String && value.matches(APP_VERSION)) { "Invalid minAppVersion" }
        value
    }
    /** Overlays and screensavers are all a device without a screen would load such a plugin for, unless it says otherwise. */
    val needsScreen get() = !headless && ("overlay" in capabilities || "screensaver" in capabilities)

    init {
        require(json.getInt("schemaVersion") == 1) { "Unsupported manifest schema" }
        require(apiVersion == 1) { "This plugin needs a different SDK version" }
        require(minAndroidSdk >= 24) { "Minimum Android SDK must be at least 24" }
        require(capabilities.all { it in setOf("overlay", "native", "entities", "host.read", "host.control", "shizuku", "screensaver", "noise", "ha", "voice.skin", "voice.text", "camera", "barcode", "ma", "screensaver.mode") }) { "Unsupported plugin capability" }
        // The room's noise level and the conversation's words are host reads, opted into on their own.
        require("noise" !in capabilities || "host.read" in capabilities) { "Unsupported plugin capability" }
        require("voice.text" !in capabilities || "host.read" in capabilities) { "Unsupported plugin capability" }
        // A voice skin draws overlays and follows the turn it draws.
        require("voice.skin" !in capabilities || ("overlay" in capabilities && "host.read" in capabilities)) { "Unsupported plugin capability" }
        text(json, "description", 1000)
        text(json, "author", 120)
        text(json, "license", 120)
        require(settings.length() <= MAX_SETTINGS) { "Too many settings" }
        require(commands.length() <= 20) { "Too many commands" }
        require(triggers.length() <= 20) { "Too many triggers" }
        require(buttons.length() <= MAX_BUTTONS) { "Too many buttons" }
        validateFields(settings, 0)
        for (i in 0 until settings.length()) {
            val setting = settings.getJSONObject(i)
            if (setting.has("group")) text(setting, "group", 80)
        }
        validateButtons()
        require(!json.has("groups") || json.opt("groups") is JSONArray) { "Display groups must be an array" }
        val groups = json.optJSONArray("groups") ?: JSONArray()
        require(groups.length() <= 20) { "Too many display groups" }
        val groupNames = mutableSetOf<String>()
        val readingKeys = mutableSetOf<String>()
        val chartKeys = mutableSetOf<String>()
        val settingGroups = (0 until settings.length()).map { settings.getJSONObject(it).optString("group", "Settings") }.toSet() +
            (0 until buttons.length()).map { buttons.getJSONObject(it).optString("group", "Settings") }
        for (i in 0 until groups.length()) {
            val group = groups.getJSONObject(i)
            val title = text(group, "title", 80)
            require(title in settingGroups && groupNames.add(title)) { "Display groups must name unique settings groups" }
            if (group.has("readingsTitle")) text(group, "readingsTitle", 80)
            // "*" claims what no other group names, and "sensor.*" every reading of one type, for keys only
            // known at runtime.
            for ((kind, used, pattern, maximum) in listOf(
                GroupReferences("readings", readingKeys, "\\*|(sensor|text_sensor|binary_sensor|select|switch)\\.([a-z][a-z0-9_]{0,39}|\\*)", 32),
                GroupReferences("charts", chartKeys, "\\*|[a-z][a-z0-9_]{0,39}", 4)
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
        val triggerIds = mutableSetOf<String>()
        for (i in 0 until triggers.length()) {
            val trigger = triggers.getJSONObject(i)
            val triggerId = text(trigger, "id", 64)
            require(triggerId.matches(Regex("[a-z][a-zA-Z0-9]*")) && triggerIds.add(triggerId)) { "Invalid or duplicate trigger ID" }
            text(trigger, "title", 80)
        }
    }

    /**
     * The complete validated settings, the way the plugin receives them. A list arrives as an
     * unmodifiable `List` of `Map` rows, with every field filled in.
     */
    fun config(overrides: JSONObject): Map<String, Any> {
        val allowed = (0 until settings.length()).map { settings.getJSONObject(it).getString("key") }.toSet()
        require(overrides.keys().asSequence().all { it in allowed }) { "Unknown plugin setting" }
        val filled = JSONObject()
        for (i in 0 until settings.length()) {
            val setting = settings.getJSONObject(i)
            val key = setting.getString("key")
            filled.put(key, if (overrides.has(key)) overrides.get(key) else setting.get("default"))
        }
        val normalized = normalizeRow(settings, filled)
        return (0 until settings.length()).associate { i ->
            val key = settings.getJSONObject(i).getString("key")
            key to pluginValue(normalized.get(key))
        }
    }

    /**
     * Top-level settings that are, or hold, an action. Only the user picks an action: a plugin's own writes keep
     * these as they are saved, so a plugin decides when an action runs and never what it does.
     */
    val actionKeys: Set<String> = topLevel.filterValues(::holdsAction).keys

    private fun holdsAction(field: JSONObject): Boolean = when (field.getString("type")) {
        "action" -> true
        "list" -> field.getJSONArray("fields").let { fields -> (0 until fields.length()).any { holdsAction(fields.getJSONObject(it)) } }
        else -> false
    }

    /** [values] with each of [actionKeys] put back to its value in [saved]. */
    fun keepActions(values: JSONObject, saved: JSONObject): JSONObject = JSONObject(values.toString()).also { kept ->
        for (key in actionKeys) if (saved.has(key)) kept.put(key, saved.get(key)) else kept.remove(key)
    }

    /**
     * Whether [path] names an action setting: its key, or for a list row field the list key, a row index and the
     * field key, such as `items.2.action`.
     */
    fun isActionPath(path: String) = actionField(path, null) != null

    /** The action saved at [path] in [config], `{}` when none is chosen, or null when the row is missing. */
    fun action(config: JSONObject, path: String): JSONObject? = actionField(path, config)?.let { it as? JSONObject }

    /** Walks [path] through the declared settings and, with [config], the saved rows. Returns the value at the end, or Unit without [config]. */
    private fun actionField(path: String, config: JSONObject?): Any? {
        if (path.length > 200) return null
        val parts = path.split('.')
        var fields = topLevel
        var values = config
        var i = 0
        while (i < parts.size) {
            val field = fields[parts[i]] ?: return null
            when (field.getString("type")) {
                "action" -> {
                    if (i != parts.size - 1) return null
                    return if (values == null) Unit else values.opt(parts[i])
                }
                "list" -> {
                    val row = parts.getOrNull(i + 1)?.takeIf { it.matches(Regex("0|[1-9][0-9]?")) }?.toInt() ?: return null
                    if (values != null) values = (values.opt(parts[i]) as? JSONArray)?.optJSONObject(row) ?: return null
                    val rowFields = field.getJSONArray("fields")
                    fields = (0 until rowFields.length()).associate { rowFields.getJSONObject(it).let { f -> f.getString("key") to f } }
                    i += 2
                }
                else -> return null
            }
        }
        return null
    }

    /** Keys of the settings that admin listings mask. */
    val secretKeys: Set<String> = (0 until settings.length()).map { settings.getJSONObject(it) }
        .filter { it.getString("type") == "secret" }.map { it.getString("key") }.toSet()

    /** A saved config with each secret replaced by [SECRET_SET] or an empty string. */
    fun masked(config: JSONObject): JSONObject = JSONObject(config.toString()).also { masked ->
        for (key in secretKeys) if (masked.has(key)) masked.put(key, if (masked.optString(key).isEmpty()) "" else SECRET_SET)
    }

    /**
     * Admin edits send the masked listing back. A secret that is omitted or
     * still reads [SECRET_SET] keeps its saved value.
     */
    fun unmasked(values: JSONObject, saved: JSONObject): JSONObject = JSONObject(values.toString()).also { merged ->
        for (key in secretKeys) {
            if (merged.has(key) && merged.opt(key) != SECRET_SET) continue
            if (saved.has(key)) merged.put(key, saved.get(key)) else merged.remove(key)
        }
    }

    /**
     * The string settings and list row fields whose choices the plugin publishes. A row field
     * goes by the dotted path of keys from its top-level list, such as `panels.tiles.sensor`.
     */
    val choiceKeys: Set<String> = choicePaths(settings, "")

    private fun choicePaths(fields: JSONArray, prefix: String): Set<String> = (0 until fields.length()).flatMap { i ->
        val field = fields.getJSONObject(i)
        val path = prefix + field.getString("key")
        when {
            field.has("choices") -> listOf(path)
            field.getString("type") == "list" -> choicePaths(field.getJSONArray("fields"), "$path.")
            else -> emptyList()
        }
    }.toSet()

    fun hasButton(id: String) = button(id) != null

    /** Whether a button or a top-level setting shows with the saved [config]. */
    fun buttonVisible(id: String, config: JSONObject) = button(id)?.let { visible(it, config, topLevel) } == true
    fun settingVisible(key: String, config: JSONObject) = topLevel[key]?.let { visible(it, config, topLevel) } == true

    /** Whether the choices at [path] can be refreshed: the setting, or the list holding the row field, shows. */
    fun choicesVisible(path: String, config: JSONObject) = path in choiceKeys && settingVisible(path.substringBefore('.'), config)

    /**
     * The saved settings with [values] written over them. Keys left out keep
     * their saved value, secrets included. The result still goes through [config].
     */
    fun merged(saved: JSONObject, values: JSONObject): JSONObject = JSONObject(saved.toString()).also { merged ->
        for (key in values.keys()) merged.put(key, values.get(key))
    }

    /**
     * The saved settings a new version of the plugin keeps: the settings it still declares, with list rows keeping
     * only the fields it still declares. A setting whose type changed still fails in [config].
     */
    fun kept(saved: JSONObject): JSONObject = JSONObject().also { kept ->
        for ((key, setting) in topLevel) if (saved.has(key)) kept.put(key, keptValue(setting, saved.get(key)))
    }

    private fun keptValue(setting: JSONObject, value: Any): Any {
        if (setting.getString("type") != "list" || value !is JSONArray) return value
        val fields = setting.getJSONArray("fields")
        val byKey = (0 until fields.length()).associate { fields.getJSONObject(it).let { f -> f.getString("key") to f } }
        return JSONArray().also { rows ->
            for (i in 0 until value.length()) {
                val row = value.get(i)
                if (row !is JSONObject) rows.put(row)
                else rows.put(JSONObject().also { out -> for ((key, field) in byKey) if (row.has(key)) out.put(key, keptValue(field, row.get(key))) })
            }
        }
    }

    /** Checks each value in [values] against its own setting, leaving out rules that depend on other settings. */
    fun checkValues(values: JSONObject) {
        val fields = topLevel
        for (key in values.keys()) normalize(fields[key] ?: throw IllegalArgumentException("Unknown plugin setting"), values.get(key), enforce = false)
    }

    private val topLevel get() = (0 until settings.length()).associate { settings.getJSONObject(it).let { f -> f.getString("key") to f } }
    private fun button(id: String) = (0 until buttons.length()).map { buttons.getJSONObject(it) }.firstOrNull { it.getString("id") == id }

    fun hasCommand(id: String) = (0 until commands.length()).any { commands.getJSONObject(it).getString("id") == id }
    fun hasTrigger(id: String) = (0 until triggers.length()).any { triggers.getJSONObject(it).getString("id") == id }

    /**
     * Checks one level of settings: the top level, or the fields of a list row. [depth] counts the
     * lists around it, so a top-level list may hold one nested list and no deeper. A condition can
     * only name a field declared before it, which keeps conditions from looping.
     */
    private fun validateFields(fields: JSONArray, depth: Int) {
        val earlier = mutableMapOf<String, JSONObject>()
        for (i in 0 until fields.length()) {
            val field = fields.getJSONObject(i)
            val key = text(field, "key", 64)
            require(key.matches(Regex("[a-zA-Z][a-zA-Z0-9_]*")) && key !in earlier) { "Invalid or duplicate setting key" }
            text(field, "title", 80)
            if (field.has("description")) text(field, "description", 400)
            val type = field.getString("type")
            require(depth == 0 || (type != "secret" && !field.has("group"))) { "Invalid list setting" }
            require(type != "list" || depth < 2) { "Invalid list setting" }
            if (field.has("required")) {
                require(depth > 0 && field.get("required") is Boolean && (type in TEXT_TYPES || type == "action")) { "Invalid list setting" }
            }
            if (field.has("visibleWhen")) validateCondition(field.get("visibleWhen"), earlier)
            // The plugin lists the choices at runtime, for a setting or a list row field alike.
            // Older apps show a setting's as a text field and reject a row field's.
            if (field.has("choices")) require(type == "string" && field.get("choices") == "plugin") { "Invalid choices setting" }
            // What the picker says before the plugin lists any choices, such as what to set up first.
            if (field.has("emptyText")) {
                require(field.has("choices")) { "Invalid choices setting" }
                text(field, "emptyText", 200)
            }
            // A number shows as a slider, or as a typed field for a wide range or an exact value.
            if (field.has("input")) require(type == "number" && field.get("input") in setOf("slider", "field")) { "Invalid input" }
            if (type == "list") validateList(field, depth)
            // Row fields may leave out their default. The type supplies one.
            normalize(field, if (depth == 0) field.get("default") else defaultOf(field), enforce = false)
            // A default in a published manifest is not a secret.
            require(type != "secret" || field.get("default") == "") { "Secret settings must default to an empty string" }
            // The user picks every action. A manifest cannot pick one in advance.
            require(type != "action" || (if (depth == 0) field.get("default") else defaultOf(field)).let { it is JSONObject && it.length() == 0 }) { "Action settings must default to {}" }
            earlier[key] = field
        }
    }

    /**
     * A button runs plugin code from the settings page. Its condition may name
     * any top-level setting, since buttons sit apart from the settings list.
     */
    private fun validateButtons() {
        val ids = mutableSetOf<String>()
        for (i in 0 until buttons.length()) {
            val button = buttons.get(i)
            require(button is JSONObject) { "Invalid button" }
            val id = text(button, "id", 64)
            require(id.matches(Regex("[a-z][a-zA-Z0-9]*")) && ids.add(id)) { "Invalid or duplicate button ID" }
            text(button, "title", 80)
            text(button, "label", 40)
            if (button.has("description")) text(button, "description", 400)
            if (button.has("group")) text(button, "group", 80)
            if (button.has("visibleWhen")) validateCondition(button.get("visibleWhen"), topLevel)
            if (button.has("confirm")) {
                val confirm = button.get("confirm")
                require(confirm is JSONObject && confirm.keys().asSequence().all { it in setOf("title", "message", "confirmLabel") }) { "Invalid button confirmation" }
                text(confirm, "title", 80)
                text(confirm, "message", 1000)
                text(confirm, "confirmLabel", 40)
            }
        }
    }

    private fun validateList(field: JSONObject, depth: Int) {
        val fields = field.opt("fields")
        require(fields is JSONArray && fields.length() in 1..MAX_LIST_FIELDS) { "Invalid list setting" }
        validateFields(fields, depth + 1)
        val byKey = (0 until fields.length()).associate { fields.getJSONObject(it).let { f -> f.getString("key") to f } }
        if (field.has("maxItems")) require(field.get("maxItems").let { it is Int && it in 1..MAX_LIST_ITEMS }) { "Invalid list setting" }
        if (field.has("minItems")) require(field.get("minItems").let { it is Int && it in 0..maxItems(field) }) { "Invalid list setting" }
        if (field.has("addTitle")) text(field, "addTitle", 40)
        if (field.has("duplicate")) require(field.get("duplicate") is Boolean) { "Invalid list setting" }
        val row = field.opt("row") ?: return
        require(row is JSONObject && row.keys().asSequence().all { it in setOf("title", "subtitle", "icon") }) { "Invalid list setting" }
        fun shown(key: Any?) = key is String && byKey[key]?.getString("type").let { it != null && it != "list" }
        // A row's title is text. An action can name a row's second line, by what it does.
        if (row.has("title")) require(shown(row.get("title")) && byKey[row.get("title")]?.getString("type") != "action") { "Invalid list setting" }
        if (row.has("icon")) require(byKey[row.opt("icon") as? String]?.getString("type") == "icon") { "Invalid list setting" }
        if (row.has("subtitle")) {
            val subtitle = row.get("subtitle")
            val keys = if (subtitle is JSONArray) (0 until subtitle.length()).map { subtitle.get(it) } else listOf(subtitle)
            require(keys.size in 1..4 && keys.all(::shown)) { "Invalid list setting" }
        }
    }

    private fun validateCondition(condition: Any, earlier: Map<String, JSONObject>) {
        require(condition is JSONObject) { "Invalid setting condition" }
        val target = earlier[condition.opt("key") as? String]
        require(target != null && target.getString("type") !in setOf("list", "secret", "action")) { "Invalid setting condition" }
        val tests = condition.keys().asSequence().filter { it != "key" }.toList()
        require(tests.size == 1 && tests[0] in setOf("equals", "notEquals", "notEmpty")) { "Invalid setting condition" }
        if (tests[0] == "notEmpty") {
            require(condition.get("notEmpty") == true) { "Invalid setting condition" }
            return
        }
        val expected = expectedValues(condition.get(tests[0]))
        require(expected.size in 1..32 && expected.all { it is String || it is Boolean || it is Number }) { "Invalid setting condition" }
    }

    /** Whether [field] shows, given the other values on its level. A field under a hidden one hides too. */
    private fun visible(field: JSONObject, values: JSONObject, fields: Map<String, JSONObject>): Boolean {
        val condition = field.optJSONObject("visibleWhen") ?: return true
        val target = fields.getValue(condition.getString("key"))
        if (!visible(target, values, fields)) return false
        val value = values.opt(target.getString("key"))
        return when {
            condition.has("notEmpty") -> when (value) {
                is String -> value.isNotEmpty()
                is Boolean -> value
                else -> value != null && value != JSONObject.NULL
            }
            condition.has("equals") -> expectedValues(condition.get("equals")).any { same(value, it) }
            else -> expectedValues(condition.get("notEquals")).none { same(value, it) }
        }
    }

    private fun expectedValues(value: Any): List<Any> =
        if (value is JSONArray) (0 until value.length()).map { value.get(it) } else listOf(value)

    private fun same(value: Any?, expected: Any) =
        if (value is Number && expected is Number) value.toDouble() == expected.toDouble() else value == expected

    /**
     * Validates [value] for [setting] and returns it in its stored form. A list comes back as a
     * JSONArray of complete rows. [enforce] applies the checks that only count while the setting
     * shows: a required field must be filled in, a list must have its minimum number of rows.
     */
    private fun normalize(setting: JSONObject, value: Any, enforce: Boolean): Any {
        if (setting.getString("type") != "list") {
            val stored = if (value is Map<*, *>) JSONObject(value) else value
            validateValue(setting, stored)
            val empty = when (stored) {
                is String -> stored.isBlank()
                is JSONObject -> stored.length() == 0
                else -> false
            }
            if (enforce && setting.optBoolean("required") && empty) throw IllegalArgumentException("Fill in every required field")
            return stored
        }
        val rows = when (value) {
            is JSONArray -> value
            is Collection<*> -> JSONArray(value)
            else -> throw IllegalArgumentException("Expected a list setting")
        }
        val minimum = if (enforce) setting.optInt("minItems", 0) else 0
        require(rows.length() in minimum..maxItems(setting)) { "Too many or too few list items" }
        val fields = setting.getJSONArray("fields")
        val normalized = JSONArray()
        for (i in 0 until rows.length()) {
            val row = when (val raw = rows.get(i)) {
                is JSONObject -> raw
                is Map<*, *> -> JSONObject(raw)
                else -> throw IllegalArgumentException("Expected a list setting")
            }
            normalized.put(normalizeRow(fields, row))
        }
        require(normalized.toString().length <= MAX_LIST_CHARS) { "List settings must be at most 32 KB" }
        return normalized
    }

    /** One complete level of values, in field order: unknown keys rejected, missing ones defaulted. */
    private fun normalizeRow(fields: JSONArray, row: JSONObject): JSONObject {
        val byKey = (0 until fields.length()).associate { fields.getJSONObject(it).let { f -> f.getString("key") to f } }
        require(row.keys().asSequence().all { it in byKey }) { "Unknown plugin setting" }
        val filled = JSONObject()
        for ((key, field) in byKey) filled.put(key, if (row.has(key)) row.get(key) else defaultOf(field))
        val normalized = JSONObject()
        for ((key, field) in byKey) normalized.put(key, normalize(field, filled.get(key), visible(field, filled, byKey)))
        return normalized
    }

    /** A field's own default, or its type's when a row field leaves it out. */
    private fun defaultOf(field: JSONObject): Any {
        if (field.has("default")) return field.get("default")
        return when (field.getString("type")) {
            "boolean" -> false
            "number" -> field.getDouble("min").let { if (it == Math.floor(it)) it.toLong() else it }
            "select" -> field.getJSONArray("options").getString(0)
            "color" -> "#FFFFFF"
            "list" -> JSONArray()
            "action" -> JSONObject()
            else -> ""
        }
    }

    private fun maxItems(setting: JSONObject) = setting.optInt("maxItems", MAX_LIST_ITEMS)

    /** The plugin's copy of a stored value, read-only like the settings map around it. */
    private fun pluginValue(value: Any): Any = when (value) {
        is JSONArray -> java.util.Collections.unmodifiableList((0 until value.length()).map { pluginValue(value.get(it)) })
        is JSONObject -> java.util.Collections.unmodifiableMap(LinkedHashMap<String, Any>().also { map ->
            for (key in value.keys()) map[key] = pluginValue(value.get(key))
        })
        else -> value
    }

    private fun validateValue(setting: JSONObject, value: Any) {
        when (setting.getString("type")) {
            "string", "secret" -> require(value is String && value.length <= 512) { "Text settings must be at most 512 characters" }
            "entity" -> require(value is String && (value.isEmpty() || (value.length <= 255 && value.matches(Regex("[a-z0-9_]+\\.[a-z0-9_]+"))))) { "Expected a Home Assistant entity ID" }
            "icon" -> require(value is String && (value.isEmpty() || (value.length <= 80 && value.matches(Regex("mdi:[a-z0-9]+(?:-[a-z0-9]+)*"))))) { "Expected an MDI icon name" }
            // The path Home Assistant navigates by, the way the dashboard picker stores it.
            "dashboard" -> require(value is String && (value.isEmpty() || (value.length <= 255 && value.matches(Regex("/?[A-Za-z0-9_.~-]+(?:/[A-Za-z0-9_.~-]+)*"))))) { "Expected a dashboard path" }
            "cameraView" -> require(value is String && (value.isEmpty() || value.matches(Regex("[A-Za-z0-9_-]{1,64}")))) { "Expected a camera view ID" }
            // What the user picked in the action chooser, the object a gesture runs, or {} for none.
            "action" -> require(value is JSONObject && validAction(value)) { "Expected an action" }
            "boolean" -> require(value is Boolean) { "Expected a boolean setting" }
            "color" -> require(value is String && value.matches(Regex("#[a-fA-F0-9]{6}"))) { "Expected an RGB hex color" }
            "number" -> {
                require(value is Number) { "Expected a numeric setting" }
                val min = setting.getDouble("min")
                val max = setting.getDouble("max")
                val step = setting.optDouble("step", 1.0)
                val number = (value as Number).toDouble()
                // A slider has at most 10000 stops and ends on one. A typed field has no such limit.
                val steps = (max - min) / step
                val slider = setting.optString("input", "slider") == "slider"
                require(min.isFinite() && max.isFinite() && min < max && step.isFinite() && step > 0 &&
                    (!slider || (steps in 1.0..10000.0 && kotlin.math.abs(steps - kotlin.math.round(steps)) < 0.00001)) && number.isFinite() && number in min..max) { "Numeric setting is outside its range" }
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

    private fun validAction(value: JSONObject): Boolean {
        if (value.length() == 0) return true
        val keys = value.keys().asSequence().toList()
        return keys.size <= 16 && keys.all { it.matches(Regex("[a-zA-Z][a-zA-Z0-9_]{0,31}")) } &&
            (value.opt("type") as? String)?.matches(Regex("[a-z][a-z_]{0,31}")) == true &&
            value.toString().length <= MAX_ACTION_CHARS
    }

    private data class GroupReferences(val kind: String, val used: MutableSet<String>, val pattern: String, val maximum: Int)

    companion object {
        /** Settings per plugin. Display groups keep a long list navigable. */
        const val MAX_SETTINGS = 50
        const val MAX_BUTTONS = 20
        /** A list counts as one setting. These bound its rows. */
        const val MAX_LIST_FIELDS = 16
        const val MAX_LIST_ITEMS = 32
        const val MAX_LIST_CHARS = 32 * 1024
        /** An action holds a few IDs, or a service call with its data. */
        const val MAX_ACTION_CHARS = 4096
        /** The types a list field can mark as required. */
        val TEXT_TYPES = setOf("string", "entity", "icon", "dashboard", "cameraView")
        /** Stands in for a saved secret, the same marker core password settings use. */
        const val SECRET_SET = "__set__"
        /** A Kiosk Satellite release: year, month and the release within the month, without padding. */
        private val APP_VERSION = Regex("[0-9]{4}\\.(?:[1-9]|1[0-2])\\.(?:0|[1-9][0-9]{0,3})")

        /**
         * Whether the running release [current], such as 2026.10.39 or a
         * build of it, is [required] or newer. A version that is not a
         * release, such as a local build's, never holds a plugin back.
         */
        fun appVersionAtLeast(current: String, required: String): Boolean {
            val running = Regex("^([0-9]+)\\.([0-9]+)\\.([0-9]+)").find(current)?.groupValues?.drop(1)?.map { it.toLong() } ?: return true
            val needed = required.split('.').map { it.toLong() }
            for (i in 0 until 3) if (running[i] != needed[i]) return running[i] > needed[i]
            return true
        }

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
