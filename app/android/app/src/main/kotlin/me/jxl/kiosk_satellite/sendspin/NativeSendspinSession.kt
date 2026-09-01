package me.jxl.kiosk_satellite.sendspin

import android.content.Context
import android.os.Handler
import android.os.HandlerThread
import android.os.Process
import android.util.Log
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

/**
 * One native-engine SendSpin session: a sendspin-cpp client (protocol, time
 * sync, decode, scheduling) plus the Android audio output and the feedback
 * loop that drives the library's synchronization.
 *
 * The engine setting decides whether SendspinBridge builds this or the
 * classic Kotlin pipeline; both feed the same bridge events, so Dart cannot
 * tell them apart.
 */
class NativeSendspinSession(
    context: Context,
    playerName: String,
    clientId: String,
    preferredCodec: String,
    softwareVersion: String,
    initialSyncOffsetMs: Long,
    initialDuckFactor: Float,
    initialMediaGain: Float,
    private val events: Events,
) {
    /** Bridge-facing events. All fire on native threads, never main. */
    interface Events {
        fun onConnectionChanged(connected: Boolean, serverName: String?)
        fun onPlaybackStateChanged(state: String?)
        fun onMetadata(
            title: String?,
            artist: String?,
            album: String?,
            artworkUrl: String?,
            positionMs: Long,
            durationMs: Long,
        )
        fun onPositionUpdate(positionMs: Long)
        fun onServerVolume(volume: Int)
        fun onServerMuted(muted: Boolean)
        /** The server's controller state: what it accepts, and the shuffle and repeat it is in. */
        fun onControllerState(commands: List<String>, shuffle: Boolean, repeat: String)
        fun onStreamActiveChanged(active: Boolean)
    }

    companion object {
        private const val TAG = "NativeSendspin"

        // Off the protocol default (8928) so a co-installed sendspinlite or
        // other client can keep it; retried upward on bind failure.
        private const val BASE_SERVER_PORT = 8930
        private const val PORT_ATTEMPTS = 4

        private const val AUDIO_BUFFER_CAPACITY = 1_000_000

        private const val FEEDBACK_INTERVAL_MS = 5L
        private const val POSITION_PUSH_INTERVAL_MS = 5_000L

        // Shell-level reconnect: the library reports the connected edge but
        // does not redial on its own.
        private val RECONNECT_DELAYS_MS = longArrayOf(1_000, 2_000, 4_000, 8_000, 15_000, 30_000)
        private const val RECONNECT_PARKED_MS = 60_000L

        private const val PREFS = "sendspin_native"
        private const val PREF_STATIC_DELAY = "static_delay_ms"
    }

    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val output = NativeAudioOutput()

    private val controlThread = HandlerThread("SendspinNativeControl").also { it.start() }
    private val controlHandler = Handler(controlThread.looper)

    private val destroyed = AtomicBoolean(false)
    @Volatile private var handle = 0L
    @Volatile private var serverUrl: String? = null
    @Volatile private var connected = false
    @Volatile private var syncOffsetMs = initialSyncOffsetMs
    @Volatile private var streamActive = false
    private var reconnectAttempt = 0

    @Volatile private var feedbackThread: Thread? = null

    val isConnected: Boolean get() = connected
    val isTimeSynced: Boolean get() = handle != 0L && NativeSendspin.nativeIsTimeSynced(handle)
    val trackProgressMs: Int get() = if (handle != 0L) NativeSendspin.nativeGetTrackProgressMs(handle) else 0

    private val reconnectRunnable = Runnable {
        val url = serverUrl
        if (destroyed.get() || connected || url == null) return@Runnable
        Log.i(TAG, "Reconnecting (attempt ${reconnectAttempt + 1})")
        NativeSendspin.nativeConnect(handle, url)
        reconnectAttempt++
        scheduleReconnect()
    }

    init {
        output.setDuckGain(initialDuckFactor)
        output.setMediaGain(initialMediaGain)

        // Preference order is what the server picks from; preferred codec
        // first, PCM always last as the universal fallback.
        val codecs = linkedSetOf(
            when (preferredCodec) {
                "opus" -> NativeSendspin.CODEC_OPUS
                "pcm" -> NativeSendspin.CODEC_PCM
                else -> NativeSendspin.CODEC_FLAC
            },
            NativeSendspin.CODEC_FLAC,
            NativeSendspin.CODEC_OPUS,
            NativeSendspin.CODEC_PCM,
        )
        val formats = ArrayList<Int>()
        for (codec in codecs) {
            for (channels in intArrayOf(2, 1)) {
                formats.addAll(listOf(codec, channels, 48_000, 16))
            }
        }

        handle = NativeSendspin.nativeCreate(
            callbacks = NativeCallbacks(),
            clientId = clientId,
            name = playerName,
            productName = "Kiosk Satellite",
            manufacturer = "Kiosk Satellite",
            softwareVersion = softwareVersion,
            serverPort = BASE_SERVER_PORT,
            audioBufferCapacity = AUDIO_BUFFER_CAPACITY,
            fixedDelayUs = 0,
            initialStaticDelayMs = prefs.getInt(PREF_STATIC_DELAY, 0),
            formats = formats.toIntArray(),
        )
        if (handle == 0L) {
            Log.e(TAG, "nativeCreate failed")
        } else {
            var startedNative = NativeSendspin.nativeStart(handle)
            var attempt = 1
            while (!startedNative && attempt < PORT_ATTEMPTS) {
                // Bind failure: recreate on the next port up.
                NativeSendspin.nativeDestroy(handle)
                handle = NativeSendspin.nativeCreate(
                    callbacks = NativeCallbacks(),
                    clientId = clientId,
                    name = playerName,
                    productName = "Kiosk Satellite",
                    manufacturer = "Kiosk Satellite",
                    softwareVersion = softwareVersion,
                    serverPort = BASE_SERVER_PORT + attempt,
                    audioBufferCapacity = AUDIO_BUFFER_CAPACITY,
                    fixedDelayUs = 0,
                    initialStaticDelayMs = prefs.getInt(PREF_STATIC_DELAY, 0),
                    formats = formats.toIntArray(),
                )
                startedNative = handle != 0L && NativeSendspin.nativeStart(handle)
                attempt++
            }
            if (!startedNative) {
                Log.e(TAG, "Native engine failed to start on any port")
                if (handle != 0L) NativeSendspin.nativeDestroy(handle)
                handle = 0L
            }
        }

        startFeedbackLoop()
        controlHandler.postDelayed(::pushPosition, POSITION_PUSH_INTERVAL_MS)
    }

    fun connect(url: String) {
        if (destroyed.get() || handle == 0L) return
        serverUrl = url
        reconnectAttempt = 0
        controlHandler.removeCallbacks(reconnectRunnable)
        Log.i(TAG, "Connecting to $url")
        NativeSendspin.nativeConnect(handle, url)
        scheduleReconnect()
    }

    /**
     * Live sync offset, no restart. Implemented as a bias on the playback
     * feedback timestamp: reporting audio as finishing later than it does
     * makes the library schedule everything correspondingly earlier, so a
     * negative offset plays earlier, matching the classic engine's setting.
     */
    fun setSyncOffset(ms: Long) {
        syncOffsetMs = ms
    }

    fun setDuckFactor(factor: Float) = output.setDuckGain(factor)

    fun setMediaGain(gain: Float) = output.setMediaGain(gain)

    fun publishVolume(volumePct: Int, muted: Boolean) {
        if (handle == 0L) return
        NativeSendspin.nativeUpdateVolume(handle, volumePct)
        NativeSendspin.nativeUpdateMuted(handle, muted)
    }

    /**
     * A seek's displacement from the engine's own progress, in ms. Music
     * Assistant restarts the stream at the new position but sends no fresh
     * metadata progress for it, so the engine keeps extrapolating from the
     * report before the seek and the UI would show the old place while the
     * audio plays the new one. The target is adopted here and carried by
     * every position push until the server's next real metadata report,
     * which re-bases everything.
     */
    @Volatile private var seekOffsetMs = 0L

    /** [arg] is the command's value where it takes one: the seek position in ms. */
    fun sendCommand(command: String, arg: Long = 0L): Boolean {
        if (handle == 0L) return false
        val sent = NativeSendspin.nativeSendCommand(handle, command, arg)
        if (sent && command == "seek") {
            seekOffsetMs = arg - NativeSendspin.nativeGetTrackProgressMs(handle)
            events.onPositionUpdate(arg)
        }
        return sent
    }

    /** The engine's progress with any seek displacement applied. */
    private fun displayedProgressMs(): Long =
        (NativeSendspin.nativeGetTrackProgressMs(handle).toLong() + seekOffsetMs).coerceAtLeast(0L)

    fun onNetworkAvailable() {
        if (destroyed.get() || handle == 0L) return
        NativeSendspin.nativeSetNetworkReady(handle, true)
        if (!connected && serverUrl != null) {
            reconnectAttempt = 0
            controlHandler.removeCallbacks(reconnectRunnable)
            controlHandler.post(reconnectRunnable)
        }
    }

    fun setNetworkReady(ready: Boolean) {
        if (handle != 0L) NativeSendspin.nativeSetNetworkReady(handle, ready)
    }

    fun buildStats(): Map<String, Any?> = mapOf(
        "engine" to "native",
        "outputQueueMs" to output.outputQueueMs(),
        "framesWritten" to output.totalFramesWritten(),
        "audioTrackUnderruns" to output.underrunCount(),
        "sinkLatencyMs" to output.sinkLatencyMs(),
        "timeSynced" to isTimeSynced,
        "progressMs" to trackProgressMs,
    )

    fun destroy() {
        if (!destroyed.compareAndSet(false, true)) return
        controlHandler.removeCallbacksAndMessages(null)
        feedbackThread?.interrupt()
        feedbackThread = null
        val h = handle
        handle = 0L
        if (h != 0L) {
            NativeSendspin.nativeDisconnect(h, NativeSendspin.REASON_USER_REQUEST)
            NativeSendspin.nativeDestroy(h)
        }
        output.release()
        controlThread.quitSafely()
    }

    // ------------------------------------------------------------------

    private fun scheduleReconnect() {
        if (destroyed.get()) return
        val delay = RECONNECT_DELAYS_MS.getOrElse(reconnectAttempt) { RECONNECT_PARKED_MS }
        controlHandler.removeCallbacks(reconnectRunnable)
        controlHandler.postDelayed(reconnectRunnable, delay)
    }

    private fun startFeedbackLoop() {
        val thread = Thread {
            Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
            while (!destroyed.get()) {
                val h = handle
                if (h != 0L && output.isStarted) {
                    val progress = output.takePresentedFramesDelta()
                    if (progress != null) {
                        val bias = progress.finishBiasUs - syncOffsetMs * 1000
                        NativeSendspin.nativeNotifyAudioPlayed(
                            h,
                            progress.frames.toInt(),
                            NativeSendspin.nativeMonotonicTimeUs() + bias,
                        )
                    }
                }
                try {
                    Thread.sleep(FEEDBACK_INTERVAL_MS)
                } catch (_: InterruptedException) {
                    break
                }
            }
        }
        thread.name = "SendspinNativeFeedback"
        thread.isDaemon = true
        feedbackThread = thread
        thread.start()
    }

    private fun pushPosition() {
        if (destroyed.get()) return
        if (streamActive && handle != 0L) {
            events.onPositionUpdate(displayedProgressMs())
        }
        controlHandler.postDelayed(::pushPosition, POSITION_PUSH_INTERVAL_MS)
    }

    // ------------------------------------------------------------------

    private inner class NativeCallbacks : NativeSendspinCallbacks {

        override fun onAudioWrite(buffer: ByteBuffer, length: Int, timeoutMs: Int): Int =
            output.write(buffer, length, timeoutMs)

        override fun onStreamStart(sampleRate: Int, channels: Int, bitDepth: Int) {
            Log.i(TAG, "Stream start sr=$sampleRate ch=$channels bd=$bitDepth")
            output.start(sampleRate, channels, bitDepth)
            streamActive = true
            events.onStreamActiveChanged(true)
        }

        override fun onStreamEnd() {
            Log.i(TAG, "Stream end")
            streamActive = false
            output.pause()
            events.onStreamActiveChanged(false)
        }

        override fun onVolumeChanged(volume: Int) = events.onServerVolume(volume)

        override fun onMuteChanged(muted: Boolean) = events.onServerMuted(muted)

        override fun onStaticDelayChanged(delayMs: Int) {
            prefs.edit().putInt(PREF_STATIC_DELAY, delayMs).apply()
        }

        override fun onMetadata(
            title: String?,
            artist: String?,
            album: String?,
            albumArtist: String?,
            artworkUrl: String?,
            year: Int,
            track: Int,
            progressMs: Long,
            durationMs: Long,
            timestampUs: Long,
        ) {
            // A real server report: whatever it says about the position
            // outranks a seek the client carried on its own.
            if (progressMs >= 0) seekOffsetMs = 0L
            events.onMetadata(title, artist, album, artworkUrl, progressMs, durationMs)
        }

        override fun onGroupUpdate(playbackState: Int, groupId: String?, groupName: String?) {
            when (playbackState) {
                1 -> events.onPlaybackStateChanged("playing")
                0 -> events.onPlaybackStateChanged("stopped")
            }
        }

        override fun onControllerState(
            commands: String,
            volume: Int,
            muted: Boolean,
            repeat: String,
            shuffle: Boolean,
            seekMaxMs: Long,
        ) {
            events.onControllerState(
                commands.split(',').map { it.trim() }.filter { it.isNotEmpty() },
                shuffle,
                repeat,
            )
        }

        override fun onTimeSyncUpdated(errorUs: Float) {}

        override fun onConnectionChanged(connected: Boolean, serverName: String?) {
            this@NativeSendspinSession.connected = connected
            if (connected) {
                reconnectAttempt = 0
                controlHandler.removeCallbacks(reconnectRunnable)
            } else {
                streamActive = false
                output.pause()
                events.onStreamActiveChanged(false)
                if (!destroyed.get() && serverUrl != null) {
                    controlHandler.post { scheduleReconnect() }
                }
            }
            events.onConnectionChanged(connected, serverName)
        }

        override fun onRequestHighPerformance() {
            Log.d(TAG, "High-performance networking requested")
        }

        override fun onReleaseHighPerformance() {
            Log.d(TAG, "High-performance networking released")
        }
    }
}
