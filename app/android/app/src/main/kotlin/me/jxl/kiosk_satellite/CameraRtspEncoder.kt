package me.jxl.kiosk_satellite

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import android.os.Bundle
import android.util.Size
import android.view.Surface
import kotlin.concurrent.thread

internal fun h264SurfaceFormat(size: Size, fps: Int, bitrate: Int): MediaFormat =
    MediaFormat.createVideoFormat("video/avc", size.width, size.height).apply {
        setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
        setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
        setInteger(MediaFormat.KEY_FRAME_RATE, fps)
        setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
    }

internal fun h264SurfaceEncoders(format: MediaFormat): List<MediaCodecInfo> =
    MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.filter { info ->
        info.isEncoder && info.supportedTypes.any { it.equals("video/avc", true) } &&
            try { info.getCapabilitiesForType("video/avc").isFormatSupported(format) }
            catch (_: Exception) { false }
    }

/** One surface encoder and graphics bridge shared by every RTSP viewer. */
class CameraRtspEncoder(
    private val fps: Int,
    private val bitrate: Int,
    private val onConfig: (List<ByteArray>) -> Unit,
    private val onFrame: (List<ByteArray>, Long) -> Unit,
    private val diagnosticSession: String = "encoder",
    private val overlayContext: android.content.Context? = null,
    private val dateTime: Boolean = false,
    private val dateTimeBackground: Boolean = false,
    private val onError: (String) -> Unit,
) {
    @Volatile private var running = true
    @Volatile private var codec: MediaCodec? = null
    private var input: Surface? = null
    private var graphics: CameraRtspGlBridge? = null
    private var drain: Thread? = null
    @Volatile var isClosed = false
        private set
    var codecName = ""
        private set
    var actualSize = ""
        private set
    var captureSize: Size? = null
        private set

    /** What the encoder sends, once it has started. */
    var outputSize: Size? = null
        private set
    var software = false
        private set

    internal fun surface(inputSize: Size, transform: RtspVideoTransform): Surface {
        check(codec == null)
        val (width, height) = transform.outputDimensions(inputSize.width, inputSize.height)
        val size = Size(width, height)
        fun format() = h264SurfaceFormat(size, fps, bitrate)
        fun hardware(info: MediaCodecInfo): Boolean =
            if (Build.VERSION.SDK_INT >= 29) info.isHardwareAccelerated
            else !info.name.startsWith("OMX.google.") && !info.name.startsWith("c2.android.")
        val candidates = h264SurfaceEncoders(format()).sortedBy { if (hardware(it)) 0 else 1 }
        var lastFailure: Exception? = null
        for (chosen in candidates) {
            var attempt: MediaCodec? = null
            var attemptSurface: Surface? = null
            var attemptGraphics: CameraRtspGlBridge? = null
            try {
                val encoder = MediaCodec.createByCodecName(chosen.name).also { attempt = it }
                encoder.configure(format(), null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                val output = encoder.createInputSurface().also { attemptSurface = it }
                encoder.start()
                val bridge = CameraRtspGlBridge(output, inputSize, size, transform, fps, diagnosticSession, onError)
                    .also { attemptGraphics = it }
                val cameraInput = bridge.surface()
                bridge.updateOverlay(overlayContext, dateTime, dateTimeBackground)
                codec = encoder
                input = output
                graphics = bridge
                codecName = chosen.name
                actualSize = "${size.width}x${size.height}"
                outputSize = size
                captureSize = inputSize
                software = !hardware(chosen)
                CameraDiagnostics.record(diagnosticSession, "encoder selected",
                    "codec=$codecName, software=$software, resolution=$size, fps=$fps, bitrate=$bitrate, cameraInput=SurfaceTexture")
                drain = thread(name = "camera-rtsp-encode") { drain(encoder) }
                return cameraInput
            } catch (e: Exception) {
                lastFailure = e
                CameraDiagnostics.record(diagnosticSession, "encoder candidate failed",
                    "codec=${chosen.name}, software=${!hardware(chosen)}, resolution=$size", true, e)
                try { attemptGraphics?.close() } catch (_: Exception) { }
                try { attempt?.stop() } catch (_: Exception) { }
                try { attempt?.release() } catch (_: Exception) { }
                attemptSurface?.release()
            }
        }
        isClosed = true
        throw IllegalStateException("No H.264 encoder could start at $size and $fps fps", lastFailure)
    }

    internal fun updateOverlay(enabled: Boolean, background: Boolean) {
        graphics?.updateOverlay(overlayContext, enabled, background)
    }

    internal fun updateTransform(transform: RtspVideoTransform) {
        graphics?.updateTransform(transform)
    }

    internal fun setPreview(surface: Surface?) {
        graphics?.setPreview(surface)
    }

    internal fun snapshot(done: (ByteArray?, String?) -> Unit) {
        val bridge = graphics
        if (bridge == null) done(null, "Video is not ready for a snapshot")
        else bridge.snapshot(done)
    }

    fun keyFrame() {
        try { codec?.setParameters(Bundle().apply { putInt(MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME, 0) }) }
        catch (_: Exception) { }
    }

    private fun drain(encoder: MediaCodec) {
        val info = MediaCodec.BufferInfo()
        var firstFrame = true
        try {
            while (running) {
                val index = encoder.dequeueOutputBuffer(info, 100_000)
                if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    CameraDiagnostics.record(diagnosticSession, "encoder format", "codec=$codecName, resolution=$actualSize, fps=$fps")
                    for (key in arrayOf("csd-0", "csd-1")) {
                        val buffer = encoder.outputFormat.getByteBuffer(key) ?: continue
                        val bytes = ByteArray(buffer.remaining()); buffer.get(bytes)
                        onConfig(nals(bytes))
                    }
                } else if (index >= 0) {
                    val buffer = encoder.getOutputBuffer(index)
                    if (buffer != null && info.size > 0) {
                        buffer.position(info.offset); buffer.limit(info.offset + info.size)
                        val bytes = ByteArray(info.size); buffer.get(bytes)
                        val units = nals(bytes)
                        onConfig(units)
                        if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0) {
                            if (firstFrame) {
                                firstFrame = false
                                CameraDiagnostics.record(diagnosticSession, "first encoded frame", "codec=$codecName, resolution=$actualSize, " +
                                    "bytes=${info.size}, keyFrame=${info.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME != 0}")
                            }
                            onFrame(units, info.presentationTimeUs)
                        }
                    }
                    encoder.releaseOutputBuffer(index, false)
                }
            }
        } catch (e: Exception) {
            if (running) {
                CameraDiagnostics.record(diagnosticSession, "encoder stopped unexpectedly", "codec=$codecName, resolution=$actualSize", true, e)
                onError("H.264 encoder stopped: ${e.message}")
            }
        }
    }


    /** Call after CameraX releases the camera surface, off the main thread. */
    @Synchronized fun close() {
        if (isClosed) return
        graphics?.close()
        graphics = null
        running = false
        if (Thread.currentThread() !== drain) drain?.join(1500)
        try { codec?.stop() } catch (_: Exception) { }
        try { codec?.release() } catch (_: Exception) { }
        codec = null
        input?.release()
        input = null
        isClosed = true
    }

    companion object {
        fun nals(bytes: ByteArray): List<ByteArray> {
            val starts = mutableListOf<Pair<Int, Int>>()
            var i = 0
            while (i + 2 < bytes.size) {
                if (bytes[i] == 0.toByte() && bytes[i + 1] == 0.toByte()) {
                    val n = if (bytes[i + 2] == 1.toByte()) 3 else
                        if (i + 3 < bytes.size && bytes[i + 2] == 0.toByte() && bytes[i + 3] == 1.toByte()) 4 else 0
                    if (n > 0) { starts.add(i to n); i += n; continue }
                }
                i++
            }
            if (starts.isEmpty()) return listOf(bytes)
            return starts.mapIndexed { index, (offset, prefix) ->
                bytes.copyOfRange(offset + prefix, if (index + 1 < starts.size) starts[index + 1].first else bytes.size)
            }
        }
    }
}
