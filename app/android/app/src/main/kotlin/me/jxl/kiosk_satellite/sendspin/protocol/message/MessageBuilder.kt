package me.jxl.kiosk_satellite.sendspin.protocol.message

import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocol
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.math.roundToInt

object MessageBuilder {

    data class FormatEntry(
        val codec: String,
        val sampleRate: Int,
        val channels: Int,
        val bitDepth: Int
    )

    fun buildClientHello(
        clientId: String,
        deviceName: String,
        bufferCapacity: Int,
        manufacturer: String,
        supportedFormats: List<FormatEntry>,
        softwareVersion: String = "unknown"
    ): String {
        val message = buildJsonObject {
            put("type", SendSpinProtocol.MessageType.CLIENT_HELLO)
            put("payload", buildJsonObject {
                put("client_id", clientId)
                put("name", deviceName)
                put("version", SendSpinProtocol.VERSION)
                // Player plus metadata: the server only sends now-playing
                // details (title, artist, artwork url, progress) to clients
                // that declare the metadata role, and the floating media
                // player on the kiosk shows them.
                put("supported_roles", buildJsonArray {
                    add(JsonPrimitive(SendSpinProtocol.Roles.PLAYER))
                    add(JsonPrimitive(SendSpinProtocol.Roles.METADATA))
                })
                put("device_info", buildJsonObject {
                    put("product_name", "Kiosk Satellite")
                    put("manufacturer", manufacturer)
                    put("software_version", softwareVersion)
                })
                put("player@v1_support", buildJsonObject {
                    put("supported_formats", buildJsonArray {
                        for (fmt in supportedFormats) {
                            add(buildJsonObject {
                                put("codec", fmt.codec)
                                put("sample_rate", fmt.sampleRate)
                                put("channels", fmt.channels)
                                put("bit_depth", fmt.bitDepth)
                            })
                        }
                    })
                    put("buffer_capacity", bufferCapacity)
                    put("supported_commands", buildJsonArray {
                        add(JsonPrimitive("volume"))
                        add(JsonPrimitive("mute"))
                    })
                })
            })
        }
        return message.toString()
    }

    fun buildClientTime(clientTransmittedMicros: Long): String {
        val message = buildJsonObject {
            put("type", SendSpinProtocol.MessageType.CLIENT_TIME)
            put("payload", buildJsonObject {
                put("client_transmitted", clientTransmittedMicros)
            })
        }
        return message.toString()
    }

    fun buildGoodbye(reason: String): String {
        val message = buildJsonObject {
            put("type", SendSpinProtocol.MessageType.CLIENT_GOODBYE)
            put("payload", buildJsonObject {
                put("reason", reason)
            })
        }
        return message.toString()
    }

    fun buildPlayerState(
        volume: Int,
        muted: Boolean,
        syncState: String = "synchronized",
        staticDelayMs: Double = 0.0,
        requiredLeadTimeMs: Int = SendSpinProtocol.PlayerTiming.REQUIRED_LEAD_TIME_MS,
        minBufferMs: Int = SendSpinProtocol.PlayerTiming.MIN_BUFFER_MS
    ): String {
        val message = buildJsonObject {
            put("type", SendSpinProtocol.MessageType.CLIENT_STATE)
            put("payload", buildJsonObject {
                // Per spec, `state` is a top-level payload field (sibling of
                // `player`), not part of the player object.
                put("state", syncState)
                put("player", buildJsonObject {
                    put("volume", volume)
                    put("muted", muted)
                    // Spec: integer, range 0-5000, negative values not
                    // supported. Locally we still apply the full signed
                    // value (user sync offset can be negative); only the
                    // reported field is clamped.
                    put("static_delay_ms", staticDelayMs.roundToInt().coerceIn(0, 5000))
                    // Both timing fields are always required for players.
                    put("required_lead_time_ms", requiredLeadTimeMs)
                    put("min_buffer_ms", minBufferMs)
                    // Declares that we handle server/command set_static_delay.
                    put("supported_commands", buildJsonArray {
                        add(JsonPrimitive("set_static_delay"))
                    })
                })
            })
        }
        return message.toString()
    }

    /**
     * Build a stream/request-format message for the player role.
     *
     * All fields optional; omitted fields keep their current value on the
     * server. The server responds with stream/start carrying the new format.
     */
    fun buildStreamRequestFormat(
        codec: String? = null,
        sampleRate: Int? = null,
        channels: Int? = null,
        bitDepth: Int? = null
    ): String {
        val message = buildJsonObject {
            put("type", SendSpinProtocol.MessageType.STREAM_REQUEST_FORMAT)
            put("payload", buildJsonObject {
                put("player", buildJsonObject {
                    if (codec != null) put("codec", codec)
                    if (sampleRate != null) put("sample_rate", sampleRate)
                    if (channels != null) put("channels", channels)
                    if (bitDepth != null) put("bit_depth", bitDepth)
                })
            })
        }
        return message.toString()
    }

    /**
     * Calculate buffer_capacity (wire bytes) from target duration and format list.
     *
     * Uses the highest-bitrate PCM entry we advertise as the basis, so the cap
     * is tight for PCM and gives compressed codecs proportionally more seconds
     * of look-ahead (but bounded decoded memory).
     */
    fun calculateBufferCapacity(formats: List<FormatEntry>, durationSec: Int): Int {
        val maxPcmBytesPerSec = formats
            .filter { it.codec == "pcm" }
            .maxOfOrNull { it.sampleRate * it.channels * (it.bitDepth / 8) }
            ?: (SendSpinProtocol.AudioFormat.SAMPLE_RATE
                    * SendSpinProtocol.AudioFormat.CHANNELS
                    * (SendSpinProtocol.AudioFormat.BIT_DEPTH / 8))
        return durationSec * maxPcmBytesPerSec
    }

    /**
     * Build the supported_formats list for the client/hello message.
     *
     * The advertised list never contains a codec other than [preferredCodec] or
     * `"pcm"`, and when both are present the preferred codec appears first
     * (each with stereo+mono variants). If [preferredCodec] is not supported on
     * this device it is silently dropped and only PCM is advertised. 16-bit
     * only; the kiosk skips 24/32-bit PCM to keep the pipeline simple.
     */
    fun buildSupportedFormats(
        preferredCodec: String,
        isCodecSupported: (String) -> Boolean
    ): List<FormatEntry> {
        val codecOrder = mutableListOf<String>()

        if (preferredCodec != "pcm" && isCodecSupported(preferredCodec)) {
            codecOrder.add(preferredCodec)
        }

        if (isCodecSupported("pcm")) {
            codecOrder.add("pcm")
        }

        return buildList {
            for (codec in codecOrder) {
                // Stereo
                add(FormatEntry(
                    codec = codec,
                    sampleRate = SendSpinProtocol.AudioFormat.SAMPLE_RATE,
                    channels = SendSpinProtocol.AudioFormat.CHANNELS,
                    bitDepth = SendSpinProtocol.AudioFormat.BIT_DEPTH
                ))
                // Mono
                add(FormatEntry(
                    codec = codec,
                    sampleRate = SendSpinProtocol.AudioFormat.SAMPLE_RATE,
                    channels = SendSpinProtocol.AudioFormat.CHANNELS_MONO,
                    bitDepth = SendSpinProtocol.AudioFormat.BIT_DEPTH
                ))
            }
        }
    }
}
