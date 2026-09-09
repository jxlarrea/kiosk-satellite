package me.jxl.kiosk_satellite

/** Converts the camera texture to the same upright, unmirrored image as a snapshot. */
internal data class RtspVideoTransform(
    val rotationDegrees: Int,
    val sensorRotationDegrees: Int,
    val frontFacing: Boolean,
    val hasCameraTransform: Boolean,
) {
    fun outputDimensions(width: Int, height: Int): Pair<Int, Int> =
        if (rotationDegrees % 180 == 0) width to height else height to width

    fun textureCoordinates(): FloatArray {
        // SurfaceTexture already includes sensor rotation and front-camera mirroring.
        // Remove those before applying CameraX's rotation relative to the display.
        // Its vertical flip and producer crop remain in the SurfaceTexture matrix.
        val degrees = Math.floorMod(rotationDegrees -
            if (hasCameraTransform) sensorRotationDegrees else 0, 360)
        val corners = floatArrayOf(0f, 0f, 1f, 0f, 0f, 1f, 1f, 1f)
        return FloatArray(8).also { result ->
            for (i in 0..3) {
                val u = corners[i * 2]
                val v = corners[i * 2 + 1]
                val (x, y) = when (degrees) {
                    0 -> u to v
                    90 -> (1f - v) to u
                    180 -> (1f - u) to (1f - v)
                    270 -> v to (1f - u)
                    else -> error("Camera rotation must be a multiple of 90 degrees")
                }
                result[i * 2] = if (hasCameraTransform && frontFacing) 1f - x else x
                result[i * 2 + 1] = y
            }
        }
    }

    fun vertexScale(inputWidth: Int, inputHeight: Int, outputWidth: Int, outputHeight: Int): Pair<Float, Float> {
        val (width, height) = outputDimensions(inputWidth, inputHeight)
        val aspect = width.toFloat() / height
        val outputAspect = outputWidth.toFloat() / outputHeight
        return if (aspect > outputAspect) 1f to (outputAspect / aspect)
            else (aspect / outputAspect) to 1f
    }
}
