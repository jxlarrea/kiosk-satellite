package me.jxl.kiosk_satellite

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.opengl.GLES20
import android.opengl.GLUtils
import android.text.format.DateFormat
import android.util.Size
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.TimeZone
import kotlin.math.ceil
import kotlin.math.min

/** Reads the app language and the device clock preferences once per displayed second. */
internal class RtspDateTimeText(private val context: Context) {
    private var second = Long.MIN_VALUE
    private var preferences = ""
    private var dateFormat: java.text.DateFormat? = null
    private var timeFormat: java.text.DateFormat? = null
    private val date = Date()
    private var text = ""

    fun at(now: Long): String {
        val currentSecond = Math.floorDiv(now, 1000L)
        if (currentSecond == second) return text
        second = currentSecond
        val locale = NativeMessages.formatLocale(context)
        val zone = TimeZone.getDefault()
        val use24Hour = DateFormat.is24HourFormat(context)
        val datePreference = android.provider.Settings.System.getString(context.contentResolver, "date_format")
        val key = "$locale|${zone.id}|$use24Hour|$datePreference"
        if (key != preferences) {
            preferences = key
            val localized = NativeMessages.withLocale(context, locale)
            dateFormat = DateFormat.getDateFormat(localized).apply { timeZone = zone }
            timeFormat = SimpleDateFormat(
                DateFormat.getBestDateTimePattern(locale, if (use24Hour) "Hms" else "hms"), locale,
            ).apply { timeZone = zone }
        }
        date.time = now
        text = "${dateFormat!!.format(date)} ${timeFormat!!.format(date)}"
        return text
    }
}

/** A small cached text texture composited directly onto the encoder surface. GL thread only. */
internal class RtspDateTimeOverlay(context: Context, private val size: Size) {
    var background = false
    private val clock = RtspDateTimeText(context)
    private val margin = (min(size.width, size.height) * 0.02f).coerceAtLeast(2f)
    private val fontSize = (min(size.width, size.height) * 0.035f).coerceAtLeast(8f)
    private val padding = fontSize * 0.3f
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        typeface = Typeface.create("sans-serif", Typeface.BOLD)
    }
    private val vertices = ByteBuffer.allocateDirect(16 * 4).order(ByteOrder.nativeOrder()).asFloatBuffer()
    private var bitmap: Bitmap? = null
    private var canvas: Canvas? = null
    private var lastText = ""
    private var lastBackground = false
    private var program = 0
    private var texture = 0
    private var position = -1
    private var coordinates = -1

    fun draw(now: Long) {
        if (program == 0) initialize()
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
        val text = clock.at(now)
        if (text != lastText || background != lastBackground) update(text)
        GLES20.glUseProgram(program)
        vertices.position(0)
        GLES20.glVertexAttribPointer(position, 2, GLES20.GL_FLOAT, false, 16, vertices)
        GLES20.glEnableVertexAttribArray(position)
        vertices.position(2)
        GLES20.glVertexAttribPointer(coordinates, 2, GLES20.GL_FLOAT, false, 16, vertices)
        GLES20.glEnableVertexAttribArray(coordinates)
        // Android bitmaps contain premultiplied alpha.
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_ONE, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisable(GLES20.GL_BLEND)
    }

    private fun update(text: String) {
        paint.textSize = fontSize
        val inset = if (background) 0f else margin
        val available = (size.width - inset * 2 - padding * 2).coerceAtLeast(1f)
        val measured = paint.measureText(text)
        if (measured > available) paint.textSize *= available / measured
        val metrics = paint.fontMetrics
        val width = ceil(paint.measureText(text) + padding * 2).toInt().coerceAtLeast(1)
        val height = ceil(metrics.descent - metrics.ascent + padding * 2).toInt().coerceAtLeast(1)
        val resized = bitmap?.width != width || bitmap?.height != height
        if (resized) {
            bitmap?.recycle()
            bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            canvas = Canvas(bitmap!!)
        }
        bitmap!!.eraseColor(if (background) Color.BLACK else Color.TRANSPARENT)
        canvas!!.drawText(text, padding, padding - metrics.ascent, paint)
        if (resized) GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
        else GLUtils.texSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, bitmap)
        val left = -1f + 2f * inset / size.width
        val right = left + 2f * width / size.width
        val top = 1f - 2f * inset / size.height
        val bottom = top - 2f * height / size.height
        vertices.position(0)
        vertices.put(floatArrayOf(left, bottom, 0f, 1f, right, bottom, 1f, 1f,
            left, top, 0f, 0f, right, top, 1f, 0f))
        vertices.position(0)
        lastText = text
        lastBackground = background
    }

    private fun initialize() {
        val vertex = shader(GLES20.GL_VERTEX_SHADER, """
            attribute vec4 position;
            attribute vec2 coordinates;
            varying vec2 uv;
            void main() { gl_Position = position; uv = coordinates; }
        """)
        val fragment = try { shader(GLES20.GL_FRAGMENT_SHADER, """
            precision mediump float;
            uniform sampler2D overlay;
            varying vec2 uv;
            void main() { gl_FragColor = texture2D(overlay, uv); }
        """) } catch (e: Exception) { GLES20.glDeleteShader(vertex); throw e }
        try {
            program = GLES20.glCreateProgram()
            GLES20.glAttachShader(program, vertex)
            GLES20.glAttachShader(program, fragment)
            GLES20.glLinkProgram(program)
            val linked = IntArray(1)
            GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linked, 0)
            check(linked[0] != 0) { "Timestamp shader link: ${GLES20.glGetProgramInfoLog(program)}" }
        } finally {
            GLES20.glDeleteShader(vertex)
            GLES20.glDeleteShader(fragment)
        }
        position = GLES20.glGetAttribLocation(program, "position")
        coordinates = GLES20.glGetAttribLocation(program, "coordinates")
        GLES20.glUseProgram(program)
        GLES20.glUniform1i(GLES20.glGetUniformLocation(program, "overlay"), 0)
        val names = IntArray(1)
        GLES20.glGenTextures(1, names, 0)
        texture = names[0]
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
    }

    fun close() {
        bitmap?.recycle()
        bitmap = null
        canvas = null
        if (texture != 0) GLES20.glDeleteTextures(1, intArrayOf(texture), 0)
        if (program != 0) GLES20.glDeleteProgram(program)
        texture = 0
        program = 0
    }

    private fun shader(type: Int, source: String): Int {
        val id = GLES20.glCreateShader(type)
        GLES20.glShaderSource(id, source)
        GLES20.glCompileShader(id)
        val compiled = IntArray(1)
        GLES20.glGetShaderiv(id, GLES20.GL_COMPILE_STATUS, compiled, 0)
        if (compiled[0] == 0) {
            val message = GLES20.glGetShaderInfoLog(id)
            GLES20.glDeleteShader(id)
            error("Timestamp shader compile: $message")
        }
        return id
    }
}
