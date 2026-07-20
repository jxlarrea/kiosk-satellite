package me.jxl.kiosk_satellite.sendspin.protocol.message

import me.jxl.kiosk_satellite.sendspin.protocol.ControllerState
import me.jxl.kiosk_satellite.sendspin.protocol.GroupInfo
import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocol
import me.jxl.kiosk_satellite.sendspin.protocol.ServerCommandResult
import me.jxl.kiosk_satellite.sendspin.protocol.ServerHelloResult
import me.jxl.kiosk_satellite.sendspin.protocol.ServerStateResult
import me.jxl.kiosk_satellite.sendspin.protocol.StreamConfig
import me.jxl.kiosk_satellite.sendspin.protocol.SyncOffsetResult
import me.jxl.kiosk_satellite.sendspin.protocol.TimeMeasurement
import me.jxl.kiosk_satellite.sendspin.protocol.TrackMetadata
import me.jxl.kiosk_satellite.sendspin.protocol.TrackProgress
import android.util.Log
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.longOrNull

object MessageParser {
    private const val TAG = "MessageParser"

    fun parseServerHello(payload: JsonObject?, defaultName: String): ServerHelloResult? {
        if (payload == null) {
            Log.e(TAG, "server/hello missing payload")
            return null
        }

        val serverName = payload.stringOrDefault("name", defaultName)
        val serverId = payload.stringOrDefault("server_id", "")
        val connectionReason = payload.stringOrDefault("connection_reason", "discovery")

        val activeRoles = payload["active_roles"]?.jsonArray?.map {
            it.jsonPrimitive.content
        } ?: emptyList()

        return ServerHelloResult(
            serverName = serverName,
            serverId = serverId,
            activeRoles = activeRoles,
            connectionReason = connectionReason
        )
    }

    fun parseServerTime(payload: JsonObject?, clientReceivedMicros: Long): TimeMeasurement? {
        if (payload == null) return null

        // Use nullable accessors so an explicit zero is distinguishable from
        // an absent field. Zero is a valid timestamp value; only an absent
        // field is grounds for rejection.
        val clientTransmitted = payload["client_transmitted"]?.jsonPrimitive?.longOrNull
        val serverReceived = payload["server_received"]?.jsonPrimitive?.longOrNull
        val serverTransmitted = payload["server_transmitted"]?.jsonPrimitive?.longOrNull

        if (clientTransmitted == null || serverReceived == null || serverTransmitted == null) {
            Log.w(TAG, "Invalid server/time payload")
            return null
        }

        val offset = ((serverReceived - clientTransmitted) + (serverTransmitted - clientReceivedMicros)) / 2
        val rtt = (clientReceivedMicros - clientTransmitted) - (serverTransmitted - serverReceived)

        return TimeMeasurement(offset, rtt, clientReceivedMicros)
    }

    fun parseServerState(payload: JsonObject?): ServerStateResult {
        if (payload == null) return ServerStateResult(null, null, null)

        val metadata = (payload["metadata"] as? JsonObject)?.let { metadataObj ->
            fun optStringClean(key: String) =
                metadataObj[key]?.jsonPrimitive?.contentOrNull?.takeUnless { it == "null" } ?: ""

            val timestamp = metadataObj.longOrDefault("timestamp", 0)
            val title = optStringClean("title")
            val artist = optStringClean("artist")
            val albumArtist = optStringClean("album_artist")
            val album = optStringClean("album")
            val artworkUrl = optStringClean("artwork_url")
            val year = metadataObj.intOrDefault("year", 0)
            val track = metadataObj.intOrDefault("track", 0)

            // Use `as? JsonObject` rather than `?.jsonObject`: the latter throws
            // IllegalArgumentException when the field is JsonNull (the server
            // sometimes sends `"progress": null` in idle metadata). The cast
            // form treats JsonNull the same as missing, which is what we want.
            val progress = (metadataObj["progress"] as? JsonObject)?.let { progressObj ->
                TrackProgress(
                    trackProgress = progressObj.longOrDefault("track_progress", 0),
                    trackDuration = progressObj.longOrDefault("track_duration", 0),
                    playbackSpeed = progressObj.intOrDefault("playback_speed", 1000)
                )
            } ?: run {
                // Legacy pre-spec Music Assistant fields, not in the
                // Sendspin spec; kept for old servers.
                TrackProgress(
                    trackProgress = metadataObj.longOrDefault("position_ms", 0),
                    trackDuration = metadataObj.longOrDefault("duration_ms", 0),
                    playbackSpeed = 1000
                )
            }

            TrackMetadata(
                timestamp = timestamp,
                title = title,
                artist = artist,
                albumArtist = albumArtist,
                album = album,
                artworkUrl = artworkUrl,
                year = year,
                track = track,
                progress = progress
            )
        }

        val state = payload.stringOrDefault("state", "").takeIf { it.isNotEmpty() }

        // Controller (group-level) state delta. All fields lenient: aiosendspin
        // sends the complete object, but spec delta semantics allow partials.
        val controller = (payload["controller"] as? JsonObject)?.let { controllerObj ->
            ControllerState(
                supportedCommands = controllerObj["supported_commands"]?.jsonArray?.mapNotNull {
                    it.jsonPrimitive.contentOrNull
                },
                volume = controllerObj["volume"]?.jsonPrimitive?.intOrNull,
                muted = controllerObj["muted"]?.jsonPrimitive?.booleanOrNull,
                repeat = controllerObj["repeat"]?.jsonPrimitive?.contentOrNull,
                shuffle = controllerObj["shuffle"]?.jsonPrimitive?.booleanOrNull
            )
        }

        return ServerStateResult(metadata, state, controller)
    }

    fun parseServerCommand(payload: JsonObject?): ServerCommandResult? {
        if (payload == null) return null

        val player = payload["player"]?.jsonObject ?: return null
        val command = player.stringOrDefault("command", "")

        return when (command) {
            "volume" -> {
                val volume = player.intOrDefault("volume", -1)
                if (volume in 0..100) {
                    ServerCommandResult.Volume(volume)
                } else {
                    null
                }
            }
            "mute" -> {
                val muted = player.booleanOrDefault("mute", false)
                ServerCommandResult.Mute(muted)
            }
            "set_static_delay" -> {
                // Spec: integer, 0-5000 ms.
                val delayMs = player.intOrDefault("static_delay_ms", -1)
                if (delayMs in 0..5000) {
                    ServerCommandResult.SetStaticDelay(delayMs)
                } else {
                    Log.w(TAG, "set_static_delay out of range: $delayMs")
                    null
                }
            }
            else -> {
                if (command.isNotEmpty()) {
                    ServerCommandResult.Unknown(command)
                } else {
                    null
                }
            }
        }
    }

    fun parseGroupUpdate(payload: JsonObject?): GroupInfo? {
        if (payload == null) return null

        val groupId = payload.stringOrDefault("group_id", "")
        val groupName = payload.stringOrDefault("group_name", "")
        val playbackState = payload.stringOrDefault("playback_state", "")

        return GroupInfo(groupId, groupName, playbackState)
    }

    fun parseStreamStart(payload: JsonObject?): StreamConfig? {
        if (payload == null) return null

        val player = payload["player"]?.jsonObject ?: return null

        val codec = player.stringOrDefault("codec", SendSpinProtocol.AudioFormat.DEFAULT_CODEC)
        val sampleRate = player.intOrDefault("sample_rate", SendSpinProtocol.AudioFormat.SAMPLE_RATE)
        val channels = player.intOrDefault("channels", SendSpinProtocol.AudioFormat.CHANNELS)
        val bitDepth = player.intOrDefault("bit_depth", SendSpinProtocol.AudioFormat.BIT_DEPTH)

        val codecHeader = player["codec_header"]?.jsonPrimitive?.contentOrNull?.let { base64 ->
            try {
                android.util.Base64.decode(base64, android.util.Base64.DEFAULT)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to decode codec_header")
                null
            }
        }

        return StreamConfig(codec, sampleRate, channels, bitDepth, codecHeader)
    }

    /**
     * Parse client/sync_offset. NOTE: this is a Music Assistant extension
     * (GroupSync), not part of the Sendspin spec.
     */
    fun parseSyncOffset(payload: JsonObject?): SyncOffsetResult? {
        if (payload == null) return null

        val playerId = payload.stringOrDefault("player_id", "")
        val offsetMs = payload.doubleOrDefault("offset_ms", 0.0)
        val source = payload.stringOrDefault("source", "unknown")

        return SyncOffsetResult(playerId, offsetMs, source)
    }

    // Helper extensions for safe JSON access with defaults

    private fun JsonObject.stringOrDefault(key: String, default: String): String =
        this[key]?.jsonPrimitive?.contentOrNull ?: default

    private fun JsonObject.longOrDefault(key: String, default: Long): Long =
        this[key]?.jsonPrimitive?.longOrNull ?: default

    private fun JsonObject.intOrDefault(key: String, default: Int): Int =
        this[key]?.jsonPrimitive?.intOrNull ?: default

    private fun JsonObject.doubleOrDefault(key: String, default: Double): Double =
        this[key]?.jsonPrimitive?.doubleOrNull ?: default

    private fun JsonObject.booleanOrDefault(key: String, default: Boolean): Boolean =
        this[key]?.jsonPrimitive?.booleanOrNull ?: default
}
