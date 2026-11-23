package me.jxl.kiosk_satellite

import android.app.Activity
import android.view.View
import android.view.ViewGroup
import android.webkit.ServiceWorkerController
import android.webkit.WebSettings
import android.webkit.WebView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.Collections
import java.util.WeakHashMap

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
                "setCacheMode" -> {
                    val noCache = call.argument<Boolean>("noCache") ?: false
                    val prefix = call.argument<String>("urlPrefix") ?: ""
                    if (prefix.isEmpty()) {
                        result.success(0)
                    } else {
                        result.success(setCacheMode(noCache, prefix))
                    }
                }
                "clearMemoryCache" -> {
                    val prefix = call.argument<String>("urlPrefix") ?: ""
                    if (prefix.isEmpty()) {
                        result.success(0)
                    } else {
                        // false keeps the disk cache: only the renderer's
                        // in-memory copies go.
                        result.success(forEachWebView(prefix) { view -> view.clearCache(false) })
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        /**
         * Whether [url] belongs to [prefix]. An origin prefix ends with the
         * URL's authority, so `https://ha.example.net` does not take in
         * `https://ha.example.net:8095`. That is Music Assistant on Home
         * Assistant's host: the overlay showing it was hidden along with
         * the dashboard frozen under it, leaving a black page. A bare
         * scheme prefix (`http`) still matches every page.
         */
        fun matchesPrefix(url: String?, prefix: String): Boolean {
            if (url == null || !url.startsWith(prefix)) return false
            if (!prefix.contains("://")) return true
            return url.length == prefix.length || url[prefix.length] in "/?#"
        }

        /**
         * The views [setHidden] hid and has not revealed since. A reveal
         * takes them in whatever page they show now: the page can move to
         * another origin while hidden (Compass leaving the Menu for a
         * dashboard view while a Custom Page on another server was up),
         * and a reveal matched by the new origin missed the view, which
         * stayed hidden with nothing over it (issue #1567). Kept for the
         * process, since the same WebView outlives a re-created Activity.
         */
        private val hiddenHere: MutableSet<WebView> =
            Collections.newSetFromMap(WeakHashMap())
    }

    /** Runs [action] on every WebView under the decor whose URL matches
     *  [prefix], or that [also] takes; returns how many matched. */
    private fun forEachWebView(
        prefix: String,
        also: (WebView) -> Boolean = { false },
        action: (WebView) -> Unit,
    ): Int {
        var matched = 0
        val stack = ArrayDeque<View>()
        stack.add(activity.window.decorView)
        while (stack.isNotEmpty()) {
            val view = stack.removeLast()
            if (view is WebView) {
                if (matchesPrefix(view.url, prefix) || also(view)) {
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

    /** Returns how many WebViews matched — 0 means the dashboard was not
     *  found (mid-rebuild, or not loaded yet) and the caller may retry. A
     *  view already in the asked-for state counts: the Dart side keeps its
     *  own idea of the state, and reporting only changes let a view that
     *  had fallen out of step with it read as "not found" forever, never
     *  to be revealed again. */
    private fun setHidden(hidden: Boolean, prefix: String): Int {
        val target = if (hidden) View.INVISIBLE else View.VISIBLE
        val changed = forEachWebView(prefix, also = { !hidden && it in hiddenHere }) { view ->
            if (hidden) hiddenHere.add(view) else hiddenHere.remove(view)
            if (view.visibility != target) {
                if (target == View.VISIBLE) {
                    revealWithoutScrollbarFlash(view)
                } else {
                    view.visibility = target
                }
            }
        }
        // Hiding a focused WebView makes Android reassign its focus, and
        // the FlutterView is what it picks — which, with a dpad attached,
        // is the system's green focus frame around the whole app (issue
        // #377). Posted so the reassignment has happened first.
        if (hidden && changed > 0) {
            activity.window.decorView.post {
                (activity as? MainActivity)?.parkFocusIfIdle()
            }
        }
        // Revealing the dashboard is the screensaver's dismissal, which
        // brings no focus change to re-hide the bars the way a wake does.
        // On some Android 12 ROMs the gesture bar stayed up over the
        // dashboard until the drawer was opened (issue #728).
        if (!hidden && changed > 0) SystemBars.reassertOnFocus(activity)
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
    /** Skip the HTTP cache or use it again on the matching views. A custom
     *  page under Home Assistant's /local/ is served to be cached for a
     *  month, so an edited page would otherwise stay stale on the kiosk.
     *  Set straight on WebSettings: the plugin's setSettings re-applies
     *  every field of the settings object it is handed, defaults included. */
    private fun setCacheMode(noCache: Boolean, prefix: String): Int {
        val mode = if (noCache) WebSettings.LOAD_NO_CACHE else WebSettings.LOAD_DEFAULT
        // Home Assistant's service worker refreshes the /local/ files it
        // keeps through the HTTP cache as well, which is shared by every
        // service worker of the app rather than set per view.
        try {
            ServiceWorkerController.getInstance().serviceWorkerWebSettings.cacheMode = mode
        } catch (_: Throwable) {
        }
        return forEachWebView(prefix) { view -> view.settings.cacheMode = mode }
    }

    /** Saved View.overScrollMode per view while a drag suppresses it. */
    private val savedOverscroll = HashMap<WebView, Int>()

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
                // The Android 12+ overscroll stretch distorts the whole
                // rendered surface, fixed-position elements included, when
                // a drag counts as edge overscroll — CSS overscroll-behavior
                // does not reach this WebView effect, so it is parked at the
                // View level for the drag's duration.
                if (!savedOverscroll.containsKey(view)) {
                    savedOverscroll[view] = view.overScrollMode
                }
                view.overScrollMode = View.OVER_SCROLL_NEVER
            } else {
                val (vertical, horizontal) = savedBars.remove(view)
                    ?: (true to true)
                view.isVerticalScrollBarEnabled = vertical
                view.isHorizontalScrollBarEnabled = horizontal
                view.overScrollMode = savedOverscroll.remove(view)
                    ?: View.OVER_SCROLL_ALWAYS
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
            val (vertical, horizontal) = savedBars.remove(view) ?: (true to true)
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
