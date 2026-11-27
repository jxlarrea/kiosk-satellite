package me.jxl.kiosk_satellite

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.camera.core.ImageProxy
import java.io.ByteArrayOutputStream

/**
 * The Camera rotation setting (issue #1616): extra clockwise degrees on top
 * of the rotation CameraX reports. Some vendor HALs report a fixed
 * orientation for every USB webcam (an external camera config hard coded to
 * 270), so the frames arrive sideways and nothing on the device can correct
 * them. Every reader of a frame's rotation goes through [of], so the face
 * and hand models, Ground Control, the camera preview, plugins, snapshots
 * and the video stream all turn together.
 *
 * Set from the arguments of each camera session and snapshot request. There
 * is one camera and one setting, so a single value serves every reader.
 */
internal object CameraRotation {
    @Volatile var extraDegrees = 0
        private set

    /** Takes the "rotation" argument Dart sends with a session or snapshot. */
    fun apply(argument: Any?) {
        extraDegrees = normalize((argument as? Number)?.toInt() ?: 0)
    }

    /** The clockwise turn that makes [image] upright. */
    fun of(image: ImageProxy): Int = turned(image.imageInfo.rotationDegrees)

    /** [reported] degrees from CameraX with the setting added. */
    fun turned(reported: Int): Int = normalize(reported + extraDegrees)

    /**
     * A captured JPEG turned upright by its reported [rotation] plus the
     * setting, or [jpeg] untouched when the setting is off. The JPEG keeps
     * its own orientation in EXIF, which decoding ignores, so the pixels
     * are turned by the whole amount and saved without EXIF.
     */
    fun jpeg(jpeg: ByteArray, rotation: Int, quality: Int): ByteArray {
        if (extraDegrees == 0) return jpeg
        val degrees = turned(rotation)
        val bitmap = BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size) ?: return jpeg
        var rotated: Bitmap? = null
        return try {
            rotated = if (degrees == 0) bitmap else Bitmap.createBitmap(
                bitmap, 0, 0, bitmap.width, bitmap.height,
                Matrix().apply { postRotate(degrees.toFloat()) }, true,
            )
            val out = ByteArrayOutputStream(jpeg.size)
            if (rotated.compress(Bitmap.CompressFormat.JPEG, quality, out)) out.toByteArray() else jpeg
        } finally {
            if (rotated !== bitmap) rotated?.recycle()
            bitmap.recycle()
        }
    }

    private fun normalize(degrees: Int): Int = Math.floorMod(degrees / 90 * 90, 360)
}
