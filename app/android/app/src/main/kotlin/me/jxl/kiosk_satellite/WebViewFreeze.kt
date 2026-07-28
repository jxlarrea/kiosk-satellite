package me.jxl.kiosk_satellite

import android.app.Activity
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Hides the dashboard WebView while the screensaver covers it, so Chromium
 * stops compositing a page nobody can see.
 *
 * The screensaver is drawn by Flutter, inside the same Android window — the
 * WebView underneath never learns it is occluded and keeps producing frames
 * at full rate. Setting the view INVISIBLE tells Chromium what a hidden tab
 * would know: rasterization and BeginFrames stop, while the page itself stays
 * in ordinary hidden-document state (timers throttled but running, events
 * delivered, the websocket still consumed). WebView.onPause() is deliberately
 * NOT used: it suspends the page's task queues wholesale, so the Home
 * Assistant socket goes unread until the server drops the connection.
 *
 * INVISIBLE, not GONE: the view keeps its layout, so re-showing never
 * triggers a page-relayout flash.
 *
 * The dashboard is found by URL prefix — the screensaver's own media WebView
 * (a bundled page) and rotation overlays must stay visible, so only views
 * whose URL matches the dashboard origin are touched.
 *
 * Activity-scoped (the traversal needs the window's decor view): registered
 * and torn down by MainActivity alongside the other Activity bridges.
 */
class WebViewFreeze(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/webview_freeze")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setHidden" -> {
                    val hidden = call.argument<Boolean>("hidden") ?: false
                    val prefix = call.argument<String>("urlPrefix") ?: ""
                    if (prefix.isEmpty()) {
                        result.success(0)
                    } else {
                        result.success(setHidden(hidden, prefix))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Returns how many WebViews were switched — 0 means the dashboard was
     *  not found (mid-rebuild, or not loaded yet) and the caller may retry. */
    private fun setHidden(hidden: Boolean, prefix: String): Int {
        val target = if (hidden) View.INVISIBLE else View.VISIBLE
        var changed = 0
        val stack = ArrayDeque<View>()
        stack.add(activity.window.decorView)
        while (stack.isNotEmpty()) {
            val view = stack.removeLast()
            if (view is WebView) {
                if (view.url?.startsWith(prefix) == true && view.visibility != target) {
                    view.visibility = target
                    changed++
                }
                continue
            }
            if (view is ViewGroup) {
                for (i in 0 until view.childCount) stack.add(view.getChildAt(i))
            }
        }
        return changed
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
