package me.jxl.kiosk_satellite

import android.app.Activity
import android.app.Application
import android.os.Looper
import android.view.View
import io.flutter.embedding.engine.FlutterJNI
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.systemchannels.PlatformChannel
import io.flutter.plugin.common.JSONMethodCodec
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.platform.PlatformPlugin
import org.json.JSONArray
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.nio.ByteBuffer

/**
 * Issue #1358: with only one bar hidden, Flutter's manual mode hides it
 * without IMMERSIVE_STICKY, and up to Android 11 that lets Android cover the
 * app with a touch-eating nav_input_consumer. The plugin must add the sticky
 * flag back to every Flutter write that hides a bar, and leave a write that
 * hides nothing alone. The messages go through Flutter's real platform
 * channel, the same way Dart's SystemChrome calls arrive.
 */
@Suppress("DEPRECATION")
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [27, 29, 30, 33], manifest = Config.NONE, application = Application::class)
class SystemBarsPlatformPluginTest {
    private val sticky = View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
    private val hideNav = View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
    private val fullScreen = View.SYSTEM_UI_FLAG_FULLSCREEN

    /** A FlutterJNI that never reaches the native engine. */
    private class FakeJni : FlutterJNI() {
        override fun cleanupMessageData(messageData: Long) {}
        override fun invokePlatformMessageResponseCallback(
            responseId: Int,
            message: ByteBuffer,
            position: Int,
        ) {}
        override fun invokePlatformMessageEmptyResponseCallback(responseId: Int) {}
    }

    private lateinit var activity: Activity
    private lateinit var jni: FakeJni
    private lateinit var plugin: SystemBarsPlatformPlugin
    private var replyId = 1

    @Before
    fun setUp() {
        activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        jni = FakeJni()
        val executor = DartExecutor(jni, activity.assets)
        executor.onAttachedToJNI()
        plugin = SystemBarsPlatformPlugin(
            activity,
            PlatformChannel(executor),
            object : PlatformPlugin.PlatformPluginDelegate {
                override fun popSystemNavigator() = false
            },
        )
    }

    @After
    fun tearDown() {
        plugin.destroy()
    }

    /** Sends a SystemChrome call the way the Dart side does. */
    private fun fromDart(method: String, args: Any?) {
        val message = JSONMethodCodec.INSTANCE.encodeMethodCall(MethodCall(method, args))
        message.rewind()
        val copy = ByteBuffer.allocateDirect(message.remaining()).put(message)
        copy.rewind()
        jni.handlePlatformMessage("flutter/platform", copy, replyId++, 0)
        shadowOf(Looper.getMainLooper()).idle()
    }

    /** What applySystemBars in main.dart sends when only some bars hide. */
    private fun manual(vararg overlays: String) =
        fromDart("SystemChrome.setEnabledSystemUIOverlays", JSONArray(overlays.toList()))

    private val flags get() = activity.window.decorView.systemUiVisibility

    private val barFlags get() = flags and (hideNav or fullScreen or sticky)

    @Test
    fun navigationOnlyKeepsSticky() {
        manual("SystemUiOverlay.top")
        assertEquals(hideNav or sticky, barFlags)
    }

    @Test
    fun statusOnlyKeepsSticky() {
        manual("SystemUiOverlay.bottom")
        assertEquals(fullScreen or sticky, barFlags)
    }

    @Test
    fun stickyComesBackAfterEveryFlutterWrite() {
        manual("SystemUiOverlay.top")
        // A resume re-applies Flutter's stored overlays, which drops sticky.
        activity.window.decorView.systemUiVisibility = flags and sticky.inv()
        plugin.updateSystemUiOverlays()
        assertEquals(hideNav or sticky, barFlags)
        // So does restoreSystemUIOverlays from Dart.
        activity.window.decorView.systemUiVisibility = flags and sticky.inv()
        fromDart("SystemChrome.restoreSystemUIOverlays", null)
        assertEquals(hideNav or sticky, barFlags)
    }

    @Test
    fun bothShownAddsNothing() {
        manual("SystemUiOverlay.top", "SystemUiOverlay.bottom")
        assertEquals(0, barFlags)
    }

    @Test
    fun showingTheBarsAgainDropsSticky() {
        manual("SystemUiOverlay.top")
        manual("SystemUiOverlay.top", "SystemUiOverlay.bottom")
        assertEquals(0, barFlags)
    }

    @Test
    fun bothHiddenStaysImmersiveSticky() {
        fromDart("SystemChrome.setEnabledSystemUIMode", "SystemUiMode.immersiveSticky")
        assertEquals(hideNav or fullScreen or sticky, barFlags)
    }
}
