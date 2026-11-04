package me.jxl.kiosk_satellite.plugins

import android.content.Context
import android.content.res.AssetManager
import android.content.res.Configuration
import android.graphics.Path
import android.graphics.Typeface
import android.os.Build
import android.util.Log
import android.view.ContextThemeWrapper
import android.view.View
import android.widget.FrameLayout
import androidx.core.graphics.PathParser
import io.flutter.FlutterInjector
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import me.jxl.kiosk.plugins.KsTheme
import me.jxl.kiosk.plugins.OverlayFactory

/**
 * Hosts plugin overlay views as Flutter platform views. Dart shows them as
 * texture-composited AndroidViews inside the kiosk's own stack, so the
 * menu, the screensaver and the lockdown shield cover them the way they
 * cover the dashboard, and they leave with the Activity. With
 * render.hybrid_plugin_overlays on, overlays use hybrid composition
 * instead (issue #1294). The views built here are the same either way. Native plugin
 * screensavers show through here too, with kind "screensaver". Everything
 * here runs on the main thread.
 */
internal class PluginOverlayViews(
    assets: AssetManager,
    /**
     * The live factory for a view request, or null once the overlay is gone. screensaver asks for a native
     * screensaver renderer instead of an overlay.
     */
    private val lookup: (id: String, session: String, key: String, generation: Int, screensaver: Boolean) -> OverlayFactory?,
    /** A plugin threw from its view code. KS disables it. */
    private val failed: (id: String, session: String, error: Throwable) -> Unit,
    /** A wrapped overlay measured a new size, in physical pixels. */
    private val measured: (Map<String, Any>) -> Unit,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    companion object {
        const val VIEW_TYPE = "kiosk_satellite/plugin_overlay"
        private const val TAG = "PluginOverlayViews"
    }

    private inner class Hosted(
        val id: String,
        val session: String,
        val factory: OverlayFactory,
        val frame: OverlayFrame,
        /** The context the plugin's view was built with, at the kiosk's UI scale. */
        val context: Context,
        var themeArgs: Map<*, *>?,
    ) : PlatformView {
        var content: View? = null
        override fun getView(): View = frame
        override fun dispose() {
            live.remove(this)
            val built = content ?: return
            content = null
            frame.removeAllViews()
            guard(this) { factory.onDestroy(built) }
        }
    }

    private val fonts = Fonts(assets)
    private val icons = MdiPaths { letter ->
        val asset = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/mdi/$letter.json")
        assets.open(asset).bufferedReader().use { it.readText() }
    }
    private val live = mutableListOf<Hosted>()

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *> ?: emptyMap<Any, Any>()
        val id = params["id"] as? String ?: ""
        val session = params["session"] as? String ?: ""
        val key = params["key"] as? String ?: ""
        val generation = (params["generation"] as? Number)?.toInt() ?: -1
        val themeArgs = params["theme"] as? Map<*, *>
        val wrapWidth = (params["width"] as? Number)?.toInt() == PluginOverlays.WRAP
        val wrapHeight = (params["height"] as? Number)?.toInt() == PluginOverlays.WRAP
        val insets = (params["insets"] as? List<*>)?.map { (it as? Number)?.toInt() ?: 0 }?.takeIf { it.size == 4 } ?: listOf(0, 0, 0, 0)
        val scale = (params["scale"] as? Number)?.toFloat()?.takeIf { it > 0f } ?: 1f
        val frame = OverlayFrame(context, wrapWidth, wrapHeight, insets, scale) { width, height ->
            measured(mapOf("id" to id, "session" to session, "key" to key, "generation" to generation, "width" to width, "height" to height))
        }
        val factory = lookup(id, session, key, generation, params["kind"] == "screensaver")
            // Hidden or replaced between Dart building it and this request.
            ?: return object : PlatformView {
                override fun getView(): View = frame
                override fun dispose() {}
            }
        val dark = themeArgs?.get("dark") as? Boolean ?: true
        val themed = ContextThemeWrapper(context,
            if (dark) android.R.style.Theme_DeviceDefault_NoActionBar else android.R.style.Theme_DeviceDefault_Light_NoActionBar)
        // The kiosk's UI scale goes into the density, so dp and sp lengths
        // in the plugin's views, layouts and KsTheme all grow with it.
        if (scale != 1f) {
            themed.applyOverrideConfiguration(Configuration().apply {
                densityDpi = Math.round(context.resources.configuration.densityDpi * scale)
            })
        }
        val hosted = Hosted(id, session, factory, frame, themed, themeArgs)
        live.add(hosted)
        val theme = theme(themed, themeArgs)
        guard(hosted) {
            val view = factory.create(themed, theme) ?: throw IllegalStateException("Overlay factory returned no view")
            hosted.content = view
            frame.addView(view)
        }
        return hosted
    }

    /** Dart's theme changed: restyle every live overlay. */
    fun setTheme(args: Map<*, *>) {
        for (hosted in live.toList()) {
            if (hosted.themeArgs == args) continue
            hosted.themeArgs = args
            val view = hosted.content ?: continue
            val theme = theme(hosted.context, args)
            guard(hosted) { hosted.factory.onThemeChanged(view, theme) }
        }
    }

    private fun guard(hosted: Hosted, action: () -> Unit) {
        try { action() } catch (error: Throwable) {
            Log.w(TAG, "Plugin ${hosted.id} overlay failed", error)
            failed(hosted.id, hosted.session, error)
        }
    }

    private fun theme(context: Context, args: Map<*, *>?): KsTheme {
        val colors = (args?.get("colors") as? Map<*, *>)?.entries
            ?.mapNotNull { (role, value) -> (role as? String)?.let { name -> (value as? Number)?.let { name to it.toInt() } } }
            ?.toMap() ?: emptyMap()
        return KsTheme(args?.get("dark") as? Boolean ?: true, context.resources.displayMetrics.density, colors, fonts, icons)
    }

    /** Rubik, the KS typeface, at real weights from its variable wght axis. */
    private class Fonts(private val assets: AssetManager) : KsTheme.Fonts {
        private val path by lazy {
            try { FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/fonts/Rubik.ttf") } catch (_: Throwable) { null }
        }
        private val cache = HashMap<Int, Typeface?>()

        @Synchronized override fun typeface(weight: Int): Typeface? {
            val rounded = (weight + 50) / 100 * 100
            return cache.getOrPut(rounded) {
                val asset = path ?: return@getOrPut null
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        Typeface.Builder(assets, asset).setFontVariationSettings("'wght' $rounded").build()
                    } else {
                        val base = Typeface.createFromAsset(assets, asset)
                        if (rounded >= 600) Typeface.create(base, Typeface.BOLD) else base
                    }
                } catch (_: Throwable) { null }
            }
        }
    }

    /**
     * Sizes the plugin's view. Flutter gives the frame an exact size. A side
     * the plugin asked to wrap is measured against the space the kiosk has,
     * and the result goes back to Dart, which resizes the platform view.
     */
    private class OverlayFrame(
        context: Context,
        private val wrapWidth: Boolean,
        private val wrapHeight: Boolean,
        /** Left, top, right and bottom, in dp. */
        private val insetsDp: List<Int>,
        /** The kiosk's UI scale, which Dart also applies to the insets. */
        private val scale: Float,
        private val onMeasured: (Int, Int) -> Unit,
    ) : FrameLayout(context) {
        private var reported: Pair<Int, Int>? = null

        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            val child = getChildAt(0)
            val width = MeasureSpec.getSize(widthMeasureSpec)
            val height = MeasureSpec.getSize(heightMeasureSpec)
            if (child == null) { setMeasuredDimension(width, height); return }
            val metrics = resources.displayMetrics
            val across = Math.round((insetsDp[0] + insetsDp[2]) * metrics.density * scale)
            val down = Math.round((insetsDp[1] + insetsDp[3]) * metrics.density * scale)
            fun spec(wrap: Boolean, exact: Int, available: Int) =
                if (wrap) MeasureSpec.makeMeasureSpec(maxOf(0, available), MeasureSpec.AT_MOST)
                else MeasureSpec.makeMeasureSpec(exact, MeasureSpec.EXACTLY)
            child.measure(spec(wrapWidth, width, metrics.widthPixels - across), spec(wrapHeight, height, metrics.heightPixels - down))
            setMeasuredDimension(width, height)
            if (!wrapWidth && !wrapHeight) return
            val size = (if (wrapWidth) child.measuredWidth else width) to (if (wrapHeight) child.measuredHeight else height)
            if (size != reported) {
                reported = size
                onMeasured(size.first, size.second)
            }
        }

        override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
            val child = getChildAt(0) ?: return
            child.layout(0, 0, child.measuredWidth, child.measuredHeight)
        }
    }
}

/**
 * KS's own Material Design Icons for KsTheme.icon: the path data the app
 * draws its icons from, one shard per first letter under assets/mdi.
 * A name is found by scanning the shard's text rather than parsing the
 * whole JSON, which keeps a lookup on the main thread to a millisecond.
 * Resolved outlines are kept, shards only while a few letters are in use.
 */
internal class MdiPaths(
    /** The text of one shard, a-z or _, or null when it cannot be read. */
    private val read: (String) -> String?,
) : KsTheme.Icons {
    private val resolved = object : LinkedHashMap<String, Path?>(64, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Path?>) = size > 256
    }
    private val shards = object : LinkedHashMap<String, String>(4, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, String>) = size > 3
    }

    @Synchronized override fun path(name: String): Path? {
        val key = name.trim().lowercase().removePrefix("mdi:")
        if (!key.matches(Regex("[a-z0-9][a-z0-9-]{0,79}"))) return null
        if (resolved.containsKey(key)) return resolved[key]
        val data = lookup(key)?.let { if (it.startsWith("@")) lookup(it.substring(1)) else it }
        // The parser turns bad data into an empty path rather than failing.
        val path = data?.let { try { PathParser.createPathFromPathData(it) } catch (_: Throwable) { null } }?.takeUnless { it.isEmpty }
        resolved[key] = path
        return path
    }

    private fun lookup(key: String): String? {
        val letter = if (key[0] in 'a'..'z') key[0].toString() else "_"
        val text = shards[letter] ?: (try { read(letter) } catch (_: Throwable) { null })?.also { shards[letter] = it } ?: return null
        val marker = "\"$key\":\""
        val start = text.indexOf(marker).takeIf { it >= 0 }?.plus(marker.length) ?: return null
        val end = text.indexOf('"', start).takeIf { it > start } ?: return null
        return text.substring(start, end)
    }
}
