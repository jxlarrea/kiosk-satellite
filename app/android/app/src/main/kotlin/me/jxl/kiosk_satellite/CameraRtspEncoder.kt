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

/** One hardware surface encoder shared by every RTSP viewer. */
class CameraRtspEncoder(
    private val fps: Int,
    private val bitrate: Int,
    private val onConfig: (List<ByteArray>) -> Unit,
    private val onFrame: (List<ByteArray>, Long) -> Unit,
    private val onError: (String) -> Unit,
) {
    @Volatile private var running = true
    @Volatile private var codec: MediaCodec? = null
    private var input: Surface? = null
    private var drain: Thread? = null
    @Volatile var isClosed = false
        private set
    var codecName = ""
        private set
    var actualSize = ""
        private set

    fun surface(size: Size): Surface {
        check(codec == null)
        val format = MediaFormat.createVideoFormat("video/avc", size.width, size.height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            // The sensor can run faster when its supported range is variable.
            setFloat(MediaFormat.KEY_MAX_FPS_TO_ENCODER, fps.toFloat())
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }
        val candidates = MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.filter {
            it.isEncoder && it.supportedTypes.any { type -> type.equals("video/avc", true) } &&
                (if (Build.VERSION.SDK_INT >= 29) it.isHardwareAccelerated else
                    !it.name.startsWith("OMX.google.") && !it.name.startsWith("c2.android."))
        }
        val chosen = candidates.firstOrNull {
            try { it.getCapabilitiesForType("video/avc").isFormatSupported(format) }
            catch (_: Exception) { false }
        } ?: error("No hardware H.264 encoder supports $size at $fps fps")
        val encoder = MediaCodec.createByCodecName(chosen.name)
        codec = encoder
        try {
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            val surface = encoder.createInputSurface()
            input = surface
            codec = encoder
            codecName = chosen.name
            actualSize = "${size.width}x${size.height}"
            encoder.start()
            drain = thread(name = "camera-rtsp-encode") { drain(encoder) }
            return surface
        } catch (e: Exception) {
            onError("Hardware H.264 encoder could not start: ${e.message}")
            close()

            throw e
        }
    }

    fun keyFrame() {
        try { codec?.setParameters(Bundle().apply { putInt(MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME, 0) }) }
        catch (_: Exception) { }
    }

    private fun drain(encoder: MediaCodec) {
        val info = MediaCodec.BufferInfo()
        try {
            while (running) {
                val index = encoder.dequeueOutputBuffer(info, 100_000)
                if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
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
                            onFrame(units, info.presentationTimeUs)
                        }
                    }
                    encoder.releaseOutputBuffer(index, false)
                }
            }
        } catch (e: Exception) { if (running) onError("Hardware H.264 encoder stopped: ${e.message}") }
    }


    /** Call after CameraX releases the input surface, off the main thread. */
    fun close() {
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
