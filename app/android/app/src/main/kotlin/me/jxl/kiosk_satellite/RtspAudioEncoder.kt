package me.jxl.kiosk_satellite

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.os.Debug
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

/** Encodes a copy of the shared microphone. Never waits on the capture thread. */
class RtspAudioEncoder(
    private val output: (ByteArray, Long) -> Unit,
) {
    private data class Chunk(val pcm: ByteArray, val timeUs: Long)
    private val queue = ArrayBlockingQueue<Chunk>(4)
    @Volatile private var running = true
    @Volatile var codecName: String? = null
        private set
    @Volatile var error: String? = null
        private set
    @Volatile var frames = 0L
        private set
    @Volatile var dropped = 0L
        private set
    @Volatile var workerCpuNs = 0L
        private set

    fun offer(pcm: ByteArray, timeUs: Long) {
        if (running && !queue.offer(Chunk(pcm.copyOf(), timeUs))) dropped++
    }

    init {
        thread(name = "rtsp-aac", isDaemon = true) {
            var codec: MediaCodec? = null
            val cpuStart = Debug.threadCpuTimeNanos()
            try {
                val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
                codec = encoder
                val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, 16000, 1)
                format.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                format.setInteger(MediaFormat.KEY_BIT_RATE, 32000)
                format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 4096)
                encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                encoder.start()
                codecName = encoder.name
                val info = MediaCodec.BufferInfo()
                var pending: Chunk? = null
                var offset = 0
                while (running) {
                    if (pending == null) {
                        pending = queue.poll(80, TimeUnit.MILLISECONDS)
                        offset = 0
                    }
                    val chunk = pending
                    if (chunk != null) {
                        val index = encoder.dequeueInputBuffer(0)
                        if (index >= 0) {
                            val buffer = encoder.getInputBuffer(index)!!
                            buffer.clear()
                            val size = minOf(buffer.remaining(), chunk.pcm.size - offset) and -2
                            check(size > 0) { "AAC encoder has no input capacity" }
                            buffer.put(chunk.pcm, offset, size)
                            encoder.queueInputBuffer(index, 0, size, chunk.timeUs + offset * 1_000_000L / 32000, 0)
                            offset += size
                            if (offset == chunk.pcm.size) pending = null
                        }
                    }
                    // Wait for output after feeding input instead of polling the codec
                    // between microphone chunks. Capture continues on its own thread.
                    var index = encoder.dequeueOutputBuffer(info, 10000)
                    while (index >= 0) {
                        if (info.size > 0 && info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0) {
                            val buffer = encoder.getOutputBuffer(index)!!
                            buffer.position(info.offset)
                            buffer.limit(info.offset + info.size)
                            val bytes = ByteArray(info.size)
                            buffer.get(bytes)
                            output(bytes, info.presentationTimeUs)
                            frames++
                        }
                        encoder.releaseOutputBuffer(index, false)
                        index = encoder.dequeueOutputBuffer(info, 0)
                    }
                    workerCpuNs = Debug.threadCpuTimeNanos() - cpuStart
                }
            } catch (e: Exception) {
                error = e.message ?: "AAC encoding failed"
            } finally {
                running = false
                queue.clear()
                try { codec?.stop() } catch (_: Exception) { }
                try { codec?.release() } catch (_: Exception) { }
                workerCpuNs = Debug.threadCpuTimeNanos() - cpuStart
            }
        }
    }

    fun close() {
        running = false
        queue.clear()
    }
}
