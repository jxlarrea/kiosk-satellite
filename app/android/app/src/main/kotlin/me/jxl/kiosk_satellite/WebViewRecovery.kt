package me.jxl.kiosk_satellite

import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.webkit.RenderProcessGoneDetail
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Terminates a stuck renderer and releases its view after Flutter detaches it. */
class WebViewRecovery(private val engine: FlutterEngine) {
    private val handler = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(
        engine.dartExecutor.binaryMessenger, "kiosk_satellite/webview_recovery",
    )

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "prepare") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val id = call.argument<Int>("viewId")
            val root = id?.let { engine.platformViewsController.getPlatformViewById(it) }
            val view = root?.let { findWebView(it) }
            if (view != null) prepare(view)
            result.success(null)
        }
    }

    private fun findWebView(view: View): WebView? {
        if (view is WebView) return view
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                findWebView(view.getChildAt(i))?.let { return it }
            }
        }
        return null
    }

    private fun prepare(view: WebView) {
        // The plugin disposes by loading about:blank and waiting for
        // onPageFinished. A dead renderer cannot finish that load. Let
        // Flutter dispose its channels first then destroy the detached view.
        view.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {}

            override fun onViewDetachedFromWindow(v: View) {
                view.removeOnAttachStateChangeListener(this)
                handler.post {
                    // The plugin replaces its client during disposal. Keep
                    // a late renderer death handled until destroy completes.
                    view.webViewClient = object : WebViewClient() {
                        override fun onRenderProcessGone(
                            view: WebView, detail: RenderProcessGoneDetail,
                        ): Boolean = true
                    }
                    (view.parent as? ViewGroup)?.removeView(view)
                    view.destroy()
                    Log.i("KSWebViewRecovery", "Destroyed detached failed WebView")
                }
            }
        })
        // A new WebView can share the old renderer. Terminate it before
        // creating the replacement even when Android sent no hang callback.
        if (WebViewFeature.isFeatureSupported(WebViewFeature.GET_WEB_VIEW_RENDERER) &&
            WebViewFeature.isFeatureSupported(WebViewFeature.WEB_VIEW_RENDERER_TERMINATE)) {
            val terminated = WebViewCompat.getWebViewRenderProcess(view)?.terminate() == true
            Log.w("KSWebViewRecovery", "Renderer termination requested: $terminated")
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
