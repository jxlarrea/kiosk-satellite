package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AudioEffect
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicLong
import kotlin.concurrent.thread
import kotlin.math.max

/**
 * Streams 16 kHz mono PCM16 microphone audio to Dart over an EventChannel.
 *
 * Implemented natively (AudioRecord) rather than via a pub package because the
 * available streaming-mic packages don't build against AGP 9. onListen starts
 * capture; onCancel (Dart cancelling the subscription) stops it and releases
 * the mic — which is what frees it for the WebView's getUserMedia during STT.
 *
 * Capture uses AudioSource.MIC without attaching Android audio effects,
 * or VOICE_COMMUNICATION when the `source` argument asks for it (some OEM
 * ROMs only record properly on the call path). Android's audio policy
 * attaches its own canceller, suppressor or gain control to the other
 * sources on many devices (a Galaxy Tab S8 put Qualcomm Fluence's
 * canceller on the call source), so [silencePlatformEffects] turns them
 * off and only the kiosk's own processing runs. Processing inside the
 * audio HAL is out of reach, so device firmware may still process any
 * source. MIC does not guarantee raw audio.
 * Echo cancellation is [SoftwareEcho]'s, fed everything the kiosk plays,
 * followed by optional noise suppression and fixed microphone gain.
 * MIC became the default and Android's own canceller, suppressor and
 * gain control are never used: the call
 * path came in 20 dB quieter on some custom ROMs, the canceller degraded
 * over a day on a Galaxy Tab S8 and let the assistant hear itself on
 * most others, and the effects did nothing or whispered the capture on
 * the rest. The microphone source is the same path many recorder apps use.
 * Some firmware feeds nothing but zeros to MIC (a Meta Portal Mini), so
 * the format ladder ends on the other sources (voice recognition, then
 * the call or MIC source, whichever was not picked): a device reaches
 * them only when every format on the picked source read silence.
 *
 * The tuning arrives as stream arguments, which is why a change of any of
 * it reopens capture.
 *
 * Channel selection: multichannel USB arrays put differently-processed
 * signals on each channel (the reSpeaker XVF3800 sends its comms output on
 * channel 1 and its raw ASR output on channel 2), and Android's stereo-to-
 * mono contraction averages them, polluting the clean channel with the
 * processed one. A `channel` argument of 1..N opens capture with a channel
 * index mask wide enough to include it and forwards only that channel; 0 (the
 * default) is the platform's mono downmix, the app's historical behavior.
 *
 * Capture format: the engines want 16 kHz mono and that is what capture
 * asks for, leaving the platform to convert from whatever the microphone
 * does. Some sound cards record at 48 kHz stereo and nothing else, and an
 * audio HAL that hands the app's format straight to ALSA then refuses the
 * open, reads nothing but errors or delivers the card's frames misread as
 * 16 kHz mono. Capture therefore walks a ladder of shapes ([captureLadder])
 * and steps down it when an open is refused, when reads return only errors
 * or zeros, when a read blocks for good (the HAL could not read the card, so
 * AudioFlinger has nothing to hand over), or when the delivered frame rate
 * does not match the rate opened (the format under the label is not the one
 * asked for). Silence is weak
 * evidence, so [CaptureWalk] decides how much of it a rung gets, where
 * capture lands when the whole ladder has been tried and when it may walk
 * again. Anything but 16 kHz mono is converted here ([CaptureConvert]). A
 * `format` argument of "hardware" starts the ladder at the card's 48 kHz
 * stereo.
 */
class MicRecorder(context: Context, messenger: BinaryMessenger) : EventChannel.StreamHandler {
    companion object {
        /** The input types a channel pick applies to. */
        private val USB_INPUT_TYPES = setOf(
            AudioDeviceInfo.TYPE_USB_DEVICE,
            AudioDeviceInfo.TYPE_USB_HEADSET,
            AudioDeviceInfo.TYPE_USB_ACCESSORY,
        )

        const val CHANNEL = "kiosk_satellite/mic"
        const val LEVELS_CHANNEL = "kiosk_satellite/mic_levels"
        private const val TAG = "MicRecorder"
        @Volatile var rtspAudioTap: ((ByteArray, Long) -> Unit)? = null
        @Volatile var inputSelector: String? = null
            private set
        private const val SAMPLE_RATE = 16000
        private const val CHUNK_BYTES = 1280 * 2 // 80 ms of 16-bit mono

        /** How long after a sound a muting microphone may still read zeros. */
        private const val PLAYBACK_MUTE_TAIL_MS = 2000L

        /**
         * A fallback source rung that delivered audio while the picked
         * source read zeros, keyed by that picked source. Later opens with
         * the same pick start on it rather than spend seconds of deafness
         * walking its formats again. A different pick is the user's to try.
         */
        @Volatile private var provenFallback: Pair<Int, Shape>? = null

        /**
         * Shapes whose capture went from zeros back to audio without a
         * reopen: the HAL gates a quiet room to exact silence there (a
         * Rockchip HAL's own gain control does), so silence on them is not
         * a dead microphone and never walks the ladder again.
         */
        @Volatile private var gatingShapes: Set<Shape> = emptySet()

        private fun sourceName(source: Int): String = when (source) {
            MediaRecorder.AudioSource.MIC -> "mic"
            MediaRecorder.AudioSource.VOICE_RECOGNITION -> "voice_recognition"
            MediaRecorder.AudioSource.VOICE_COMMUNICATION -> "voice_communication"
            else -> "source $source"
        }

        /**
         * The sound card's own format on the devices that cannot do 16 kHz
         * mono: 48 kHz, two channels. Also the deafness guard's second try:
         * a capture stuck on all-zero frames or read errors (a wedged
         * AudioRecord after an audioserver death, a ROM whose direct 16 kHz
         * record path is broken, a HAL that could not open the card at
         * 16 kHz mono) cannot be fixed in place, so it is reopened at this
         * format - the mismatch against a 16 kHz device forces
         * AudioFlinger's record converter path and a fresh server-side
         * track, and a 48 kHz card gets the format it wanted - and
         * converted back to 16 kHz mono here. Echo cancellation can
         * produce exact silence, so communication playback and its
         * settling time are excluded from the silence watchdog.
         */
        private const val HARDWARE_RATE = 48000
        private const val HARDWARE_CHANNELS = 2

        /**
         * Delivered-rate check: a blocking read paces at the real rate, so
         * frames per wall second should match the rate the capture was
         * opened at. An old HAL asked for 48 kHz stereo can hand over mono
         * under the stereo label (half the frames, pitch doubled), and a
         * card's 48 kHz stereo misread as 16 kHz mono arrives six times
         * too fast. Two seconds from the first read is long enough for
         * read granularity not to matter. [CaptureWalk.rateVerdict] judges
         * the measurement.
         */
        private const val RATE_CHECK_NS = 2_000_000_000L
        private const val RATE_BLOCKED_READ_NS = 20_000_000L
        private const val RATE_WINDOW_AFTER_READS = 8

        /**
         * Read-stall guard. When the audio HAL cannot read the card (a USB
         * microphone opened in a format it does not record, a card that
         * went away) AudioFlinger has nothing to hand over and a blocking
         * read waits forever: no zeros and no errors, so none of the checks
         * in the read loop ever run. A healthy read returns within one
         * 80 ms chunk, so three seconds is a stall on any device.
         */
        private const val READ_STALL_NS = 3_000_000_000L
        private const val STALL_POLL_MS = 500L
        private const val STALLED = -1L

    }

    private val appContext = context.applicationContext
    private val eventChannel = EventChannel(messenger, CHANNEL)
    private val levelsChannel = MethodChannel(messenger, LEVELS_CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var recording = false
    // Volatile: the stall guard stops it from its own thread.
    @Volatile private var record: AudioRecord? = null
    private var worker: Thread? = null
    private var delivery: PcmDelivery? = null
    // Our handles on the platform effects of the open record's session,
    // held off for as long as that record lives.
    private val platformEffects = mutableListOf<AudioEffect>()

    // Bluetooth capture routing we brought up and therefore owe a teardown:
    // the communication device on Android 12+, the SCO link below it.
    private var commDeviceSet = false
    private var scoStarted = false

    init {
        eventChannel.setStreamHandler(this)
        // Wake word arbitration reads the levels before the noise
        // suppressor here, not the cleaned audio the stream delivers.
        levelsChannel.setMethodCallHandler { call, result ->
            if (call.method == "recent") {
                result.success(MicLevels.recent((call.argument<Number>("ms") ?: 3000).toInt()))
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        if (sink == null || recording) return
        val args = arguments as? Map<*, *>
        val unprocessedSupported = appContext.getSystemService(AudioManager::class.java)
            .getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED)
        val source = if (args?.get("source") == "voice_communication") {
            MediaRecorder.AudioSource.VOICE_COMMUNICATION
        } else {
            MediaRecorder.AudioSource.MIC
        }
        val wantSoftwareAec = args?.get("softwareAec") != false
        val wantNs = args?.get("noiseSuppression") == true
        // A gain of 0 dB is the overwhelmingly common case, and a factor of
        // exactly 1 lets the read loop skip the sample walk entirely.
        val gain = gainFactor((args?.get("gainDb") as? Number)?.toDouble() ?: 0.0)
        val selector = args?.get("device") as? String
        inputSelector = selector
        // A channel pick is for a USB microphone array. A built-in mic
        // opened with one captures raw channels past the platform echo
        // canceller, so a pick left over from a USB array must not follow
        // the selection back to it (it cost a Galaxy Tab S8 its echo
        // cancellation: the assistant heard itself).
        val usbSelected = selector?.substringBefore('|')?.toIntOrNull() in USB_INPUT_TYPES
        val wantChannel = if (usbSelected) (args?.get("channel") as? Number)?.toInt() ?: 0 else 0
        val hardwareFormat = args?.get("format") == "hardware"
        // The mask must reach the chosen channel even when the device cannot
        // be resolved right now (it may still appear by open time), and must
        // cover the whole device when it can, so a 4-channel array does not
        // get opened 2-wide and remapped underneath the selection.
        val chans = if (wantChannel >= 1) {
            val reported = AudioRouting.resolve(selector, source = true)
                ?.channelCounts?.maxOrNull() ?: 0
            maxOf(2, wantChannel, reported)
        } else {
            1
        }
        // A channel pick is an index mask over the array's wire order; the
        // plain stereo open is positional, the shape every input profile
        // lists, so a HAL that matches by mask finds it.
        val indexed = wantChannel >= 1
        val ladder = captureLadder(source, hardwareFormat, chans, indexed)
        // A proven fallback first, then the ladder in order.
        val proven = provenFallback?.takeIf { it.first == source }
            ?.let { ladder.indexOf(it.second) } ?: -1
        val order = if (proven > 0) listOf(proven) + ladder.indices.filter { it != proven } else ladder.indices.toList()
        var step = 0
        var rec: AudioRecord? = null
        try {
            for ((i, rung) in order.withIndex()) {
                step = rung
                rec = openRecord(ladder[rung], indexed)
                if (rec != null) break
                Log.w(TAG, "${ladder[rung]} capture refused" +
                    (if (i + 1 < order.size) "; trying ${ladder[order[i + 1]]}" else ""))
            }
        } catch (e: SecurityException) {
            mainHandler.post { sink.error("permission", "RECORD_AUDIO not granted", null) }
            return
        }
        val opened = rec ?: run {
            mainHandler.post { sink.error("init", "AudioRecord init failed", null) }
            return
        }
        record = opened
        Log.i(
            TAG,
            "capture opening (source=${sourceName(ladder[step].source)} unprocessed-supported=$unprocessedSupported device=${selector ?: "automatic"} " +
                "gain=${"%.1f".format(gainDbOf(gain))}dB echo-cancellation=$wantSoftwareAec ns=$wantNs" +
                (if (wantChannel >= 1) " channel=$wantChannel/${ladder[step].channels}" else "") +
                " format=${ladder[step]}" +
                (if (hardwareFormat) " hardware-format" else "") + ")",
        )
        applyPreferredDevice(opened, selector)
        silencePlatformEffects(opened, ladder[step].source)
        SoftwareEcho.setEnabled(wantSoftwareAec)
        SoftwareEcho.setNoiseSuppression(wantNs)
        MicLevels.clear()
        MicLevels.gainDb = gainDbOf(gain)
        // Four 80 ms chunks cover ordinary scheduling jitter. A stalled
        // platform thread must not retain an unlimited history of audio.
        val frames = PcmDelivery(
            CHUNK_BYTES * 4, mainHandler::post, mainHandler::removeCallbacks,
        ) { sink.success(it) }
        delivery = frames
        recording = true
        opened.startRecording()
        val channelIdx = wantChannel - 1
        worker = thread(name = "vsww-mic") {
            var cur = opened
            val walk = CaptureWalk(ladder.size, step, ladder.indices.filter { ladder[it] in gatingShapes }.toSet())
            var shape = ladder[walk.step]
            var decimator = if (shape.rateHz == HARDWARE_RATE) CaptureConvert.Decimator3() else null
            var announcedAudio = false
            // Whether the picked source delivered audio. A fallback source
            // is remembered only for a pick that never did.
            var pickedAudible = gatingShapes.any { it.source == source }
            // Rolling, not since-open: a capture can emit a startup
            // transient before going silent, so any single nonzero frame
            // must not disarm the watchdog for good. Both runs count 16 kHz
            // mono bytes whatever the shape.
            var zeroRun = 0L
            var errorRun = 0L
            // Delivered-rate check, once per open: frames read against the
            // wall clock. The window opens at the first read that blocked
            // (the backlog since startRecording has drained) or after a
            // few reads regardless (a stream arriving several times too
            // fast never blocks), so neither the open latency nor the
            // backlog counts.
            var windowNs = 0L
            var framesRead = 0L
            var reads = 0
            var rateChecked = false
            // Whether this open's rate check already said it is waiting
            // out a sound (once per open, the app log is not a meter).
            var rateDeferred = false
            var buf = ByteArray(shape.chunkBytes)
            // Frames read from this record: when each chunk was heard, for
            // pairing it with what the speaker played then (SoftwareEcho).
            var capturedFrames = 0L
            val captureClock = CaptureClock()

            // The walk's verdicts also go to the app log, the one people
            // send: logcat alone left a deaf capture looking healthy there.
            fun warn(message: String) {
                Log.w(TAG, message)
                mainHandler.post { if (frames.isOpen) sink.success(mapOf("warning" to message)) }
            }

            fun tryOpen(rung: Int): AudioRecord? = try {
                openRecord(ladder[rung], indexed)
            } catch (_: SecurityException) {
                null
            }

            fun swapTo(next: AudioRecord, rung: Int) {
                try { cur.stop() } catch (_: IllegalStateException) {}
                releasePlatformEffects()
                cur.release()
                applyPreferredDevice(next, selector)
                silencePlatformEffects(next, ladder[rung].source)
                next.startRecording()
                cur = next
                record = next
                walk.opened(rung)
                shape = ladder[rung]
                decimator = if (shape.rateHz == HARDWARE_RATE) CaptureConvert.Decimator3() else null
                zeroRun = 0
                errorRun = 0
                windowNs = 0
                framesRead = 0
                reads = 0
                rateChecked = false
                rateDeferred = false
                announcedAudio = false
                capturedFrames = 0
                captureClock.reset()
                buf = ByteArray(shape.chunkBytes)
            }

            // The next rung of the ladder that opens. When the ladder is
            // exhausted, back to the rung that delivered audio (the first
            // rung when none did), with the next walk held off by the
            // backoff. False when no walk is allowed yet: the capture in
            // hand stays, whatever it is.
            fun advance(why: String): Boolean {
                if (!frames.isOpen) return false
                val now = System.nanoTime()
                if (!walk.mayWalk(now)) return false
                var next: AudioRecord? = null
                var rung = walk.step
                while (frames.isOpen && next == null && rung + 1 < ladder.size) {
                    rung++
                    next = tryOpen(rung)
                    if (next == null) warn("$why; ${ladder[rung]} refused")
                }
                if (!frames.isOpen) {
                    next?.release()
                    return false
                }
                if (next == null) {
                    rung = walk.exhausted(now)
                    val wait = "next check in ${walk.waitSeconds}s"
                    next = tryOpen(rung)
                    if (next == null) {
                        warn("$why and no other capture format is left; keeping $shape, $wait")
                        return true
                    }
                    warn(
                        "$why and no other capture format is left; back to ${ladder[rung]}" +
                            (if (walk.audibleStep == rung) ", which delivered audio earlier" else "") +
                            ", $wait",
                    )
                } else {
                    warn("$why - reopening at ${ladder[rung]}")
                }
                if (!frames.isOpen) {
                    next.release()
                    return false
                }
                swapTo(next, rung)
                return true
            }

            // When the read in progress began (0 between reads, STALLED once
            // the guard has claimed it) and when the guard may act again: it
            // holds off while the walk backs off, so a capture that stays
            // dead is not reopened every few seconds.
            val readSince = AtomicLong(0L)
            val stallHoldUntil = AtomicLong(0L)
            thread(name = "vsww-mic-stall", isDaemon = true) {
                while (frames.isOpen) {
                    try { Thread.sleep(STALL_POLL_MS) } catch (_: InterruptedException) { break }
                    val since = readSince.get()
                    val now = System.nanoTime()
                    if (since <= 0L || now - since < READ_STALL_NS || now < stallHoldUntil.get()) continue
                    // Stopping the record is what frees a blocked read. Taken
                    // before the claim, so a record the loop swapped out in
                    // between is the one stopped (it throws, released).
                    val stalled = record
                    if (readSince.compareAndSet(since, STALLED)) {
                        try { stalled?.stop() } catch (_: IllegalStateException) {}
                    }
                }
            }

            while (frames.isOpen) {
                val readStartNs = System.nanoTime()
                readSince.set(readStartNs)
                val read = cur.read(buf, 0, buf.size)
                val stalled = readSince.getAndSet(0L) == STALLED
                if (!frames.isOpen) break
                if (stalled) {
                    advance("capture delivered nothing for ${READ_STALL_NS / 1_000_000_000L}s" + stallHint(cur))
                    stallHoldUntil.set(walk.nextWalkNs)
                    // Held off, or no format would reopen: the guard stopped
                    // this record and it has to run again to recover.
                    if (cur.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                        try { cur.startRecording() } catch (_: IllegalStateException) {}
                    }
                    continue
                }
                if (read == 0) continue
                if (read < 0) {
                    // ERROR_DEAD_OBJECT and friends come back on every call:
                    // a track the server side gave up on. Pace the loop and
                    // let the watchdog treat the wait as silence.
                    if (!frames.isOpen) break
                    Thread.sleep(20)
                    errorRun += SAMPLE_RATE * 2 / 50
                    if (errorRun >= CaptureWalk.FRESH_ZERO_BYTES) {
                        errorRun = 0
                        advance("capture read only errors for 2s ($read)")
                    }
                    continue
                }
                errorRun = 0
                capturedFrames += read / (2 * shape.channels)
                if (windowNs == 0L) {
                    reads++
                    val blocked = System.nanoTime() - readStartNs >= RATE_BLOCKED_READ_NS
                    if (blocked || reads >= RATE_WINDOW_AFTER_READS) windowNs = System.nanoTime()
                } else {
                    framesRead += read / (2 * shape.channels)
                }
                if (!rateChecked && windowNs != 0L) {
                    val elapsedNs = System.nanoTime() - windowNs
                    if (elapsedNs >= RATE_CHECK_NS) {
                        rateChecked = true
                        val ratio = framesRead * 1e9 / elapsedNs / shape.rateHz
                        Log.i(TAG, "capture delivers ${(ratio * 100).toInt()}% of ${shape.rateHz} Hz")
                        // A sound anywhere in the window, its tail included.
                        val played = EchoReference.playedWithin(
                            elapsedNs / 1_000_000L + PLAYBACK_MUTE_TAIL_MS,
                        )
                        val verdict = CaptureWalk.rateVerdict(ratio, played)
                        if (verdict == CaptureWalk.RateVerdict.MEASURE_AGAIN) {
                            if (!rateDeferred) {
                                rateDeferred = true
                                warn(
                                    "capture delivers ${(ratio * 100).toInt()}% of the " +
                                        "${shape.rateHz} Hz it was opened at while a sound plays; " +
                                        "measuring again once it ends",
                                )
                            }
                            rateChecked = false
                            windowNs = System.nanoTime()
                            framesRead = 0
                        } else if (verdict == CaptureWalk.RateVerdict.LIE) {
                            val why = "capture delivers ${(ratio * 100).toInt()}% of the " +
                                "${shape.rateHz} Hz it was opened at (wrong format under the label)"
                            if (!advance(why)) warn("$why; keeping $shape until the next check")
                            continue
                        }
                    }
                }
                // Everything downstream - the watchdog included - listens to
                // the selected channel: the array's other channels carrying
                // audio is no consolation when the chosen one is dead.
                val mono = when {
                    shape.channels == 1 -> null
                    channelIdx >= 0 -> extractChannel(buf, read, shape.channels, channelIdx)
                    else -> CaptureConvert.downmix(buf, read, shape.channels)
                }
                val monoLen = mono?.size ?: read
                val silent = allZero(mono ?: buf, monoLen)
                // Some hardware mutes its microphone outright while the
                // device plays, and for a moment after: not a stalled
                // recorder.
                if (silent && !EchoReference.playedWithin(PLAYBACK_MUTE_TAIL_MS)) {
                    zeroRun += monoLen * SAMPLE_RATE / shape.rateHz
                    val limit = walk.zeroLimitBytes
                    if (zeroRun >= limit) {
                        zeroRun = 0
                        if (walk.gating) {
                            // Silence on a gating rung is a quiet room.
                            // Reopening in place still frees a wedged record.
                            tryOpen(walk.step)?.let {
                                Log.i(TAG, "$shape read only zeros for ${limit / (SAMPLE_RATE * 2)}s; reopening it in place")
                                swapTo(it, walk.step)
                            }
                            continue
                        }
                        // Held off (a trusted rung in a quiet room inside
                        // the backoff): nothing to say, silence is not news.
                        advance("capture read only zeros for ${limit / (SAMPLE_RATE * 2)}s")
                        continue
                    }
                } else {
                    if (!silent) {
                        if (walk.audible(zeroRun)) {
                            gatingShapes = gatingShapes + shape
                            Log.i(TAG, "$shape gates quiet audio to zeros; silence no longer walks the ladder from it")
                        }
                        if (shape.source == source) pickedAudible = true
                        if (shape.source != source && !pickedAudible) provenFallback = source to shape
                        if (walk.step > 0 && !announcedAudio) {
                            announcedAudio = true
                            Log.i(TAG, "$shape capture is delivering audio")
                        }
                    }
                    zeroRun = 0
                }
                val chunk = when {
                    decimator != null -> decimator!!.process(mono ?: buf, monoLen)
                    mono != null -> mono
                    else -> buf.copyOf(read)
                }
                if (chunk.isEmpty()) continue
                // A realtime conversation cancelling its own voice in
                // software: everything downstream hears the cleaned audio.
                if (SoftwareEcho.enabled || SoftwareEcho.noiseSuppression) {
                    SoftwareEcho.process(
                        chunk,
                        captureClock.heard(capturedFrames, shape.rateHz, System.nanoTime()),
                    )
                } else {
                    MicLevels.measure(chunk)
                }
                // Boost cleaned speech after cancellation. Boosting the speaker
                // echo first can clip it and make nearby speech disappear.
                if (gain != 1.0) amplify(chunk, chunk.size, gain)
                rtspAudioTap?.invoke(chunk, System.nanoTime() / 1000 - chunk.size * 1_000_000L / 32000)
                frames.offer(chunk)
            }
        }
    }

    /** A capture shape: rate, channel count and source, as a log-friendly string. */
    data class Shape(
        val rateHz: Int,
        val channels: Int,
        val source: Int = MediaRecorder.AudioSource.MIC,
    ) {
        /** 80 ms of interleaved PCM16 at this shape. */
        val chunkBytes: Int get() = CHUNK_BYTES * (rateHz / SAMPLE_RATE) * channels
        override fun toString() = "${rateHz}Hz x$channels ${sourceName(source)}"
    }

    /**
     * The shapes to try, in order. The engines' 16 kHz mono first, then
     * the sound card's 48 kHz stereo, then 48 kHz mono for a HAL that gets
     * stereo wrong; the hardware format starts at the card and keeps 16 kHz
     * mono as its last resort. A channel pick fixes the channel count (the
     * array's own), so only the rate varies, with the plain mono open as
     * the last rung for a device that cannot satisfy the pick (mic swapped
     * for a mono one, a ROM that refuses index masks): capture beats
     * silence. Every shape is on the picked [source]. The other sources
     * close the ladder for firmware that feeds the picked one nothing but
     * zeros (a Meta Portal Mini read silence on MIC and captured on voice
     * recognition).
     */
    private fun captureLadder(
        source: Int,
        hardwareFormat: Boolean,
        chans: Int,
        indexed: Boolean,
    ): List<Shape> {
        val usual = Shape(SAMPLE_RATE, chans, source)
        val card = if (indexed) {
            listOf(Shape(HARDWARE_RATE, chans, source))
        } else {
            listOf(
                Shape(HARDWARE_RATE, HARDWARE_CHANNELS, source),
                Shape(HARDWARE_RATE, 1, source),
            )
        }
        val ladder = if (hardwareFormat) card + usual else listOf(usual) + card
        val picked = if (indexed) ladder + Shape(SAMPLE_RATE, 1, source) else ladder
        val fallbacks = listOf(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            MediaRecorder.AudioSource.MIC,
        ).filter { it != source }
        return picked + fallbacks.map { Shape(SAMPLE_RATE, 1, it) }
    }

    /**
     * Open a capture at the given rate and channel count, or null when it
     * cannot be had. A channel pick opens with a channel index mask
     * (channels in wire order, no positional meaning) because that is what
     * USB arrays are: numbered outputs, not a left and a right. The plain
     * stereo open of the hardware format is positional, and wider opens
     * without a pick fall back to the index mask, the only mask there is
     * past two channels.
     */
    private fun openRecord(shape: Shape, indexed: Boolean): AudioRecord? {
        val rateHz = shape.rateHz
        val channels = shape.channels
        val minBuf = AudioRecord.getMinBufferSize(
            rateHz,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        ) * channels
        val chunk = CHUNK_BYTES * (rateHz / SAMPLE_RATE) * channels
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(rateHz)
            .apply {
                if (channels == 2 && !indexed) {
                    setChannelMask(AudioFormat.CHANNEL_IN_STEREO)
                } else if (channels > 1) {
                    setChannelIndexMask((1 shl channels) - 1)
                } else {
                    setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                }
            }
            .build()
        val rec = try {
            AudioRecord.Builder()
                .setAudioSource(shape.source)
                .setAudioFormat(format)
                .setBufferSizeInBytes(max(minBuf, chunk * 4))
                .build()
        } catch (e: SecurityException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, "AudioRecord open at $shape failed: ${e.message}")
            return null
        }
        if (rec.state != AudioRecord.STATE_INITIALIZED) {
            rec.release()
            return null
        }
        return rec
    }

    /**
     * One channel of an interleaved PCM16 buffer as a fresh mono buffer.
     * [channelIdx] beyond the frame (stale selection, fallback-narrowed
     * capture) clamps to the last channel rather than reading past the frame.
     */
    /**
     * What a stalled read on [rec] points at, for the log line: the device
     * it was reading and, for a USB microphone, the usual cause. Custom
     * ROMs for boards like the Raspberry Pi pin the USB input to one format
     * in their audio policy, and a microphone that cannot record it is
     * opened anyway and never delivers a frame.
     */
    private fun stallHint(rec: AudioRecord): String {
        val device = rec.routedDevice ?: rec.preferredDevice ?: return ""
        val usb = device.type == AudioDeviceInfo.TYPE_USB_DEVICE ||
            device.type == AudioDeviceInfo.TYPE_USB_HEADSET
        return " from ${device.productName}" + if (usb) {
            " (a USB microphone that never delivers usually means the ROM's USB audio " +
                "configuration opens it in a format it cannot record)"
        } else {
            ""
        }
    }

    private fun extractChannel(
        buf: ByteArray,
        length: Int,
        channels: Int,
        channelIdx: Int,
    ): ByteArray {
        val idx = channelIdx.coerceIn(0, channels - 1)
        val frames = length / 2 / channels
        val out = ByteArray(frames * 2)
        var si = idx * 2
        var oi = 0
        val stride = channels * 2
        repeat(frames) {
            out[oi] = buf[si]
            out[oi + 1] = buf[si + 1]
            si += stride
            oi += 2
        }
        return out
    }

    private fun allZero(buf: ByteArray, length: Int): Boolean {
        for (i in 0 until length) {
            if (buf[i] != 0.toByte()) return false
        }
        return true
    }

    /**
     * Multiply 16-bit little-endian samples in place, saturating at full
     * scale. Clipping rather than wrapping matters: a wrapped sample flips
     * sign and reads to a wake word model as an impulse, which is worse than
     * the flat top clipping gives.
     */
    private fun amplify(buf: ByteArray, length: Int, gain: Double) {
        var i = 0
        val end = length - 1
        while (i < end) {
            val sample = ((buf[i + 1].toInt() shl 8) or (buf[i].toInt() and 0xFF)).toShort()
            var scaled = (sample * gain).toInt()
            if (scaled > Short.MAX_VALUE.toInt()) scaled = Short.MAX_VALUE.toInt()
            if (scaled < Short.MIN_VALUE.toInt()) scaled = Short.MIN_VALUE.toInt()
            buf[i] = (scaled and 0xFF).toByte()
            buf[i + 1] = ((scaled shr 8) and 0xFF).toByte()
            i += 2
        }
    }

    /**
     * Decibels to a linear factor, clamped to the range the settings slider
     * offers so a bad value from an import cannot blow the signal apart.
     * Negative values attenuate, for microphones that run too hot.
     */
    private fun gainFactor(db: Double): Double {
        if (db == 0.0) return 1.0
        return Math.pow(10.0, db.coerceIn(-24.0, 24.0) / 20.0)
    }

    private fun gainDbOf(factor: Double): Double =
        if (factor == 1.0) 0.0 else 20.0 * Math.log10(factor)

    /**
     * Pin capture to the user's chosen input, when one is configured and
     * currently present. A Bluetooth microphone additionally needs its call
     * audio link brought up - a plain setPreferredDevice quietly keeps
     * recording from the built-in mic without it. Absent or unmatched
     * selections fall through to Android's own routing.
     */
    private fun applyPreferredDevice(rec: AudioRecord, selector: String?) {
        if (selector.isNullOrBlank()) return
        val device = AudioRouting.resolve(selector, source = true)
        if (device == null) {
            // Absent device (BT speaker off) or a stale selector: Android
            // routes. Said out loud because silently-wrong capture routing is
            // exactly the complaint this feature answers.
            Log.w(TAG, "selected mic not matched ($selector); automatic routing")
            return
        }
        rec.preferredDevice = device
        Log.i(TAG, "capture pinned to ${device.productName} (type ${device.type}, ${device.address})")
        val bluetooth = device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
            (Build.VERSION.SDK_INT >= 31 && device.type == 26 /* TYPE_BLE_HEADSET */)
        if (!bluetooth) return
        val am = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= 31) {
            // setCommunicationDevice only accepts entries from
            // availableCommunicationDevices - the route handle, not the
            // input device we resolved. Passing the input is silently
            // refused (returns false) and capture stays on a dead SCO
            // input, which reads as a mic that hears nothing.
            val comm = am.availableCommunicationDevices.firstOrNull {
                it.type == device.type && it.address == device.address
            } ?: am.availableCommunicationDevices.firstOrNull { it.type == device.type }
            commDeviceSet = try {
                comm != null && am.setCommunicationDevice(comm)
            } catch (e: IllegalArgumentException) {
                Log.w(TAG, "setCommunicationDevice rejected: ${e.message}")
                false
            }
            if (!commDeviceSet) {
                Log.w(
                    TAG,
                    "bluetooth capture link refused (comm device " +
                        "${if (comm == null) "not offered" else "rejected"}); " +
                        "capture will likely be silent",
                )
            }
            AudioRouting.micHoldsCommDevice = commDeviceSet
        } else {
            @Suppress("DEPRECATION")
            am.startBluetoothSco()
            @Suppress("DEPRECATION")
            am.isBluetoothScoOn = true
            scoStarted = true
        }
        if (commDeviceSet || scoStarted) {
            Log.i(TAG, "bluetooth capture link up (${device.productName})")
        }
    }

    /**
     * Turn off the echo canceller, noise suppressor and gain control the
     * platform attaches to [rec]'s session, so the kiosk's own canceller
     * and suppressor are the only ones. A handle created on the session
     * takes control of an effect the audio policy added there. MIC gets
     * none on the devices we know, so it is left alone. Each effect is
     * optional per device, and what the device made of the request goes to
     * the log, since creating an effect and the effect being off are
     * different things on some OEM builds.
     */
    private fun silencePlatformEffects(rec: AudioRecord, source: Int) {
        if (source == MediaRecorder.AudioSource.MIC) return
        val session = rec.audioSessionId
        fun off(name: String, available: Boolean, create: () -> AudioEffect?): String {
            if (!available) return "$name=unsupported-on-device"
            val effect = try {
                create()
            } catch (e: RuntimeException) {
                Log.w(TAG, "$name control unavailable: ${e.message}")
                null
            } ?: return "$name=unsupported-on-session"
            synchronized(platformEffects) { platformEffects.add(effect) }
            effect.setEnabled(false)
            return "$name=" + if (effect.enabled) "still-on" else "off"
        }
        val aec = off("aec", AcousticEchoCanceler.isAvailable()) { AcousticEchoCanceler.create(session) }
        val ns = off("ns", NoiseSuppressor.isAvailable()) { NoiseSuppressor.create(session) }
        val agc = off("agc", AutomaticGainControl.isAvailable()) { AutomaticGainControl.create(session) }
        Log.i(TAG, "platform effects on ${sourceName(source)}: $aec $ns $agc")
    }

    private fun releasePlatformEffects() {
        synchronized(platformEffects) {
            platformEffects.forEach { it.release() }
            platformEffects.clear()
        }
    }

    override fun onCancel(arguments: Any?) {
        stop()
    }

    private fun stop() {
        delivery?.let {
            it.close()
            if (it.droppedChunks > 0) Log.w(TAG, "capture delivery dropped ${it.droppedChunks} stale chunks")
        }
        delivery = null
        recording = false
        worker?.let { try { it.join(500) } catch (_: InterruptedException) {} }
        worker = null
        // Effects first: they are attached to the session this record owns.
        releasePlatformEffects()
        record?.let {
            try { it.stop() } catch (_: IllegalStateException) {}
            it.release()
        }
        record = null
        SoftwareEcho.setEnabled(false)
        SoftwareEcho.setNoiseSuppression(false)
        // Only tear down Bluetooth routing this recorder brought up; a stop
        // with automatic routing must not disturb whatever else holds it.
        if (commDeviceSet || scoStarted) {
            val am = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (commDeviceSet && Build.VERSION.SDK_INT >= 31) am.clearCommunicationDevice()
            if (scoStarted) {
                @Suppress("DEPRECATION")
                am.isBluetoothScoOn = false
                @Suppress("DEPRECATION")
                am.stopBluetoothSco()
            }
            commDeviceSet = false
            scoStarted = false
            AudioRouting.micHoldsCommDevice = false
        }
    }
}
