package me.jxl.kiosk_satellite

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import me.jxl.kiosk_satellite.sendspin.NativeSendspinSession
import me.jxl.kiosk_satellite.sendspin.discovery.NsdDiscoveryManager
import me.jxl.kiosk_satellite.sendspin.network.WebSocketUrlBuilder

/**
 * Headless SendSpin synchronized-audio player, exposed to Dart over the
 * `kiosk_satellite/sendspin` method channel.
 *
 * The engine is sendspin-cpp, the protocol's reference implementation,
 * behind [NativeSendspinSession]: it owns the WebSocket, time sync, codec
 * decoding and playback scheduling, while the session provides the Android
 * audio output and playback feedback. This bridge keeps the Dart-facing
 * surface: session lifecycle, mDNS discovery, and the volume plumbing.
 * Server volume commands move [VolumeController]'s MEDIA fader (AudioTrack
 * gain under the master ceiling, issue #79) - the Music Assistant slider is
 * the music's, never the device's - and media fader moves from any surface
 * are reported back to the server.
 *
 * Methods:
 * - start {serverUrl?, playerName, clientId, preferredCodec, syncOffsetMs}
 * - setSyncOffset {ms}
 * - stop
 * - discover {timeoutMs}
 * - getStatus
 * - duck {factor}
 * - control {command}
 *
 * Events pushed to Dart: stateChanged, metadataChanged, volumeChanged,
 * playingChanged, controllerChanged.
 */
class SendspinBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    companion object {
        private const val TAG = "sendspin"
        private const val DEFAULT_PORT = 8927
        private const val ENDPOINT_PATH = "/sendspin"
        private const val DEFAULT_DISCOVER_TIMEOUT_MS = 4000
        private const val DISCOVERY_RETRY_MS = 5_000L
        // Recycle a fruitless mDNS browse after this long (see discoveryRestart).
        private const val DISCOVERY_REBROWSE_MS = 600_000L  // 10 minutes
    }

    private val channel = MethodChannel(messenger, "kiosk_satellite/sendspin")
    private val mainHandler = Handler(Looper.getMainLooper())

    private val versionName: String = try {
        context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "unknown"
    } catch (_: Exception) {
        "unknown"
    }

    @Volatile private var session: NativeSendspinSession? = null
    @Volatile private var autoDiscovery: NsdDiscoveryManager? = null

    @Volatile private var started = false
    @Volatile private var discoveryMode = false

    // Status mirrors for getStatus / event payloads
    @Volatile private var connected = false
    @Volatile private var serverName: String? = null
    @Volatile private var playbackState: String? = null
    @Volatile private var supportedCommands: List<String> = emptyList()
    @Volatile private var duckFactor: Float = 1f
    @Volatile private var title: String? = null
    @Volatile private var artist: String? = null
    @Volatile private var album: String? = null
    @Volatile private var lastPositionMs: Long = -1
    @Volatile private var lastDurationMs: Long = -1
    @Volatile private var streamActive = false
    @Volatile private var lastPlaying = false
    @Volatile private var syncOffsetMs = 0L

    @Volatile private var lastReportedVolume = -1
    @Volatile private var lastReportedMuted = false

    // Connectivity kick: when a network (re)appears, retry the connection
    // immediately instead of waiting out the reconnect ladder's current
    // delay. Registered per session; the registration-time callback for
    // the already-present network is skipped so session start does not
    // self-nudge.
    @Volatile private var networkCallback: ConnectivityManager.NetworkCallback? = null

    private fun registerNetworkCallback() {
        if (networkCallback != null) return
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        if (cm == null) {
            Log.w(TAG, "No ConnectivityManager; network kick disabled")
            return
        }
        // Only skip the registration-time replay when a network really was
        // up at registration. A session that starts offline (boot before
        // wifi) gets its first onAvailable when the outage ENDS - swallowing
        // that one left recovery to the reconnect ladder's current delay.
        var expectInitialReplay = cm.activeNetwork != null
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                mainHandler.post {
                    if (expectInitialReplay) {
                        expectInitialReplay = false
                        return@post
                    }
                    if (!started) return@post
                    Log.i(TAG, "Network available - nudging Sendspin recovery")
                    session?.onNetworkAvailable()
                    if (discoveryMode && session?.isConnected != true) {
                        // Recycle the browse now rather than at the next
                        // 10-minute tick; a wedged NSD browse cannot see the
                        // server that just became reachable.
                        mainHandler.removeCallbacks(discoveryRestart)
                        discoveryRestart.run()
                    }
                }
            }
        }
        try {
            cm.registerDefaultNetworkCallback(cb)
            networkCallback = cb
        } catch (e: Exception) {
            Log.w(TAG, "Failed to register network callback", e)
        }
    }

    private fun unregisterNetworkCallback() {
        val cb = networkCallback ?: return
        networkCallback = null
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        try {
            cm?.unregisterNetworkCallback(cb)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to unregister network callback", e)
        }
    }

    private val discoveryRestart: Runnable = object : Runnable {
        override fun run() {
            if (started && discoveryMode && session?.isConnected != true) {
                // Recycle any existing browse rather than trusting it:
                // Android's NSD can wedge silently after a wifi drop (no
                // callbacks, no error), and startAutoDiscovery's null guard
                // would then turn every restart into a no-op forever - a
                // dead player until app restart. A fresh browse is cheap.
                autoDiscovery?.cleanup()
                autoDiscovery = null
                startAutoDiscovery()
            }
            if (started && discoveryMode) {
                mainHandler.postDelayed(this, DISCOVERY_REBROWSE_MS)
            }
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
                    syncOffsetMs = (call.argument<Number>("syncOffsetMs") ?: 0).toLong()
                    startSession(serverUrl, playerName, clientId, preferredCodec)
                    result.success(true)
                }
                // Applied live, no session restart: a slider being tuned by
                // ear must not interrupt the music it is tuning against.
                "setSyncOffset" -> {
                    syncOffsetMs = (call.argument<Number>("ms") ?: 0).toLong()
                    session?.setSyncOffset(syncOffsetMs)
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
                "duck" -> {
                    val factor = call.argument<Number>("factor")?.toFloat() ?: 1f
                    duckFactor = factor.coerceIn(0f, 1f)
                    session?.setDuckFactor(duckFactor)
                    result.success(true)
                }
                "control" -> {
                    val command = call.argument<String>("command") ?: ""
                    // Seek carries its position (ms); the rest take no value.
                    val value = call.argument<Number>("value")?.toLong() ?: 0L
                    val allowed = supportedCommands
                    if (command.isNotEmpty() &&
                        (allowed.isEmpty() || command in allowed)
                    ) {
                        session?.sendCommand(command, value)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
        // Any fader move (media, fixed-volume master, a server command)
        // must reach the live AudioTrack and be reported to the server,
        // no matter which surface moved it.
        VolumeController.addListener {
            session?.setMediaGain(VolumeController.mediaGain)
            if (started) publishVolumeIfChanged()
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

        val newSession = NativeSendspinSession(
            context = context,
            playerName = playerName,
            clientId = clientId,
            preferredCodec = preferredCodec,
            softwareVersion = versionName,
            initialSyncOffsetMs = syncOffsetMs,
            initialDuckFactor = duckFactor,
            initialMediaGain = VolumeController.mediaGain,
            events = SessionEvents(),
        )
        newSession.publishVolume(deviceVolumePct(), deviceMuted())
        lastReportedVolume = deviceVolumePct()
        lastReportedMuted = deviceMuted()
        session = newSession

        if (serverUrl.isNullOrBlank()) {
            discoveryMode = true
            Log.i(TAG, "start: no serverUrl, using mDNS discovery")
            startAutoDiscovery()
            // Arm the browse recycler from the very first browse too.
            mainHandler.postDelayed(discoveryRestart, DISCOVERY_REBROWSE_MS)
        } else {
            discoveryMode = false
            val (address, path) = parseServerUrl(serverUrl)
            Log.i(TAG, "start: connecting to $address$path")
            newSession.connect("ws://$address$path")
        }

        registerNetworkCallback()
    }

    private fun stopSession() {
        started = false
        discoveryMode = false
        unregisterNetworkCallback()
        mainHandler.removeCallbacks(discoveryRestart)

        autoDiscovery?.cleanup()
        autoDiscovery = null

        session?.destroy()
        session = null

        connected = false
        serverName = null
        playbackState = null
        title = null
        artist = null
        album = null
        lastPositionMs = -1
        lastDurationMs = -1
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
            path = ENDPOINT_PATH
        }
        return WebSocketUrlBuilder.ensureDefaultPort(authority, DEFAULT_PORT) to path
    }

    /**
     * Browse for the first `_sendspin-server._tcp.` server and connect to it.
     * Keeps browsing until a server appears; if the subsequent connection
     * dies for good, the session's reconnect ladder and [discoveryRestart]
     * take over.
     */
    private fun startAutoDiscovery() {
        mainHandler.post {
            if (!started || !discoveryMode || autoDiscovery != null) return@post
            if (session?.isConnected == true) return@post

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
                            session?.connect("ws://$address$path")
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

    // The server's volume is the MEDIA fader, not the device volume: the
    // Music Assistant slider is the music's. Master stays with the MQTT
    // Volume entity and the hardware buttons.
    private fun deviceVolumePct(): Int = VolumeController.mediaPercent()

    private fun deviceMuted(): Boolean = VolumeController.mediaMuted()

    /**
     * Detect a device-side volume/mute change (hardware buttons, other apps),
     * report it to the server, and push it to Dart.
     */
    private fun publishVolumeIfChanged() {
        val vol = deviceVolumePct()
        val muted = deviceMuted()
        if (vol == lastReportedVolume && muted == lastReportedMuted) return
        lastReportedVolume = vol
        lastReportedMuted = muted
        session?.publishVolume(vol, muted)
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
                "synced" to (session?.isTimeSynced ?: false),
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
        "synced" to (session?.isTimeSynced ?: false),
        // Pipeline health, for diagnosing stutter reports without an adb
        // cable: what the shell can see around the native engine.
        "stats" to session?.buildStats(),
    )

    // ==================================================================
    // Session events
    // ==================================================================

    /**
     * Maps [NativeSendspinSession.Events] onto the bridge mirrors and Dart
     * emissions. Position needs no base pairing against an audible clock:
     * the engine interpolates track progress itself and holds metadata
     * deliveries to their server timestamps.
     */
    private inner class SessionEvents : NativeSendspinSession.Events {

        override fun onConnectionChanged(connected: Boolean, serverName: String?) {
            this@SendspinBridge.connected = connected
            if (connected) {
                if (serverName != null) this@SendspinBridge.serverName = serverName
                mainHandler.removeCallbacks(discoveryRestart)
            } else if (started && discoveryMode) {
                scheduleDiscoveryRestart()
            }
            emitState()
        }

        override fun onPlaybackStateChanged(state: String?) {
            playbackState = state
            recomputePlaying()
            emitState()
        }

        override fun onMetadata(
            title: String?,
            artist: String?,
            album: String?,
            artworkUrl: String?,
            positionMs: Long,
            durationMs: Long,
        ) {
            this@SendspinBridge.title = title
            this@SendspinBridge.artist = artist
            this@SendspinBridge.album = album
            if (positionMs >= 0) lastPositionMs = positionMs
            if (durationMs >= 0) lastDurationMs = durationMs
            emit(
                "metadataChanged",
                buildMap {
                    put("title", title ?: "")
                    put("artist", artist ?: "")
                    put("album", album ?: "")
                    put("artworkUrl", artworkUrl ?: "")
                    if (positionMs >= 0) put("positionMs", positionMs)
                    if (durationMs >= 0) put("durationMs", durationMs)
                },
            )
        }

        override fun onPositionUpdate(positionMs: Long) {
            lastPositionMs = positionMs
            emit("metadataChanged", mapOf("positionMs" to positionMs))
        }

        override fun onServerVolume(volume: Int) {
            VolumeController.setMediaPercent(volume)
            publishVolumeIfChanged()
        }

        override fun onServerMuted(muted: Boolean) {
            VolumeController.setMediaMuted(muted)
            publishVolumeIfChanged()
        }

        override fun onControllerState(commands: List<String>, shuffle: Boolean, repeat: String) {
            supportedCommands = commands
            emit(
                "controllerChanged",
                mapOf("supportedCommands" to commands, "shuffle" to shuffle, "repeat" to repeat),
            )
        }

        override fun onStreamActiveChanged(active: Boolean) {
            streamActive = active
            recomputePlaying()
        }
    }
}
