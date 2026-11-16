package com.pichillilorenzo.flutter_inappwebview_android

import android.app.Activity
import android.app.Application
import android.content.MutableContextWrapper
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.lang.reflect.Proxy
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * The dashboard WebView outlives its Activity. These cover the wrapper that
 * keeps Chromium's pickers on the Activity attached now: without it a color
 * or time input after an Activity swap crashed with BadTokenException.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, application = Application::class, sdk = [29, 33])
class WebViewContextsTest {
    private fun activity(): Activity = Robolectric.buildActivity(Activity::class.java).setup().get()

    private fun binding(activity: Activity): ActivityPluginBinding =
        Proxy.newProxyInstance(
            ActivityPluginBinding::class.java.classLoader,
            arrayOf(ActivityPluginBinding::class.java),
        ) { _, method, _ -> if (method.name == "getActivity") activity else null } as ActivityPluginBinding

    @Test
    fun activityIsWrapped() {
        val first = activity()
        val context = WebViewContexts.wrap(first)
        assertTrue(context is MutableContextWrapper)
        assertSame(first, (context as MutableContextWrapper).baseContext)
    }

    @Test
    fun otherContextsAreLeftAlone() {
        val app = RuntimeEnvironment.getApplication()
        assertSame(app, WebViewContexts.wrap(app))
        val flutters = MutableContextWrapper(activity())
        assertSame(flutters, WebViewContexts.wrap(flutters))
    }

    @Test
    fun attachMovesWrappersToTheNewActivity() {
        val first = activity()
        val second = activity()
        val context = WebViewContexts.wrap(first) as MutableContextWrapper
        InAppWebViewFlutterPlugin().onAttachedToActivity(binding(second))
        assertSame(second, context.baseContext)
    }

    @Test
    fun reattachMovesWrappersToo() {
        val first = activity()
        val second = activity()
        val context = WebViewContexts.wrap(first) as MutableContextWrapper
        InAppWebViewFlutterPlugin().onReattachedToActivityForConfigChanges(binding(second))
        assertSame(second, context.baseContext)
    }
}
