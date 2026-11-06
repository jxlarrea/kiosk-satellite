package me.jxl.kiosk_satellite

import io.flutter.view.TextureRegistry
import org.junit.Assert.assertEquals
import org.junit.Test
import java.lang.reflect.Proxy

class IntercomVideoReleaseTest {
    private fun producer(surfaceTexture: Boolean, calls: MutableList<String>) =
        Proxy.newProxyInstance(
            TextureRegistry.SurfaceProducer::class.java.classLoader,
            arrayOf(TextureRegistry.SurfaceProducer::class.java),
        ) { _, method, _ ->
            when (method.name) {
                "handlesCropAndRotation" -> surfaceTexture
                "getSurface" -> {
                    calls.add("surface")
                    null
                }
                "release" -> {
                    calls.add("release")
                    null
                }
                else -> null
            }
        } as TextureRegistry.SurfaceProducer

    @Test
    fun aSurfaceTextureProducerGetsASurfaceBeforeItIsReleased() {
        val calls = mutableListOf<String>()
        producer(surfaceTexture = true, calls).releaseAlways()
        assertEquals(listOf("surface", "release"), calls)
    }

    @Test
    fun anImageReaderProducerIsOnlyReleased() {
        val calls = mutableListOf<String>()
        producer(surfaceTexture = false, calls).releaseAlways()
        assertEquals(listOf("release"), calls)
    }
}
