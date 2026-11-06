package me.jxl.kiosk_satellite

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Surface
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.view.TextureRegistry
import java.nio.ByteBuffer
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/** The header of one video frame on the wire: flags, width, height and the
 *  capture time in milliseconds, all big endian. */
internal const val INTERCOM_VIDEO_HEADER = 9
internal const val INTERCOM_VIDEO_KEY = 1

/**
 * Where the camera session meets an intercom call. The encoder lives in
 * [CameraMotion], which comes and goes with the Activity, and the call lives
 * in [IntercomVideo], which lasts as long as the process.
 */
internal object IntercomVideoHub {
    private val startCode = byteArrayOf(0, 0, 0, 1)
    @Volatile private var video: IntercomVideo? = null
    @Volatile private var encoder: CameraRtspEncoder? = null
    @Volatile private var sps: ByteArray? = null
    @Volatile private var pps: ByteArray? = null

    /** Frames still crossing to Dart. A busy main thread must not pile them up. */
    private val crossing = AtomicInteger(0)

    @Volatile var sending = false
        set(value) {
            field = value
            if (value) keyFrame()
        }

    fun connect(owner: IntercomVideo) {
        video = owner
    }

    fun keyFrame() {
        encoder?.keyFrame()
    }

    fun currentEncoder(): CameraRtspEncoder? = encoder

    fun attach(next: CameraRtspEncoder) {
        encoder = next
        sps = null
        pps = null
        video?.encoderChanged(next)
        if (sending) next.keyFrame()
    }

    fun detach(old: CameraRtspEncoder) {
        if (encoder === old) {
            encoder = null
            video?.encoderChanged(null)
        }
    }

    fun fail(message: String) {
        video?.report("cameraFailed", mapOf("message" to message))
    }

    fun config(units: List<ByteArray>) {
        for (unit in units) {
            if (unit.isEmpty()) continue
            when (unit[0].toInt() and 0x1f) {
                7 -> sps = unit
                8 -> pps = unit
            }
        }
    }

    /** One encoded frame, on the encoder's thread. A key frame carries its
     *  parameter sets, so any frame after a gap can start a decoder. */
    fun frame(units: List<ByteArray>, timeUs: Long) {
        if (!sending) return
        val owner = video ?: return
        val size = encoder?.outputSize ?: return
        val key = units.any { it.isNotEmpty() && it[0].toInt() and 0x1f == 5 }
        if (crossing.get() >= MAX_CROSSING && !key) return
        val sets = if (key) listOfNotNull(sps, pps) else emptyList()
        if (key && sets.size < 2) return
        val slices = units.filter { it.isNotEmpty() && it[0].toInt() and 0x1f !in 7..8 }
        var length = INTERCOM_VIDEO_HEADER
        for (unit in sets) length += startCode.size + unit.size
        for (unit in slices) length += startCode.size + unit.size
        val out = ByteBuffer.allocate(length)
        out.put((if (key) INTERCOM_VIDEO_KEY else 0).toByte())
        out.putShort(size.width.toShort())
        out.putShort(size.height.toShort())
        out.putInt((timeUs / 1000).toInt())
        for (unit in sets) out.put(startCode).put(unit)
        for (unit in slices) out.put(startCode).put(unit)
        crossing.incrementAndGet()
        owner.send(out.array()) { crossing.decrementAndGet() }
    }

    private const val MAX_CROSSING = 6
}

/**
 * Releases a producer whether or not it ever made a surface. Below Android 10
 * the engine backs a producer with a SurfaceTexture, and its release() calls
 * surface.release() with no null check, so a far camera that went away before
 * a first frame took the app down when the call ended. Handing out a surface
 * first lets release() finish. Catching the exception would not: the producer
 * would stay unreleased and its finalizer would run the same release again.
 */
internal fun TextureRegistry.SurfaceProducer.releaseAlways() {
    if (handlesCropAndRotation()) getSurface()
    release()
}

/**
 * Video for intercom calls: the picture from the other kiosk and this kiosk's
 * own. Frames cross to Dart, which carries them over the call's video socket
 * with the intercom's key and TLS, and come back through a background queue
 * so a busy UI cannot hold them up.
 */
class IntercomVideo(
    messenger: BinaryMessenger,
    private val textures: TextureRegistry,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "kiosk_satellite/intercom_video")
    private val data = MethodChannel(
        messenger,
        "kiosk_satellite/intercom_video_data",
        StandardMethodCodec.INSTANCE,
        messenger.makeBackgroundTaskQueue(),
    )
    private val main = Handler(Looper.getMainLooper())
    @Volatile private var far: FarVideo? = null
    private var self: TextureRegistry.SurfaceProducer? = null

    init {
        channel.setMethodCallHandler(this)
        data.setMethodCallHandler { call, result ->
            if (call.method == "frame") {
                (call.arguments as? ByteArray)?.let { far?.push(it) }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        IntercomVideoHub.connect(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openFar" -> {
                far?.close()
                val next = FarVideo()
                far = next
                result.success(next.textureId)
            }
            "closeFar" -> {
                far?.close()
                far = null
                result.success(null)
            }
            "openSelf" -> {
                closeSelf()
                val producer = textures.createSurfaceProducer()
                producer.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                    override fun onSurfaceAvailable() = showSelf()
                    override fun onSurfaceCleanup() {
                        IntercomVideoHub.currentEncoder()?.setPreview(null)
                    }
                })
                self = producer
                showSelf()
                result.success(producer.id())
            }
            "closeSelf" -> {
                closeSelf()
                result.success(null)
            }
            "sending" -> {
                IntercomVideoHub.sending = call.arguments == true
                result.success(null)
            }
            "keyFrame" -> {
                IntercomVideoHub.keyFrame()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun closeSelf() {
        val producer = self ?: return
        self = null
        IntercomVideoHub.currentEncoder()?.setPreview(null)
        producer.setCallback(null)
        producer.releaseAlways()
    }

    private fun showSelf() {
        val producer = self ?: return
        val encoder = IntercomVideoHub.currentEncoder() ?: return
        val size = encoder.outputSize ?: return
        producer.setSize(size.width, size.height)
        encoder.setPreview(producer.surface)
        report("self", mapOf("width" to size.width, "height" to size.height))
    }

    /** The camera session started or stopped an encoder. Main thread. */
    internal fun encoderChanged(encoder: CameraRtspEncoder?) {
        if (encoder != null) showSelf()
    }

    internal fun send(frame: ByteArray, done: () -> Unit) {
        main.post {
            try {
                channel.invokeMethod("frame", frame)
            } finally {
                done()
            }
        }
    }

    internal fun report(event: String, details: Map<String, Any?> = emptyMap()) {
        main.post { channel.invokeMethod(event, details) }
    }

    /** Runs on the main thread and waits, for what the texture needs there. */
    private fun <T> onMain(work: () -> T): T? {
        if (Looper.myLooper() == Looper.getMainLooper()) return work()
        var value: T? = null
        val done = CountDownLatch(1)
        main.post {
            try {
                value = work()
            } finally {
                done.countDown()
            }
        }
        return if (done.await(2, TimeUnit.SECONDS)) value else null
    }

    /** One decoder onto one texture, the other kiosk's picture. */
    private inner class FarVideo {
        private val producer = textures.createSurfaceProducer()
        private var glEntry: TextureRegistry.SurfaceTextureEntry? = null
        private var glSurface: Surface? = null

        /** How this decoder reaches the screen, see [outputRoute]. */
        private var route = outputRoute
        val textureId: Long
            get() = glEntry?.id() ?: producer.id()
        private val thread = HandlerThread("intercom-video-decode").apply { start() }
        private val handler = Handler(thread.looper)
        private val lock = Any()
        private var codec: MediaCodec? = null
        private var generation = 0
        private var sps: ByteArray? = null
        private var pps: ByteArray? = null
        private var width = 0
        private var height = 0
        private var waitingKey = true
        private var firstShown = false
        private var surfaceGone = false
        private var closed = false
        private var lastKeyAskMs = 0L
        private val free = ArrayDeque<Int>()
        private val pending = ArrayDeque<Frame>()

        private inner class Frame(val bytes: ByteArray, val timeUs: Long)

        init {
            if (route == ROUTE_GL_TEXTURE) openGlTexture()
            producer.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                override fun onSurfaceAvailable() {
                    synchronized(lock) { surfaceGone = false }
                    askKey()
                }

                override fun onSurfaceCleanup() {
                    synchronized(lock) {
                        surfaceGone = true
                        stopCodec()
                    }
                }
            })
        }

        /** One frame from the socket, on the data channel's queue. */
        fun push(frame: ByteArray) {
            if (frame.size <= INTERCOM_VIDEO_HEADER) return
            val header = ByteBuffer.wrap(frame)
            val key = header.get().toInt() and INTERCOM_VIDEO_KEY != 0
            val frameWidth = header.short.toInt() and 0xffff
            val frameHeight = header.short.toInt() and 0xffff
            val timeUs = (header.int.toLong() and 0xffffffffL) * 1000
            val bytes = frame.copyOfRange(INTERCOM_VIDEO_HEADER, frame.size)
            synchronized(lock) {
                if (closed || surfaceGone) return
                if (key) {
                    val units = CameraRtspEncoder.nals(bytes)
                    val nextSps = units.firstOrNull { it.isNotEmpty() && it[0].toInt() and 0x1f == 7 }
                    val nextPps = units.firstOrNull { it.isNotEmpty() && it[0].toInt() and 0x1f == 8 }
                    if (nextSps == null || nextPps == null) return
                    val changed = codec == null || frameWidth != width || frameHeight != height ||
                        !nextSps.contentEquals(sps) || !nextPps.contentEquals(pps)
                    if (changed && !start(frameWidth, frameHeight, nextSps, nextPps)) return
                    waitingKey = false
                }
                if (waitingKey || codec == null) {
                    askKey()
                    return
                }
                val next = Frame(bytes, timeUs)
                val index = free.removeFirstOrNull()
                if (index != null) {
                    queue(index, next)
                } else {
                    pending.addLast(next)
                    if (pending.size > MAX_PENDING) {
                        pending.clear()
                        waitingKey = true
                        askKey()
                    }
                }
            }
        }

        private fun openGlTexture() {
            val entry = textures.createSurfaceTexture()
            glEntry = entry
            glSurface = Surface(entry.surfaceTexture())
        }

        private fun target(width: Int, height: Int): Surface? = onMain {
            if (route == ROUTE_GL_TEXTURE) {
                if (glEntry == null) {
                    openGlTexture()
                    report("farTexture", mapOf("id" to textureId))
                }
                glEntry?.surfaceTexture()?.setDefaultBufferSize(width, height)
                glSurface
            } else {
                glEntry?.let { old ->
                    glEntry = null
                    glSurface?.release()
                    glSurface = null
                    old.release()
                    report("farTexture", mapOf("id" to textureId))
                }
                producer.setSize(width, height)
                producer.surface
            }
        }

        private fun softwareDecoder(): String? =
            MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.firstOrNull { info ->
                !info.isEncoder && info.supportedTypes.any { it.equals("video/avc", true) } &&
                    (info.name.startsWith("c2.android.") || info.name.startsWith("OMX.google."))
            }?.name

        /** Starts a decoder, stepping down the routes until one runs. */
        private fun start(nextWidth: Int, nextHeight: Int, nextSps: ByteArray, nextPps: ByteArray): Boolean {
            while (true) {
                if (tryStart(nextWidth, nextHeight, nextSps, nextPps)) {
                    outputRoute = route
                    return true
                }
                if (route == ROUTE_SOFTWARE) {
                    report("error", mapOf("message" to "No decoder at ${nextWidth}x$nextHeight"))
                    return false
                }
                route++
            }
        }

        private fun tryStart(nextWidth: Int, nextHeight: Int, nextSps: ByteArray, nextPps: ByteArray): Boolean {
            stopCodec()
            val surface: Surface = target(nextWidth, nextHeight) ?: return false
            val mine = ++generation
            var starting: MediaCodec? = null
            try {
                val software = if (route == ROUTE_SOFTWARE) softwareDecoder() else null
                val decoder = if (software != null) MediaCodec.createByCodecName(software)
                    else MediaCodec.createDecoderByType("video/avc")
                starting = decoder
                // Asking a decoder without the feature fails configure
                // outright: the MediaTek one in the Echo Shows does.
                val lowLatency = Build.VERSION.SDK_INT >= 30 &&
                    decoder.codecInfo.getCapabilitiesForType("video/avc")
                        .isFeatureSupported(MediaCodecInfo.CodecCapabilities.FEATURE_LowLatency)
                val format = MediaFormat.createVideoFormat("video/avc", nextWidth, nextHeight).apply {
                    setByteBuffer("csd-0", ByteBuffer.wrap(byteArrayOf(0, 0, 0, 1) + nextSps))
                    setByteBuffer("csd-1", ByteBuffer.wrap(byteArrayOf(0, 0, 0, 1) + nextPps))
                    setInteger(MediaFormat.KEY_PRIORITY, 0)
                    if (lowLatency) setInteger(MediaFormat.KEY_LOW_LATENCY, 1)
                }
                decoder.setCallback(object : MediaCodec.Callback() {
                    override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
                        synchronized(lock) {
                            if (mine != generation) return
                            val next = pending.removeFirstOrNull()
                            if (next != null) queue(index, next) else free.addLast(index)
                        }
                    }

                    override fun onOutputBufferAvailable(codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo) {
                        synchronized(lock) {
                            if (mine != generation) return
                            try {
                                codec.releaseOutputBuffer(index, true)
                            } catch (e: IllegalStateException) {
                                return
                            }
                            if (!firstShown) {
                                firstShown = true
                                report("farShown")
                            }
                        }
                    }

                    override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) = Unit

                    override fun onError(codec: MediaCodec, e: MediaCodec.CodecException) {
                        Log.w(TAG, "decoder failed: ${e.message}")
                        synchronized(lock) {
                            if (mine != generation) return
                            stopCodec()
                            waitingKey = true
                        }
                        askKey()
                    }
                }, handler)
                decoder.configure(format, surface, null, 0)
                decoder.start()
                codec = decoder
                sps = nextSps
                pps = nextPps
                width = nextWidth
                height = nextHeight
                firstShown = false
                Log.i(TAG, "decoding ${nextWidth}x$nextHeight with ${decoder.name} on route $route")
                report("far", mapOf("width" to nextWidth, "height" to nextHeight, "decoder" to decoder.name))
                return true
            } catch (e: Exception) {
                Log.w(TAG, "decoder route $route failed at ${nextWidth}x$nextHeight: ${e.message}")
                stopCodec()
                // It never became [codec], so nothing else lets it go.
                try { starting?.release() } catch (_: Exception) { }
                return false
            }
        }

        private fun queue(index: Int, frame: Frame) {
            val decoder = codec ?: return
            try {
                val input = decoder.getInputBuffer(index) ?: return
                input.clear()
                if (frame.bytes.size > input.capacity()) {
                    free.addLast(index)
                    waitingKey = true
                    askKey()
                    return
                }
                input.put(frame.bytes)
                decoder.queueInputBuffer(index, 0, frame.bytes.size, frame.timeUs, 0)
            } catch (e: IllegalStateException) {
                Log.w(TAG, "queue: ${e.message}")
            }
        }

        private fun stopCodec() {
            generation++
            free.clear()
            pending.clear()
            val decoder = codec ?: return
            codec = null
            try { decoder.stop() } catch (_: Exception) { }
            try { decoder.release() } catch (_: Exception) { }
        }

        /** Asks the other kiosk for a key frame, at most once a second. */
        private fun askKey() {
            val now = SystemClock.elapsedRealtime()
            if (now - lastKeyAskMs < 1000) return
            lastKeyAskMs = now
            report("requestKey")
        }

        fun close() {
            // The codec's release is a binder call, which has held the main
            // thread for a minute before: it runs off it, and the texture
            // goes once the decoder has let go of its surface.
            handler.post {
                synchronized(lock) {
                    closed = true
                    stopCodec()
                }
                main.post {
                    producer.setCallback(null)
                    producer.releaseAlways()
                    glSurface?.release()
                    glEntry?.release()
                }
                thread.quitSafely()
            }
        }
    }

    private companion object {
        const val TAG = "IntercomVideo"
        const val MAX_PENDING = 12

        /**
         * Flutter's texture surface asks a decoder for more buffers than the
         * MediaTek one in the Echo Shows takes, and it fails to allocate. A
         * GL texture needs fewer. The software decoder is the last resort.
         */
        const val ROUTE_TEXTURE = 0
        const val ROUTE_GL_TEXTURE = 1
        const val ROUTE_SOFTWARE = 2

        /** What worked last, so a call does not repeat the failures. */
        @Volatile var outputRoute = ROUTE_TEXTURE
    }
}
