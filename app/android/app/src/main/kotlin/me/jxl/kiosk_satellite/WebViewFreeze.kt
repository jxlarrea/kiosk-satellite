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
                "setScrollBars" -> {
                    val hidden = call.argument<Boolean>("hidden") ?: false
                    val prefix = call.argument<String>("urlPrefix") ?: ""
                    if (prefix.isEmpty()) {
                        result.success(0)
                    } else {
                        result.success(setScrollBars(hidden, prefix))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Runs [action] on every WebView under the decor whose URL matches
     *  [prefix]; returns how many matched. */
    private fun forEachWebView(prefix: String, action: (WebView) -> Unit): Int {
        var matched = 0
        val stack = ArrayDeque<View>()
        stack.add(activity.window.decorView)
        while (stack.isNotEmpty()) {
            val view = stack.removeLast()
            if (view is WebView) {
                if (view.url?.startsWith(prefix) == true) {
                    action(view)
                    matched++
                }
                continue
            }
            if (view is ViewGroup) {
                for (i in 0 until view.childCount) stack.add(view.getChildAt(i))
            }
        }
        return matched
    }

    /** Returns how many WebViews were switched — 0 means the dashboard was
     *  not found (mid-rebuild, or not loaded yet) and the caller may retry. */
    private fun setHidden(hidden: Boolean, prefix: String): Int {
        val target = if (hidden) View.INVISIBLE else View.VISIBLE
        var changed = 0
        forEachWebView(prefix) { view ->
            if (view.visibility != target) {
                if (target == View.VISIBLE) {
                    revealWithoutScrollbarFlash(view)
                } else {
                    view.visibility = target
                }
                changed++
            }
        }
        return changed
    }

    /**
     * Suppress (or restore) the native scrollbars, used by the dashboard
     * carousel around a drag: the swipe's slight vertical drift and the
     * parked preview's widened content extent both awaken the bars over an
     * animation that is not a scroll. Suppressing saves the current state
     * and restoring puts exactly that back, sharing the bookkeeping with
     * [revealWithoutScrollbarFlash] so a drag inside a reveal's suppression
     * window cannot resurrect bars early or restore a suppressed state.
     */
    private fun setScrollBars(hidden: Boolean, prefix: String): Int {
        return forEachWebView(prefix) { view ->
            if (hidden) {
                pendingRestore.remove(view)?.let { view.removeCallbacks(it) }
                    ?: run {
                        if (!savedBars.containsKey(view)) {
                            savedBars[view] = view.isVerticalScrollBarEnabled to
                                view.isHorizontalScrollBarEnabled
                        }
                    }
                view.isVerticalScrollBarEnabled = false
                view.isHorizontalScrollBarEnabled = false
            } else {
                val (vertical, horizontal) = savedBars.remove(view)
                    ?: (true to false)
                view.isVerticalScrollBarEnabled = vertical
                view.isHorizontalScrollBarEnabled = horizontal
            }
        }
    }

    /** Scrollbar state saved across a reveal, and the restore that puts it
     *  back, per view. One pending restore at a time: a re-reveal inside the
     *  suppression window must not re-read the (suppressed) state as the
     *  thing to restore, or the bars would come back disabled for good. */
    private val savedBars = HashMap<WebView, Pair<Boolean, Boolean>>()
    private val pendingRestore = HashMap<WebView, Runnable>()

    /**
     * Make the view visible without the scrollbar blink.
     *
     * Android "awakens" a scrollable view's scrollbars when it reappears, so
     * every screensaver dismissal flashed a gray bar down the dashboard's
     * edge for a second. Disabling the bars across the reveal suppresses the
     * awaken; they are handed back shortly after, so a finger scroll shows
     * them exactly as it always did.
     */
    private fun revealWithoutScrollbarFlash(view: WebView) {
        pendingRestore.remove(view)?.let { view.removeCallbacks(it) }
            ?: run { savedBars[view] = view.isVerticalScrollBarEnabled to
                view.isHorizontalScrollBarEnabled }
        view.isVerticalScrollBarEnabled = false
        view.isHorizontalScrollBarEnabled = false
        view.visibility = View.VISIBLE
        val restore = Runnable {
            pendingRestore.remove(view)
            // Fallback matches the app's settings: the horizontal bar is
            // disabled at WebView creation and must stay that way.
            val (vertical, horizontal) = savedBars.remove(view) ?: (true to false)
            view.isVerticalScrollBarEnabled = vertical
            view.isHorizontalScrollBarEnabled = horizontal
        }
        pendingRestore[view] = restore
        view.postDelayed(restore, 1500)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
