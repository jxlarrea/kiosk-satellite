package me.jxl.kiosk_satellite.plugins

import org.json.JSONArray
import org.json.JSONObject

/** SDK event contract and per-session bounds for asynchronous commands. */
internal object PluginHostPolicy {
    fun entityEvent(event: String) = event.startsWith("ha.entity.") &&
        event.removePrefix("ha.entity.").let { it.length <= 255 && it.matches(Regex("[a-z0-9_]+\\.[a-z0-9_]+")) }
    fun validEvent(event: String) = event in events || entityEvent(event)
    val events = setOf(
        "screensaver.state", "screensaver.countdown", "screensaver.view", "screensaver.appearance",
        "screen.state", "screen.brightness", "screen.ambient",
        "device.power", "device.network", "device.volume", "device.light", "device.key",
        "detection.motion", "detection.face", "detection.proximity",
        "detection.person", "detection.presence", "voice.interaction", "voice.state", "intercom.state",
        "wakeword.state", "wakeword.detected", "stopword.detected", "camera.view", "browser.state",
        "audio.noise", "voice.text", "voice.level", "voice.overlay", "voice.skin", "voice.appearance",
        "sendspin.player",
    )

    /** The key of a Home Assistant subscription event, `ha.subscription.KEY`, or null. */
    fun haSubscriptionKey(event: String) = event.removePrefix("ha.subscription.").takeIf { it != event && haKey(it) }
    fun haKey(key: String) = key.matches(Regex("[A-Za-z0-9_.-]{1,64}"))

    /** The key of a Music Assistant subscription event, `ma.subscription.KEY`, or null. */
    fun maSubscriptionKey(event: String) = event.removePrefix("ma.subscription.").takeIf { it != event && haKey(it) }

    /**
     * A detached copy of a plugin's Home Assistant message with JSON values only, at most 32 KB encoded. The app
     * checks the message itself; this keeps what crosses the channel small and plain.
     */
    fun haMessage(message: Map<*, *>): Map<String, Any?> = jsonMessage(message, "Home Assistant message")

    /** The same for a Music Assistant command's args or a subscription's filter. */
    fun maMessage(message: Map<*, *>): Map<String, Any?> = jsonMessage(message, "Music Assistant request")

    private fun jsonMessage(message: Map<*, *>, label: String): Map<String, Any?> {
        @Suppress("UNCHECKED_CAST")
        val copy = json(message, 0, label) as Map<String, Any?>
        require(JSONObject(copy).toString().toByteArray().size <= 32_768) { "$label is larger than 32 KB" }
        return copy
    }

    private fun json(value: Any?, depth: Int, label: String): Any? {
        require(depth <= 32) { "$label is nested too deeply" }
        return when (value) {
            null, JSONObject.NULL -> null
            is String, is Boolean, is Int, is Long -> value
            is Number -> value.toDouble().also { require(it.isFinite()) { "$label holds finite numbers only" } }
            is Map<*, *> -> LinkedHashMap<String, Any?>().apply {
                for ((key, item) in value) {
                    require(key is String) { "$label keys must be strings" }
                    put(key, json(item, depth + 1, label))
                }
            }
            is Iterable<*> -> value.map { json(it, depth + 1, label) }
            is Array<*> -> value.map { json(it, depth + 1, label) }
            is JSONObject, is JSONArray -> json(jsonValue(value), depth, label)
            else -> throw IllegalArgumentException("$label holds JSON values only")
        }
    }

    /**
     * The `device.key` payload. Null for printing and modifier keys, so typed
     * text never reaches a plugin. [name] is Android's KEYCODE_ constant.
     */
    fun keyPayload(name: String, code: Int, scanCode: Int, down: Boolean, repeat: Int, printing: Boolean, modifier: Boolean, time: String): Map<String, Any>? =
        if (printing || modifier) null else mapOf(
            "key" to name.removePrefix("KEYCODE_"),
            "code" to code,
            "scanCode" to scanCode,
            "action" to if (down) "down" else "up",
            "repeat" to repeat,
            "time" to time,
        )
}

internal class PluginCommandBudget {
    private var windowStart: Long? = null
    private var count = 0
    private var pending = 0

    @Synchronized fun acquire(now: Long = System.nanoTime()) {
        if (windowStart == null || now - windowStart!! >= 1_000_000_000L) { windowStart = now; count = 0 }
        check(pending < 8) { "At most 8 KS commands may be pending" }
        check(count < 20) { "At most 20 KS commands per second" }
        pending++; count++
    }
    @Synchronized fun release() { if (pending > 0) pending-- }
}
