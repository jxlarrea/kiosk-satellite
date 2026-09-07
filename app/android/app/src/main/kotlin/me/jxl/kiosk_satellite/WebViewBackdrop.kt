package me.jxl.kiosk_satellite

import android.app.Activity
import android.graphics.Color
import android.graphics.Rect
import android.graphics.drawable.ColorDrawable
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.webkit.WebView
import io.flutter.embedding.android.FlutterImageView
import io.flutter.embedding.android.FlutterView

/** Avoid sampling Flutter's background while the dashboard covers it. */
class WebViewBackdrop(activity: Activity) : ViewTreeObserver.OnPreDrawListener {
    private val root = activity.window.decorView
    private val viewport = Rect()
    private val pageBounds = Rect()
    private var hidden: FlutterImageView? = null
    private var backedPage: WebView? = null

    init {
        root.viewTreeObserver.addOnPreDrawListener(this)
    }

    override fun onPreDraw(): Boolean {
        val flutter = findFlutterView(root)
        val image = flutter?.currentImageSurface
        // The first WebView is the dashboard. A second full-screen WebView
        // may be a transparent overlay and must not suppress its background.
        val page = flutter?.let { firstWebView(it) }
        val covers = image != null && page != null && page.isShown &&
            page.isHardwareAccelerated && unblended(page, flutter) &&
            flutter.getGlobalVisibleRect(viewport) &&
            page.getGlobalVisibleRect(pageBounds) && pageBounds.contains(viewport)
        if (covers && backedPage !== page) {
            // KioskScreen's scaffold is black. Give transparent documents
            // that same background directly so every pixel stays covered.
            val background = page!!.background
            if (!page.isOpaque && (background == null ||
                background is ColorDrawable && Color.alpha(background.color) == 0)) {
                page.setBackgroundColor(Color.BLACK)
                // WebView's opacity hint can stay false after the color
                // changes. A native drawable guarantees the same fill.
                page.background = ColorDrawable(Color.BLACK)
            }
            backedPage = page
        }
        val color = (page?.background as? ColorDrawable)?.color ?: Color.TRANSPARENT
        val opaque = page?.isOpaque == true || Color.alpha(color) == 255
        val next = if (covers && opaque) image else null
        if (page == null) backedPage = null
        if (hidden !== next) {
            hidden?.alpha = 1f
            hidden = next
        }
        // Flutter can replace or reattach its image surface after a route
        // transition. Reassert only when necessary to avoid redraw loops.
        if (next != null && next.alpha != 0f) next.alpha = 0f
        return true
    }

    private fun unblended(view: View, flutter: FlutterView): Boolean {
        var current: View? = view
        while (current != null && current !== flutter) {
            // Flutter uses a hardware layer for platform-view opacity.
            // Leave it alone during fades and any other cached composition.
            if (current.alpha != 1f || current.layerType != View.LAYER_TYPE_NONE) return false
            current = current.parent as? View
        }
        return current === flutter
    }

    private fun findFlutterView(view: View): FlutterView? {
        if (view is FlutterView) return view
        if (view is ViewGroup) for (i in 0 until view.childCount) {
            findFlutterView(view.getChildAt(i))?.let { return it }
        }
        return null
    }

    private fun firstWebView(view: View): WebView? {
        if (view is WebView) return view
        if (view is ViewGroup) for (i in 0 until view.childCount) {
            firstWebView(view.getChildAt(i))?.let { return it }
        }
        return null
    }

    fun dispose() {
        if (root.viewTreeObserver.isAlive) {
            root.viewTreeObserver.removeOnPreDrawListener(this)
        }
        hidden?.alpha = 1f
        hidden = null
        backedPage = null
    }
}
