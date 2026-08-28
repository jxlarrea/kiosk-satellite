package me.jxl.kiosk_satellite.btproxy

/**
 * Native-API entities: the kiosk's own sensors and controls, served over the
 * same ESPHome connection the Bluetooth proxy already holds (issue: phase
 * out the MQTT broker requirement).
 *
 * The Dart side owns the catalog - which entities exist, their current
 * values, and what a command does. This layer only speaks the wire format:
 * ListEntities descriptions, state responses, and command requests, exactly
 * as an ESP32 with the matching YAML would. Entity keys are a stable hash of
 * the object id, so they survive restarts and reinstalls (Home Assistant
 * addresses entities by key within the device).
 *
 * The entity set is fixed for the lifetime of one server run: changing it
 * (settings) restarts the proxy, and Home Assistant re-lists on reconnect.
 */
internal sealed class EspEntity {
    abstract val objectId: String
    abstract val name: String
    abstract val icon: String
    abstract val deviceClass: String

    /** 0 = none, 1 = config, 2 = diagnostic (api.proto EntityCategory). */
    abstract val category: Int
    abstract val disabledByDefault: Boolean

    /** FNV-1a over the object id: stable across runs, unique enough. */
    val key: Int get() = fnv1a(objectId)

    class Sensor(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val deviceClass: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
        val unit: String = "",
        /** 0 = none, 1 = measurement, 2 = total_increasing, 3 = total. */
        val stateClass: Int = 0,
        val accuracyDecimals: Int = 0,
    ) : EspEntity()

    class BinarySensor(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val deviceClass: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
    ) : EspEntity()

    class TextSensor(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val deviceClass: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
    ) : EspEntity()

    class Switch(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val deviceClass: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
        val assumedState: Boolean = false,
    ) : EspEntity()

    class Number(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val deviceClass: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
        val min: Float = 0f,
        val max: Float = 100f,
        val step: Float = 1f,
        val unit: String = "",
        /** 0 = auto, 1 = box, 2 = slider (api.proto NumberMode). */
        val mode: Int = 0,
    ) : EspEntity()

    class Select(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
        val options: List<String> = emptyList(),
    ) : EspEntity() {
        override val deviceClass: String get() = ""
    }

    class Button(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val deviceClass: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
    ) : EspEntity()

    /**
     * On/off plus brightness, declared through the legacy capability flag:
     * the modern color-modes vocabulary buys nothing for a screen and the
     * legacy path is the one every old ESP32 exercises daily.
     * State value: map {on: Bool, brightness: Double 0..1}.
     * Command value: map with the fields the client sent.
     */
    class Light(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
    ) : EspEntity() {
        override val deviceClass: String get() = ""
    }

    /** A free-text config value. State/command value: String. */
    class Text(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
        val maxLength: Int = 255,
    ) : EspEntity() {
        override val deviceClass: String get() = ""
    }

    /**
     * The app-update entity. State value: map {current, latest, title,
     * summary, url: String, progress: Double?, inProgress: Bool}.
     * Command value delivered as "install" or "check".
     */
    class Update(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val deviceClass: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
    ) : EspEntity()

    /**
     * A still camera. Images flow through [EntityHub.requestCameraImage]
     * and the server's chunked CameraImageResponse path, not through the
     * state store. A device may carry several: the image request has no
     * key (it asks every camera at once) but each response carries one,
     * and aioesphomeapi assembles frames per key, so every listed camera
     * must answer every request or the client entity that got nothing
     * times out.
     */
    class Camera(
        override val objectId: String,
        override val name: String,
        override val icon: String = "",
        override val category: Int = 0,
        override val disabledByDefault: Boolean = false,
    ) : EspEntity() {
        override val deviceClass: String get() = ""
    }

    companion object {
        fun fnv1a(s: String): Int {
            var hash = -2128831035 // 2166136261 as signed Int
            for (b in s.toByteArray(Charsets.UTF_8)) {
                hash = hash xor (b.toInt() and 0xFF)
                hash *= 16777619
            }
            return hash
        }

        /** Builds an entity from the map the Flutter bridge hands over. */
        fun fromMap(m: Map<*, *>): EspEntity {
            fun s(k: String) = (m[k] as? String) ?: ""
            // kotlin.Number spelled out: the Number entity class shadows it.
            fun i(k: String) = (m[k] as? kotlin.Number)?.toInt() ?: 0
            fun f(k: String, orElse: Float) =
                (m[k] as? kotlin.Number)?.toFloat() ?: orElse
            fun b(k: String) = m[k] == true
            val objectId = s("objectId")
            val name = s("name")
            require(objectId.isNotEmpty() && name.isNotEmpty()) {
                "entity needs objectId and name"
            }
            return when (val type = s("type")) {
                "sensor" -> Sensor(objectId, name, s("icon"), s("deviceClass"),
                    i("category"), b("disabled"), s("unit"), i("stateClass"),
                    i("accuracyDecimals"))
                "binary_sensor" -> BinarySensor(objectId, name, s("icon"),
                    s("deviceClass"), i("category"), b("disabled"))
                "text_sensor" -> TextSensor(objectId, name, s("icon"),
                    s("deviceClass"), i("category"), b("disabled"))
                "switch" -> Switch(objectId, name, s("icon"), s("deviceClass"),
                    i("category"), b("disabled"), b("assumedState"))
                "number" -> Number(objectId, name, s("icon"), s("deviceClass"),
                    i("category"), b("disabled"), f("min", 0f), f("max", 100f),
                    f("step", 1f), s("unit"), i("mode"))
                "select" -> Select(objectId, name, s("icon"), i("category"),
                    b("disabled"),
                    (m["options"] as? List<*>)?.map { "$it" } ?: emptyList())
                "button" -> Button(objectId, name, s("icon"), s("deviceClass"),
                    i("category"), b("disabled"))
                "light" -> Light(objectId, name, s("icon"), i("category"),
                    b("disabled"))
                "text" -> Text(objectId, name, s("icon"), i("category"),
                    b("disabled"),
                    (m["maxLength"] as? kotlin.Number)?.toInt() ?: 255)
                "update" -> Update(objectId, name, s("icon"), s("deviceClass"),
                    i("category"), b("disabled"))
                "camera" -> Camera(objectId, name, s("icon"), i("category"),
                    b("disabled"))
                else -> throw IllegalArgumentException("unknown entity type '$type'")
            }
        }
    }
}

/** Wire encodings for entity descriptions, states and commands. */
internal object EntityCodec {

    /** (message type, payload) for one entity's ListEntities description. */
    fun describe(entity: EspEntity, uniquePrefix: String): Pair<Int, ByteArray> {
        val w = ProtoWriter()
        w.string(1, entity.objectId)
        w.fixed32(2, entity.key)
        w.string(3, entity.name)
        w.string(4, "$uniquePrefix-${entity.objectId}")
        return when (entity) {
            is EspEntity.BinarySensor -> {
                w.string(5, entity.deviceClass)
                w.bool(7, entity.disabledByDefault)
                w.string(8, entity.icon)
                w.varint(9, entity.category)
                Msg.LIST_ENTITIES_BINARY_SENSOR_RESPONSE to w.toByteArray()
            }
            is EspEntity.Sensor -> {
                w.string(5, entity.icon)
                w.string(6, entity.unit)
                w.varint(7, entity.accuracyDecimals)
                w.string(9, entity.deviceClass)
                w.varint(10, entity.stateClass)
                w.bool(12, entity.disabledByDefault)
                w.varint(13, entity.category)
                Msg.LIST_ENTITIES_SENSOR_RESPONSE to w.toByteArray()
            }
            is EspEntity.Switch -> {
                w.string(5, entity.icon)
                w.bool(6, entity.assumedState)
                w.bool(7, entity.disabledByDefault)
                w.varint(8, entity.category)
                w.string(9, entity.deviceClass)
                Msg.LIST_ENTITIES_SWITCH_RESPONSE to w.toByteArray()
            }
            is EspEntity.TextSensor -> {
                w.string(5, entity.icon)
                w.bool(6, entity.disabledByDefault)
                w.varint(7, entity.category)
                w.string(8, entity.deviceClass)
                Msg.LIST_ENTITIES_TEXT_SENSOR_RESPONSE to w.toByteArray()
            }
            is EspEntity.Number -> {
                w.string(5, entity.icon)
                w.float(6, entity.min)
                w.float(7, entity.max)
                w.float(8, entity.step)
                w.bool(9, entity.disabledByDefault)
                w.varint(10, entity.category)
                w.string(11, entity.unit)
                w.varint(12, entity.mode)
                w.string(13, entity.deviceClass)
                Msg.LIST_ENTITIES_NUMBER_RESPONSE to w.toByteArray()
            }
            is EspEntity.Select -> {
                w.string(5, entity.icon)
                for (option in entity.options) w.string(6, option)
                w.bool(7, entity.disabledByDefault)
                w.varint(8, entity.category)
                Msg.LIST_ENTITIES_SELECT_RESPONSE to w.toByteArray()
            }
            is EspEntity.Button -> {
                w.string(5, entity.icon)
                w.bool(6, entity.disabledByDefault)
                w.varint(7, entity.category)
                w.string(8, entity.deviceClass)
                Msg.LIST_ENTITIES_BUTTON_RESPONSE to w.toByteArray()
            }
            is EspEntity.Light -> {
                // Legacy brightness capability only: HA still speaks the
                // pre-color-modes dialect for every old ESP32, and a screen
                // needs nothing richer.
                w.bool(5, true) // legacy_supports_brightness, pre-1.6 clients
                // supported_color_modes: modern Home Assistant IGNORES the
                // legacy field whenever the API version is 1.6+, so without
                // this the light renders as bare on/off (issue #242).
                // COLOR_MODE_BRIGHTNESS (3) carries the on/off bit too.
                w.varint(12, 3)
                w.bool(13, entity.disabledByDefault)
                w.string(14, entity.icon)
                w.varint(15, entity.category)
                Msg.LIST_ENTITIES_LIGHT_RESPONSE to w.toByteArray()
            }
            is EspEntity.Text -> {
                w.string(5, entity.icon)
                w.bool(6, entity.disabledByDefault)
                w.varint(7, entity.category)
                w.varint(9, entity.maxLength)
                Msg.LIST_ENTITIES_TEXT_RESPONSE to w.toByteArray()
            }
            is EspEntity.Update -> {
                w.string(5, entity.icon)
                w.bool(6, entity.disabledByDefault)
                w.varint(7, entity.category)
                w.string(8, entity.deviceClass)
                Msg.LIST_ENTITIES_UPDATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.Camera -> {
                w.bool(5, entity.disabledByDefault)
                w.string(6, entity.icon)
                w.varint(7, entity.category)
                Msg.LIST_ENTITIES_CAMERA_RESPONSE to w.toByteArray()
            }
        }
    }

    /**
     * (message type, payload) for an entity's current state, or null for
     * types with no state (buttons) and for never-set values (a state
     * message would assert a value; missing_state says "no reading yet").
     */
    fun state(entity: EspEntity, value: Any?): Pair<Int, ByteArray>? {
        val w = ProtoWriter()
        w.fixed32(1, entity.key)
        return when (entity) {
            is EspEntity.Button -> null
            is EspEntity.Sensor -> {
                if (value == null) w.bool(3, true)
                else w.float(2, (value as Number).toFloat())
                Msg.SENSOR_STATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.Number -> {
                if (value == null) w.bool(3, true)
                else w.float(2, (value as Number).toFloat())
                Msg.NUMBER_STATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.BinarySensor -> {
                if (value == null) w.bool(3, true) else w.bool(2, value == true)
                Msg.BINARY_SENSOR_STATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.Switch -> {
                if (value == null) return null // switches have no missing_state
                w.bool(2, value == true)
                Msg.SWITCH_STATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.TextSensor -> {
                if (value == null) w.bool(3, true) else w.string(2, "$value")
                Msg.TEXT_SENSOR_STATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.Select -> {
                if (value == null) w.bool(3, true) else w.string(2, "$value")
                Msg.SELECT_STATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.Light -> {
                val map = value as? Map<*, *> ?: return null
                w.bool(2, map["on"] == true)
                (map["brightness"] as? kotlin.Number)?.let {
                    w.float(3, it.toFloat())
                }
                // color_mode: matches the single mode the description
                // advertises; a color-mode client shows the brightness
                // slider only when the state claims the mode (issue #242).
                w.varint(11, 3)
                Msg.LIGHT_STATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.Text -> {
                if (value == null) w.bool(3, true) else w.string(2, "$value")
                Msg.TEXT_STATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.Update -> {
                val map = value as? Map<*, *>
                if (map == null) {
                    w.bool(2, true) // missing_state
                } else {
                    w.bool(3, map["inProgress"] == true)
                    (map["progress"] as? kotlin.Number)?.let {
                        w.bool(4, true)
                        w.float(5, it.toFloat())
                    }
                    w.string(6, "${map["current"] ?: ""}")
                    w.string(7, "${map["latest"] ?: ""}")
                    w.string(8, "${map["title"] ?: ""}")
                    w.string(9, "${map["summary"] ?: ""}")
                    w.string(10, "${map["url"] ?: ""}")
                }
                Msg.UPDATE_STATE_RESPONSE to w.toByteArray()
            }
            is EspEntity.Camera -> null // images ride their own path
        }
    }

    class Command(val key: Int, val value: Any?)

    /** Parses a command request; null for message types that are not commands. */
    fun parseCommand(type: Int, payload: ByteArray): Command? {
        var key = 0
        var boolValue = false
        var floatValue = 0f
        var stringValue = ""
        // LightCommandRequest's has_/value pairs and Update's command enum.
        var hasState = false
        var lightOn = false
        var hasBrightness = false
        var brightness = 0f
        var updateCommand = 0
        val r = ProtoReader(payload)
        while (r.next()) when (type) {
            Msg.LIGHT_COMMAND_REQUEST -> when (r.field) {
                1 -> key = r.asFixed32()
                2 -> hasState = r.asBool()
                3 -> lightOn = r.asBool()
                4 -> hasBrightness = r.asBool()
                5 -> brightness = r.asFloat()
            }
            Msg.UPDATE_COMMAND_REQUEST -> when (r.field) {
                1 -> key = r.asFixed32()
                2 -> updateCommand = r.asInt()
            }
            else -> when (r.field) {
                1 -> key = r.asFixed32()
                2 -> when (type) {
                    Msg.SWITCH_COMMAND_REQUEST -> boolValue = r.asBool()
                    Msg.NUMBER_COMMAND_REQUEST -> floatValue = r.asFloat()
                    Msg.SELECT_COMMAND_REQUEST,
                    Msg.TEXT_COMMAND_REQUEST -> stringValue = r.asString()
                }
            }
        }
        return when (type) {
            Msg.SWITCH_COMMAND_REQUEST -> Command(key, boolValue)
            Msg.NUMBER_COMMAND_REQUEST -> Command(key, floatValue)
            Msg.SELECT_COMMAND_REQUEST -> Command(key, stringValue)
            Msg.TEXT_COMMAND_REQUEST -> Command(key, stringValue)
            Msg.BUTTON_COMMAND_REQUEST -> Command(key, null)
            Msg.LIGHT_COMMAND_REQUEST -> Command(key, buildMap<String, Any> {
                if (hasState) put("on", lightOn)
                if (hasBrightness) put("brightness", brightness.toDouble())
            })
            Msg.UPDATE_COMMAND_REQUEST ->
                Command(key, if (updateCommand == 1) "install" else "check")
            else -> null
        }
    }
}

/**
 * The registry the server serves from: entity catalog, latest values, and
 * the command path back to the Dart side. Values arrive from the Flutter
 * main thread and are read from session reader threads; the lock keeps the
 * pair (catalog, values) consistent.
 */
internal class EntityHub(
    entities: List<EspEntity>,
    private val onCommand: (objectId: String, value: Any?) -> Unit,
    /** User-defined actions served alongside the entities (see EspServices). */
    val services: List<EspService> = emptyList(),
    /**
     * Where an action call lands: its name, its arguments by name, and the
     * reply to make once it has run (success, error message, JSON response
     * data). The reply is a no-op for calls that expect none.
     */
    private val onServiceCall: (
        name: String,
        args: Map<String, Any?>,
        reply: ServiceReply,
    ) -> Unit = { _, _, _ -> },
) {
    private val lock = Any()
    private val byKey = LinkedHashMap<Int, EspEntity>()
    private val values = HashMap<Int, Any?>()

    /** Fired on every state update; the server broadcasts to subscribers. */
    @Volatile
    var onStateChanged: ((EspEntity, Any?) -> Unit)? = null

    /** The camera entities, in catalog order; empty when there are none. */
    val cameras: List<EspEntity.Camera> = entities.filterIsInstance<EspEntity.Camera>()

    init {
        for (entity in entities) {
            val clash = byKey.put(entity.key, entity)
            require(clash == null) {
                "entity key collision: ${clash?.objectId} / ${entity.objectId}"
            }
        }
    }

    /** The camera with this object id, if the catalog carries one. */
    fun cameraFor(objectId: String): EspEntity.Camera? =
        cameras.firstOrNull { it.objectId == objectId }

    /**
     * A client asked for a frame. The request names no camera, so every
     * one is asked; the Dart side captures and pushes a frame per camera.
     */
    fun requestCameraImage() {
        for (camera in cameras) onCommand(camera.objectId, "capture")
    }

    val all: List<EspEntity>
        get() = synchronized(lock) { byKey.values.toList() }

    fun valueOf(entity: EspEntity): Any? = synchronized(lock) { values[entity.key] }

    fun updateState(objectId: String, value: Any?) {
        val entity = synchronized(lock) {
            val found = byKey.values.firstOrNull { it.objectId == objectId }
                ?: return
            values[found.key] = value
            found
        }
        onStateChanged?.invoke(entity, value)
    }

    fun dispatchCommand(command: EntityCodec.Command) {
        val entity = synchronized(lock) { byKey[command.key] } ?: return
        onCommand(entity.objectId, command.value)
    }

    /**
     * A Home Assistant action call: values arrive positionally and unnamed,
     * so the declaration is what turns them back into a map. A value the
     * client left at its protobuf default arrives as nothing at all; the
     * declared type says what that default was.
     */
    /**
     * Runs an action call. [respond] sends an ExecuteServiceResponse
     * payload back over the session it came in on; it is only ever used
     * when the call carried a call id, since a client that sent none is
     * not listening for one.
     */
    fun dispatchService(call: ServiceCodec.Call, respond: (ByteArray) -> Unit) {
        val service = services.firstOrNull { it.key == call.key } ?: return
        val args = LinkedHashMap<String, Any?>(service.args.size)
        service.args.forEachIndexed { index, arg ->
            val value = call.values.getOrNull(index) ?: when (arg.type) {
                EspService.BOOL -> false
                EspService.INT -> 0
                EspService.FLOAT -> 0f
                else -> ""
            }
            args[arg.name] = value
        }
        onServiceCall(service.name, args, replyFor(call, respond))
    }

    /** The reply for [call]: a no-op for a client that sent no call id. */
    private fun replyFor(
        call: ServiceCodec.Call,
        respond: (ByteArray) -> Unit,
    ): ServiceReply {
        if (call.callId == 0) return { _, _, _ -> }
        // Once: the Dart side answers exactly once, but a reply sent twice
        // would confuse the client's call-id matching.
        val answered = java.util.concurrent.atomic.AtomicBoolean(false)
        return { success, error, json ->
            if (answered.compareAndSet(false, true)) {
                respond(
                    ServiceCodec.response(
                        call.callId, success, error,
                        if (call.returnResponse) json else null,
                    ),
                )
            }
        }
    }
}

/** (success, error message, JSON response data); see EntityHub. */
internal typealias ServiceReply = (Boolean, String?, String?) -> Unit
