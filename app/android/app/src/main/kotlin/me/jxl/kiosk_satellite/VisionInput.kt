package me.jxl.kiosk_satellite

import androidx.camera.core.ImageProxy
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.max
import kotlin.math.min

/**
 * The float RGB input tensor of the on-device vision models
 * ([FaceDetector], [PalmDetector]): a camera frame (YUV_420_888, in
 * sensor orientation) turned upright, resized into a [size] square and
 * mapped into the model's value range ([lo]..[hi]). Nearest-neighbor
 * sampling from the YUV planes straight into the float tensor: at the
 * analyzer's 320x240 that is at most 37k pixels, no bitmap and no
 * intermediate buffer. Each detector owns one, since the models want
 * different ranges and framings.
 *
 * Two framings per call. Without a crop, the whole frame is letterboxed
 * on its longer side, with bars of [bar] (the frame region overwrites
 * everything else, so the bars are written only when the geometry
 * changes). With one, a square of the upright frame fills the tensor:
 * the caller names its center and side, and a subject that spans a
 * tenth of the frame spans a fifth of the tensor. Either way the
 * mapping from tensor coordinates back to upright-frame coordinates
 * ([originU], [spanU], [originV], [spanV]) is left for the caller, so
 * boxes from any framing compare.
 */
class VisionInput(
    private val size: Int,
    private val lo: Float,
    private val hi: Float,
    private val bar: Float = 0f,
) {
    /** The last fill's mapping from tensor-normalized coordinates t
     *  (0..1 across the tensor) to upright-frame-normalized ones:
     *  u = originU + t * spanU across the frame's width, v likewise
     *  down its height. [aspect] is the upright frame's height over its
     *  width, for turning a horizontal span into a vertical one. */
    var originU = 0f
        private set
    var spanU = 1f
        private set
    var originV = 0f
        private set
    var spanV = 1f
        private set
    var aspect = 0.75f
        private set

    /** The upright frame's size in pixels, from the last fill. */
    var frameW = 0
        private set
    var frameH = 0
        private set
    val buffer: ByteBuffer =
        ByteBuffer.allocateDirect(size * size * 3 * 4).order(ByteOrder.nativeOrder())

    /** The letterbox geometry the bars were last written for (packed
     *  ow/oh/ox/oy). */
    private var barsFor = -1

    private val gain = (hi - lo) / 255f

    /**
     * Fill the tensor from [image]. [rotation] is the frame's
     * rotationDegrees: the models are not rotation invariant, and an
     * analysis frame arrives in sensor orientation, so it is turned
     * upright first. [cropU], [cropV] and [cropSide] select a square of
     * the upright frame to fill the tensor with instead of the whole
     * frame: its center as fractions of the frame's width and height,
     * its side as a fraction of the frame's height (clamped to fit, and
     * shifted to stay inside the frame). Leaves [buffer] rewound.
     */
    fun fill(
        image: ImageProxy,
        rotation: Int,
        cropU: Float = 0.5f,
        cropV: Float = 0.5f,
        cropSide: Float = 0f,
    ) {
        val yPlane = image.planes[0]
        val uPlane = image.planes[1]
        val vPlane = image.planes[2]
        val yBuf = yPlane.buffer
        val uBuf = uPlane.buffer
        val vBuf = vPlane.buffer
        val w = image.width
        val h = image.height
        val turned = rotation == 90 || rotation == 270
        val rw = if (turned) h else w
        val rh = if (turned) w else h
        aspect = rh.toFloat() / rw
        frameW = rw
        frameH = rh
        val fit = cropSide <= 0f

        // (ow, oh) at (ox, oy) is the tensor region the frame lands in;
        // (sx0, sy0) is where the sampled region starts in the upright
        // frame, and scale is upright-frame pixels per tensor pixel.
        val scale: Float
        val ow: Int
        val oh: Int
        val ox: Int
        val oy: Int
        val sx0: Int
        val sy0: Int
        if (fit) {
            scale = max(rw, rh).toFloat() / size
            ow = (rw / scale).toInt().coerceIn(1, size)
            oh = (rh / scale).toInt().coerceIn(1, size)
            ox = (size - ow) / 2
            oy = (size - oh) / 2
            sx0 = 0
            sy0 = 0
            spanU = size.toFloat() / ow
            originU = -ox.toFloat() / ow
            spanV = size.toFloat() / oh
            originV = -oy.toFloat() / oh
        } else {
            val side = (cropSide * rh).toInt().coerceIn(1, min(rw, rh))
            scale = side.toFloat() / size
            ow = size
            oh = size
            ox = 0
            oy = 0
            sx0 = (cropU * rw - side / 2f).toInt().coerceIn(0, rw - side)
            sy0 = (cropV * rh - side / 2f).toInt().coerceIn(0, rh - side)
            spanU = side.toFloat() / rw
            originU = sx0.toFloat() / rw
            spanV = side.toFloat() / rh
            originV = sy0.toFloat() / rh
        }

        buffer.rewind()
        val out = buffer.asFloatBuffer()
        val geometry = (ow shl 24) or (oh shl 16) or (ox shl 8) or oy
        if (fit && geometry != barsFor) {
            for (i in 0 until size * size * 3) out.put(i, bar)
            barsFor = geometry
        }

        val yLimit = yBuf.limit()
        val uLimit = uBuf.limit()
        val vLimit = vBuf.limit()
        for (iy in 0 until oh) {
            val sy = (sy0 + ((iy + 0.5f) * scale).toInt()).coerceIn(0, rh - 1)
            for (ix in 0 until ow) {
                val sx = (sx0 + ((ix + 0.5f) * scale).toInt()).coerceIn(0, rw - 1)
                // (sx, sy) is a pixel of the upright frame; map it back to
                // the sensor frame the buffers hold.
                val px: Int
                val py: Int
                when (rotation) {
                    90 -> { px = sy; py = h - 1 - sx }
                    180 -> { px = w - 1 - sx; py = h - 1 - sy }
                    270 -> { px = w - 1 - sy; py = sx }
                    else -> { px = sx; py = sy }
                }
                val yIdx = py * yPlane.rowStride + px * yPlane.pixelStride
                val uIdx = (py / 2) * uPlane.rowStride + (px / 2) * uPlane.pixelStride
                val vIdx = (py / 2) * vPlane.rowStride + (px / 2) * vPlane.pixelStride
                if (yIdx >= yLimit || uIdx >= uLimit || vIdx >= vLimit) continue
                val yv = (yBuf.get(yIdx).toInt() and 0xFF) - 16
                val uv = (uBuf.get(uIdx).toInt() and 0xFF) - 128
                val vv = (vBuf.get(vIdx).toInt() and 0xFF) - 128
                val yl = 1.164f * yv
                val r = (yl + 1.596f * vv).coerceIn(0f, 255f)
                val g = (yl - 0.813f * vv - 0.391f * uv).coerceIn(0f, 255f)
                val b = (yl + 2.018f * uv).coerceIn(0f, 255f)
                val o = ((oy + iy) * size + (ox + ix)) * 3
                out.put(o, r * gain + lo)
                out.put(o + 1, g * gain + lo)
                out.put(o + 2, b * gain + lo)
            }
        }
        buffer.rewind()
    }

    /**
     * Fill the tensor from a rotated square of the upright frame: center
     * ([cx], [cy]) and [side] in upright-frame pixels, turned by [angle]
     * radians so that a subject leaning that way stands up in the tensor
     * (the hand landmark model wants the fingers pointing up). Pixels
     * outside the frame are black. Leaves [buffer] rewound.
     */
    fun fillRotated(
        image: ImageProxy,
        rotation: Int,
        cx: Float,
        cy: Float,
        side: Float,
        angle: Float,
    ) {
        val yPlane = image.planes[0]
        val uPlane = image.planes[1]
        val vPlane = image.planes[2]
        val yBuf = yPlane.buffer
        val uBuf = uPlane.buffer
        val vBuf = vPlane.buffer
        val w = image.width
        val h = image.height
        val turned = rotation == 90 || rotation == 270
        val rw = if (turned) h else w
        val rh = if (turned) w else h
        aspect = rh.toFloat() / rw
        frameW = rw
        frameH = rh
        val c = kotlin.math.cos(angle)
        val s = kotlin.math.sin(angle)
        val yLimit = yBuf.limit()
        val uLimit = uBuf.limit()
        val vLimit = vBuf.limit()
        buffer.rewind()
        val out = buffer.asFloatBuffer()
        for (iy in 0 until size) {
            val ty = (iy + 0.5f) / size - 0.5f
            for (ix in 0 until size) {
                val tx = (ix + 0.5f) / size - 0.5f
                val fx = cx + (tx * c + ty * s) * side
                val fy = cy + (-tx * s + ty * c) * side
                val o = (iy * size + ix) * 3
                if (fx < 0f || fy < 0f || fx >= rw || fy >= rh) {
                    out.put(o, lo)
                    out.put(o + 1, lo)
                    out.put(o + 2, lo)
                    continue
                }
                val sx = fx.toInt()
                val sy = fy.toInt()
                val px: Int
                val py: Int
                when (rotation) {
                    90 -> { px = sy; py = h - 1 - sx }
                    180 -> { px = w - 1 - sx; py = h - 1 - sy }
                    270 -> { px = w - 1 - sy; py = sx }
                    else -> { px = sx; py = sy }
                }
                val yIdx = py * yPlane.rowStride + px * yPlane.pixelStride
                val uIdx = (py / 2) * uPlane.rowStride + (px / 2) * uPlane.pixelStride
                val vIdx = (py / 2) * vPlane.rowStride + (px / 2) * vPlane.pixelStride
                if (yIdx >= yLimit || uIdx >= uLimit || vIdx >= vLimit) {
                    out.put(o, lo)
                    out.put(o + 1, lo)
                    out.put(o + 2, lo)
                    continue
                }
                val yv = (yBuf.get(yIdx).toInt() and 0xFF) - 16
                val uv = (uBuf.get(uIdx).toInt() and 0xFF) - 128
                val vv = (vBuf.get(vIdx).toInt() and 0xFF) - 128
                val yl = 1.164f * yv
                val r = (yl + 1.596f * vv).coerceIn(0f, 255f)
                val g = (yl - 0.813f * vv - 0.391f * uv).coerceIn(0f, 255f)
                val b = (yl + 2.018f * uv).coerceIn(0f, 255f)
                out.put(o, r * gain + lo)
                out.put(o + 1, g * gain + lo)
                out.put(o + 2, b * gain + lo)
            }
        }
        buffer.rewind()
    }
}
