package me.jxl.kiosk_satellite.airplay

import android.util.Log
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress

/** One decoded audio packet: [frames] stereo frames from RTP time [rtp]. */
internal class AudioPacket(val seq: Int, val rtp: Long, val pcm: ShortArray, val frames: Int)

/** Signed distance from [b] to [a] on a 16-bit sequence counter. */
internal fun seqDiff(a: Int, b: Int): Int = ((a - b + 0x8000) and 0xFFFF) - 0x8000

/** Signed distance from [b] to [a] on a 32-bit RTP clock. */
internal fun rtpDiff(a: Long, b: Long): Long = ((a - b + 0x8000_0000L) and 0xFFFF_FFFFL) - 0x8000_0000L

/**
 * The sender's clock as seen from here: the offset from this device's
 * monotonic nanoseconds to the sender's NTP timeline, from the timing
 * exchange. Each reply gives an offset and the round trip it was measured
 * over. The one with the shortest round trip among the last few is the
 * least disturbed by the network and wins. Before any reply, a sync
 * packet's own timestamp against its arrival stands in.
 */
internal class ClockSync {
    private val samples = ArrayDeque<Pair<Long, Long>>() // round trip, offset

    @Volatile var offsetNs: Long? = null
        private set

    @Synchronized
    fun addExchange(sentNs: Long, receivedNs: Long, remoteReceiveNs: Long, remoteSendNs: Long) {
        val roundTrip = (receivedNs - sentNs) - (remoteSendNs - remoteReceiveNs)
        if (roundTrip < 0 || roundTrip > 200_000_000L) return
        // Midpoints written so a sender clock near the top of the range
        // cannot overflow the sum.
        val remoteMid = remoteReceiveNs + (remoteSendNs - remoteReceiveNs) / 2
        val localMid = sentNs + (receivedNs - sentNs) / 2
        val offset = remoteMid - localMid
        samples.addLast(roundTrip to offset)
        while (samples.size > 8) samples.removeFirst()
        offsetNs = samples.minByOrNull { it.first }!!.second
    }

    /** Only until the first exchange lands. */
    @Synchronized
    fun guessFromSync(remoteNs: Long, arrivedNs: Long) {
        if (samples.isEmpty()) offsetNs = remoteNs - arrivedNs
    }

    @Synchronized
    fun reset() {
        samples.clear()
        offsetNs = null
    }
}

/**
 * Where the stream's RTP clock sits on the sender's timeline: frame [rtp]
 * plays at sender time [remoteNs]. From the sync packets, about once a
 * second while audio flows.
 */
internal class Anchor(val rtp: Long, val remoteNs: Long)

/**
 * The jitter buffer between the network and the player, indexed by RTP
 * sequence number. Packets may arrive late, twice or out of order. A gap
 * is asked for again at once and filled if the resend arrives before the
 * player reaches it. [read] hands out the packets in sequence, a missing
 * one as null with its slot counted, so the player can play silence in
 * its place.
 */
internal class PacketBuffer(private val onGap: (first: Int, count: Int) -> Unit) {
    private val slots = arrayOfNulls<AudioPacket>(SIZE)
    private var readSeq = -1
    private var writeSeq = -1
    /** RTP time of the next frame the player takes. */
    private var nextRtp = -1L
    /** Packets with an RTP time before this are from before a flush. */
    private var floorRtp: Long? = null

    /** Packets set aside as from before a flush, for diagnostics. */
    @Volatile var droppedAsStale = 0L
        private set

    /** The flush point last set, for diagnostics. */
    @Volatile var lastFlushRtp: Long? = null
        private set
    @Volatile var lastArrivalNs = 0L
        private set

    @Synchronized
    fun put(packet: AudioPacket) {
        floorRtp?.let {
            if (rtpDiff(packet.rtp, it) < 0) {
                droppedAsStale++
                return
            }
            floorRtp = null
        }
        lastArrivalNs = System.nanoTime()
        if (readSeq < 0) {
            readSeq = packet.seq
            writeSeq = (packet.seq + 1) and 0xFFFF
            nextRtp = packet.rtp
            slots[packet.seq and MASK] = packet
            return
        }
        val ahead = seqDiff(packet.seq, writeSeq)
        when {
            ahead == 0 -> {
                slots[packet.seq and MASK] = packet
                writeSeq = (writeSeq + 1) and 0xFFFF
            }
            ahead > 0 && ahead < SIZE / 2 -> {
                onGap(writeSeq, ahead)
                // Slots skipped over are stale from a lap ago.
                var s = writeSeq
                while (s != packet.seq) {
                    slots[s and MASK] = null
                    s = (s + 1) and 0xFFFF
                }
                slots[packet.seq and MASK] = packet
                writeSeq = (packet.seq + 1) and 0xFFFF
            }
            ahead < 0 && seqDiff(packet.seq, readSeq) >= 0 -> {
                // A resend, or a straggler, still in time.
                slots[packet.seq and MASK] = packet
            }
            ahead >= SIZE / 2 || ahead <= -SIZE / 2 -> {
                // The sender jumped: start over from here.
                clearLocked()
                put(packet)
            }
        }
    }

    /** RTP time of the next frame [read] would give out, or null when empty. */
    @Synchronized
    fun headRtp(): Long? = if (readSeq < 0 || readSeq == writeSeq) null else nextRtp

    @Synchronized
    fun buffered(): Int = if (readSeq < 0) 0 else seqDiff(writeSeq, readSeq)

    /**
     * The next packet, or null for a missing one in its place, which
     * stands for [framesPerPacket] frames. Call only when [headRtp] is not
     * null.
     */
    @Synchronized
    fun read(framesPerPacket: Int): AudioPacket? {
        val slot = readSeq and MASK
        val p = slots[slot]?.takeIf { it.seq == readSeq }
        slots[slot] = null
        readSeq = (readSeq + 1) and 0xFFFF
        val frames = p?.frames ?: framesPerPacket
        nextRtp = ((p?.rtp ?: nextRtp) + frames) and 0xFFFF_FFFFL
        return p
    }

    /** Drop everything; packets before [rtp] are ignored from now on. */
    @Synchronized
    fun flush(rtp: Long?) {
        clearLocked()
        floorRtp = rtp
        lastFlushRtp = rtp
    }

    private fun clearLocked() {
        java.util.Arrays.fill(slots, null)
        readSeq = -1
        writeSeq = -1
        nextRtp = -1
    }

    companion object {
        const val SIZE = 1024
        private const val MASK = SIZE - 1
    }
}

/**
 * Decrypts and decodes audio payloads. Live packets arrive on the audio
 * thread and resent ones on the control thread. The cipher and the ALAC
 * decoder both keep working state for the packet in hand, so [decode]
 * takes one packet at a time.
 */
internal class PayloadDecoder(private val format: StreamFormat) {
    private val cipher = format.aesKey?.let { RaopCrypto.PacketCipher(it, format.aesIv!!) }
    private val decoder = if (format.alac) AlacDecoder(
        frameLength = format.fmtp[1],
        sampleSize = format.fmtp[3],
        historyMult = format.fmtp[4],
        initialHistory = format.fmtp[5],
        riceLimit = format.fmtp[6],
        channels = format.fmtp[7],
    ) else null

    /**
     * Decrypts the [size] bytes at [payload] in place and decodes them into
     * [pcm] as interleaved samples. Returns the number of sample frames
     * written.
     */
    @Synchronized
    fun decode(buf: ByteArray, payload: Int, size: Int, pcm: ShortArray): Int {
        cipher?.decrypt(buf, payload, size)
        if (decoder != null) return decoder.decode(buf, payload, size, pcm)
        // L16: big-endian stereo samples.
        val count = minOf(size / 4, format.framesPerPacket)
        for (i in 0 until count * 2) {
            val p = payload + i * 2
            pcm[i] = ((buf[p].toInt() shl 8) or (buf[p + 1].toInt() and 0xFF)).toShort()
        }
        return count
    }
}

/**
 * The three UDP channels of one AirPlay 1 stream: audio in, control
 * (sync packets, resend requests and the resent audio) and timing (the
 * NTP-like exchange with the sender). The sockets bind on [start] and
 * their ports go back in the SETUP reply.
 */
internal class RaopStream(
    private val format: StreamFormat,
    private val sender: InetAddress,
    private val senderControlPort: Int,
    private val senderTimingPort: Int,
) {
    val buffer = PacketBuffer(::requestResend)
    val clock = ClockSync()
    @Volatile var anchor: Anchor? = null
        private set
    /** Frames between a sync packet's two RTP times, plus the receiver's share. */
    @Volatile var latencyFrames: Long = DEFAULT_LATENCY
        private set

    private val audio = DatagramSocket(null)
    private val control = DatagramSocket(null)
    private val timing = DatagramSocket(null)
    @Volatile private var running = false
    private val threads = ArrayList<Thread>()
    private val payloads = PayloadDecoder(format)
    private var resendSeq = 1
    @Volatile private var timingSentNs = 0L

    val audioPort: Int get() = audio.localPort
    val controlPort: Int get() = control.localPort
    val timingPort: Int get() = timing.localPort

    fun start() {
        for (s in listOf(audio, control, timing)) {
            s.reuseAddress = true
            s.bind(InetSocketAddress(0))
        }
        running = true
        spawn("airplay-audio") { receive(audio) { p, n -> onAudio(p, 0, n) } }
        spawn("airplay-control") { receive(control, ::onControl) }
        spawn("airplay-timing") { receive(timing, ::onTiming) }
        spawn("airplay-clock") { timingLoop() }
    }

    fun stop() {
        running = false
        for (s in listOf(audio, control, timing)) runCatching { s.close() }
        for (t in threads) t.interrupt()
    }

    /** Pause or seek: everything buffered goes, and timing starts over. */
    fun flush(rtp: Long?) {
        buffer.flush(rtp)
        anchor = null
    }

    private fun spawn(name: String, body: () -> Unit) {
        val t = Thread({
            try {
                body()
            } catch (e: Exception) {
                if (running) Log.w(TAG, "$name stopped: $e")
            }
        }, name).apply { isDaemon = true; priority = Thread.MAX_PRIORITY }
        threads.add(t)
        t.start()
    }

    private fun receive(socket: DatagramSocket, handle: (ByteArray, Int) -> Unit) {
        val buf = ByteArray(2048)
        val packet = DatagramPacket(buf, buf.size)
        while (running) {
            packet.length = buf.size
            socket.receive(packet)
            try {
                handle(buf, packet.length)
            } catch (e: Exception) {
                Log.w(TAG, "bad packet on ${socket.localPort}: $e")
            }
        }
    }

    /** An RTP audio packet starting at [offset]. */
    private fun onAudio(buf: ByteArray, offset: Int, length: Int) {
        if (length < 12 + 4) return
        val type = buf[offset + 1].toInt() and 0x7F
        if (type != 0x60) return
        val seq = u16(buf, offset + 2)
        val rtp = u32(buf, offset + 4)
        val payload = offset + 12
        val size = length - 12
        val frames = format.framesPerPacket
        val pcm = ShortArray(frames * 2)
        val n = try {
            payloads.decode(buf, payload, size, pcm)
        } catch (e: AlacDecoder.AlacException) {
            Log.w(TAG, "packet $seq undecodable: ${e.message}")
            frames
        }
        buffer.put(AudioPacket(seq, rtp, pcm, n))
    }

    private fun onControl(buf: ByteArray, length: Int) {
        if (length < 4) return
        when (buf[1].toInt() and 0xFF) {
            0xD4 -> if (length >= 20) onSync(buf)
            // A resent packet: four bytes, then the original.
            0xD6 -> onAudio(buf, 4, length - 4)
        }
    }

    /**
     * A sync packet: the frame at its first RTP time plays when the
     * sender's clock reads its NTP time, and the frame at its second, the
     * sender's "now", plays a latency later. The receiver adds the 11025
     * frames (a quarter second) it reports as its own in Audio-Latency,
     * which makes the usual two seconds in all.
     */
    private fun onSync(buf: ByteArray) {
        val arrived = System.nanoTime()
        val lessLatency = u32(buf, 4)
        val remote = ntpToNs(buf, 8)
        val now = u32(buf, 16)
        val latency = rtpDiff(now, lessLatency) + RECEIVER_LATENCY
        if (latency in 0..MAX_LATENCY) latencyFrames = latency
        clock.guessFromSync(remote, arrived)
        anchor = Anchor((now - latencyFrames) and 0xFFFF_FFFFL, remote)
    }

    private fun onTiming(buf: ByteArray, length: Int) {
        if (length < 32 || buf[1].toInt() and 0xFF != 0xD3) return
        val received = System.nanoTime()
        clock.addExchange(timingSentNs, received, ntpToNs(buf, 16), ntpToNs(buf, 24))
    }

    /** Ask the sender for its clock: three quick ones, then every three seconds. */
    private fun timingLoop() {
        var count = 0
        val request = ByteArray(32)
        request[0] = 0x80.toByte()
        request[1] = 0xD2.toByte()
        request[3] = 0x07
        while (running) {
            timingSentNs = System.nanoTime()
            runCatching {
                timing.send(DatagramPacket(request, request.size, sender, senderTimingPort))
            }
            count++
            Thread.sleep(if (count <= 3) 300 else 3000)
        }
    }

    private fun requestResend(first: Int, count: Int) {
        if (!running || senderControlPort <= 0) return
        val req = ByteArray(8)
        req[0] = 0x80.toByte()
        req[1] = 0xD5.toByte()
        val seq = resendSeq++ and 0xFFFF
        req[2] = (seq shr 8).toByte(); req[3] = seq.toByte()
        req[4] = (first shr 8).toByte(); req[5] = first.toByte()
        req[6] = (count shr 8).toByte(); req[7] = count.toByte()
        runCatching { control.send(DatagramPacket(req, req.size, sender, senderControlPort)) }
    }

    /** Sender time of frame [rtp] on this device's monotonic clock, or null. */
    fun localTimeOf(rtp: Long): Long? {
        val a = anchor ?: return null
        val offset = clock.offsetNs ?: return null
        val frames = rtpDiff(rtp, a.rtp)
        return a.remoteNs - offset + frames * 1_000_000_000L / format.sampleRate
    }

    /** RTP time of the frame due on the speaker at monotonic [nowNs], or null. */
    fun rtpAt(nowNs: Long): Long? {
        val a = anchor ?: return null
        val offset = clock.offsetNs ?: return null
        val frames = (nowNs + offset - a.remoteNs) * format.sampleRate / 1_000_000_000L
        return (a.rtp + frames) and 0xFFFF_FFFFL
    }

    /** Stands in for the anchor when a sender sends no sync packets. */
    fun assumeAnchor(rtp: Long, playAtNs: Long) {
        if (anchor != null) return
        if (clock.offsetNs == null) clock.guessFromSync(playAtNs, playAtNs)
        val offset = clock.offsetNs ?: return
        anchor = Anchor(rtp, playAtNs + offset)
    }

    private companion object {
        const val TAG = "AirPlay"
        const val RECEIVER_LATENCY = 11025L
        const val DEFAULT_LATENCY = 88200L
        const val MAX_LATENCY = 44100L * 4

        fun u16(b: ByteArray, o: Int) = ((b[o].toInt() and 0xFF) shl 8) or (b[o + 1].toInt() and 0xFF)

        fun u32(b: ByteArray, o: Int): Long =
            ((b[o].toLong() and 0xFF) shl 24) or ((b[o + 1].toLong() and 0xFF) shl 16) or
                ((b[o + 2].toLong() and 0xFF) shl 8) or (b[o + 3].toLong() and 0xFF)

        /** A 32.32 NTP timestamp as nanoseconds on the sender's timeline. */
        fun ntpToNs(b: ByteArray, o: Int): Long {
            val seconds = u32(b, o)
            val fraction = u32(b, o + 4)
            return seconds * 1_000_000_000L + ((fraction * 1_000_000_000L) ushr 32)
        }
    }
}
