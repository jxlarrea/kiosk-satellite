package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.util.concurrent.atomic.AtomicInteger

/**
 * The intercom's playback sink: one streaming AudioTrack, fed the far
 * kiosk's voice as raw 16 kHz mono PCM16, or an announcement from Home
 * Assistant at its own rate. It plays as media, and what it
 * plays goes to the software echo canceller through a [TrackTap], so the
 * microphone does not send the far kiosk its own voice back.
 *
 * Methods (channel `kiosk_satellite/intercom_audio`):
 *  - start {volume, handsFree, rate}: opens the track, `volume` the linear base gain 0..1
 *    (the intercom fader, tapered on the Dart side), `rate` the PCM's sample
 *    rate, 16 kHz when left out. True when playing.
 *  - write <bytes>, on `kiosk_satellite/intercom_audio_data`: one chunk.
 *    That channel runs on a background queue, not the main thread: on an
 *    Echo Show 8 a busy UI thread held chunks back and handed them over in
 *    bursts, the backlog rule dropped the excess, and the far voice played
 *    two seconds, stopped for one and went on. Queued to a worker; the
 *    track's own buffer is the jitter buffer, and a backlog past a few
 *    chunks is dropped so the voice never drifts seconds behind.
 *  - setVolume {volume}: moves the fader live.
 *  - setHandsFree {enabled}: selects call-specific echo cancellation tuning.
 *  - stop: releases the track.
 *  - decode {bytes, rate}: an audio file to mono PCM16 at `rate`, or at the
 *    file's own rate (within [MIN_RATE]..[MAX_RATE]) when `rate` is 0.
 *    Answers {pcm, rate}.
 *  - chimePcm {rate}: the built-in announcement chime at `rate`.
 *
 * Android puts the master volume on the track. On fixed-volume devices
 * the software master ([VolumeController.masterGain]) stands in.
 */
class IntercomAudio(context: Context, messenger: BinaryMessenger) {
    companion object {
        private const val TAG = "IntercomAudio"
        private const val SAMPLE_RATE = 16000

        /** The rates an announcement keeps as decoded; others are converted to the nearest. */
        private const val MIN_RATE = 16000
        private const val MAX_RATE = 48000
        private const val BUFFER_MS = 400
        private const val MAX_QUEUED = 6

        /**
         * What the track may hold before silent chunks are dropped: the
         * line's delay, and with it how late the far side hears a turn
         * end, so as short as the network's jitter allows.
         */
        private const val BUFFER_TARGET_MS = 160
    }

    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, "kiosk_satellite/intercom_audio")
    private val dataChannel = MethodChannel(
        messenger, "kiosk_satellite/intercom_audio_data",
        StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue(),
    )
    private val worker = HandlerThread("ks-intercom").apply { start() }
    private val workerHandler = Handler(worker.looper)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var track: AudioTrack? = null

    /** What the track plays, for the software echo canceller. */

    @Volatile private var tap: TrackTap? = null

    /** The far voice's equalizer, run on the worker thread ahead of the tap. */
    @Volatile private var equalizer: Equalizer.Stream? = null
    @Volatile private var output: AudioDeviceInfo? = null
    @Volatile private var baseVolume = 1f

    /** The open track's sample rate. */
    @Volatile private var rate = SAMPLE_RATE
    private val queued = AtomicInteger(0)

    /** Frames written to [track] since it started, the prime included. */
    private var written = 0L

    private val volumeListener: () -> Unit = { applyVolume() }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    baseVolume = (call.argument<Double>("volume") ?: 1.0).toFloat().coerceIn(0f, 1f)
                    result.success(
                        start(
                            call.argument<Boolean>("handsFree") ?: false,
                            call.argument<Int>("rate") ?: SAMPLE_RATE,
                        ),
                    )
                }
                "setHandsFree" -> {
                    val on = call.argument<Boolean>("enabled") == true && track != null
                    SoftwareEcho.setMode(this, if (on) ResidualEchoGate.Mode.INTERCOM else null)
                    result.success(null)
                }
                "setVolume" -> {
                    baseVolume = (call.argument<Double>("volume") ?: 1.0).toFloat().coerceIn(0f, 1f)
                    applyVolume()
                    result.success(null)
                }
                "stop" -> { stop(); result.success(null) }
                "ring" -> {
                    ring(
                        (call.argument<Double>("volume") ?: 1.0).toFloat().coerceIn(0f, 1f),
                        call.argument<Boolean>("short") ?: false,
                    )
                    result.success(null)
                }
                "stopRing" -> { stopRing(); result.success(null) }
                "chimePcm" -> result.success(chimePcm(call.argument<Int>("rate") ?: SAMPLE_RATE))
                "decode" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val wanted = call.argument<Int>("rate") ?: SAMPLE_RATE
                    if (bytes == null) { result.success(null) }
                    else workerHandler.post {
                        val out = try { decode(bytes, wanted) } catch (e: Exception) {
                            Log.w(TAG, "decode failed: ${e.message}"); null
                        }
                        mainHandler.post {
                            result.success(out?.let { mapOf("pcm" to it.first, "rate" to it.second) })
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
        dataChannel.setMethodCallHandler { call, result ->
            if (call.method == "write") {
                val bytes = call.arguments as? ByteArray
                if (bytes != null) enqueue(bytes)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        VolumeController.addListener(volumeListener)
    }

    /** Chunks dropped since the last report, and when that was. */
    private val dropped = AtomicInteger(0)
    @Volatile private var droppedReportedAt = 0L

    /** A dropped chunk is a gap the far side hears: say so, at most every five seconds. */
    private fun drop() {
        dropped.incrementAndGet()
        val now = System.nanoTime()
        if (now - droppedReportedAt > 5_000_000_000L) {
            droppedReportedAt = now
            Log.w(TAG, "dropped ${dropped.getAndSet(0)} late chunks")
        }
    }

    private fun start(handsFree: Boolean, sampleRate: Int): Boolean {
        stop()
        val target = AudioRouting.currentOutput()
        val sr = sampleRate.coerceIn(8000, MAX_RATE)
        val minBuf = AudioTrack.getMinBufferSize(
            sr, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minBuf <= 0) {
            Log.e(TAG, "unsupported format")
            return false
        }
        val bufferBytes = maxOf(minBuf * 2, sr * 2 * BUFFER_MS / 1000)
        val newTrack = try {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sr)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build(),
                )
                .setTransferMode(AudioTrack.MODE_STREAM)
                .setBufferSizeInBytes(bufferBytes)
                .build()
        } catch (e: Exception) {
            Log.e(TAG, "AudioTrack create failed", e)
            return false
        }
        if (newTrack.state != AudioTrack.STATE_INITIALIZED) {
            Log.e(TAG, "AudioTrack init failed (state=${newTrack.state})")
            runCatching { newTrack.release() }
            return false
        }
        if (Build.VERSION.SDK_INT >= 28 && target != null) {
            runCatching { newTrack.preferredDevice = target }
        }
        track = newTrack
        output = target
        rate = sr
        tap = TrackTap(newTrack, sr, 1)
        equalizer = Equalizer.Stream(sr, 1)
        applyVolume()
        // Prime a short silence so the first chunk lands on a running
        // track without an underrun at the very start.
        val silence = ByteArray(sr * 2 / 10)
        written = 0
        tap?.wrote(silence, 0, silence.size)
        newTrack.write(silence, 0, silence.size)
        written += silence.size / 2
        newTrack.play()
        // Use the call's echo processing without an extra energy gate.
        // Nearby speech must remain audible while the other side talks.
        SoftwareEcho.setMode(this, if (handsFree) ResidualEchoGate.Mode.INTERCOM else null)
        Log.i(TAG, "playback started ($sr Hz, buffer=${bufferBytes}b)")
        return true
    }

    private fun enqueue(bytes: ByteArray) {
        val t = track ?: return
        val reference = tap
        val equalizer = equalizer
        if (queued.get() >= MAX_QUEUED) {
            // Behind by half a second: the network hiccuped, and playing
            // the backlog would keep the voice late for the whole call.
            drop()
            return
        }
        queued.incrementAndGet()
        workerHandler.post {
            try {
                if (track === t && t.playState == AudioTrack.PLAYSTATE_PLAYING) {
                    // What the track still holds. The two kiosks' audio
                    // clocks drift, and a sender a little fast fills the
                    // buffer over a long call, at which point every write
                    // blocks for a chunk and the voice runs a buffer late.
                    // A silent chunk is
                    // dropped once the buffer holds more than
                    // [BUFFER_TARGET_MS], and any chunk once it holds far
                    // more.
                    val head = t.playbackHeadPosition.toLong() and 0xFFFFFFFFL
                    val buffered = written - head
                    if (buffered > rate * 3 / 4) {
                        drop()
                        return@post
                    }
                    if (buffered > rate * BUFFER_TARGET_MS / 1000 && silent(bytes)) {
                        return@post
                    }
                    // The canceller's reference first: a write blocks while
                    // the buffer is full, and told after it the reference
                    // reached the canceller a chunk late and the far voice
                    // leaked through for that long.
                    // Equalized first, so the reference is what the speaker plays.
                    equalizer?.process(bytes, 0, bytes.size)
                    reference?.wrote(bytes, 0, bytes.size)
                    var offset = 0
                    while (offset < bytes.size && track === t) {
                        val n = t.write(bytes, offset, bytes.size - offset, AudioTrack.WRITE_BLOCKING)
                        if (n <= 0) break
                        offset += n
                    }
                    if (track === t) written += offset / 2
                }
            } catch (e: Exception) {
                Log.w(TAG, "write failed: ${e.message}")
            } finally {
                queued.decrementAndGet()
            }
        }
    }

    /** Whether a chunk is digital silence, or as good as (mean |sample| under 4). */
    private fun silent(bytes: ByteArray): Boolean {
        var sum = 0L
        var i = 0
        while (i + 1 < bytes.size) {
            val v = ((bytes[i].toInt() and 0xFF) or (bytes[i + 1].toInt() shl 8)).toShort().toInt()
            sum += kotlin.math.abs(v)
            i += 2
        }
        return sum < bytes.size / 2 * 4
    }

    // ── Decoding an announcement ─────────────────────────────────────

    /**
     * Decodes a whole audio file (whatever the platform's codecs read:
     * MP3, AAC, OGG, WAV) to mono PCM16 at [wanted] Hz, or at the file's
     * own rate when [wanted] is 0. An announcement plays at the file's
     * rate: brought down to 16 kHz, text to speech lost everything over
     * 8 kHz and its sibilants turned harsh. Answers the PCM and its rate.
     * Runs on the worker.
     */
    private fun decode(bytes: ByteArray, wanted: Int): Pair<ByteArray, Int>? {
        val file = java.io.File.createTempFile("ks-announce", ".bin", appContext.cacheDir)
        try {
            file.writeBytes(bytes)
            val extractor = android.media.MediaExtractor()
            extractor.setDataSource(file.path)
            var trackIndex = -1
            var format: android.media.MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                val mime = f.getString(android.media.MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("audio/")) { trackIndex = i; format = f; break }
            }
            if (trackIndex < 0 || format == null) { extractor.release(); return null }
            extractor.selectTrack(trackIndex)
            val mime = format.getString(android.media.MediaFormat.KEY_MIME)!!
            var rate = format.getInteger(android.media.MediaFormat.KEY_SAMPLE_RATE)
            var channels = format.getInteger(android.media.MediaFormat.KEY_CHANNEL_COUNT)
            val codec = android.media.MediaCodec.createDecoderByType(mime)
            codec.configure(format, null, null, 0)
            codec.start()
            val samples = java.io.ByteArrayOutputStream()
            val info = android.media.MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            var floatPcm = false
            while (!outputDone) {
                if (!inputDone) {
                    val inIndex = codec.dequeueInputBuffer(10_000)
                    if (inIndex >= 0) {
                        val buf = codec.getInputBuffer(inIndex)!!
                        val n = extractor.readSampleData(buf, 0)
                        if (n < 0) {
                            codec.queueInputBuffer(inIndex, 0, 0, 0, android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            codec.queueInputBuffer(inIndex, 0, n, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }
                val outIndex = codec.dequeueOutputBuffer(info, 10_000)
                when {
                    outIndex == android.media.MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        val f = codec.outputFormat
                        rate = f.getInteger(android.media.MediaFormat.KEY_SAMPLE_RATE)
                        channels = f.getInteger(android.media.MediaFormat.KEY_CHANNEL_COUNT)
                        floatPcm = Build.VERSION.SDK_INT >= 24 &&
                            f.containsKey(android.media.MediaFormat.KEY_PCM_ENCODING) &&
                            f.getInteger(android.media.MediaFormat.KEY_PCM_ENCODING) == AudioFormat.ENCODING_PCM_FLOAT
                    }
                    outIndex >= 0 -> {
                        val buf = codec.getOutputBuffer(outIndex)!!
                        buf.position(info.offset)
                        buf.limit(info.offset + info.size)
                        val chunk = ByteArray(info.size)
                        buf.get(chunk)
                        samples.write(chunk)
                        codec.releaseOutputBuffer(outIndex, false)
                        if (info.flags and android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                    }
                }
            }
            codec.stop(); codec.release(); extractor.release()
            val raw = samples.toByteArray()
            // To mono 16-bit at the decoder's rate.
            val bb = java.nio.ByteBuffer.wrap(raw).order(java.nio.ByteOrder.LITTLE_ENDIAN)
            val frames = if (floatPcm) raw.size / 4 / channels else raw.size / 2 / channels
            val mono = FloatArray(frames)
            for (i in 0 until frames) {
                var acc = 0f
                for (c in 0 until channels) {
                    acc += if (floatPcm) bb.float else bb.short / 32768f
                }
                mono[i] = acc / channels
            }
            // To the rate asked for. Low-passed first when it comes down,
            // or what is over the new limit folds back as a hiss.
            val target = if (wanted > 0) wanted else rate.coerceIn(MIN_RATE, MAX_RATE)
            val converted = ReferenceResampler(rate, target).process(mono)
            val out = java.nio.ByteBuffer.allocate(converted.size * 2).order(java.nio.ByteOrder.LITTLE_ENDIAN)
            for (v in converted) out.putShort((v * 32767f).toInt().coerceIn(-32768, 32767).toShort())
            Log.i(TAG, "decoded ${raw.size} bytes ($mime, $rate Hz, $channels ch) to ${converted.size * 1000L / target} ms at $target Hz")
            return out.array() to target
        } finally {
            runCatching { file.delete() }
        }
    }

    // ── The ring ────────────────────────────────────────────────────

    @Volatile private var ringTrack: AudioTrack? = null

    /**
     * The built-in ring, made here rather than shipped: the classic
     * telephone ring, 440 and 480 Hz together, as two bursts of 0.4 s with
     * a 0.2 s gap, or one burst of 0.35 s for the short form. Played on the
     * media route at the notification volume.
     */
    private fun ring(volume: Float, short: Boolean) {
        stopRing()
        val sr = 16000
        val burst = if (short) (sr * 0.35).toInt() else (sr * 0.4).toInt()
        val gap = (sr * 0.2).toInt()
        val total = if (short) burst else burst * 2 + gap
        val pcm = ShortArray(total)
        val fade = sr / 100
        fun fill(start: Int, length: Int) {
            for (i in 0 until length) {
                val t = i.toDouble() / sr
                var a = 0.5 * Math.sin(2 * Math.PI * 440 * t) + 0.5 * Math.sin(2 * Math.PI * 480 * t)
                val env = when {
                    i < fade -> i.toDouble() / fade
                    i > length - fade -> (length - i).toDouble() / fade
                    else -> 1.0
                }
                a *= env * 0.6
                pcm[start + i] = (a * Short.MAX_VALUE).toInt().coerceIn(-32768, 32767).toShort()
            }
        }
        fill(0, burst)
        if (!short) fill(burst + gap, burst)
        val track = try {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sr)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build(),
                )
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(pcm.size * 2)
                .build()
        } catch (e: Exception) {
            Log.w(TAG, "ring track failed: ${e.message}")
            return
        }
        // A static track reads STATE_NO_STATIC_DATA until its buffer is
        // written, and STATE_INITIALIZED only after; only uninitialized
        // means it failed.
        if (track.state == AudioTrack.STATE_UNINITIALIZED) {
            Log.w(TAG, "ring track init failed")
            runCatching { track.release() }
            return
        }
        val out = AudioRouting.currentOutput()
        if (Build.VERSION.SDK_INT >= 28 && out != null) runCatching { track.preferredDevice = out }
        val written = track.write(pcm, 0, pcm.size)
        if (written != pcm.size || track.state != AudioTrack.STATE_INITIALIZED) {
            Log.w(TAG, "ring track took $written of ${pcm.size} samples (state=${track.state})")
            runCatching { track.release() }
            return
        }
        Log.i(TAG, "ring ${if (short) "short" else "double"} at ${"%.2f".format(volume)}")
        runCatching { track.setVolume(volume * VolumeController.assistGain.coerceAtLeast(0f).let { if (VolumeController.isFixed) it else 1f }) }
        ringTrack = track
        track.play()
        // Release once it has played out, unless stopped first.
        val ms = total * 1000L / sr + 200
        workerHandler.postDelayed({ if (ringTrack === track) stopRing() }, ms)
    }

    /**
     * The built-in announcement chime: two soft bell notes, E6 then C6,
     * each a sine with a quick attack and an exponential decay, the
     * second starting under the first's tail. About a second, as mono
     * PCM16 at [sr] Hz peaking near full scale like the text to speech audio.
     * Dart plays it ahead of the words on the same track, so the two
     * share one route, one gain and the platform's processing.
     */
    private fun chimePcm(sampleRate: Int): ByteArray {
        val sr = sampleRate.coerceIn(8000, MAX_RATE)
        val total = (sr * 1.1).toInt()
        val wave = DoubleArray(total)
        fun note(freq: Double, start: Int, length: Int, gain: Double) {
            for (i in 0 until length) {
                val idx = start + i
                if (idx >= total) break
                val t = i.toDouble() / sr
                val attack = (i / (sr * 0.008)).coerceAtMost(1.0)
                val env = attack * Math.exp(-t * 4.5)
                wave[idx] += (Math.sin(2 * Math.PI * freq * t) + 0.25 * Math.sin(2 * Math.PI * freq * 2 * t)) * env * gain
            }
        }
        note(1318.5, 0, (sr * 0.9).toInt(), 1.0)
        note(1046.5, (sr * 0.22).toInt(), (sr * 0.88).toInt(), 0.9)
        val peak = wave.maxOf { Math.abs(it) }.coerceAtLeast(1e-9)
        val scale = Short.MAX_VALUE * 0.9 / peak
        val out = java.nio.ByteBuffer.allocate(total * 2).order(java.nio.ByteOrder.LITTLE_ENDIAN)
        for (v in wave) out.putShort((v * scale).toInt().coerceIn(-32768, 32767).toShort())
        return out.array()
    }

    private fun stopRing() {
        val t = ringTrack ?: return
        ringTrack = null
        runCatching { t.stop() }
        runCatching { t.release() }
    }

    /**
     * The intercom fader over the device's master and nothing else: not
     * the assistant fader, which is Voice Satellite's, and not the media
     * one. On the communication route the master is the call stream's
     * compensation; on the media route the hardware applies it, except
     * on fixed-volume devices where it is software.
     */
    private fun applyVolume() {
        val t = track ?: return
        val level = PlaybackVolume.level(baseVolume, 1f, VolumeController.masterGain)
        runCatching { t.setVolume(level) }
        tap?.gain = level
    }

    private fun stop() {
        val t = track ?: return
        track = null
        SoftwareEcho.setMode(this, null)
        tap?.close()
        tap = null
        output = null
        runCatching { t.pause() }
        workerHandler.post {
            runCatching { t.flush() }
            runCatching { t.release() }
            Log.i(TAG, "playback stopped")
        }
    }
}
