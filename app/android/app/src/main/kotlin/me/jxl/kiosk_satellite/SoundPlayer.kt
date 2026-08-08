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
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.exoplayer.audio.TeeAudioProcessor
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.abs

/**
 * Native playback for page-delegated sounds (Voice Satellite chimes and
 * TTS): local files the Dart side fetched, or its loopback relay for
 * still-streaming sources, played on paths that honor the user's speaker
 * selection - the things the WebView's audio cannot do (no device routing,
 * autoplay-gated).
 *
 * Short local files play from decoded PCM on a static AudioTrack; streamed
 * sources play on Media3 ExoPlayer, whose in-process pipeline outputs to an
 * app-owned AudioTrack - the kind whose device pin OEM audio policies honor
 * where MediaPlayer's is ignored (issue #93). MediaPlayer remains only for
 * the Bluetooth call route, where the SCO handling lives.
 *
 * Contract: `play {id, source, volume}` starts (`source` is a file path or
 * an http URL; same id replaces), `stop {id}` ends early. A `started {id}`
 * callback fires when audio actually begins, and every sound reports back
 * exactly once via `ended {id, error?}` - completion, failure and stop all
 * funnel through it, so the Dart side can clean up without special cases.
 */
@androidx.annotation.OptIn(UnstableApi::class)
class SoundPlayer(context: Context, messenger: BinaryMessenger) {
    companion object {
        const val CHANNEL = "kiosk_satellite/sound"
        private const val TAG = "SoundPlayer"

        /** Routing re-assert cap per sound, so a platform that keeps
         *  winning cannot ping-pong the route forever. */
        private const val MAX_ROUTING_REASSERTS = 5

        /** Startup and post-rebuffer targets for streamed sounds. TTS wants
         *  first audio fast; ExoPlayer's 2.5s default reads as lag. */
        private const val STREAM_STARTUP_BUFFER_MS = 250
        private const val STREAM_REBUFFER_MS = 500

        /** Level-tap envelope: per-window decay (50 ms windows, so a pause
         *  of a few seconds re-adapts), the mean amplitude below which a
         *  sound counts as silent rather than normalized up, and the most
         *  gain normalization may apply - full normalization pegs every
         *  syllable at 1.0, which reads as a bar stuck at the top. */
        private const val ENVELOPE_DECAY = 0.98
        private const val ENVELOPE_FLOOR = 0.008
        private const val MAX_LEVEL_BOOST = 5.0
    }

    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Live call-route players by sound id. Channel calls arrive on the
     *  main thread. */
    private val players = mutableMapOf<String, MediaPlayer>()

    /** Live streamed-sound players by sound id, alongside [players]. */
    private val exoPlayers = mutableMapOf<String, ExoPlayer>()

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

    /** Routing re-asserts done per live sound, against [MAX_ROUTING_REASSERTS].
     *  Mutated only on the main thread (the listeners land on [mainHandler]). */
    private val routingReasserts = mutableMapOf<String, Int>()

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
                    exoPlayers[id]?.let {
                        baseVolumes[id] = v
                        it.volume = e.coerceIn(0f, 1f)
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
            for ((id, exo) in exoPlayers) {
                val e = (baseVolumes[id] ?: 1f) * VolumeController.assistGain
                exo.volume = e.coerceIn(0f, 1f)
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
        exoPlayers.remove(id)?.release()
        stopTrack(id)
        val target = AudioRouting.currentOutput()
        val callRouteWanted =
            target != null && target.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
        val v = volume.toFloat().coerceIn(0f, 1f)
        baseVolumes[id] = v
        // The call route stays on MediaPlayer, where the SCO handling
        // already lives. A short local file plays from decoded PCM: no
        // codec spin-up, no teardown, and none of it on this thread.
        // Everything else - streamed TTS above all - goes to ExoPlayer.
        if (callRouteWanted) return playWithMediaPlayer(id, source, target)
        if (!source.startsWith("http")) {
            workerHandler.post { startClip(id, source, target) }
            return true
        }
        return playWithExo(id, source, target)
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
                    target?.let {
                        player.preferredDevice = it
                        enforceRouting(id, player)
                    }
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
            mainHandler.post { playWithExo(id, source, target) }
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
            mainHandler.post { playWithExo(id, source, target) }
            return
        }
        try {
            track.write(clip.pcm, 0, clip.pcm.size)
            val v = (baseVolumes[id] ?: 1f) * VolumeController.assistGain
            track.setVolume(v.coerceIn(0f, 1f))
            if (Build.VERSION.SDK_INT >= 28) {
                target?.let {
                    track.preferredDevice = it
                    enforceRouting(id, track)
                }
            }
            synchronized(tracks) { tracks[id] = track }
            track.play()
        } catch (e: Exception) {
            Log.w(TAG, "clip play failed for $id: ${e.message}")
            synchronized(tracks) { tracks.remove(id) }
            try { track.release() } catch (_: Exception) {}
            mainHandler.post { playWithExo(id, source, target) }
            return
        }
        mainHandler.post { channel.invokeMethod("started", mapOf("id" to id)) }
        emitClipLevels(id, clip)
        // AudioTrack has no completion callback worth trusting on a static
        // buffer, and the duration is known exactly, so the end is scheduled.
        workerHandler.postDelayed({ endClip(id, null) }, clip.durationMs.toLong() + 60)
    }

    /**
     * Streamed playback on Media3 ExoPlayer. Its whole pipeline runs in
     * this process, so the output is an app-owned AudioTrack: the kind of
     * track whose device pin OEM audio policies honor where MediaPlayer's
     * is ignored, and the sink re-applies the pin to every track it
     * rebuilds mid-stream (format change, sink error). A TeeAudioProcessor
     * taps the decoded PCM for the page's reactive bar, replacing the
     * Visualizer and its RECORD_AUDIO dependency for these sounds.
     */
    private fun playWithExo(id: String, source: String, target: AudioDeviceInfo?): Boolean {
        return try {
            val player = ExoPlayer.Builder(appContext, exoRenderersFactory(id))
                // Media3's default HTTP stack announces itself, not the app;
                // a Home Assistant access log should name the kiosk that
                // pulled the TTS clip.
                .setMediaSourceFactory(
                    DefaultMediaSourceFactory(
                        DefaultDataSource.Factory(
                            appContext,
                            DefaultHttpDataSource.Factory()
                                .setUserAgent(AppIdentity.userAgent),
                        ),
                    ),
                )
                .setLoadControl(
                    DefaultLoadControl.Builder()
                        .setBufferDurationsMs(
                            DefaultLoadControl.DEFAULT_MIN_BUFFER_MS,
                            DefaultLoadControl.DEFAULT_MAX_BUFFER_MS,
                            STREAM_STARTUP_BUFFER_MS,
                            STREAM_REBUFFER_MS,
                        )
                        .build(),
                )
                .build()
            exoPlayers[id] = player
            player.setAudioAttributes(
                androidx.media3.common.AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build(),
                /* handleAudioFocus = */ false,
            )
            target?.let { player.setPreferredAudioDevice(it) }
            val e = (baseVolumes[id] ?: 1f) * VolumeController.assistGain
            player.volume = e.coerceIn(0f, 1f)
            player.addListener(object : Player.Listener {
                private var reported = false
                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    if (!isPlaying || reported) return
                    if (exoPlayers[id] !== player) return
                    reported = true
                    // The page times stop-word arming and its speaking UI
                    // off real audio start, not off the play call.
                    channel.invokeMethod("started", mapOf("id" to id))
                    scheduleRoutingKicks(id, player)
                }

                override fun onPlaybackStateChanged(state: Int) {
                    if (state == Player.STATE_ENDED && exoPlayers[id] === player) {
                        finish(id, null)
                    }
                }

                override fun onPlayerError(error: PlaybackException) {
                    if (exoPlayers[id] === player) finish(id, error.errorCodeName)
                }
            })
            player.setMediaItem(MediaItem.fromUri(source))
            player.prepare()
            player.playWhenReady = true
            true
        } catch (e: Exception) {
            Log.w(TAG, "exo play($id) failed: ${e.message}")
            finish(id, e.message ?: "play failed")
            false
        }
    }

    /**
     * Some policies shove a fresh track onto their own preferred device
     * right around playback start (issue #93's Lenovo does it to every
     * sound). Re-setting the preference on the live sink re-issues the pin
     * on the actual AudioTrack, which is exactly the nudge that pulled clip
     * tracks back. Re-resolved per kick: device ids are transient.
     */
    private fun scheduleRoutingKicks(id: String, player: ExoPlayer) {
        for (delay in longArrayOf(300, 1200)) {
            mainHandler.postDelayed({
                if (exoPlayers[id] !== player) return@postDelayed
                val selected = AudioRouting.currentOutput() ?: return@postDelayed
                player.setPreferredAudioDevice(selected)
            }, delay)
        }
    }

    /** An audio-only renderers factory whose sink taps decoded PCM for the
     *  page's reactive bar. One per sound: the tap closure carries the id. */
    private fun exoRenderersFactory(id: String): DefaultRenderersFactory =
        object : DefaultRenderersFactory(appContext) {
            override fun buildAudioSink(
                context: Context,
                enableFloatOutput: Boolean,
                enableAudioTrackPlaybackParams: Boolean,
            ): AudioSink = DefaultAudioSink.Builder(context)
                .setAudioProcessors(arrayOf(levelTap(id)))
                .build()
        }

    /**
     * Levels per [SoundClips.LEVEL_WINDOW_MS] of the PCM flowing into the
     * sink, for the page's reactive bar. Each window's mean |amplitude| is
     * reported relative to a slowly decaying envelope of the sound's own
     * recent peaks, not as an absolute: the Visualizer this replaces
     * normalized its waveform toward full scale, and the bar is tuned for
     * that look - raw speech PCM averages a tenth of full scale and would
     * barely move it.
     *
     * The tap sees PCM as it enters the sink, which runs a track buffer
     * ahead of the speaker (and the whole startup burst arrives at once),
     * so emissions are scheduled on the stream's own clock: window k of a
     * sound is posted at first-audio time plus k windows, which is when
     * that audio is actually heard. A rebuffer would drift the remainder;
     * for one TTS utterance on a LAN that trade is fine.
     */
    private fun levelTap(id: String): TeeAudioProcessor =
        TeeAudioProcessor(object : TeeAudioProcessor.AudioBufferSink {
            private var sampleRate = 44100
            private var channels = 2
            private var pcm16 = true
            private var sum = 0L
            private var count = 0
            private var envelope = 0.0
            private var streamStartUptime = 0L
            private var windowsEmitted = 0L
            private var lastSent = -1.0

            override fun flush(sampleRate: Int, channelCount: Int, encoding: Int) {
                this.sampleRate = sampleRate
                this.channels = channelCount
                pcm16 = encoding == C.ENCODING_PCM_16BIT
                sum = 0
                count = 0
                streamStartUptime = 0
                windowsEmitted = 0
                lastSent = -1.0
            }

            override fun handleBuffer(buffer: ByteBuffer) {
                if (!pcm16) return
                val window = sampleRate * channels * SoundClips.LEVEL_WINDOW_MS / 1000
                var i = buffer.position()
                val limit = buffer.limit()
                while (i + 1 < limit) {
                    val s = (
                        (buffer.get(i + 1).toInt() shl 8) or
                            (buffer.get(i).toInt() and 0xFF)
                        ).toShort().toInt()
                    sum += abs(s)
                    count++
                    if (count >= window) {
                        val mean = sum.toDouble() / count / 32768.0
                        sum = 0
                        count = 0
                        envelope = maxOf(envelope * ENVELOPE_DECAY, mean)
                        val gain =
                            minOf(MAX_LEVEL_BOOST, 1.0 / maxOf(envelope, ENVELOPE_FLOOR))
                        val level = (mean * gain).coerceIn(0.0, 1.0)
                        if (streamStartUptime == 0L) {
                            streamStartUptime = android.os.SystemClock.uptimeMillis()
                        }
                        val due = streamStartUptime +
                            windowsEmitted * SoundClips.LEVEL_WINDOW_MS
                        windowsEmitted++
                        // Near-identical consecutive levels are visual no-ops
                        // (the page quantizes to 0.05 steps); skip the bridge
                        // round-trip for them, like the Visualizer path does.
                        if (abs(level - lastSent) < 0.008) {
                            i += 2
                            continue
                        }
                        lastSent = level
                        mainHandler.postAtTime({
                            if (exoPlayers.containsKey(id)) {
                                channel.invokeMethod(
                                    "level",
                                    mapOf("id" to id, "level" to level),
                                )
                            }
                        }, due)
                    }
                    i += 2
                }
            }
        })

    /**
     * Walk the clip's precomputed envelope in step with playback, so the
     * page's reactive bar moves for a clip exactly as it does for anything
     * else. No Visualizer, which means no RECORD_AUDIO and no per-sound
     * effect attach.
     */
    private fun emitClipLevels(id: String, clip: SoundClips.Clip) {
        val step = SoundClips.LEVEL_WINDOW_MS.toLong()
        var lastSent = -1f
        for ((i, level) in clip.levels.withIndex()) {
            // Near-identical consecutive levels are visual no-ops (the page
            // quantizes to 0.05 steps); don't schedule a bridge round-trip
            // for them.
            if (abs(level - lastSent) < 0.008f) continue
            lastSent = level
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
            routingReasserts.remove(id)
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
     * Watch a live player's actual route and pull it back when the platform
     * moves it off the selected output. Some builds invalidate and rebuild a
     * track mid-start (a "dead IAudioTrack" restore, seen on Lenovo when the
     * voice_communication capture on the USB card closes just as TTS begins),
     * and the rebuilt track follows default routing - the USB device - instead
     * of the pin (issue #93). The selector is re-resolved on every kick
     * because the reroute that caused it can re-enumerate device ids, which
     * would make the originally pinned AudioDeviceInfo stale.
     */
    private fun enforceRouting(id: String, router: android.media.AudioRouting) {
        if (Build.VERSION.SDK_INT < 28) return
        router.addOnRoutingChangedListener(
            android.media.AudioRouting.OnRoutingChangedListener { r ->
                val live = players.containsKey(id) ||
                    synchronized(tracks) { tracks.containsKey(id) }
                if (!live) return@OnRoutingChangedListener
                val selected = AudioRouting.currentOutput()
                    ?: return@OnRoutingChangedListener
                val routed = r.routedDevice ?: return@OnRoutingChangedListener
                if (routed.type == selected.type && routed.address == selected.address) {
                    return@OnRoutingChangedListener
                }
                val tries = routingReasserts[id] ?: 0
                if (tries >= MAX_ROUTING_REASSERTS) return@OnRoutingChangedListener
                routingReasserts[id] = tries + 1
                Log.w(
                    TAG,
                    "sound $id rerouted to ${routed.productName} (type ${routed.type}); " +
                        "re-pinning to ${selected.productName} (type ${selected.type}) " +
                        "[${tries + 1}/$MAX_ROUTING_REASSERTS]",
                )
                try {
                    if (!r.setPreferredDevice(selected)) {
                        Log.w(TAG, "re-pin rejected for $id (setPreferredDevice=false)")
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "re-pin failed for $id: ${e.message}")
                }
            },
            mainHandler,
        )
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
        routingReasserts.remove(id)
        val mp = players.remove(id)
        val exo = exoPlayers.remove(id)
        if (mp == null && exo == null) return
        // Releasing a MediaPlayer tears down the decoder and its track,
        // which is tens of milliseconds of this thread - and this thread is
        // the one drawing the dashboard. The player is already out of the
        // map, so nothing can reach it while the worker lets it go.
        // ExoPlayer must be released from its application thread (this
        // one), and its release only posts to an internal playback thread.
        if (mp != null) {
            workerHandler.post {
                try { mp.release() } catch (_: Exception) {}
            }
        }
        try { exo?.release() } catch (_: Exception) {}
        channel.invokeMethod("ended", mapOf("id" to id, "error" to error))
    }
}
