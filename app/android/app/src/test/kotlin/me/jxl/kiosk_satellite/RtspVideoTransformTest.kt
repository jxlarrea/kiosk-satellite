package me.jxl.kiosk_satellite

import org.junit.Assert.*
import org.junit.Test

class RtspVideoTransformTest {
    @Test fun producerRotationAndMirroringAreRemovedForEveryCameraAndDisplayRotation() {
        // Expected buffer samples for an upright output, including GL's vertical flip.
        val expected = mapOf(
            0 to floatArrayOf(0f, 1f, 1f, 1f, 0f, 0f, 1f, 0f),
            90 to floatArrayOf(1f, 1f, 1f, 0f, 0f, 1f, 0f, 0f),
            180 to floatArrayOf(1f, 0f, 0f, 0f, 1f, 1f, 0f, 1f),
            270 to floatArrayOf(0f, 0f, 0f, 1f, 1f, 0f, 1f, 1f),
        )
        for (sensor in listOf(0, 90, 180, 270)) {
            for (front in listOf(false, true)) {
                for (rotation in listOf(0, 90, 180, 270)) {
                    val uv = RtspVideoTransform(rotation, sensor, front, true).textureCoordinates()
                    val sampled = FloatArray(8)
                    for (i in 0..3) {
                        var x = if (front) 1f - uv[i * 2] else uv[i * 2]
                        var y = uv[i * 2 + 1]
                        repeat(sensor / 90) { val oldX = x; x = 1f - y; y = oldX }
                        sampled[i * 2] = x
                        sampled[i * 2 + 1] = 1f - y
                    }
                    assertArrayEquals("sensor=$sensor front=$front rotation=$rotation",
                        expected.getValue(rotation), sampled, 0.0001f)
                }
            }
        }
    }

    @Test fun aProcessedSurfaceIsNotUnrotatedOrUnmirroredAgain() {
        assertArrayEquals(floatArrayOf(1f, 0f, 1f, 1f, 0f, 0f, 0f, 1f),
            RtspVideoTransform(90, 270, true, false).textureCoordinates(), 0f)
    }

    @Test fun portraitEncodingSwapsDimensionsAndUsesTheWholeFrame() {
        for (rotation in listOf(0, 90, 180, 270)) {
            val transform = RtspVideoTransform(rotation, 90, true, true)
            val expected = if (rotation == 90 || rotation == 270) 480 to 640 else 640 to 480
            assertEquals(expected, transform.outputDimensions(640, 480))
            assertEquals(1f to 1f, transform.vertexScale(640, 480, expected.first, expected.second))
        }
    }

    @Test fun rotatingDuringStreamingFitsTheImageWithoutStretchingOrCropping() {
        val portrait = RtspVideoTransform(90, 90, false, true)
        assertEquals(0.5625f to 1f, portrait.vertexScale(640, 480, 640, 480))
        val landscape = portrait.copy(rotationDegrees = 0)
        assertEquals(1f to 0.5625f, landscape.vertexScale(640, 480, 480, 640))
    }
}
