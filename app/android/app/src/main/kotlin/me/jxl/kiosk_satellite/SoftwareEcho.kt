package me.jxl.kiosk_satellite

import android.content.Context
import android.util.Log
import java.io.File

/**
 * Echo cancellation in software: LocalVQE's neural canceller (GTCRN-AEC) when
 * the CPU and the model allow it, WebRTC's AEC3 otherwise, and the opt-in
 * custom filter for duplex voice, with everything the kiosk plays
 * ([EchoReference]) as the
 * reference. MicRecorder turns it on with the capture when the setting
 * asks for it, and hands every chunk to [process] on its thread before any
 * consumer sees it, so the wake word, Assist, realtime conversations, the
 * intercom and the RTSP stream all hear the cleaned microphone.
 *
 * It only works while something plays and for a short tail after: with
 * nothing in the reference there is no echo to take out, and the idle
 * microphone goes through untouched. The canceller itself stays loaded, so
 * what it learned about the room carries over to the next sound.
 */
object SoftwareEcho {
    private const val TAG = "SoftwareEcho"
    private const val RATE = EchoReference.RATE

    /** A frame, 10 ms of 16 kHz PCM16. */
    private const val FRAME = RATE / 100
    private const val FRAME_BYTES = FRAME * 2

    /** How long after the last sound the room can still echo it. */
    private const val TAIL_MS = 1500L

    /** Each source's recent history, longer than any capture chunk. */
    private const val HISTORY = RATE * 400 / 1000

    private val loaded: Boolean = try {
        System.loadLibrary("kiosk_echo")
        true
    } catch (e: Throwable) {
        Log.w(TAG, "native library unavailable: ${e.message}")
        false
    }

    /** LocalVQE's model, an asset copied to app storage on first use (the library loads from a path). */
    private const val VQE_MODEL = "localvqe-pi-aec-v1-49k-f32.gguf"

    private var appContext: Context? = null

    /** Also receives the canceller's log lines, for the app log (AudioRoutingBridge sets it). */
    @Volatile var onLog: ((String) -> Unit)? = null

    private fun report(message: String) {
        Log.i(TAG, message)
        onLog?.invoke(message)
    }

    /** Why LocalVQE is not the canceller, when it is not. */
    private var vqeWhyNot = ""

    /** The application context, for copying the model out of the APK. */
    fun attach(context: Context) {
        appContext = context.applicationContext
        // 2026.11.1 kept its AEC3 verdict in this file; the setting holds it now.
        File(context.filesDir, "localvqe/aec3-here").delete()
    }

    /** Null when LocalVQE can run here, else why not. */
    private val vqeUnavailable: String? = when {
        !loaded -> "native library missing"
        else -> try {
            if (nativeVqeSupported()) null else "this CPU has no VFPv4"
        } catch (e: UnsatisfiedLinkError) {
            "this build has no LocalVQE"
        }
    }

    /** The LocalVQE canceller, 0 while AEC3 runs instead. */
    private var vqe = 0L

    /**
     * How many 10 ms frames LocalVQE's output trails its input: every capture
     * frame comes back this much later, cleaned or not, while it is on.
     */
    private var vqeDelay = 0

    /** The last frames' levels before the canceller and in the reference, for the gate after the delay. */
    private var heardRing = IntArray(1)
    private var playedRing = IntArray(1)
    private var ringAt = 0

    private fun vqeModelFile(): File? {
        val context = appContext ?: return null
        val file = File(context.filesDir, "localvqe/$VQE_MODEL")
        if (file.isFile && file.length() > 0) return file
        return try {
            file.parentFile?.mkdirs()
            val tmp = File(file.path + ".tmp")
            context.assets.open("localvqe/$VQE_MODEL").use { input -> tmp.outputStream().use { input.copyTo(it) } }
            if (!tmp.renameTo(file)) null else file
        } catch (e: Exception) {
            Log.w(TAG, "LocalVQE model unavailable: ${e.message}")
            null
        }
    }

    /**
     * Whether GTCRN keeps up with this device's echo. A microphone that
     * comes through a vendor's own adaptive canceller carries an echo that
     * moves as that canceller adapts, and no reference-based canceller can
     * follow it: on an Echo Show 8 whose capture ran through Amazon's ASR
     * pipeline GTCRN took 3 to 5 dB off an answer, where it takes 33 dB or
     * more off the raw microphone once it has had 3 s to learn the room.
     * AEC3 copes a little better there. With Echo cancellation method on
     * Automatic, three bad 3 s stretches of playback in a row settle on AEC3
     * for the device and ten good ones on GTCRN. The verdict goes to the
     * setting (AudioRoutingManager), which shows it and keeps it.
     *
     * Someone talking over an answer must not look like leftover echo: a
     * voice passes through the canceller, so on its frames little comes
     * off. Each stretch is judged by its best quarter of frames instead of
     * its median. On recordings of GTCRN working on the raw microphone of an
     * Echo Show 8, that stayed 19 dB or more with a loud talker over 90% of
     * the playback, while the median fell to 11 dB once a talker covered
     * three quarters of it, which is how a device that worked switched to
     * AEC3 in its first conversation. The first 3 s of each new GTCRN, while
     * it learns the room, do not count.
     */
    private object EchoCheck {
        const val WINDOW = 300                 // frames of playback, 3 s
        const val MIN_REMOVED_DB = 12.0        // off the best quarter of a stretch
        const val MAX_ROOM_RATIO = 6.0
        const val STRIKES = 3
        const val GOOD = 10                    // stretches in a row, 30 s of playback
        private const val ROOM_FRAMES = 1000   // the last 10 s of idle microphone
        private val room = IntArray(ROOM_FRAMES)
        private var roomCount = 0
        private var roomAt = 0
        private val heard = IntArray(WINDOW)
        private val left = IntArray(WINDOW)
        private val removed = DoubleArray(WINDOW)
        private var count = 0
        private var learning = 0
        private var strikes = 0
        private var goods = 0

        /** The last measured stretch, for the log: echo left, dB under the microphone, times the room. */
        var lastLeft = -1
        var lastRemovedDb = 0.0
        var lastRoomRatio = 0.0

        /** A new GTCRN: its first stretch learns the room and is not judged. */
        fun started() {
            count = 0
            learning = WINDOW
        }

        /** How far Automatic's test got, for the log. */
        fun progress() = "testing: $goods of $GOOD good and $strikes of $STRIKES bad stretches in a row"

        /** Automatic picked again: judge this device from the start. */
        fun reset() {
            strikes = 0
            goods = 0
            lastLeft = -1
            started()
        }

        /** A frame with nothing playing: the room's own level. */
        fun idle(level: Int) {
            room[roomAt] = level
            roomAt = (roomAt + 1) % ROOM_FRAMES
            if (roomCount < ROOM_FRAMES) roomCount++
        }

        private fun roomLevel(): Int? {
            if (roomCount < 200) return null
            val sorted = room.copyOf(roomCount).also { it.sort() }
            return sorted[roomCount / 5]
        }

        /**
         * A frame the speaker played: [AEC3] once [STRIKES] stretches in a
         * row say GTCRN cannot cope, [GTCRN] once [GOOD] in a row say it
         * does, else null. The stretches run on across playback periods:
         * realtime answers are often shorter than one.
         */
        fun playing(heardLevel: Int, leftLevel: Int): String? {
            if (learning > 0) {
                learning--
                return null
            }
            heard[count] = heardLevel
            left[count] = leftLevel
            removed[count] = 20 * kotlin.math.log10(maxOf(heardLevel, 1) / maxOf(leftLevel, 1).toDouble())
            if (++count < WINDOW) return null
            count = 0
            val medHeard = heard.copyOf().also { it.sort() }[WINDOW / 2]
            val sortedLeft = left.copyOf().also { it.sort() }
            if (medHeard < 50) return null     // too quiet to judge
            // Unknown until the microphone has had 2 s with nothing playing,
            // which music playing from the start never gives it.
            val roomNow = roomLevel()
            lastLeft = sortedLeft[WINDOW / 2]
            lastRemovedDb = 20 * kotlin.math.log10(medHeard / maxOf(lastLeft, 1).toDouble())
            lastRoomRatio = roomNow?.let { lastLeft / maxOf(it, 10).toDouble() } ?: Double.NaN
            val best = removed.copyOf().also { it.sort() }[WINDOW * 3 / 4]
            val bestRatio = roomNow?.let { sortedLeft[WINDOW / 4] / maxOf(it, 10).toDouble() }
            // A stretch GTCRN cleans well counts whatever the room. One it
            // does not waits for the room: on a quiet device little comes
            // off because there was little echo to begin with.
            val good = best >= MIN_REMOVED_DB || (bestRatio != null && bestRatio <= MAX_ROOM_RATIO)
            if (!good && bestRatio == null) return null
            val bad = !good
            strikes = if (bad) strikes + 1 else 0
            goods = if (bad) 0 else goods + 1
            return when {
                strikes >= STRIKES -> AEC3
                goods >= GOOD -> GTCRN
                else -> null
            }
        }
    }

    /** Echo cancellation method values (definitions.dart), with Automatic's verdicts. */
    private const val AUTO = "auto"
    private const val GTCRN = "gtcrn"
    private const val AEC3 = "aec3"
    private const val DETECTED = "auto:"

    /** The method this capture runs, from the setting. */
    private var method = AUTO

    /** Automatic still judging the device: GTCRN runs and EchoCheck watches it. */
    private var checking = false

    /** Receives Automatic's verdict, [GTCRN] or [AEC3], for the setting (AudioRoutingBridge sets it). */
    @Volatile var onDetected: ((String) -> Unit)? = null

    private fun detected(verdict: String) {
        checking = false
        onDetected?.invoke(verdict)
    }

    /** GTCRN has shown it cannot keep up: AEC3 takes over once this sound ends. */
    private var aec3Pending = false

    /** Automatic settled on AEC3: swap GTCRN for it (under [lock]). */
    private fun switchToAec3() {
        aec3Pending = false
        val created = nativeCreate(RATE, RATE, false, residualGate.intercomOnly, residualGate.realtime)
        if (created == 0L) return
        nativeVqeDestroy(vqe)
        vqe = 0L
        vqeDelay = 0
        handle = created
        usesPrototype = false
        report(
            "echo cancellation: AEC3 (detected: GTCRN left too much echo: %d, %.0f dB under the microphone, %.0fx the room)".format(
                EchoCheck.lastLeft, EchoCheck.lastRemovedDb, EchoCheck.lastRoomRatio,
            ),
        )
        ran(AEC3, "detected")
        detected(AEC3)
    }

    /** A LocalVQE canceller, or 0 when this device or build cannot run it. */
    private fun createVqe(): Long {
        vqeUnavailable?.let { vqeWhyNot = it; return 0L }
        if (customDuplex || customRealtime) { vqeWhyNot = "the echo prototype build uses AEC3"; return 0L }
        val file = vqeModelFile() ?: run { vqeWhyNot = "the model could not be copied out of the APK"; return 0L }
        var created = nativeVqeCreate(file.path)
        if (created == 0L) {
            // a damaged copy fails the library's checksum: copy it again once
            file.delete()
            val again = vqeModelFile() ?: run { vqeWhyNot = "the model could not be copied out of the APK"; return 0L }
            created = nativeVqeCreate(again.path)
        }
        if (created == 0L) vqeWhyNot = "LocalVQE did not load the model"
        return created
    }

    private val customDuplex = loaded && nativePrototypeAvailable(false)
    private val customRealtime = loaded && nativePrototypeAvailable(true)
    private var usesPrototype = false

    private val lock = Object()
    private var handle = 0L
    private var working = false
    private var workingSinceNs = 0L

    /**
     * WebRTC's noise suppressor over every capture chunk, after the
     * canceller: a microphone's hiss is there whether or not anything
     * plays, and it carried straight into intercom calls on an Echo Show
     * 8. Its own module, so it runs while the canceller's rests.
     */
    private var nsHandle = 0L

    /** Whether the suppressor runs. */
    @Volatile var noiseSuppression = false
        private set

    fun setNoiseSuppression(on: Boolean) {
        synchronized(lock) {
            if (on == noiseSuppression) return
            if (on) {
                if (!loaded) return
                val created = nativeNsCreate(RATE)
                if (created == 0L) return
                nsHandle = created
                noiseSuppression = true
            } else {
                noiseSuppression = false
                nativeDestroy(nsHandle)
                nsHandle = 0L
            }
        }
    }

    /**
     * How far a chunk's place by the clock may stray from where the last
     * chunk ended and still follow on from it. A track's position comes in
     * mixer-sized steps a few milliseconds apart: jumping on each of them
     * would cut the reference into pieces the canceller cannot follow.
     */
    private const val SLACK = RATE * 10 / 1000

    /**
     * A source's recent samples, placed in time: [end] is one past the last
     * one the speaker had presented at [endNs]. A capture chunk reads the
     * samples the speaker was playing while it was being captured, by the
     * capture's own clock (MicRecorder's CaptureClock). Placing each chunk
     * by the clock rather than by when this code happens to run keeps the
     * reference the same distance from the microphone every time a sound
     * starts, so the canceller keeps what it learned instead of relearning
     * the delay for a second and a half at the start of every answer.
     */
    private class Stream {
        val samples = ShortArray(HISTORY)
        var length = 0
        var end = 0L
        var endNs = 0L
        var cursor = Long.MIN_VALUE
    }

    private val streams = HashMap<EchoReference.Source, Stream>()

    private val residualGate = ResidualEchoGate()

    /**
     * Each player owns its processing request. Stopping one cannot disable
     * another. AEC3 runs with one configuration in every mode, so a call
     * starting or ending keeps the canceller and what it learned from the
     * ring and every sound before it: rebuilt at each call, it started
     * every call empty and let the first far sentence through while it
     * learned. Only an experimental build that swaps in the custom filter
     * for a mode rebuilds.
     */
    internal fun setMode(owner: Any, mode: ResidualEchoGate.Mode?) {
        synchronized(lock) {
            residualGate.set(owner, mode)
            val prototype = (customDuplex && residualGate.intercomOnly) ||
                (customRealtime && residualGate.realtime)
            if (enabled && vqe == 0L && prototype != usesPrototype) {
                val next = nativeCreate(RATE, RATE, false, residualGate.intercomOnly, residualGate.realtime)
                if (next != 0L) {
                    stopWorking()
                    nativeDestroy(handle)
                    handle = next
                    usesPrototype = prototype
                }
            }
        }
    }

    private val mix = ShortArray(FRAME)
    private val mixBytes = ByteArray(FRAME_BYTES)

    /** Whether the capture runs through the canceller. */
    @Volatile var enabled = false
        private set

    /**
     * The canceller this process last ran, "gtcrn" or "aec3", empty until
     * one has, and why: "picked" in Microphone settings, "detected" by
     * Automatic, "testing" while Automatic still judges GTCRN, or
     * "unavailable" when GTCRN cannot run here. Kept after the capture
     * stops, for usage analytics: it is what this kiosk cancels with when
     * it listens, whatever the setting says.
     */
    @Volatile var lastEngine = ""
        private set
    @Volatile var lastWhy = ""
        private set

    private fun ran(engine: String, why: String) {
        lastEngine = engine
        lastWhy = why
    }

    /** [lastEngine], [lastWhy] and whether a capture runs through it now. */
    fun state(): Map<String, Any> = mapOf("engine" to lastEngine, "why" to lastWhy, "running" to enabled)

    /**
     * On or off with the capture's settings, with the Echo cancellation
     * method: [AUTO], [GTCRN], [AEC3], or Automatic's verdict ("auto:gtcrn",
     * "auto:aec3").
     */
    fun setEnabled(on: Boolean, method: String = AUTO) {
        synchronized(lock) {
            if (on == enabled) return
            if (on) {
                if (!loaded) return
                // Automatic picked again after a verdict or another method
                // judges this device from the start.
                if (method == AUTO && this.method != AUTO) {
                    EchoCheck.reset()
                    report("echo cancellation: Automatic test starts over")
                }
                this.method = method
                val pick = method.removePrefix(DETECTED)
                val why = when {
                    method.startsWith(DETECTED) -> "detected"
                    method == AUTO -> "automatic"
                    else -> "picked in Microphone settings"
                }
                vqe = if (pick == AEC3) 0L else createVqe()
                if (vqe != 0L) {
                    vqeDelay = nativeVqeLatencyFrames()
                    heardRing = IntArray(vqeDelay + 1)
                    playedRing = IntArray(vqeDelay + 1)
                    ringAt = 0
                    enabled = true
                    checking = method == AUTO
                    ran(GTCRN, if (checking) "testing" else if (method.startsWith(DETECTED)) "detected" else "picked")
                    EchoCheck.started()
                    val testing = if (checking) ", ${EchoCheck.progress()}" else ""
                    report("echo cancellation: GTCRN (LocalVQE, $why$testing), capture ${vqeDelay * 10} ms late")
                    return
                }
                val created = nativeCreate(RATE, RATE, false, residualGate.intercomOnly, residualGate.realtime)
                if (created == 0L) return
                handle = created
                usesPrototype = (customDuplex && residualGate.intercomOnly) || (customRealtime && residualGate.realtime)
                enabled = true
                checking = false
                ran(AEC3, if (pick != AEC3) "unavailable" else if (method.startsWith(DETECTED)) "detected" else "picked")
                if (pick == AEC3) {
                    report("echo cancellation: AEC3 ($why)")
                } else {
                    report("echo cancellation: AEC3 (GTCRN unavailable: $vqeWhyNot)")
                    // A CPU that cannot run GTCRN never will: Automatic settles here.
                    if (method == AUTO && vqeUnavailable != null) detected(AEC3)
                }
            } else {
                enabled = false
                stopWorking()
                val wasVqe = vqe != 0L
                if (vqe != 0L) nativeVqeDestroy(vqe)
                vqe = 0L
                vqeDelay = 0
                nativeDestroy(handle)
                handle = 0L
                usesPrototype = false
                streams.clear()
                residualGate.reset()
                report("echo cancellation: ${if (wasVqe) "GTCRN" else "AEC3"} off")
            }
        }
    }

    /** Each frame's level after the canceller and before the gate, for [MicLevels]. */
    private var levels = DoubleArray(0)

    /** One capture chunk of 16 kHz mono PCM16 whose last frame was heard at [heardNs], cleaned in place. */
    fun process(chunk: ByteArray, heardNs: Long) {
        if (!enabled && !noiseSuppression) return
        synchronized(lock) {
            // Arbitration's levels come before the gate and the suppressor,
            // which only make the floor quieter.
            if (cancel(chunk, heardNs)) MicLevels.add(levels, chunk.size / FRAME_BYTES)
            else MicLevels.measure(chunk)
            val ns = nsHandle
            if (ns != 0L) {
                var at = 0
                while (at + FRAME_BYTES <= chunk.size) {
                    nativeNsProcess(ns, chunk, at)
                    at += FRAME_BYTES
                }
            }
        }
    }

    /**
     * The canceller's share of [process], under [lock]. True when it ran,
     * with each frame's level before the gate in [levels].
     */
    private fun cancel(chunk: ByteArray, heardNs: Long): Boolean {
        if (!enabled) return false
        run {
            val h = if (vqe != 0L) vqe else handle
            if (h == 0L) return false
            val sources = EchoReference.sources()
            var fresh = false
            for (source in sources) {
                val takenNs = System.nanoTime()
                source.take()?.let {
                    val stream = streams.getOrPut(source) { Stream() }
                    append(stream, it)
                    stream.endNs = takenNs
                    fresh = true
                }
            }
            streams.keys.retainAll(sources.toSet())
            if (!EchoReference.playedWithin(TAIL_MS) && !fresh) {
                stopWorking()
                // AEC3 takes over between sounds, so it starts at the beginning
                // of the next one: created in the middle of an answer on an
                // Echo Show 8 it found a delay of 0 to 16 ms against the real 96
                // and let the answer through.
                if (aec3Pending && vqe != 0L) switchToAec3()
                if (vqe != 0L) idleThroughVqe(chunk)
                return false
            }
            if (!working) {
                working = true
                workingSinceNs = System.nanoTime()
            }
            val frames = chunk.size / FRAME_BYTES
            val need = frames * FRAME
            if (levels.size < frames) levels = DoubleArray(frames)
            for (stream in streams.values) {
                // The sample the speaker was presenting as the chunk's last
                // frame was heard, and the chunk's worth before it.
                val heard = stream.end - (stream.endNs - heardNs) * RATE / 1_000_000_000L
                val start = heard - need
                if (stream.cursor == Long.MIN_VALUE || kotlin.math.abs(start - stream.cursor) > SLACK) {
                    stream.cursor = start
                }
            }
            var at = 0
            var switchTo = false
            for (f in 0 until frames) {
                mixFrame(f)
                for (i in 0 until FRAME) {
                    val v = mix[i].toInt()
                    mixBytes[i * 2] = v.toByte()
                    mixBytes[i * 2 + 1] = (v shr 8).toByte()
                }
                var heard = meanAbs(chunk, at)
                var played = meanAbs(mixBytes, 0)
                if (vqe != 0L) {
                    nativeVqeRender(h, mixBytes, 0)
                    nativeVqeCapture(h, chunk, at, true)
                    // the frame that came back is vqeDelay frames old: gate it on its own levels
                    val back = remember(heard, played)
                    heard = heardRing[back]
                    played = playedRing[back]
                    if (played >= 100 && checking) {
                        when (EchoCheck.playing(heard, meanAbs(chunk, at))) {
                            AEC3 -> switchTo = true
                            GTCRN -> {
                                report("echo cancellation: GTCRN (detected: %.0f dB under the microphone)".format(EchoCheck.lastRemovedDb))
                                ran(GTCRN, "detected")
                                detected(GTCRN)
                            }
                        }
                    }
                } else {
                    nativeRender(h, mixBytes, 0)
                    nativeCapture(h, chunk, at)
                }
                levels[f] = MicLevels.meanSquare(chunk, at)
                if (residualGate.suppress(heard, played, meanAbs(chunk, at), subtractionOnly = usesPrototype)) {
                    java.util.Arrays.fill(chunk, at, at + FRAME_BYTES, 0)
                }
                at += FRAME_BYTES
            }
            for (stream in streams.values) stream.cursor += need
            if (switchTo) aec3Pending = true
        }
        return true
    }

    /**
     * Records this frame's levels and returns the ring slot of the frame
     * [vqeDelay] frames back, the one LocalVQE hands out now.
     */
    private fun remember(heard: Int, played: Int): Int {
        heardRing[ringAt] = heard
        playedRing[ringAt] = played
        ringAt = (ringAt + 1) % heardRing.size
        return ringAt   // the oldest slot: vqeDelay frames before the one just written
    }

    /** Nothing plays: the frames still pass LocalVQE's delay, as they are. */
    private fun idleThroughVqe(chunk: ByteArray) {
        var at = 0
        while (at + FRAME_BYTES <= chunk.size) {
            val level = meanAbs(chunk, at)
            remember(level, 0)
            EchoCheck.idle(level)
            nativeVqeCapture(vqe, chunk, at, false)
            at += FRAME_BYTES
        }
    }

    /** Mean |sample| of the frame at [at]. */
    private fun meanAbs(pcm: ByteArray, at: Int): Int {
        var sum = 0
        for (i in 0 until FRAME) {
            val v = (pcm[at + i * 2].toInt() and 0xFF) or (pcm[at + i * 2 + 1].toInt() shl 8)
            sum += kotlin.math.abs(v.toShort().toInt())
        }
        return sum / FRAME
    }

    /** Frame [f] of this chunk from every source, read at its cursor and summed into [mix]. */
    private fun mixFrame(f: Int) {
        java.util.Arrays.fill(mix, 0)
        for (stream in streams.values) {
            val first = stream.end - stream.length
            val from = stream.cursor + f * FRAME
            for (i in 0 until FRAME) {
                val at = from + i - first
                if (at < 0 || at >= stream.length) continue
                mix[i] = (mix[i] + stream.samples[at.toInt()]).coerceIn(-32768, 32767).toShort()
            }
        }
    }

    private fun append(stream: Stream, samples: ShortArray) {
        val buffer = stream.samples
        if (samples.size >= buffer.size) {
            System.arraycopy(samples, samples.size - buffer.size, buffer, 0, buffer.size)
            stream.length = buffer.size
        } else {
            val drop = maxOf(0, stream.length + samples.size - buffer.size)
            if (drop > 0) {
                System.arraycopy(buffer, drop, buffer, 0, stream.length - drop)
                stream.length -= drop
            }
            System.arraycopy(samples, 0, buffer, stream.length, samples.size)
            stream.length += samples.size
        }
        stream.end += samples.size
    }

    /**
     * Back to idle, and a line for the log: how long it worked and the echo
     * delay it found (the time from a sound playing to its echo in the
     * microphone, 110 to 130 ms on a Galaxy Tab S8).
     */
    private fun stopWorking() {
        if (!working) return
        working = false
        residualGate.reset()
        val delayMs = when {
            vqe != 0L -> nativeVqeDelayMs(vqe)
            handle != 0L -> nativeStats(handle)[1]
            else -> return
        }
        val seconds = (System.nanoTime() - workingSinceNs) / 1_000_000_000.0
        val measured = if (vqe != 0L && EchoCheck.lastLeft >= 0) {
            ", echo left %d (%.0f dB under the microphone%s)".format(
                EchoCheck.lastLeft, EchoCheck.lastRemovedDb,
                if (EchoCheck.lastRoomRatio.isNaN()) "" else ", %.1fx the room".format(EchoCheck.lastRoomRatio),
            )
        } else ""
        report("%s cancelled for %.1f s, echo delay %s%s%s".format(
            if (vqe != 0L) "GTCRN" else "AEC3",
            seconds, if (delayMs.isNaN()) "not found" else "${delayMs.toInt()} ms", measured,
            if (checking) ", ${EchoCheck.progress()}" else "",
        ))
    }

    @JvmStatic private external fun nativeCreate(captureRate: Int, renderRate: Int, noiseSuppression: Boolean, intercom: Boolean, realtime: Boolean): Long
    @JvmStatic private external fun nativePrototypeAvailable(realtime: Boolean): Boolean
    @JvmStatic private external fun nativeRender(handle: Long, pcm: ByteArray, offset: Int)
    @JvmStatic private external fun nativeCapture(handle: Long, pcm: ByteArray, offset: Int)
    @JvmStatic private external fun nativeStats(handle: Long): DoubleArray
    @JvmStatic private external fun nativeDestroy(handle: Long)
    @JvmStatic private external fun nativeNsCreate(rate: Int): Long
    @JvmStatic private external fun nativeNsProcess(handle: Long, pcm: ByteArray, offset: Int)
    @JvmStatic private external fun nativeVqeSupported(): Boolean
    @JvmStatic private external fun nativeVqeCreate(modelPath: String): Long
    @JvmStatic private external fun nativeVqeLatencyFrames(): Int
    @JvmStatic private external fun nativeVqeRender(handle: Long, pcm: ByteArray, offset: Int)
    @JvmStatic private external fun nativeVqeCapture(handle: Long, pcm: ByteArray, offset: Int, work: Boolean)
    @JvmStatic private external fun nativeVqeDelayMs(handle: Long): Double
    @JvmStatic private external fun nativeVqeDestroy(handle: Long)
}
