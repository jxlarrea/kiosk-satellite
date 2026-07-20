package me.jxl.kiosk_satellite

import android.content.Context
import android.database.ContentObserver
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt
import me.jxl.kiosk_satellite.sendspin.PlaybackState
import me.jxl.kiosk_satellite.sendspin.SendSpin
import me.jxl.kiosk_satellite.sendspin.SyncAudioPlayer
import me.jxl.kiosk_satellite.sendspin.decoder.AudioDecoder
import me.jxl.kiosk_satellite.sendspin.decoder.AudioDecoderFactory
import me.jxl.kiosk_satellite.sendspin.discovery.NsdDiscoveryManager
import me.jxl.kiosk_satellite.sendspin.network.WebSocketUrlBuilder
import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocol

/**
 * Headless SendSpin synchronized-audio player, exposed to Dart over the
 * `kiosk_satellite/sendspin` method channel.
 *
 * Owns the whole native pipeline: the SendSpin protocol client (WebSocket,
 * time sync, reconnect), the codec decoder, the DAC-gated SyncAudioPlayer,
 * and mDNS discovery. Volume commands map onto the device's media stream
 * (AudioManager STREAM_MUSIC), never per-track gain, and hardware volume
 * changes are observed and reported back to the server via client/state.
 *
 * Methods:
 * - start {serverUrl?, playerName, clientId, preferredCodec}
 * - stop
 * - discover {timeoutMs}
 * - getStatus
 *
 * Events pushed to Dart: stateChanged, metadataChanged, volumeChanged,
 * playingChanged.
 */
class SendspinBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    companion object {
        private const val TAG = "sendspin"
        private const val DEFAULT_PORT = 8927
        private const val DEFAULT_DISCOVER_TIMEOUT_MS = 4000
        private const val DISCOVERY_RETRY_MS = 5_000L
        private const val BUFFER_CAPACITY_SECONDS = 35L
    }

    private val channel = MethodChannel(messenger, "kiosk_satellite/sendspin")
    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private val versionName: String = try {
        context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "unknown"
    } catch (_: Exception) {
        "unknown"
    }

    // Session objects. pipelineLock guards player/decoder swaps, which happen
    // on the WebSocket thread while stop() can run on the main thread.
    private val pipelineLock = Any()
    @Volatile private var client: SendSpin? = null
    @Volatile private var player: SyncAudioPlayer? = null
    @Volatile private var decoder: AudioDecoder? = null
    @Volatile private var autoDiscovery: NsdDiscoveryManager? = null

    @Volatile private var started = false
    @Volatile private var discoveryMode = false

    // Status mirrors for getStatus / event payloads
    @Volatile private var connected = false
    @Volatile private var serverName: String? = null
    @Volatile private var playbackState: String? = null
    @Volatile private var title: String? = null
    @Volatile private var artist: String? = null
    @Volatile private var album: String? = null
    @Volatile private var streamActive = false
    @Volatile private var lastPlaying = false

    @Volatile private var lastReportedVolume = -1
    @Volatile private var lastReportedMuted = false

    private val volumeObserver = object : ContentObserver(mainHandler) {
        override fun onChange(selfChange: Boolean) {
            if (started) publishVolumeIfChanged()
        }
    }

    private val discoveryRestart = Runnable {
        if (started && discoveryMode && client?.isConnected != true) {
            startAutoDiscovery()
        }
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val serverUrl = call.argument<String>("serverUrl")
                    val playerName = call.argument<String>("playerName") ?: "Kiosk Satellite"
                    val clientId = call.argument<String>("clientId") ?: "kiosk-satellite"
                    val preferredCodec =
                        (call.argument<String>("preferredCodec") ?: "flac").lowercase()
                    startSession(serverUrl, playerName, clientId, preferredCodec)
                    result.success(true)
                }
                "stop" -> {
                    stopSession()
                    result.success(true)
                }
                "discover" -> {
                    val timeoutMs = call.argument<Number>("timeoutMs")?.toInt()
                        ?: DEFAULT_DISCOVER_TIMEOUT_MS
                    runDiscover(timeoutMs, result)
                }
                "getStatus" -> result.success(buildStatus())
                else -> result.notImplemented()
            }
        }
    }

    // ==================================================================
    // Session lifecycle
    // ==================================================================

    private fun startSession(
        serverUrl: String?,
        playerName: String,
        clientId: String,
        preferredCodec: String,
    ) {
        if (started) stopSession()
        started = true

        context.contentResolver.registerContentObserver(
            Settings.System.CONTENT_URI, true, volumeObserver,
        )

        val newClient = SendSpin(
            deviceName = playerName,
            clientId = clientId,
            preferredCodec = preferredCodec,
            softwareVersion = versionName,
            callback = ClientCallback(),
        )
        newClient.setInitialVolume(deviceVolumePct(), deviceMuted())
        lastReportedVolume = deviceVolumePct()
        lastReportedMuted = deviceMuted()
        client = newClient

        if (serverUrl.isNullOrBlank()) {
            discoveryMode = true
            Log.i(TAG, "start: no serverUrl, using mDNS discovery")
            startAutoDiscovery()
        } else {
            discoveryMode = false
            val (address, path) = parseServerUrl(serverUrl)
            Log.i(TAG, "start: connecting to $address$path")
            newClient.connect(address, path)
        }
    }

    private fun stopSession() {
        started = false
        discoveryMode = false
        mainHandler.removeCallbacks(discoveryRestart)

        autoDiscovery?.cleanup()
        autoDiscovery = null

        try {
            context.contentResolver.unregisterContentObserver(volumeObserver)
        } catch (_: Exception) {
        }

        // Goodbye + disconnect + release, in dependency order.
        client?.destroy()
        client = null

        synchronized(pipelineLock) {
            player?.release()
            player = null
            decoder?.release()
            decoder = null
        }

        connected = false
        serverName = null
        playbackState = null
        title = null
        artist = null
        album = null
        streamActive = false
        if (lastPlaying) {
            lastPlaying = false
            emit("playingChanged", mapOf("playing" to false))
        }
        emitState()
    }

    // ==================================================================
    // Discovery
    // ==================================================================

    /** Parse a user-supplied server URL/address into ("host:port", "/path"). */
    private fun parseServerUrl(raw: String): Pair<String, String> {
        var s = raw.trim()
            .removePrefix("ws://")
            .removePrefix("wss://")
            .removePrefix("http://")
            .removePrefix("https://")
        val slash = s.indexOf('/')
        val authority: String
        val path: String
        if (slash >= 0) {
            authority = s.substring(0, slash)
            path = s.substring(slash)
        } else {
            authority = s
            path = SendSpinProtocol.ENDPOINT_PATH
        }
        return WebSocketUrlBuilder.ensureDefaultPort(authority, DEFAULT_PORT) to path
    }

    /**
     * Browse for the first `_sendspin-server._tcp.` server and connect to it.
     * Keeps browsing until a server appears; if the subsequent connection
     * dies for good, [ClientCallback] schedules a fresh browse.
     */
    private fun startAutoDiscovery() {
        mainHandler.post {
            if (!started || !discoveryMode || autoDiscovery != null) return@post
            if (client?.isConnected == true) return@post

            val manager = NsdDiscoveryManager(
                context,
                object : NsdDiscoveryManager.DiscoveryListener {
                    override fun onServerDiscovered(
                        name: String,
                        host: String,
                        port: Int,
                        path: String,
                        friendlyName: String,
                    ) {
                        mainHandler.post {
                            if (!started) return@post
                            val d = autoDiscovery ?: return@post
                            autoDiscovery = null
                            d.cleanup()
                            val address =
                                if (host.contains(":")) "[$host]:$port" else "$host:$port"
                            Log.i(TAG, "Discovery: connecting to '$friendlyName' at $address$path")
                            client?.connect(address, path)
                        }
                    }

                    override fun onServerLost(name: String) {}
                    override fun onDiscoveryStarted() {}
                    override fun onDiscoveryStopped() {}

                    override fun onDiscoveryError(error: String) {
                        Log.w(TAG, "Discovery error: $error")
                        mainHandler.post {
                            autoDiscovery?.cleanup()
                            autoDiscovery = null
                            scheduleDiscoveryRestart()
                        }
                    }
                },
            )
            autoDiscovery = manager
            manager.startDiscovery()
        }
    }

    private fun scheduleDiscoveryRestart() {
        mainHandler.removeCallbacks(discoveryRestart)
        mainHandler.postDelayed(discoveryRestart, DISCOVERY_RETRY_MS)
    }

    /** One-shot bounded discovery for the "discover" method call. */
    private fun runDiscover(timeoutMs: Int, result: MethodChannel.Result) {
        val results = mutableListOf<Map<String, Any>>()
        val seen = HashSet<String>()

        val manager = NsdDiscoveryManager(
            context,
            object : NsdDiscoveryManager.DiscoveryListener {
                override fun onServerDiscovered(
                    name: String,
                    host: String,
                    port: Int,
                    path: String,
                    friendlyName: String,
                ) {
                    synchronized(results) {
                        if (seen.add("$host:$port")) {
                            results.add(
                                mapOf(
                                    "name" to friendlyName,
                                    "host" to host,
                                    "port" to port,
                                    "url" to WebSocketUrlBuilder.buildFromHostPort(host, port, path),
                                ),
                            )
                        }
                    }
                }

                override fun onServerLost(name: String) {}
                override fun onDiscoveryStarted() {}
                override fun onDiscoveryStopped() {}
                override fun onDiscoveryError(error: String) {
                    Log.w(TAG, "discover: $error")
                }
            },
        )
        manager.startDiscovery()
        mainHandler.postDelayed({
            manager.cleanup()
            result.success(synchronized(results) { results.toList() })
        }, timeoutMs.toLong().coerceIn(500L, 60_000L))
    }

    // ==================================================================
    // Device volume (STREAM_MUSIC)
    // ==================================================================

    private fun deviceVolumePct(): Int {
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
        val cur = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        return (cur * 100.0 / max).roundToInt().coerceIn(0, 100)
    }

    private fun deviceMuted(): Boolean =
        audioManager.isStreamMute(AudioManager.STREAM_MUSIC)

    private fun setDeviceVolumePct(volume: Int) {
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
        val index = (volume.coerceIn(0, 100) / 100.0 * max).roundToInt().coerceIn(0, max)
        try {
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, index, 0)
        } catch (e: SecurityException) {
            Log.w(TAG, "setStreamVolume rejected: ${e.message}")
        }
    }

    private fun setDeviceMuted(muted: Boolean) {
        try {
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                if (muted) AudioManager.ADJUST_MUTE else AudioManager.ADJUST_UNMUTE,
                0,
            )
        } catch (e: SecurityException) {
            Log.w(TAG, "adjustStreamVolume rejected: ${e.message}")
        }
    }

    /**
     * Detect a device-side volume/mute change (hardware buttons, other apps),
     * report it to the server via client/state, and push it to Dart.
     */
    private fun publishVolumeIfChanged() {
        val vol = deviceVolumePct()
        val muted = deviceMuted()
        if (vol == lastReportedVolume && muted == lastReportedMuted) return
        lastReportedVolume = vol
        lastReportedMuted = muted
        client?.setInitialVolume(vol, muted)
        client?.sendClientStateSnapshot()
        emit("volumeChanged", mapOf("volume" to vol, "muted" to muted))
    }

    // ==================================================================
    // Events / status
    // ==================================================================

    private fun emit(method: String, arguments: Any?) {
        mainHandler.post { channel.invokeMethod(method, arguments) }
    }

    private fun emitState() {
        emit(
            "stateChanged",
            mapOf(
                "connected" to connected,
                "serverName" to serverName,
                "playbackState" to playbackState,
                "synced" to (client?.isSynchronized() ?: false),
            ),
        )
    }

    private fun recomputePlaying() {
        val playing = streamActive && playbackState == "playing"
        if (playing != lastPlaying) {
            lastPlaying = playing
            emit("playingChanged", mapOf("playing" to playing))
        }
    }

    private fun buildStatus(): Map<String, Any?> = mapOf(
        "connected" to connected,
        "serverName" to serverName,
        "playbackState" to playbackState,
        "title" to title,
        "artist" to artist,
        "album" to album,
        "volume" to deviceVolumePct(),
        "muted" to deviceMuted(),
        "synced" to (client?.isSynchronized() ?: false),
    )

    // ==================================================================
    // Audio pipeline
    // ==================================================================

    private fun configurePipeline(
        codec: String,
        sampleRate: Int,
        channels: Int,
        bitDepth: Int,
        codecHeader: ByteArray?,
    ) {
        synchronized(pipelineLock) {
            val c = client ?: return

            val existing = player
            if (existing != null && existing.matchesFormat(sampleRate, channels, bitDepth)) {
                // Reuse the live AudioTrack: keeps DAC timestamps warm across
                // stream/end -> stream/start cycles with the same format.
                if (existing.getPlaybackState() == PlaybackState.DRAINING) {
                    existing.exitDraining()
                }
            } else {
                existing?.release()
                player = SyncAudioPlayer(
                    timeFilter = c.getTimeFilter(),
                    sampleRate = sampleRate,
                    channels = channels,
                    bitDepth = bitDepth,
                    maxQueueSamples = BUFFER_CAPACITY_SECONDS * sampleRate,
                    requestClientStateSnapshot = { client?.sendClientStateSnapshot() },
                ).also {
                    it.initialize()
                    it.start()
                }
            }

            decoder?.release()
            decoder = try {
                AudioDecoderFactory.create(codec).also {
                    it.configure(sampleRate, channels, bitDepth, codecHeader)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to configure $codec decoder", e)
                null
            }
        }
    }

    // ==================================================================
    // SendSpin client callback
    // ==================================================================

    private inner class ClientCallback : SendSpin.Callback {

        override fun onConnectionStateChanged(state: SendSpin.ConnectionState) {
            val wasConnected = connected
            connected = state == SendSpin.ConnectionState.READY

            if (wasConnected && !connected) {
                // Transport dropped: keep playing from buffer while the client
                // reconnects (SyncAudioPlayer no-ops unless it was playing).
                player?.enterDraining()
            }

            if (!connected &&
                (state == SendSpin.ConnectionState.IDLE || state == SendSpin.ConnectionState.FAILED) &&
                started && discoveryMode
            ) {
                // Terminal state in discovery mode: go find a server again.
                scheduleDiscoveryRestart()
            }

            emitState()
        }

        override fun onHandshakeComplete(serverName: String) {
            this@SendspinBridge.serverName = serverName
            mainHandler.removeCallbacks(discoveryRestart)
            emitState()
        }

        override fun onStateChanged(state: String) {
            playbackState = state
            recomputePlaying()
            emitState()
        }

        override fun onGroupUpdate(groupId: String, groupName: String, playbackState: String) {
            if (playbackState.isNotEmpty()) {
                this@SendspinBridge.playbackState = playbackState
                recomputePlaying()
                emitState()
            }
        }

        override fun onMetadataUpdate(
            title: String,
            artist: String,
            album: String,
            artworkUrl: String,
            durationMs: Long,
            positionMs: Long,
        ) {
            this@SendspinBridge.title = title.ifEmpty { null }
            this@SendspinBridge.artist = artist.ifEmpty { null }
            this@SendspinBridge.album = album.ifEmpty { null }
            emit(
                "metadataChanged",
                mapOf(
                    "title" to title,
                    "artist" to artist,
                    "album" to album,
                    "artworkUrl" to artworkUrl,
                    "positionMs" to positionMs,
                    "durationMs" to durationMs,
                ),
            )
        }

        override fun onStreamStart(
            codec: String,
            sampleRate: Int,
            channels: Int,
            bitDepth: Int,
            codecHeader: ByteArray?,
        ) {
            configurePipeline(codec, sampleRate, channels, bitDepth, codecHeader)
            streamActive = true
            recomputePlaying()
        }

        override fun onStreamClear() {
            decoder?.flush()
            player?.clearBuffer()
        }

        override fun onStreamEnd() {
            streamActive = false
            // Keep the AudioTrack alive writing silence so DAC timestamps stay
            // warm for the next stream.
            player?.enterIdle()
            decoder?.flush()
            recomputePlaying()
        }

        override fun onAudioChunk(serverTimeMicros: Long, audioData: ByteArray) {
            val d = decoder ?: return
            val pcm = try {
                d.decode(audioData)
            } catch (e: Exception) {
                Log.e(TAG, "Decode failed (${audioData.size} bytes)", e)
                return
            }
            if (pcm.isNotEmpty()) {
                player?.queueChunk(serverTimeMicros, pcm)
            }
        }

        override fun onVolumeChanged(volume: Int) {
            setDeviceVolumePct(volume)
            publishVolumeIfChanged()
        }

        override fun onMutedChanged(muted: Boolean) {
            setDeviceMuted(muted)
            publishVolumeIfChanged()
        }

        override fun onSyncMuteChanged(muted: Boolean) {
            player?.setSyncMuted(muted)
        }

        override fun onReconnectExhausted() {
            Log.w(TAG, "Reconnect attempts exhausted")
            if (started && discoveryMode) scheduleDiscoveryRestart()
            emitState()
        }
    }
}
