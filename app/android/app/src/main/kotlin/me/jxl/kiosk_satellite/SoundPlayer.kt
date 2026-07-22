package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.audiofx.Visualizer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

/**
 * Native playback for page-delegated sounds (Voice Satellite chimes and
 * TTS): local files the Dart side fetched, or its loopback relay for
 * still-streaming sources, played through a MediaPlayer that honors the
 * user's speaker selection - the things the WebView's audio cannot do
 * (no device routing, autoplay-gated).
 *
 * Contract: `play {id, source, volume}` starts (`source` is a file path or
 * an http URL; same id replaces), `stop {id}` ends early. A `started {id}`
 * callback fires when audio actually begins, and every sound reports back
 * exactly once via `ended {id, error?}` - completion, failure and stop all
 * funnel through it, so the Dart side can clean up without special cases.
 */
class SoundPlayer(context: Context, messenger: BinaryMessenger) {
    companion object {
        const val CHANNEL = "kiosk_satellite/sound"
        private const val TAG = "SoundPlayer"
    }

    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Live players by sound id. Channel calls arrive on the main thread. */
    private val players = mutableMapOf<String, MediaPlayer>()

    /** Per-sound level taps, feeding the page's reactive bar. */
    private val visualizers = mutableMapOf<String, Visualizer>()

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> result.success(
                    play(
                        call.argument<String>("id") ?: "",
                        call.argument<String>("source") ?: "",
                        call.argument<Double>("volume") ?: 1.0,
                    ),
                )
                "stop" -> {
                    finish(call.argument<String>("id") ?: "", null)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun play(id: String, source: String, volume: Double): Boolean {
        if (id.isEmpty() || source.isEmpty()) return false
        // Same id twice = replace: the page re-firing a chime wants the new
        // one, not two overlapped copies.
        players.remove(id)?.release()
        val mp = MediaPlayer()
        players[id] = mp
        return try {
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
            )
            mp.setDataSource(source)
            val v = volume.toFloat().coerceIn(0f, 1f)
            mp.setVolume(v, v)
            mp.setOnPreparedListener { player ->
                if (players[id] !== player) return@setOnPreparedListener
                if (Build.VERSION.SDK_INT >= 28) {
                    AudioRouting.currentOutput()?.let { player.preferredDevice = it }
                }
                player.start()
                // The page times stop-word arming and its speaking UI off
                // real audio start, not off the play call.
                channel.invokeMethod("started", mapOf("id" to id))
                startLevelCapture(id, player)
            }
            mp.setOnCompletionListener { finish(id, null) }
            mp.setOnErrorListener { _, what, extra ->
                finish(id, "MediaPlayer error $what/$extra")
                true
            }
            mp.prepareAsync()
            true
        } catch (e: Exception) {
            Log.w(TAG, "play($id) failed: ${e.message}")
            finish(id, e.message ?: "play failed")
            false
        }
    }

    /**
     * Stream playback levels to the page at the capture rate (<= 20 Hz) so
     * its reactive bar can animate to audio it never touches. The measure is
     * mean |amplitude| normalized 0..1, matching what the page's analyser
     * computes from getByteTimeDomainData for element playback. Best-effort:
     * Visualizer needs RECORD_AUDIO and an OEM that implements it - without
     * either the sound still plays, the bar just stays dark.
     */
    private fun startLevelCapture(id: String, mp: MediaPlayer) {
        try {
            val vis = Visualizer(mp.audioSessionId)
            vis.captureSize = Visualizer.getCaptureSizeRange()[0]
            var last = -1f
            vis.setDataCaptureListener(
                object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(
                        v: Visualizer,
                        waveform: ByteArray,
                        samplingRate: Int,
                    ) {
                        var sum = 0
                        for (b in waveform) sum += abs((b.toInt() and 0xFF) - 128)
                        val level = sum.toFloat() / waveform.size / 128f
                        // Near-identical consecutive levels are visual no-ops;
                        // skip the bridge round-trip for them.
                        if (abs(level - last) < 0.008f) return
                        last = level
                        mainHandler.post {
                            if (players[id] != null) {
                                channel.invokeMethod(
                                    "level",
                                    mapOf("id" to id, "level" to level.toDouble()),
                                )
                            }
                        }
                    }

                    override fun onFftDataCapture(
                        v: Visualizer,
                        fft: ByteArray,
                        samplingRate: Int,
                    ) {}
                },
                minOf(Visualizer.getMaxCaptureRate(), 20000),
                true,
                false,
            )
            vis.enabled = true
            visualizers[id] = vis
        } catch (e: Exception) {
            Log.w(TAG, "level capture unavailable: ${e.message}")
        }
    }

    private fun finish(id: String, error: String?) {
        visualizers.remove(id)?.let {
            try {
                it.enabled = false
                it.release()
            } catch (_: Exception) {}
        }
        val mp = players.remove(id) ?: return
        try { mp.release() } catch (_: Exception) {}
        channel.invokeMethod("ended", mapOf("id" to id, "error" to error))
    }
}
