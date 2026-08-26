package me.jxl.kiosk_satellite.btproxy

/**
 * User-defined actions: the ESPHome API's one way for Home Assistant to
 * push a payload AT the device rather than set a value on an entity (an
 * ESP32 declares them under `api: actions:`). Home Assistant registers
 * each one as `esphome.<device name>_<action name>`, and an ESPHome node
 * can call it directly with `homeassistant.action:`.
 *
 * That is what carries a notification here: text, a title, a duration and
 * the rest arrive together in one call, which no entity command can do.
 *
 * Every argument is REQUIRED on the Home Assistant side - its generated
 * action schema marks them all so, and the protocol has no notion of an
 * optional one - so the Dart catalog gives each argument a value that
 * means "leave it alone" (empty string, negative number) instead of
 * pretending a caller can omit it.
 *
 * Arguments are matched to values POSITIONALLY: ExecuteServiceRequest
 * carries a bare list in declaration order, with no names on the wire.
 */
internal class EspService(
    val name: String,
    val args: List<Arg>,
    /**
     * Whether a call may be answered with data (api.proto
     * SupportsResponseType): NONE for fire-and-forget, OPTIONAL when the
     * device sends a JSON object back and Home Assistant hands it to an
     * automation's `response_variable`. With OPTIONAL Home Assistant waits
     * for the answer on EVERY call, so the device must reply to each one
     * that carries a call id.
     */
    val supportsResponse: Int = RESPONSE_NONE,
) {
    class Arg(val name: String, val type: Int)

    /** Same FNV-1a as entities, namespaced so an action and an entity of
     *  the same object id can never collide. */
    val key: Int get() = EspEntity.fnv1a("service:$name")

    companion object {
        /** api.proto ServiceArgType. Only the scalars are used here. */
        const val BOOL = 0
        const val INT = 1
        const val FLOAT = 2
        const val STRING = 3

        /** api.proto SupportsResponseType. */
        const val RESPONSE_NONE = 0
        const val RESPONSE_OPTIONAL = 1

        private fun typeOf(name: String): Int = when (name) {
            "bool" -> BOOL
            "int" -> INT
            "float" -> FLOAT
            "string" -> STRING
            else -> throw IllegalArgumentException("unknown arg type '$name'")
        }

        /** Builds an action from the map the Flutter bridge hands over. */
        fun fromMap(m: Map<*, *>): EspService {
            val name = (m["name"] as? String) ?: ""
            require(name.isNotEmpty()) { "action needs a name" }
            val args = (m["args"] as? List<*>)?.map { raw ->
                val arg = raw as? Map<*, *>
                    ?: throw IllegalArgumentException("action arg must be a map")
                val argName = (arg["name"] as? String) ?: ""
                require(argName.isNotEmpty()) { "action arg needs a name" }
                Arg(argName, typeOf((arg["type"] as? String) ?: ""))
            } ?: emptyList()
            val responds = (m["supportsResponse"] as? Boolean) ?: false
            return EspService(
                name, args,
                if (responds) RESPONSE_OPTIONAL else RESPONSE_NONE,
            )
        }
    }
}

/** Wire encodings for action descriptions and calls. */
internal object ServiceCodec {

    /**
     * ListEntitiesServicesResponse: 1=name, 2=key (fixed32),
     * 3=repeated ListEntitiesServicesArgument {1=name, 2=type},
     * 4=supports_response (left out when NONE, its default).
     */
    fun describe(service: EspService): ByteArray = ProtoWriter().run {
        string(1, service.name)
        fixed32(2, service.key)
        for (arg in service.args) {
            message(3, ProtoWriter().run {
                string(1, arg.name)
                varint(2, arg.type)
                toByteArray()
            })
        }
        if (service.supportsResponse != EspService.RESPONSE_NONE) {
            varint(4, service.supportsResponse)
        }
        toByteArray()
    }

    /**
     * One call: the action's key and its argument values, in order, plus
     * the call id to answer under. A call id of 0 is a client that expects
     * no answer (older Home Assistant, or an action declared NONE), and
     * none must be sent.
     */
    class Call(
        val key: Int,
        val values: List<Any?>,
        val callId: Int = 0,
        val returnResponse: Boolean = false,
    )

    /**
     * ExecuteServiceRequest: 1=key (fixed32), 2=repeated
     * ExecuteServiceArgument {1=bool, 2=legacy_int, 3=float, 4=string,
     * 5=int (sint32)}, 3=call_id, 4=return_response. Exactly one value
     * field is set per argument; `int_` is the one current clients send,
     * `legacy_int` what the pre-1.3 ones did, and an all-defaults argument
     * (false, 0, "") arrives as an empty message, hence the nullable slot.
     */
    fun parseExecute(payload: ByteArray): Call {
        var key = 0
        var callId = 0
        var returnResponse = false
        val values = mutableListOf<Any?>()
        val r = ProtoReader(payload)
        while (r.next()) when (r.field) {
            1 -> key = r.asFixed32()
            2 -> values.add(parseArgument(r.asBytes()))
            3 -> callId = r.asInt()
            4 -> returnResponse = r.asBool()
        }
        return Call(key, values, callId, returnResponse)
    }

    /**
     * ExecuteServiceResponse: 1=call_id, 2=success, 3=error_message,
     * 4=response_data (a JSON object, which Home Assistant hands to the
     * automation as the action's response).
     */
    fun response(
        callId: Int,
        success: Boolean,
        error: String?,
        responseJson: String?,
    ): ByteArray = ProtoWriter().run {
        varint(1, callId)
        bool(2, success)
        if (!error.isNullOrEmpty()) string(3, error)
        if (!responseJson.isNullOrEmpty()) {
            bytes(4, responseJson.toByteArray(Charsets.UTF_8))
        }
        toByteArray()
    }

    private fun parseArgument(payload: ByteArray): Any? {
        var value: Any? = null
        val r = ProtoReader(payload)
        while (r.next()) when (r.field) {
            1 -> value = r.asBool()
            2 -> value = r.asInt()
            3 -> value = r.asFloat()
            4 -> value = r.asString()
            5 -> value = r.asSint32()
        }
        return value
    }
}
