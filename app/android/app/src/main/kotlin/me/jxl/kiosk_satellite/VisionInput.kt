package me.jxl.kiosk_satellite

import androidx.camera.core.ImageProxy
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.max

/**
 * The float RGB input tensor of the on-device vision models
 * ([FaceDetector]): a camera frame (YUV_420_888, in
 * sensor orientation) turned upright, resized into a [size] square and
 * mapped into the model's value range ([lo]..[hi]). Nearest-neighbor
 * sampling from the YUV planes straight into the float tensor: at the
 * analyzer's 320x240 that is at most 37k pixels, no bitmap and no
 * intermediate buffer. Each detector owns one, since the models want
 * different ranges and framings.
 *
 * The whole frame is letterboxed on its longer side, with bars of
 * [bar] (the frame region overwrites everything else, so the bars are
 * written only when the geometry changes).
 */
class VisionInput(
    private val size: Int,
    private val lo: Float,
    private val hi: Float,
    private val bar: Float = 0f,
) {
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
     * upright first. Leaves [buffer] rewound.
     */
    fun fill(image: ImageProxy, rotation: Int) {
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
        scale = max(rw, rh).toFloat() / size
        ow = (rw / scale).toInt().coerceIn(1, size)
        oh = (rh / scale).toInt().coerceIn(1, size)
        ox = (size - ow) / 2
        oy = (size - oh) / 2
        sx0 = 0
        sy0 = 0

        buffer.rewind()
        val out = buffer.asFloatBuffer()
        val geometry = (ow shl 24) or (oh shl 16) or (ox shl 8) or oy
        if (geometry != barsFor) {
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
}
