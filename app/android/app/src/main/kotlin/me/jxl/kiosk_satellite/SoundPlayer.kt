package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.MediaPlayer
import android.media.audiofx.Visualizer
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
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

    /**
     * Each sound's own volume, before the assistant fader. Kept so a
     * fader move mid-utterance (the assistant slider, a fixed-volume
     * master change) can re-derive every live player's effective level
     * (issues #62, #79).
     */
    private val baseVolumes = mutableMapOf<String, Float>()

    /** Per-sound level taps, feeding the page's reactive bar. */
    private val visualizers = mutableMapOf<String, Visualizer>()

    /** Sounds whose SCO link this player brought up itself (call-route
     *  output selected while the mic does not hold the link). */
    private val scoOwnedSounds = mutableSetOf<String>()

    /**
     * Decoding and clip playback, off the main thread.
     *
     * Nothing here may run on the main thread: the dashboard's WebView
     * renders on it, and holding it is what the whole clip path exists to
     * avoid. Everything that talks to Dart is posted back to [mainHandler].
     */
    private val worker = HandlerThread("ks-sound").apply { start() }
    private val workerHandler = Handler(worker.looper)

    /** Live clip playbacks by sound id, alongside [players]. */
    private val tracks = mutableMapOf<String, AudioTrack>()

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
                    val id = call.argument<String>("id") ?: ""
                    // Whichever path it took; only one of these does anything.
                    endClip(id, null)
                    finish(id, null)
                    result.success(true)
                }
                "setVolume" -> {
                    val id = call.argument<String>("id") ?: ""
                    val v = (call.argument<Double>("volume") ?: 1.0)
                        .toFloat().coerceIn(0f, 1f)
                    val e = v * VolumeController.assistGain
                    players[id]?.let {
                        baseVolumes[id] = v
                        try { it.setVolume(e, e) } catch (_: IllegalStateException) {}
                    }
                    synchronized(tracks) { tracks[id] }?.let {
                        baseVolumes[id] = v
                        try { it.setVolume(e.coerceIn(0f, 1f)) } catch (_: Exception) {}
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        // A fader moved mid-utterance - the assistant slider, or a
        // fixed-volume master change - and must reach the sound already
        // playing.
        VolumeController.addListener {
            for ((id, mp) in players) {
                val e = (baseVolumes[id] ?: 1f) * VolumeController.assistGain
                try { mp.setVolume(e, e) } catch (_: IllegalStateException) {}
            }
            val live = synchronized(tracks) { tracks.toMap() }
            for ((id, track) in live) {
                val e = (baseVolumes[id] ?: 1f) * VolumeController.assistGain
                try { track.setVolume(e.coerceIn(0f, 1f)) } catch (_: Exception) {}
            }
        }
    }

    private fun play(id: String, source: String, volume: Double): Boolean {
        if (id.isEmpty() || source.isEmpty()) return false
        // Same id twice = replace: the page re-firing a chime wants the new
        // one, not two overlapped copies.
        players.remove(id)?.release()
        stopTrack(id)
        val target = AudioRouting.currentOutput()
        // A short local file plays from decoded PCM instead: no NuPlayer, no
        // codec, no teardown, and none of it on this thread. The call route
        // stays on MediaPlayer, where the SCO handling already lives.
        val callRouteWanted =
            target != null && target.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
        if (!callRouteWanted && !source.startsWith("http")) {
            val v = volume.toFloat().coerceIn(0f, 1f)
            baseVolumes[id] = v
            workerHandler.post { startClip(id, source, target) }
            return true
        }
        val v = volume.toFloat().coerceIn(0f, 1f)
        baseVolumes[id] = v
        return playWithMediaPlayer(id, source, target)
    }

    /**
     * The general path: anything streamed, long, or bound for the call
     * route. Reads its volume from [baseVolumes], which the caller has
     * already set, so the clip path can fall back into it unchanged.
     */
    private fun playWithMediaPlayer(
        id: String,
        source: String,
        target: AudioDeviceInfo?,
    ): Boolean {
        // The Bluetooth CALL route only carries communication audio: a
        // media-usage stream pinned to it plays into nothing (and while the
        // link is up, the same headset's A2DP profile is suspended, so the
        // call route is the ONLY way to be heard there). Play call-route
        // sounds as communication audio; everything else stays media.
        val callRoute =
            target != null && target.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
        val mp = MediaPlayer()
        players[id] = mp
        return try {
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(
                        if (callRoute) AudioAttributes.USAGE_VOICE_COMMUNICATION
                        else AudioAttributes.USAGE_MEDIA,
                    )
                    .setContentType(
                        if (callRoute) AudioAttributes.CONTENT_TYPE_SPEECH
                        else AudioAttributes.CONTENT_TYPE_MUSIC,
                    )
                    .build(),
            )
            if (callRoute) ensureScoLink(id, target!!)
            mp.setDataSource(source)
            val e = (baseVolumes[id] ?: 1f) * VolumeController.assistGain
            mp.setVolume(e, e)
            mp.setOnPreparedListener { player ->
                if (players[id] !== player) return@setOnPreparedListener
                if (Build.VERSION.SDK_INT >= 28) {
                    target?.let { player.preferredDevice = it }
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
     * Play a decoded clip on the worker thread.
     *
     * Falls back to a MediaPlayer when the file is not one [SoundClips] can
     * hold - a long download, or something it could not decode - so the
     * caller never has to know which path a sound took.
     */
    private fun startClip(id: String, source: String, target: AudioDeviceInfo?) {
        val clip = SoundClips.get(source)
        if (clip == null) {
            mainHandler.post { playWithMediaPlayer(id, source, target) }
            return
        }
        val channelMask = if (clip.channels >= 2) {
            AudioFormat.CHANNEL_OUT_STEREO
        } else {
            AudioFormat.CHANNEL_OUT_MONO
        }
        val track = try {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(clip.sampleRate)
                        .setChannelMask(channelMask)
                        .build(),
                )
                // The whole clip lives in the track: one write, then play.
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(clip.pcm.size)
                .build()
        } catch (e: Exception) {
            Log.w(TAG, "clip track failed for $id: ${e.message}")
            mainHandler.post { playWithMediaPlayer(id, source, target) }
            return
        }
        try {
            track.write(clip.pcm, 0, clip.pcm.size)
            val v = (baseVolumes[id] ?: 1f) * VolumeController.assistGain
            track.setVolume(v.coerceIn(0f, 1f))
            if (Build.VERSION.SDK_INT >= 28) target?.let { track.preferredDevice = it }
            synchronized(tracks) { tracks[id] = track }
            track.play()
        } catch (e: Exception) {
            Log.w(TAG, "clip play failed for $id: ${e.message}")
            synchronized(tracks) { tracks.remove(id) }
            try { track.release() } catch (_: Exception) {}
            mainHandler.post { playWithMediaPlayer(id, source, target) }
            return
        }
        mainHandler.post { channel.invokeMethod("started", mapOf("id" to id)) }
        emitClipLevels(id, clip)
        // AudioTrack has no completion callback worth trusting on a static
        // buffer, and the duration is known exactly, so the end is scheduled.
        workerHandler.postDelayed({ endClip(id, null) }, clip.durationMs.toLong() + 60)
    }

    /**
     * Walk the clip's precomputed envelope in step with playback, so the
     * page's reactive bar moves for a clip exactly as it does for anything
     * else. No Visualizer, which means no RECORD_AUDIO and no per-sound
     * effect attach.
     */
    private fun emitClipLevels(id: String, clip: SoundClips.Clip) {
        val step = SoundClips.LEVEL_WINDOW_MS.toLong()
        for ((i, level) in clip.levels.withIndex()) {
            workerHandler.postDelayed({
                val live = synchronized(tracks) { tracks.containsKey(id) }
                if (!live) return@postDelayed
                mainHandler.post {
                    channel.invokeMethod(
                        "level",
                        mapOf("id" to id, "level" to level.toDouble()),
                    )
                }
            }, i * step)
        }
    }

    /** Stop and release a clip's track, if it has one. Returns whether it did. */
    private fun stopTrack(id: String): Boolean {
        val track = synchronized(tracks) { tracks.remove(id) } ?: return false
        try {
            track.pause()
            track.flush()
            track.stop()
        } catch (_: Exception) {
        }
        try {
            track.release()
        } catch (_: Exception) {
        }
        return true
    }

    /** A clip reaching its end, or being stopped: reported like any sound. */
    private fun endClip(id: String, error: String?) {
        if (!stopTrack(id)) return
        baseVolumes.remove(id)
        mainHandler.post {
            channel.invokeMethod("ended", mapOf("id" to id, "error" to error))
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

    /**
     * A call-route sound needs the SCO link up. When a Bluetooth mic is
     * selected the mic already holds it for the life of capture; otherwise
     * bring it up for this sound and remember to tear it down at its end.
     * The first moments can be quiet while the link ramps - selecting the
     * Bluetooth mic alongside is the combination that avoids that.
     */
    private fun ensureScoLink(id: String, target: AudioDeviceInfo) {
        if (Build.VERSION.SDK_INT < 31) return
        val am = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (am.communicationDevice?.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO) return
        val comm = am.availableCommunicationDevices.firstOrNull {
            it.type == target.type && it.address == target.address
        } ?: am.availableCommunicationDevices.firstOrNull { it.type == target.type }
        val up = try {
            comm != null && am.setCommunicationDevice(comm)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "call-route link rejected: ${e.message}")
            false
        }
        if (up) scoOwnedSounds.add(id) else Log.w(TAG, "call-route link unavailable for $id")
    }

    private fun finish(id: String, error: String?) {
        visualizers.remove(id)?.let {
            try {
                it.enabled = false
                it.release()
            } catch (_: Exception) {}
        }
        if (scoOwnedSounds.remove(id) && scoOwnedSounds.isEmpty() &&
            !AudioRouting.micHoldsCommDevice && Build.VERSION.SDK_INT >= 31
        ) {
            val am = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.clearCommunicationDevice()
        }
        baseVolumes.remove(id)
        val mp = players.remove(id) ?: return
        // Releasing tears down the decoder and its track, which is tens of
        // milliseconds of this thread - and this thread is the one drawing
        // the dashboard. The player is already out of the map, so nothing
        // can reach it while the worker lets it go.
        workerHandler.post {
            try { mp.release() } catch (_: Exception) {}
        }
        channel.invokeMethod("ended", mapOf("id" to id, "error" to error))
    }
}
