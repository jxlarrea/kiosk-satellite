package me.jxl.kiosk_satellite

import android.graphics.SurfaceTexture
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLExt
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.os.Handler
import android.os.HandlerThread
import android.util.Size
import android.view.Surface
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** Camera-facing texture and a GPU pass into the encoder, owned by one GL thread. */
internal class CameraRtspGlBridge(
    private val encoderSurface: Surface,
    private val inputSize: Size,
    private val size: Size,
    private val initialTransform: RtspVideoTransform,
    fps: Int,
    private val diagnosticSession: String,
    private val onError: (String) -> Unit,
) {
    private val thread = HandlerThread("camera-rtsp-gl").apply { start() }
    private val handler = Handler(thread.looper)
    private val closing = AtomicBoolean(false)
    private val stopped = CountDownLatch(1)
    private val pacer = RtspFramePacer(fps)
    private var display = EGL14.EGL_NO_DISPLAY
    private var context = EGL14.EGL_NO_CONTEXT
    private var window = EGL14.EGL_NO_SURFACE
    private var texture: SurfaceTexture? = null
    private var cameraSurface: Surface? = null
    private var textureId = 0
    private var program = 0
    private var position = -1
    private var coordinates = -1
    private var transform = -1
    private val matrix = FloatArray(16)
    private val vertices = ByteBuffer.allocateDirect(16 * 4).order(ByteOrder.nativeOrder())
        .asFloatBuffer().apply {
            put(floatArrayOf(-1f, -1f, 0f, 0f, 1f, -1f, 1f, 0f,
                -1f, 1f, 0f, 1f, 1f, 1f, 1f, 1f))
            position(0)
        }
    private var first = true
    private var lastPresentationNs = 0L
    private var failed = false

    /** Initialization never binds an EGL context to Flutter's main thread. */
    fun surface(): Surface {
        val ready = CountDownLatch(1)
        var failure: Throwable? = null
        check(handler.post {
            try {
                if (!closing.get()) initialize()
            } catch (e: Throwable) {
                failure = e
            } finally {
                ready.countDown()
            }
        }) { "The RTSP graphics worker is stopped" }
        try {
            check(ready.await(5, TimeUnit.SECONDS)) { "RTSP graphics initialization timed out" }
            failure?.let { throw IllegalStateException("RTSP graphics initialization failed", it) }
            return checkNotNull(cameraSurface) { "RTSP graphics initialization was cancelled" }
        } catch (e: Exception) {
            close()
            throw e
        }
    }

    private fun initialize() {
        applyTransform(initialTransform)
        display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        check(display != EGL14.EGL_NO_DISPLAY) { "No EGL display" }
        val version = IntArray(2)
        check(EGL14.eglInitialize(display, version, 0, version, 1)) { "EGL initialization failed" }
        val configs = arrayOfNulls<EGLConfig>(1)
        val count = IntArray(1)
        val attributes = intArrayOf(
            EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8, EGL14.EGL_BLUE_SIZE, 8,
            EGL14.EGL_ALPHA_SIZE, 8, EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
            EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT,
            0x3142, 1, // EGL_RECORDABLE_ANDROID
            EGL14.EGL_NONE,
        )
        check(EGL14.eglChooseConfig(display, attributes, 0, configs, 0, 1, count, 0) && count[0] > 0) {
            "No recordable EGL configuration"
        }
        context = EGL14.eglCreateContext(display, configs[0], EGL14.EGL_NO_CONTEXT,
            intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE), 0)
        check(context != EGL14.EGL_NO_CONTEXT) { "EGL context creation failed" }
        window = EGL14.eglCreateWindowSurface(display, configs[0], encoderSurface,
            intArrayOf(EGL14.EGL_NONE), 0)
        check(window != EGL14.EGL_NO_SURFACE) { "EGL encoder surface creation failed" }
        check(EGL14.eglMakeCurrent(display, window, window, context)) { "EGL makeCurrent failed" }
        val vertex = shader(GLES20.GL_VERTEX_SHADER, VERTEX)
        val fragment = try { shader(GLES20.GL_FRAGMENT_SHADER, FRAGMENT) }
            catch (e: Exception) { GLES20.glDeleteShader(vertex); throw e }
        try {
            program = GLES20.glCreateProgram()
            GLES20.glAttachShader(program, vertex)
            GLES20.glAttachShader(program, fragment)
            GLES20.glLinkProgram(program)
            val linked = IntArray(1)
            GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linked, 0)
            check(linked[0] != 0) { "RTSP shader link: ${GLES20.glGetProgramInfoLog(program)}" }
        } finally {
            GLES20.glDeleteShader(vertex)
            GLES20.glDeleteShader(fragment)
        }
        position = GLES20.glGetAttribLocation(program, "position")
        coordinates = GLES20.glGetAttribLocation(program, "coordinates")
        transform = GLES20.glGetUniformLocation(program, "transform")
        val names = IntArray(1)
        GLES20.glGenTextures(1, names, 0)
        textureId = names[0]
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        texture = SurfaceTexture(textureId).also {
            it.setDefaultBufferSize(inputSize.width, inputSize.height)
            it.setOnFrameAvailableListener({ source -> render(source) }, handler)
            cameraSurface = Surface(it)
        }
        CameraDiagnostics.record(diagnosticSession, "graphics ready",
            "cameraInput=SurfaceTexture, encoderInput=EGL, input=$inputSize, output=$size")
    }

    fun updateTransform(value: RtspVideoTransform) {
        if (!closing.get()) handler.post { if (!closing.get()) applyTransform(value) }
    }

    private fun applyTransform(value: RtspVideoTransform) {
        val uv = value.textureCoordinates()
        val (scaleX, scaleY) = value.vertexScale(inputSize.width, inputSize.height, size.width, size.height)
        vertices.position(0)
        for (i in 0..3) {
            vertices.put(if (i % 2 == 0) -scaleX else scaleX)
            vertices.put(if (i < 2) -scaleY else scaleY)
            vertices.put(uv[i * 2])
            vertices.put(uv[i * 2 + 1])
        }
        vertices.position(0)
        CameraDiagnostics.record(diagnosticSession, "video transform",
            "rotation=${value.rotationDegrees}, sensorRotation=${value.sensorRotationDegrees}, " +
                "front=${value.frontFacing}, cameraTransform=${value.hasCameraTransform}, " +
                "input=$inputSize, output=$size, scale=$scaleX,$scaleY")
    }

    private fun render(source: SurfaceTexture) {
        if (closing.get() || failed) return
        try {
            source.updateTexImage()
            val timestamp = source.timestamp.takeIf { it > 0 } ?: System.nanoTime()
            if (!pacer.accept(timestamp)) return
            source.getTransformMatrix(matrix)
            GLES20.glViewport(0, 0, size.width, size.height)
            GLES20.glClearColor(0f, 0f, 0f, 1f)
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
            GLES20.glUseProgram(program)
            GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
            GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
            vertices.position(0)
            GLES20.glVertexAttribPointer(position, 2, GLES20.GL_FLOAT, false, 16, vertices)
            GLES20.glEnableVertexAttribArray(position)
            vertices.position(2)
            GLES20.glVertexAttribPointer(coordinates, 2, GLES20.GL_FLOAT, false, 16, vertices)
            GLES20.glEnableVertexAttribArray(coordinates)
            GLES20.glUniformMatrix4fv(transform, 1, false, matrix, 0)
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
            val glError = GLES20.glGetError()
            check(glError == GLES20.GL_NO_ERROR) { "RTSP graphics error 0x${glError.toString(16)}" }
            lastPresentationNs = maxOf(timestamp, lastPresentationNs + 1)
            check(EGLExt.eglPresentationTimeANDROID(display, window, lastPresentationNs)) {
                "RTSP presentation timestamp failed"
            }
            check(EGL14.eglSwapBuffers(display, window)) { "RTSP graphics swap failed: ${EGL14.eglGetError()}" }
            if (first) {
                first = false
                CameraDiagnostics.record(diagnosticSession, "first graphics frame", "size=$size")
            }
        } catch (e: Exception) {
            failed = true
            CameraDiagnostics.record(diagnosticSession, "graphics failure", "size=$size", true, e)
            onError("Camera video rendering failed: ${e.message}")
        }
    }

    /** Called after CameraX gives up the camera-facing surface. */
    fun close() {
        if (closing.compareAndSet(false, true)) handler.post {
            try { release() } finally {
                stopped.countDown()
                thread.quitSafely()
            }
        }
        if (Thread.currentThread() !== thread && !stopped.await(3, TimeUnit.SECONDS)) {
            CameraDiagnostics.record(diagnosticSession, "graphics close timeout", "size=$size", true)
        }
    }

    private fun release() {
        texture?.setOnFrameAvailableListener(null)
        cameraSurface?.release()
        cameraSurface = null
        texture?.release()
        texture = null
        if (context != EGL14.EGL_NO_CONTEXT) {
            if (program != 0) GLES20.glDeleteProgram(program)
            if (textureId != 0) GLES20.glDeleteTextures(1, intArrayOf(textureId), 0)
        }
        if (display != EGL14.EGL_NO_DISPLAY) {
            EGL14.eglMakeCurrent(display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
            if (window != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(display, window)
            if (context != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(display, context)
            EGL14.eglTerminate(display)
        }
        EGL14.eglReleaseThread()
    }

    private fun shader(type: Int, source: String): Int {
        val id = GLES20.glCreateShader(type)
        GLES20.glShaderSource(id, source)
        GLES20.glCompileShader(id)
        val compiled = IntArray(1)
        GLES20.glGetShaderiv(id, GLES20.GL_COMPILE_STATUS, compiled, 0)
        if (compiled[0] == 0) {
            val reason = GLES20.glGetShaderInfoLog(id)
            GLES20.glDeleteShader(id)
            error("RTSP shader compile: $reason")
        }
        return id
    }

    private companion object {
        const val VERTEX = """
            attribute vec4 position;
            attribute vec2 coordinates;
            uniform mat4 transform;
            varying vec2 uv;
            void main() {
                gl_Position = position;
                uv = (transform * vec4(coordinates, 0.0, 1.0)).xy;
            }
        """
        const val FRAGMENT = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            uniform samplerExternalOES camera;
            varying vec2 uv;
            void main() { gl_FragColor = texture2D(camera, uv); }
        """
    }
}
