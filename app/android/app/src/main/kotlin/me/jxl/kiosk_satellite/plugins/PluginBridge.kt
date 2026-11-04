package me.jxl.kiosk_satellite.plugins

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.KeyEvent
import dalvik.system.DexClassLoader
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.Collections
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import me.jxl.kiosk.plugins.KioskPlugin
import me.jxl.kiosk.plugins.OverlayFactory
import me.jxl.kiosk.plugins.OverlaySpec
import me.jxl.kiosk.plugins.PluginHost
import me.jxl.kiosk_satellite.Headless
import org.json.JSONObject

/** Process-owned runtime for explicitly installed, trusted SDK 1 plugins. */
class PluginBridge(private val context: Context, messenger: BinaryMessenger) {
    companion object {
        /** Incomplete startups in a row that switch the enabled plugins off. */
        internal const val STARTUP_STRIKES = 2

        /** How often running setup runs are checked for a quiet plugin. */
        internal const val SETUP_CHECK_MS = 5_000L

        /** The largest voice skin picture a plugin may name, in bytes. */
        internal const val MAX_THUMBNAIL_BYTES = 256 * 1024L

        /**
         * Restart app and Exit end the process on purpose, so a startup still
         * inside its 30 seconds did not fail.
         */
        fun noteDeliberateExit(context: Context) {
            context.getSharedPreferences("kiosk_plugins", Context.MODE_PRIVATE)
                .edit().putBoolean("startupPending", false).commit()
        }

        /**
         * Counts the incomplete startups in a row, including the previous
         * launch. A startup that finished counts nothing, and neither does
         * one cut short by an app update, which kills the process wherever
         * it is.
         */
        internal fun startupStrikes(pending: Boolean, startedUpdatedAt: Long, updatedAt: Long, strikes: Int): Int =
            if (!pending || startedUpdatedAt != updatedAt) 0 else strikes + 1

        @Volatile private var current: PluginBridge? = null

        /** Forwarded from MainActivity.dispatchKeyEvent before KS handles the key. */
        fun onKey(event: KeyEvent) { current?.hardwareKey(event) }

        /**
         * The plugin whose class appears in the crash's stack, walking
         * causes too. A class counts only when the plugin's own loader
         * defined it, so KS and SDK classes on the way never take the blame.
         */
        internal fun culprit(error: Throwable, loaders: List<Pair<String, ClassLoader>>): String? {
            if (loaders.isEmpty()) return null
            val seen = HashSet<Throwable>()
            var cause: Throwable? = error
            while (cause != null && seen.add(cause)) {
                for (frame in cause.stackTrace) for ((id, loader) in loaders) {
                    val owner = try { Class.forName(frame.className, false, loader).classLoader } catch (_: Throwable) { null }
                    if (owner === loader) return id
                }
                cause = cause.cause
            }
            return null
        }
    }

    private val channel = MethodChannel(messenger, "kiosk_satellite/plugins")
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor { task -> Thread(task, "plugin-manager").apply { isDaemon = true } }
    private val prefs = context.getSharedPreferences("kiosk_plugins", Context.MODE_PRIVATE)
    private val headless = Headless.active(context)
    private val appVersion = try { context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "" } catch (_: Exception) { "" }
    private val root = File(context.filesDir, "plugins-v1").apply { mkdirs() }
    // Each installed package as it arrived, by its hash, so a fleet leader
    // can hand its followers the exact bytes it runs.
    private val packages = File(context.filesDir, "plugin-packages").apply { mkdirs() }
    // What KS keeps for each plugin by its ID, such as the choices it last
    // listed. It survives updates and goes with the plugin.
    private val pluginData = File(context.filesDir, "plugin-data")
    private var records = JSONObject(prefs.getString("installed", "{}") ?: "{}")
    @Volatile private var pluginsEnabled = prefs.getBoolean("pluginsEnabled", records.length() > 0)
    private var startupGeneration = 0
    // Read from the main thread too, where Flutter asks for overlay views.
    private val sessions = ConcurrentHashMap<String, Session>()
    private val loadedIds = mutableSetOf<String>()
    private val loadedHashes = mutableSetOf<String>()
    private val restartRequired = mutableSetOf<String>()
    private var initialized = false
    private val shizukuDevice = ShizukuDeviceBridge(context, messenger) { shizuku }
    private val shizuku: PluginShizuku by lazy {
        PluginShizuku(context) { state ->
            emit("shizukuState", state)
            shizukuDevice.changed(state)
            worker.execute {
                sessions.values.toList().filter { it.alive.get() && "shizuku" in it.manifest.capabilities }.forEach { session ->
                    try { session.call { session.plugin?.onEvent("shizuku.state", state) } }
                    catch (error: Throwable) { fail(session.id, error); emit("changed", snapshot()) }
                }
            }
        }
    }


    private inner class Session(val id: String, val manifest: PluginManifest, val packageDir: File) {
        val nativeDir = File(root, ".runtime-${UUID.randomUUID()}")
        val entities = PluginEntities()
        private val entityPending = AtomicBoolean(false)
        private val entityUpdate = Runnable {
            entityPending.set(false)
            if (alive.get()) emit("entities", mapOf("id" to id, "session" to token, "entities" to entities.snapshot()), alive)
        }
        fun notifyEntities() {
            if (entityPending.compareAndSet(false, true)) main.postDelayed(entityUpdate, 250)
        }
        fun closeEntities() { entities.close(); main.removeCallbacks(entityUpdate) }
        val screensavers = PluginScreensavers<OverlayFactory>(packageDir)
        fun screensaverSnapshot(): List<Map<String, Any>> = screensavers.snapshot().map { item ->
            if (item.containsKey("entry")) item + mapOf(
                "assetDirectory" to File(packageDir, "assets").canonicalPath,
                "assetOrigin" to "https://ks-plugin-$token.invalid"
            ) else if (item.containsKey("view")) item + ("session" to token) else item
        }
        private val screensaverPending = AtomicBoolean(false)
        private val screensaverUpdate = Runnable {
            screensaverPending.set(false)
            if (alive.get()) emit("screensavers", mapOf("id" to id, "session" to token, "screensavers" to screensaverSnapshot()), alive)
        }
        fun notifyScreensavers() {
            if (screensaverPending.compareAndSet(false, true)) main.postDelayed(screensaverUpdate, 250)
        }
        fun closeScreensavers() { screensavers.close(); main.removeCallbacks(screensaverUpdate) }
        val charts = PluginCharts()
        private val chartPending = AtomicBoolean(false)
        private val chartUpdate = Runnable {
            chartPending.set(false)
            if (alive.get()) emit("charts", mapOf("id" to id, "session" to token, "charts" to charts.snapshot()), alive)
        }
        fun notifyCharts() {
            if (chartPending.compareAndSet(false, true)) main.postDelayed(chartUpdate, 1000)
        }
        fun closeCharts() { charts.close(); main.removeCallbacks(chartUpdate) }
        val statusTiles = PluginStatusTiles()
        private val statusTilePending = AtomicBoolean(false)
        private val statusTileUpdate = Runnable {
            statusTilePending.set(false)
            if (alive.get()) emit("statusTiles", mapOf("id" to id, "session" to token, "statusTiles" to statusTiles.snapshot()), alive)
        }
        fun notifyStatusTiles() {
            if (statusTilePending.compareAndSet(false, true)) main.postDelayed(statusTileUpdate, 250)
        }
        fun closeStatusTiles() { statusTiles.close(); main.removeCallbacks(statusTileUpdate) }
        val overlays = PluginOverlays<OverlayFactory>()
        fun notifyOverlays() = emit("overlays", mapOf("id" to id, "session" to token, "overlays" to overlays.snapshot()), alive)
        val triggers = PluginTriggers(manifest::hasTrigger)
        /** The same four per second for action settings, so two plugins that run each other's actions cannot spin. */
        val actionBudget = PluginTriggers({ true })
        val setup = PluginSetup(manifest, File(pluginData, "$id/choices"))
        private val setupPending = AtomicBoolean(false)
        // Choice lists can be large, so each one goes to the app once per revision.
        private val choicesSent = mutableMapOf<String, Long>()
        private val setupUpdate = Runnable {
            setupPending.set(false)
            if (alive.get()) emit("setup", mapOf("id" to id, "session" to token, "setup" to setup.snapshot(choicesSent)), alive)
        }
        fun notifySetup() {
            if (setupPending.compareAndSet(false, true)) main.postDelayed(setupUpdate, 100)
        }
        fun closeSetup() = main.removeCallbacks(setupUpdate)
        private val setupWatched = AtomicBoolean(false)
        /** Fails runs the plugin went quiet on, checking while any is running. Called on the worker. */
        fun watchSetup() {
            if (!setupWatched.compareAndSet(false, true)) return
            main.postDelayed(object : Runnable {
                override fun run() {
                    worker.execute {
                        if (!alive.get() || sessions[id] !== this@Session) { setupWatched.set(false); return@execute }
                        val ended = setup.expire(SystemClock.elapsedRealtime())
                        if (ended.isNotEmpty()) notifySetup()
                        for (run in ended) deliverSetup(this@Session, "settings.cancel", mapOf("run" to run.run, "reason" to run.reason))
                        if (alive.get() && setup.hasRunning()) main.postDelayed(this, SETUP_CHECK_MS) else setupWatched.set(false)
                    }
                }
            }, SETUP_CHECK_MS)
        }
        /** Whether the plugin last heard that its settings page is open. Used on the worker. */
        var settingsPageOpen = false
        var status = ""
        var statusError = false
        val lights = linkedMapOf<String, Map<String, Any?>>()
        init {
            if ("native" in manifest.capabilities) {
                val abis = if (android.os.Process.is64Bit()) Build.SUPPORTED_64_BIT_ABIS else Build.SUPPORTED_32_BIT_ABIS
                val source = abis.map { File(packageDir, "native/$it") }.firstOrNull { it.isDirectory }
                    ?: throw IllegalArgumentException("Plugin has no native library for this device ABI")
                check(nativeDir.mkdirs())
                source.listFiles()?.forEach { file ->
                    val target = File(nativeDir, file.name)
                    file.copyTo(target)
                    check(target.setReadOnly())
                }
            }
        }
        val token = UUID.randomUUID().toString()
        val subscriptions = ConcurrentHashMap.newKeySet<String>()
        /** Keys of this session's Home Assistant subscriptions, so events for an ended one are dropped. */
        val haSubscriptions = ConcurrentHashMap.newKeySet<String>()
        /** Keys of this session's Music Assistant subscriptions, likewise. */
        val maSubscriptions = ConcurrentHashMap.newKeySet<String>()
        val commandBudget = PluginCommandBudget()
        /**
         * Send a Home Assistant or Music Assistant request to the app. Unlike KS commands, a failure keeps its data:
         * the server's {code, message}.
         * Service calls can run a script to its end, so the wait is longer.
         */
        fun haRequest(method: String, arguments: Map<String, Any?>, callback: PluginHost.CommandCallback, done: (Boolean) -> Unit = {}) {
            commandBudget.acquire()
            val completed = AtomicBoolean(false)
            lateinit var timeout: Runnable
            fun finish(ok: Boolean, data: Any?, error: String?) {
                if (!completed.compareAndSet(false, true)) return
                main.removeCallbacks(timeout)
                done(ok)
                worker.execute {
                    try {
                        if (alive.get() && sessions[id] === this) {
                            try { call { callback.onResult(ok, data, error) } }
                            catch (failure: Throwable) { fail(id, failure); emit("changed", snapshot()) }
                        }
                    } finally { commandBudget.release() }
                }
            }
            timeout = Runnable { finish(false, mapOf("code" to "timeout", "message" to ""), "timeout") }
            main.post {
                if (!alive.get()) { commandBudget.release(); done(false); return@post }
                main.postDelayed(timeout, 30_000)
                channel.invokeMethod(method, mapOf("id" to id, "session" to token) + arguments, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        val value = result as? Map<*, *>
                        val ok = value?.get("ok") == true
                        finish(ok, value?.get("data"), if (ok) null else (value?.get("error") as? String ?: "KS command bridge is unavailable"))
                    }
                    override fun error(code: String, message: String?, details: Any?) = finish(false, null, "KS command bridge is unavailable")
                    override fun notImplemented() = finish(false, null, "KS command bridge is unavailable")
                })
            }
        }
        /** The camera claim and the barcode scan this session holds. Guarded by [cameraLock]. */
        @Volatile var camera: CameraClaim? = null
        @Volatile var scan: BarcodeScan? = null
        private var cameraThread: java.util.concurrent.ExecutorService? = null
        /** Frames and camera closes reach the plugin here, apart from its other callbacks. */
        @Synchronized fun cameraExecutor(): java.util.concurrent.ExecutorService =
            cameraThread ?: Executors.newSingleThreadExecutor { task -> Thread(task, "plugin-$id-camera").apply { isDaemon = true } }
                .also { cameraThread = it }
        @Synchronized fun closeCameraThread() { cameraThread?.shutdownNow(); cameraThread = null }
        private var shizukuClient: PluginShizuku.Client? = null
        @Synchronized fun closeShizuku() { shizukuClient?.close(); shizukuClient = null }
        @Synchronized fun shizukuClient(): PluginShizuku.Client {
            check(alive.get() && "shizuku" in manifest.capabilities) { "SDK 1 shizuku access is required" }
            return shizukuClient ?: shizuku.client().also { shizukuClient = it }
        }
        val alive = AtomicBoolean(true)
        @Volatile var loader: ClassLoader? = null
        val executor = Executors.newSingleThreadExecutor { task -> Thread(task, "plugin-$id").apply { isDaemon = true } }
        var plugin: KioskPlugin? = null
        val host = object : PluginHost {
            override fun shizukuState(): Map<String, Any> {
                check(alive.get() && "shizuku" in manifest.capabilities) { "SDK 1 shizuku access is required" }
                return shizuku.state()
            }
            override fun executeShizuku(command: Array<String>, timeoutMs: Int, callback: PluginHost.CommandCallback) {
                shizukuClient().execute(command, timeoutMs) { ok, data, error ->
                    worker.execute {
                        if (alive.get() && sessions[id] === this@Session) {
                            try { call { callback.onResult(ok, data, error) } }
                            catch (failure: Throwable) { fail(id, failure); emit("changed", snapshot()) }
                        }
                    }
                }
            }
            override fun executeCommand(command: String, arguments: Map<String, Any>, callback: PluginHost.CommandCallback) {
                check(alive.get() && manifest.capabilities.any { it == "host.read" || it == "host.control" || it == "screensaver.mode" || it == "screensaver" }) { "Host capability is required" }
                require(command.length in 1..80 && arguments.size <= 2 && arguments.all { it.key.length <= 32 && (it.value is Boolean || (it.value is String && (it.value as String).length <= 2048)) }) { "Invalid host request" }
                commandBudget.acquire()
                val copied = HashMap(arguments)
                val completed = AtomicBoolean(false)
                lateinit var timeout: Runnable
                fun finish(ok: Boolean, data: Any?, error: String?) {
                    if (!completed.compareAndSet(false, true)) return
                    main.removeCallbacks(timeout)
                    worker.execute {
                        try {
                            if (alive.get() && sessions[id] === this@Session) {
                                try { call { callback.onResult(ok, data, error) } }
                                catch (failure: Throwable) { fail(id, failure); emit("changed", snapshot()) }
                            }
                        } finally { commandBudget.release() }
                    }
                }
                timeout = Runnable { finish(false, null, "KS command timed out") }
                main.post {
                    if (!alive.get()) { commandBudget.release(); return@post }
                    main.postDelayed(timeout, 10_000)
                    channel.invokeMethod("hostCommand", mapOf("id" to id, "session" to token, "command" to command, "arguments" to copied), object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            val value = result as? Map<*, *>
                            val ok = value?.get("ok") == true
                            finish(ok, if (ok) value?.get("data") else null, if (ok) null else (value?.get("error") as? String ?: "KS command bridge is unavailable"))
                        }
                        override fun error(code: String, message: String?, details: Any?) = finish(false, null, "KS command bridge is unavailable")
                        override fun notImplemented() = finish(false, null, "KS command bridge is unavailable")
                    })
                }
            }
            override fun haCall(message: Map<String, Any>, callback: PluginHost.CommandCallback) {
                check(alive.get() && "ha" in manifest.capabilities) { "SDK 1 ha access is required" }
                haRequest("haCall", mapOf("message" to PluginHostPolicy.haMessage(message)), callback)
            }
            override fun haSubscribe(key: String, message: Map<String, Any>, callback: PluginHost.CommandCallback) {
                check(alive.get() && "ha" in manifest.capabilities) { "SDK 1 ha access is required" }
                require(PluginHostPolicy.haKey(key)) { "Subscription keys are 1 to 64 letters, digits, dots, dashes or underscores" }
                val copy = PluginHostPolicy.haMessage(message)
                require(haSubscriptions.size < 16 || key in haSubscriptions) { "At most 16 Home Assistant subscriptions per plugin" }
                require(haSubscriptions.add(key)) { "Subscription $key is already active" }
                try { haRequest("haSubscribe", mapOf("key" to key, "message" to copy), callback) { ok -> if (!ok) haSubscriptions.remove(key) } }
                catch (error: Throwable) { haSubscriptions.remove(key); throw error }
            }
            override fun haUnsubscribe(key: String) {
                check(alive.get() && "ha" in manifest.capabilities) { "SDK 1 ha access is required" }
                if (haSubscriptions.remove(key)) emit("haUnsubscribe", mapOf("id" to id, "session" to token, "key" to key), alive)
            }
            override fun maCall(command: String, args: Map<String, Any>, callback: PluginHost.CommandCallback) {
                check(alive.get() && "ma" in manifest.capabilities) { "SDK 1 ma access is required" }
                require(command.length in 1..128) { "Music Assistant commands are 1 to 128 characters" }
                haRequest("maCall", mapOf("command" to command, "args" to PluginHostPolicy.maMessage(args)), callback)
            }
            override fun maSubscribe(key: String, filter: Map<String, Any>, callback: PluginHost.CommandCallback) {
                check(alive.get() && "ma" in manifest.capabilities) { "SDK 1 ma access is required" }
                require(PluginHostPolicy.haKey(key)) { "Subscription keys are 1 to 64 letters, digits, dots, dashes or underscores" }
                val copy = PluginHostPolicy.maMessage(filter)
                require(maSubscriptions.size < 16 || key in maSubscriptions) { "At most 16 Music Assistant subscriptions per plugin" }
                require(maSubscriptions.add(key)) { "Subscription $key is already active" }
                try { haRequest("maSubscribe", mapOf("key" to key, "filter" to copy), callback) { ok -> if (!ok) maSubscriptions.remove(key) } }
                catch (error: Throwable) { maSubscriptions.remove(key); throw error }
            }
            override fun maUnsubscribe(key: String) {
                check(alive.get() && "ma" in manifest.capabilities) { "SDK 1 ma access is required" }
                if (maSubscriptions.remove(key)) emit("maUnsubscribe", mapOf("id" to id, "session" to token, "key" to key), alive)
            }
            override fun openCamera(options: Map<String, Any>, listener: PluginHost.CameraListener) {
                check(alive.get() && "camera" in manifest.capabilities) { "SDK 1 camera access is required" }
                val claim = CameraClaim(this@Session, PluginCameraRequest.parse(options), listener, cameraClaims.incrementAndGet())
                // Opening again replaces this plugin's own claim. Another plugin's stands.
                var replaced: CameraClaim? = null
                val accepted = synchronized(cameraLock) {
                    val owner = cameraOwner
                    if (owner != null && owner !== this@Session) false else {
                        replaced = camera
                        camera = claim
                        cameraOwner = this@Session
                        PluginCameraFrames.sink = ::offerFrame
                        true
                    }
                }
                if (!accepted) { cameraClosed(this@Session, listener, "busy"); return }
                main.post {
                    replaced?.let { main.removeCallbacks(it.timeout) }
                    if (!alive.get() || camera !== claim) return@post
                    main.postDelayed(claim.timeout, claim.request.timeoutMs)
                    // The app decides whether the camera may run and binds it.
                    channel.invokeMethod("cameraOpen", mapOf(
                        "id" to id, "session" to token, "claim" to claim.number,
                        "width" to claim.request.width, "height" to claim.request.height, "facing" to claim.request.facing,
                    ), object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            val reason = result as? String ?: return
                            worker.execute { endCamera(this@Session, claim, reason.takeIf { it in PLUGIN_CAMERA_REASONS } ?: "camera_failed", notifyApp = false) }
                        }
                        override fun error(code: String, message: String?, details: Any?) =
                            worker.execute { endCamera(this@Session, claim, "camera_failed", notifyApp = true) }
                        override fun notImplemented() =
                            worker.execute { endCamera(this@Session, claim, "camera_failed", notifyApp = false) }
                    })
                }
            }
            override fun closeCamera() {
                check(alive.get() && "camera" in manifest.capabilities) { "SDK 1 camera access is required" }
                worker.execute { endCamera(this@Session, null, "closed", notifyApp = true) }
            }
            override fun scanBarcode(options: Map<String, Any>, callback: PluginHost.CommandCallback) {
                check(alive.get() && "barcode" in manifest.capabilities) { "SDK 1 barcode access is required" }
                val request = PluginBarcodeRequest.parse(options)
                val current = BarcodeScan(this@Session, UUID.randomUUID().toString(), callback)
                val started = synchronized(cameraLock) {
                    if (scanOwner != null) false else { scanOwner = this@Session; scan = current; true }
                }
                if (!started) { answerScan(this@Session, callback, false, null, "busy"); return }
                main.post {
                    if (!alive.get() || scan !== current) return@post
                    // A backstop: the app times the scan out itself.
                    main.postDelayed(current.timeout, request.timeoutMs + 30_000)
                    channel.invokeMethod("barcodeScan", mapOf("id" to id, "session" to token, "scan" to current.id) + request.toMap(),
                        object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                val value = result as? Map<*, *>
                                if (value?.get("ok") == true && value["value"] is String) {
                                    finishScan(current, true, mapOf("value" to value["value"], "format" to (value["format"] as? String ?: "unknown")), null)
                                } else {
                                    finishScan(current, false, null, (value?.get("error") as? String)?.takeIf { it in PLUGIN_SCAN_ERRORS } ?: "unavailable")
                                }
                            }
                            override fun error(code: String, message: String?, details: Any?) = finishScan(current, false, null, "unavailable")
                            override fun notImplemented() = finishScan(current, false, null, "unavailable")
                        })
                }
            }
            override fun cancelBarcodeScan() {
                check(alive.get() && "barcode" in manifest.capabilities) { "SDK 1 barcode access is required" }
                val current = synchronized(cameraLock) { scan } ?: return
                emit("barcodeCancel", mapOf("id" to id, "session" to token, "scan" to current.id), alive)
            }
            override fun subscribe(event: String) {
                check(alive.get() && "host.read" in manifest.capabilities) { "SDK 1 host.read access is required" }
                require(PluginHostPolicy.validEvent(event)) { "Unknown KS event" }
                if (PluginHostPolicy.entityEvent(event) && event !in subscriptions) {
                    require(subscriptions.count { PluginHostPolicy.entityEvent(it) } < 16) { "At most 16 entity subscriptions per plugin" }
                }
                if (subscriptions.add(event)) emit("hostSubscription", mapOf("id" to id, "session" to token, "event" to event, "subscribed" to true), alive)
            }
            override fun unsubscribe(event: String) {
                check(alive.get() && "host.read" in manifest.capabilities) { "SDK 1 host.read access is required" }
                require(PluginHostPolicy.validEvent(event)) { "Unknown KS event" }
                if (subscriptions.remove(event)) emit("hostSubscription", mapOf("id" to id, "session" to token, "event" to event, "subscribed" to false), alive)
            }
            override fun publishScreensaver(key: String, title: String, html: String) {
                check(alive.get() && "screensaver" in manifest.capabilities) { "Screensaver capability is required" }
                screensavers.publish(key, title, html)
                notifyScreensavers()
            }
            override fun publishScreensaverAsset(key: String, title: String, entry: String, data: Map<String, Any>) {
                check(alive.get() && "screensaver" in manifest.capabilities) { "Screensaver capability is required" }
                screensavers.publishAsset(key, title, entry, data)
                notifyScreensavers()
            }
            override fun removeScreensaver(key: String) {
                check(alive.get() && "screensaver" in manifest.capabilities) { "Screensaver capability is required" }
                screensavers.remove(key)
                notifyScreensavers()
            }
            override fun publishScreensaverView(key: String, title: String, factory: OverlayFactory) =
                publishScreensaverView(key, title, factory, false)
            override fun publishScreensaverView(key: String, title: String, factory: OverlayFactory, touch: Boolean) {
                check(alive.get() && "screensaver" in manifest.capabilities) { "Screensaver capability is required" }
                screensavers.publishView(key, title, factory, touch)
                notifyScreensavers()
            }
            override fun publishSeries(key: String, chart: Map<String, Any>) {
                charts.publish(key, chart)
                notifyCharts()
            }
            override fun removeSeries(key: String) {
                charts.remove(key)
                notifyCharts()
            }
            override fun publishStatusTile(key: String, title: String, level: String, text: String) {
                statusTiles.publish(key, title, level, text)
                notifyStatusTiles()
            }
            override fun removeStatusTile(key: String) {
                statusTiles.remove(key)
                notifyStatusTiles()
            }
            override fun fireTrigger(id: String) {
                check(alive.get()) { "Plugin session has ended" }
                if (triggers.fire(id)) emit("trigger", mapOf("id" to this@Session.id, "session" to token, "trigger" to id), alive)
            }
            override fun runAction(setting: String, callback: PluginHost.CommandCallback) {
                check(alive.get()) { "Plugin session has ended" }
                require(manifest.isActionPath(setting)) { "Unknown action setting" }
                val allowed = actionBudget.fire(setting)
                worker.execute {
                    if (!alive.get() || sessions[id] !== this@Session) return@execute
                    val action = manifest.action(records.getJSONObject(id).optJSONObject("config") ?: JSONObject(), setting)
                    var refused = when {
                        !allowed -> "Too many actions"
                        action == null -> "No such row"
                        action.length() == 0 -> "No action is chosen"
                        else -> null
                    }
                    if (refused == null) {
                        try { haRequest("runAction", mapOf("action" to jsonValue(action)), callback); return@execute }
                        catch (busy: IllegalStateException) { refused = busy.message ?: "Too many actions" }
                    }
                    try { call { callback.onResult(false, null, refused) } }
                    catch (failure: Throwable) { fail(id, failure); emit("changed", snapshot()) }
                }
            }
            override fun showWindow(title: String, message: String, buttonLabel: String) {
                require("overlay" in manifest.capabilities) { "Plugin did not declare overlay access" }
                require(title.length in 1..80 && message.length <= 4096 && buttonLabel.length <= 80) { "Window text is too long" }
                emit("window", mapOf("id" to id, "title" to title, "message" to message, "buttonLabel" to buttonLabel), alive)
            }
            override fun hideWindow() = emit("hideWindow", mapOf("id" to id), alive)
            override fun showOverlay(key: String, spec: OverlaySpec, factory: OverlayFactory) {
                check(alive.get() && "overlay" in manifest.capabilities) { "Plugin did not declare overlay access" }
                overlays.show(key, PluginOverlays.Placement(
                    spec.anchor() ?: "", spec.width(), spec.height(),
                    listOf(spec.insetLeft(), spec.insetTop(), spec.insetRight(), spec.insetBottom()),
                    spec.offsetX(), spec.offsetY(), spec.closeOnBack(), spec.onTop(), spec.touchable(),
                    spec.closeOnOutsideTouch(), spec.passOutsideTouch(), spec.enter() ?: "", spec.exit() ?: "", spec.transitionDuration(),
                ), factory)
                notifyOverlays()
            }
            override fun hideOverlay(key: String) {
                if (overlays.hide(key)) notifyOverlays()
            }
            override fun setContentInsets(left: Int, top: Int, right: Int, bottom: Int) {
                check(alive.get() && "overlay" in manifest.capabilities) { "Plugin did not declare overlay access" }
                val insets = listOf(left, top, right, bottom)
                require(insets.all { it in 0..PluginOverlays.MAX_INSET }) { "Content insets must be 0 to 4096 dp" }
                emit("contentInsets", mapOf("id" to id, "session" to token, "insets" to insets), alive)
            }
            override fun isHeadless() = headless
            override fun log(message: String) = emit("log", mapOf("id" to id, "message" to message.take(1000)), alive)
            override fun nativeLibraryPath(name: String): String {
                check(alive.get() && "native" in manifest.capabilities)
                require(name.matches(Regex("[a-zA-Z0-9_]+")))
                return File(nativeDir, "lib$name.so").also { require(it.isFile) { "Native library is not packaged" } }.absolutePath
            }
            override fun packagePath(): String {
                check(alive.get() && "native" in manifest.capabilities)
                return File(packageDir, "plugin.jar").absolutePath
            }
            // Assets were checked against their digests when the session started.
            override fun assetPath(name: String): String {
                check(alive.get())
                return PluginPackage.assetFile(packageDir, name).absolutePath
            }
            override fun openAsset(name: String): java.io.InputStream = File(assetPath(name)).inputStream()
            override fun status(message: String, error: Boolean) {
                require(message.length <= 1000)
                worker.execute { if (alive.get()) {
                    status = message; statusError = error
                    emit("changed", snapshot())
                } }
            }
            override fun saveSettings(values: Map<String, Any>) {
                val incoming = JSONObject(values)
                manifest.config(incoming)
                worker.execute { if (alive.get()) {
                    val record = records.getJSONObject(id)
                    // Action settings stay as the user saved them.
                    val config = manifest.config(manifest.keepActions(incoming, record.optJSONObject("config") ?: JSONObject()))
                    record.put("config", JSONObject(config)); save()
                    emit("changed", snapshot())
                } }
            }
            override fun updateSettings(values: Map<String, Any>) {
                check(alive.get()) { "Plugin session has ended" }
                val partial = JSONObject(values)
                require(partial.keys().asSequence().none { it in manifest.actionKeys }) { "Action settings are chosen by the user" }
                // Each value is checked here, so a bad one throws in the plugin. Rules
                // that depend on other settings wait for the merge with the saved ones.
                manifest.checkValues(partial)
                worker.execute { if (alive.get()) {
                    val record = records.getJSONObject(id)
                    try {
                        val config = manifest.config(manifest.merged(record.optJSONObject("config") ?: JSONObject(), partial))
                        record.put("config", JSONObject(config)); save()
                        emit("changed", snapshot())
                    } catch (error: IllegalArgumentException) {
                        log("updateSettings: ${error.message}")
                    }
                } }
            }
            override fun setupResult(run: String, state: String, message: String): Boolean {
                check(alive.get()) { "Plugin session has ended" }
                return setup.result(run, state, message, SystemClock.elapsedRealtime()).also { if (it) notifySetup() }
            }
            override fun confirmSetup(run: String, title: String, message: String, confirmLabel: String): Boolean {
                check(alive.get()) { "Plugin session has ended" }
                return setup.confirm(run, title, message, confirmLabel, SystemClock.elapsedRealtime()).also { if (it) notifySetup() }
            }
            override fun setSettingChoices(key: String, ids: Array<String>, labels: Array<String>?) {
                check(alive.get()) { "Plugin session has ended" }
                setup.setChoices(key, ids, labels)
                notifySetup()
            }
            override fun setSettingChoices(key: String, choices: List<Map<String, Any?>?>?) {
                check(alive.get()) { "Plugin session has ended" }
                setup.setChoices(key, requireNotNull(choices) { "Missing choices" })
                notifySetup()
            }
            override fun setSettingChoicesEnabled(key: String, enabled: Boolean) {
                check(alive.get()) { "Plugin session has ended" }
                setup.setChoicesEnabled(key, enabled)
                notifySetup()
            }
            private fun publishEntity(type: String, key: String, name: String, metadata: Map<String, Any>, state: Any?) {
                check(alive.get() && "entities" in manifest.capabilities) { "SDK 1 entities access is required" }
                entities.publish(type, key, name, metadata, state)
                notifyEntities()
            }
            private fun removeEntity(type: String, key: String) {
                check(alive.get() && "entities" in manifest.capabilities) { "SDK 1 entities access is required" }
                entities.remove(type, key)
                notifyEntities()
            }
            override fun publishSensor(key: String, name: String, metadata: Map<String, Any>, state: Double?) = publishEntity("sensor", key, name, metadata, state)
            override fun removeSensor(key: String) = removeEntity("sensor", key)
            override fun publishTextSensor(key: String, name: String, state: String?) = publishEntity("text_sensor", key, name, emptyMap(), state)
            override fun removeTextSensor(key: String) = removeEntity("text_sensor", key)
            override fun publishBinarySensor(key: String, name: String, deviceClass: String, state: Boolean?) = publishEntity("binary_sensor", key, name, mapOf("deviceClass" to deviceClass), state)
            override fun removeBinarySensor(key: String) = removeEntity("binary_sensor", key)
            override fun publishSwitch(key: String, name: String, state: Boolean) = publishEntity("switch", key, name, emptyMap(), state)
            override fun removeSwitch(key: String) = removeEntity("switch", key)
            override fun publishSelect(key: String, name: String, options: Array<String>, state: String?) = publishEntity("select", key, name, mapOf("options" to options.toList()), state)
            override fun removeSelect(key: String) = removeEntity("select", key)
            override fun publishLight(key: String, name: String, effects: Array<String>, state: Map<String, Any>) {
                require("entities" in manifest.capabilities)
                require(key.matches(Regex("[a-z][a-z0-9_]{0,39}")) && name.length in 1..80)
                require(effects.size <= 24 && effects.all { it.length in 1..80 } && effects.toSet().size == effects.size)
                val normalized = PluginLightState.validate(state, effects.toList())
                val light = mapOf("key" to key, "name" to name, "effects" to effects.toList(), "state" to normalized)
                worker.execute { if (alive.get()) {
                    if (lights.size < 4 || lights.containsKey(key)) {
                        lights[key] = light; emit("changed", snapshot())
                    }
                } }
            }
            override fun removeLight(key: String) {
                worker.execute { if (alive.get() && lights.remove(key) != null) emit("changed", snapshot()) }
            }
        }
        fun <T> call(action: () -> T): T {
            val future = executor.submit(Callable { action() })
            try {
                return future.get(3, TimeUnit.SECONDS)
            } catch (error: java.util.concurrent.TimeoutException) {
                future.cancel(true)
                restartRequired.add(id)
                throw IllegalStateException("Plugin callback timed out. Restart Kiosk if the plugin left work running.")
            } catch (error: java.util.concurrent.ExecutionException) {
                throw error.cause ?: error
            }
        }
    }

    /** One plugin holds the camera and one scans at a time, across every session. */
    private val cameraLock = Any()
    private var cameraOwner: Session? = null
    private var scanOwner: Session? = null
    private val cameraClaims = AtomicInteger()

    /** A plugin's openCamera, numbered so a late close from the app cannot end a newer one. */
    private inner class CameraClaim(val session: Session, val request: PluginCameraRequest, val listener: PluginHost.CameraListener, val number: Int) {
        /** A frame is with the plugin. Frames that arrive meanwhile are skipped. */
        val busy = AtomicBoolean(false)
        @Volatile var lastFrameNs = 0L
        val timeout = Runnable { worker.execute { endCamera(session, this, "timeout", notifyApp = true) } }
    }

    private inner class BarcodeScan(val session: Session, val id: String, val callback: PluginHost.CommandCallback) {
        val timeout = Runnable { finishScan(this, false, null, "timeout") }
    }

    /**
     * A motion session frame for the plugin holding the camera, on the
     * analyzer thread. Paced to the claim's rate and copied, since the image
     * goes back to the camera when this returns.
     */
    private fun offerFrame(image: androidx.camera.core.ImageProxy, front: Boolean) {
        val claim = synchronized(cameraLock) { cameraOwner?.camera } ?: return
        val session = claim.session
        if (!session.alive.get()) return
        val now = System.nanoTime()
        if (now - claim.lastFrameNs < 1_000_000_000L / claim.request.fps) return
        if (!claim.busy.compareAndSet(false, true)) return
        claim.lastFrameNs = now
        val frame = try {
            me.jxl.kiosk.plugins.CameraFrame(image.width, image.height, image.imageInfo.rotationDegrees, front,
                image.imageInfo.timestamp, claim.request.format, PluginCameraFrames.copy(image, claim.request.format == "nv21"))
        } catch (error: Exception) {
            claim.busy.set(false)
            throw error
        }
        try {
            session.cameraExecutor().execute {
                try {
                    if (session.alive.get() && session.camera === claim) claim.listener.onFrame(frame)
                } catch (error: Throwable) {
                    cameraFailed(session, error)
                } finally {
                    claim.busy.set(false)
                }
            }
        } catch (_: java.util.concurrent.RejectedExecutionException) {
            claim.busy.set(false)
        }
    }

    /**
     * Ends a session's camera claim, or only [claim] when it is still the
     * current one. [notifyApp] tells the app to let the camera go, unless
     * the app ended it.
     */
    private fun endCamera(session: Session, claim: CameraClaim?, reason: String, notifyApp: Boolean) {
        val ended = synchronized(cameraLock) {
            val current = session.camera
            if (current == null || (claim != null && current !== claim)) null else {
                session.camera = null
                if (cameraOwner === session) {
                    cameraOwner = null
                    PluginCameraFrames.sink = null
                }
                current
            }
        } ?: return
        main.removeCallbacks(ended.timeout)
        if (notifyApp) emit("cameraClose", mapOf("id" to session.id, "session" to session.token, "claim" to ended.number))
        if (session.alive.get()) cameraClosed(session, ended.listener, reason)
    }

    private fun cameraClosed(session: Session, listener: PluginHost.CameraListener, reason: String) {
        try {
            session.cameraExecutor().execute {
                try { if (session.alive.get()) listener.onClosed(reason) } catch (error: Throwable) { cameraFailed(session, error) }
            }
        } catch (_: java.util.concurrent.RejectedExecutionException) { /* The session ended. */ }
    }

    /** A camera callback threw. The plugin is stopped like any failed callback. */
    private fun cameraFailed(session: Session, error: Throwable) {
        worker.execute {
            if (session.alive.get() && sessions[session.id] === session) {
                fail(session.id, error)
                emit("changed", snapshot())
            }
        }
    }

    /** The scan is over. A session that ended hears nothing. */
    private fun finishScan(scan: BarcodeScan, ok: Boolean, data: Any?, error: String?) {
        val session = scan.session
        val current = synchronized(cameraLock) {
            if (session.scan !== scan) false else {
                session.scan = null
                if (scanOwner === session) scanOwner = null
                true
            }
        }
        if (!current) return
        main.removeCallbacks(scan.timeout)
        answerScan(session, scan.callback, ok, data, error)
    }

    private fun answerScan(session: Session, callback: PluginHost.CommandCallback, ok: Boolean, data: Any?, error: String?) {
        worker.execute {
            if (!session.alive.get() || sessions[session.id] !== session) return@execute
            try { session.call { callback.onResult(ok, data ?: if (ok) null else mapOf("code" to error), error) } }
            catch (failure: Throwable) { fail(session.id, failure); emit("changed", snapshot()) }
        }
    }

    /** Registered on the engine by KioskApplication. */
    internal val overlayViews = PluginOverlayViews(
        context.assets,
        lookup = { id, token, key, generation, screensaver ->
            sessions[id]?.takeIf { it.alive.get() && it.token == token }?.let { session ->
                if (screensaver) session.screensavers.view(key, generation) else session.overlays.get(key, generation)?.factory
            }
        },
        failed = { id, token, error ->
            worker.execute {
                val session = sessions[id]
                if (session != null && session.alive.get() && session.token == token) {
                    fail(id, error)
                    emit("changed", snapshot())
                }
            }
        },
        measured = { size -> emit("overlaySize", size) },
    )

    init {
        current = this
        installCrashGuard()
        channel.setMethodCallHandler { call, result ->
            worker.execute {
                try {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                    val value: Any? = when (call.method) {
                        "initialize" -> { initialize(); snapshot() }
                        "list" -> snapshot()
                        "voiceSkinThumbnail" -> voiceSkinThumbnail(id(args))
                        "icon" -> icon(id(args))
                        "shizukuState" -> shizuku.state()
                        "requestShizukuPermission" -> {
                            check(pluginsEnabled && "shizuku" in manifest(id(args)).capabilities) { "Enable Plugins and select a plugin that declares Shizuku access" }
                            shizuku.requestPermission()
                            shizuku.state()
                        }
                        "setEnabled" -> {
                            val enabled = args["enabled"] as? Boolean ?: throw IllegalArgumentException("Missing enabled flag")
                            setEnabled(enabled)
                            snapshot()
                        }
                        "validateManifest" -> {
                            try {
                                val manifest = PluginManifest(JSONObject(args["manifest"] as String))
                                require(manifest.minAndroidSdk <= Build.VERSION.SDK_INT) { "Plugin needs Android API ${manifest.minAndroidSdk}" }
                                requireScreen(manifest)
                                requireAppVersion(manifest)
                                mapOf("compatible" to true, "compatibilityError" to "")
                            } catch (error: Exception) {
                                mapOf("compatible" to false, "compatibilityError" to (error.message ?: "Invalid plugin manifest"))
                            }
                        }
                        "install" -> install(args)
                        "enable" -> { enable(id(args)); snapshot() }
                        "disable" -> { disable(id(args)); snapshot() }
                        "remove" -> { remove(id(args)); snapshot() }
                        "configure" -> { configure(id(args), args); snapshot() }
                        "configureAction" -> { configureAction(id(args), args); snapshot() }
                        "fleetState" -> fleetState()
                        "fleetConfigure" -> { fleetConfigure(id(args), args); snapshot() }
                        "packagePath" -> packageFile(id(args))?.absolutePath
                        "keepPackage" -> {
                            val id = id(args)
                            val bytes = args["bytes"] as? ByteArray ?: throw IllegalArgumentException("Missing plugin ZIP")
                            val hash = records.getJSONObject(id).getString("hash")
                            require(PluginPackage.sha256(bytes) == hash) { "Package SHA-256 does not match the installed plugin" }
                            keepPackage(hash, bytes)
                            packageFile(id)?.absolutePath
                        }
                        "execute" -> { execute(id(args), args); snapshot() }
                        "setupRun" -> setupRun(id(args), args)
                        "setupCancel" -> { setupCancel(id(args), args); null }
                        "setupConfirm" -> { setupConfirm(id(args), args); null }
                        "settingsPage" -> { settingsPage(args); null }
                        "entityCommand" -> {
                            val session = sessions[id(args)] ?: throw IllegalStateException("Enable the plugin first")
                            val key = args["key"] as? String ?: throw IllegalArgumentException("Missing entity key")
                            val type = args["type"] as? String ?: "light"
                            val value = when (type) {
                                "light" -> {
                                    require(session.lights.containsKey(key)) { "Plugin light is not available" }
                                    (args["value"] as? Map<String, Any?>) ?: emptyMap()
                                }
                                "switch" -> session.entities.switchCommand(key, args["value"])
                                "select" -> session.entities.select(key, args["value"])
                                else -> throw IllegalArgumentException("Plugin entity is read-only")
                            }
                            try { session.call { session.plugin!!.onEvent("$type.$key", value) } }
                            catch (error: Throwable) { fail(session.id, error); throw error }
                            snapshot()
                        }
                        "hostEvent" -> {
                            val session = sessions[args["id"]]
                            val event = args["event"] as? String
                            val haKey = event?.let(PluginHostPolicy::haSubscriptionKey)
                            val maKey = event?.let(PluginHostPolicy::maSubscriptionKey)
                            if (session != null && session.alive.get() && session.token == args["session"] &&
                                (event in session.subscriptions || (haKey != null && haKey in session.haSubscriptions) ||
                                    (maKey != null && maKey in session.maSubscriptions))) {
                                val payload = args["payload"] as? Map<String, Any?> ?: emptyMap()
                                try { session.call { session.plugin!!.onEvent("ks.$event", payload) } }
                                catch (error: Throwable) { fail(session.id, error); emit("changed", snapshot()); throw error }
                            }
                            null
                        }
                        "cameraClosed" -> {
                            // The app could not run the camera or had to stop it.
                            val session = sessions[args["id"]]
                            val number = (args["claim"] as? Number)?.toInt()
                            val claim = session?.camera
                            if (session != null && session.token == args["session"] && claim != null && claim.number == number) {
                                endCamera(session, claim, (args["reason"] as? String)?.takeIf { it in PLUGIN_CAMERA_REASONS } ?: "camera_failed", notifyApp = false)
                            }
                            null
                        }
                        "windowEvent" -> { windowEvent(id(args), args); null }
                        "overlayClosed" -> { overlayClosed(args); null }
                        "overlayTheme" -> { main.post { overlayViews.setTheme(args) }; null }
                        "stopAll" -> {
                            sessions.keys.toList().forEach { id ->
                                try { stopSession(id) } catch (_: Throwable) { /* Continue stopping other plugins. */ }
                            }
                            null
                        }
                        else -> throw IllegalArgumentException("Unknown plugin method")
                    }
                    main.post { result.success(value) }
                } catch (error: Throwable) {
                    val message = error.message ?: error.javaClass.simpleName
                    emit("changed", snapshot())
                    main.post { result.error("plugin_error", message, null) }
                }
            }
        }
    }

    private fun id(args: Map<String, Any?>): String {
        val id = args["id"] as? String ?: throw IllegalArgumentException("Missing plugin ID")
        require(records.has(id)) { "Plugin is not installed" }
        return id
    }

    private fun save() {
        check(prefs.edit().putString("installed", records.toString()).commit()) { "Cannot save plugin state" }
    }

    private fun directory(id: String): File {
        val hash = records.getJSONObject(id).getString("hash")
        require(hash.matches(Regex("[a-f0-9]{64}"))) { "Invalid installed package hash" }
        return File(root, hash)
    }

    /** An installed plugin's voice skin picture, or null when it names none. Running or not. */
    private fun voiceSkinThumbnail(id: String): ByteArray? =
        manifest(id).voiceSkinThumbnail?.let { picture(id, it, "voiceSkinThumbnail") }

    /** An installed plugin's icon, or null when it names none. Running or not. */
    private fun icon(id: String): ByteArray? = manifest(id).icon?.let { picture(id, it, "icon") }

    /** A picture from an installed plugin's assets, checked against the digest it was installed with. */
    private fun picture(id: String, name: String, field: String): ByteArray {
        val file = PluginPackage.assetFile(directory(id), name)
        require(file.length() <= MAX_THUMBNAIL_BYTES) { "$field is too large" }
        val bytes = file.readBytes()
        val expected = records.getJSONObject(id).optJSONObject("assetSha256")?.optString("assets/$name")
        require(expected.isNullOrEmpty() || expected == PluginPackage.sha256(bytes)) { "$field changed after install" }
        return bytes
    }

    private fun manifest(id: String) = PluginManifest(JSONObject(PluginPackage.installedManifest(directory(id)).readText()))

    private fun snapshot(): Map<String, Any?> = mapOf("enabled" to pluginsEnabled, "plugins" to installedSnapshot())

    private fun installedSnapshot(): List<Any?> = records.keys().asSequence().sorted().map { id ->
        val record = records.getJSONObject(id)
        try {
            val manifest = manifest(id)
            val value = JSONObject(manifest.json.toString())
                .put("enabled", record.optBoolean("enabled"))
                .put("running", sessions.containsKey(id))
                .put("loaded", id in loadedIds)
                .put("sha256", record.getString("hash"))
                .put("source", record.optJSONObject("source"))
                .put("status", sessions[id]?.status ?: "")
                .put("statusError", sessions[id]?.statusError ?: false)
                .put("entities", org.json.JSONArray(sessions[id]?.entities?.snapshot() ?: emptyList<Any>()))
                .put("screensavers", org.json.JSONArray(sessions[id]?.screensaverSnapshot() ?: emptyList<Any>()))
                .put("charts", org.json.JSONArray(sessions[id]?.charts?.snapshot() ?: emptyList<Any>()))
                .put("statusTiles", org.json.JSONArray(sessions[id]?.statusTiles?.snapshot() ?: emptyList<Any>()))
                .put("lights", org.json.JSONArray(sessions[id]?.lights?.values?.toList() ?: emptyList<Any>()))
                .put("values", manifest.masked(record.optJSONObject("config") ?: JSONObject()))
                .put("actionOptions", record.optJSONObject("actionOptions") ?: JSONObject())
                .put("error", record.optString("error"))
            jsonValue(value)
        } catch (error: Throwable) {
            mapOf("id" to id, "name" to id, "version" to "?", "enabled" to false,
                "running" to false, "loaded" to (id in loadedIds), "settings" to emptyList<Any>(),
                "commands" to emptyList<Any>(), "values" to emptyMap<String, Any>(),
                "error" to "Cannot read installed plugin: ${error.message}")
        }
    }.toList()

    private fun initialize() {
        if (initialized) return
        initialized = true
        val installedHashes = records.keys().asSequence().map { records.getJSONObject(it).optString("hash") }.toSet()
        root.listFiles()?.filter { it.name !in installedHashes && it.name !in loadedHashes }
            ?.forEach { it.deleteRecursively() }
        packages.listFiles()?.filter { it.name.removeSuffix(".zip") !in installedHashes }
            ?.forEach { it.delete() }
        pluginData.listFiles()?.filter { !records.has(it.name) }?.forEach { it.deleteRecursively() }
        // Existing installations keep running. New installations start with plugins off.
        if (!prefs.contains("pluginsEnabled")) {
            check(prefs.edit().putBoolean("pluginsEnabled", pluginsEnabled).commit())
        }
        if (!pluginsEnabled) {
            check(prefs.edit().putBoolean("startupPending", false).commit())
            return
        }
        val updatedAt = appUpdatedAt()
        val strikes = startupStrikes(
            prefs.getBoolean("startupPending", false),
            prefs.getLong("startupUpdatedAt", updatedAt),
            updatedAt,
            prefs.getInt("startupStrikes", 0),
        )
        if (strikes >= STARTUP_STRIKES) {
            for (id in enabledIds()) records.getJSONObject(id).put("enabled", false)
                .put("error", "Disabled after two incomplete plugin startups in a row. Enable it to try again.")
            save()
            prefs.edit().putBoolean("startupPending", false).putInt("startupStrikes", 0).commit()
            return
        }
        prefs.edit().putInt("startupStrikes", strikes).commit()
        startEnabled()
    }

    private fun enabledIds(): List<String> = records.keys().asSequence()
        .filter { records.getJSONObject(it).optBoolean("enabled") }.toList()

    private fun startEnabled() {
        val enabled = enabledIds()
        if (enabled.isEmpty()) return
        val generation = ++startupGeneration
        check(prefs.edit().putBoolean("startupPending", true).putLong("startupUpdatedAt", appUpdatedAt()).commit())
        for (id in enabled) {
            try { enable(id) } catch (_: Throwable) { /* Failure is recorded by enable. */ }
        }
        main.postDelayed({ worker.execute {
            if (startupGeneration == generation) {
                prefs.edit().putBoolean("startupPending", false).putInt("startupStrikes", 0).commit()
            }
        } }, 30_000)
    }

    private fun appUpdatedAt(): Long = try {
        context.packageManager.getPackageInfo(context.packageName, 0).lastUpdateTime
    } catch (_: Exception) { 0L }

    private fun setEnabled(enabled: Boolean) {
        if (pluginsEnabled == enabled) return
        check(prefs.edit().putBoolean("pluginsEnabled", enabled).commit()) { "Cannot save plugin state" }
        pluginsEnabled = enabled
        if (enabled) {
            startEnabled()
        } else {
            startupGeneration++
            // Revoke every host before waiting for stop callbacks from individual plugins.
            sessions.forEach { (id, session) ->
                session.alive.set(false)
                session.closeShizuku(); session.closeCharts(); session.closeStatusTiles(); session.triggers.close(); session.actionBudget.close(); session.closeEntities(); session.closeScreensavers(); session.overlays.close(); session.closeSetup()
                emit("hideWindow", mapOf("id" to id))
            }
            for (id in sessions.keys.toList()) {
                try { stopSession(id) } catch (error: Throwable) {
                    records.getJSONObject(id).put("error", error.message ?: error.javaClass.simpleName)
                }
            }
            save()
            check(prefs.edit().putBoolean("startupPending", false).putInt("startupStrikes", 0).commit())
        }
    }

    private fun install(args: Map<String, Any?>): Map<String, Any?> {
        require(args["trusted"] == true) { "Confirm that you trust the plugin author" }
        val bytes = args["bytes"] as? ByteArray ?: throw IllegalArgumentException("Missing plugin ZIP")
        val hash = PluginPackage.sha256(bytes)
        val expected = args["sha256"] as? String
        require(expected.isNullOrEmpty() || hash == expected.lowercase()) { "Package SHA-256 does not match" }
        val staging = File(root, ".staging-${UUID.randomUUID()}")
        val manifest = PluginPackage.extract(bytes, staging)
        try {
            val expectedManifest = args["expectedManifest"] as? String
            if (expectedManifest != null) {
                PluginPackage.verifyManifest(manifest, expectedManifest)
            }
            val source = (args["source"] as? String)?.let { JSONObject(it) }
            val previousSource = records.optJSONObject(manifest.id)?.optJSONObject("source")?.optString("repository")
            require(previousSource.isNullOrEmpty() || previousSource == source?.optString("repository")) {
                "This plugin ID belongs to another repository. Uninstall it before changing sources."
            }
            require(manifest.minAndroidSdk <= Build.VERSION.SDK_INT) { "Plugin needs Android API ${manifest.minAndroidSdk}" }
            requireScreen(manifest)
            requireAppVersion(manifest)
            manifest.voiceSkinThumbnail?.let {
                require(PluginPackage.assetFile(staging, it).length() <= MAX_THUMBNAIL_BYTES) { "voiceSkinThumbnail must be at most 256 KB" }
            }
            manifest.icon?.let {
                val file = PluginPackage.assetFile(staging, it)
                require(file.length() <= MAX_THUMBNAIL_BYTES && PluginPackage.pngSize(file.readBytes()) == 256 to 256) { "icon must be a 256 by 256 PNG of at most 256 KB" }
            }
            require(manifest.id !in restartRequired) { "This plugin did not stop cleanly. Restart Kiosk Satellite before replacing it." }
            val previous = records.optJSONObject(manifest.id)
            // Keep only settings and list row fields still declared by the new version. Reject changed types.
            val config = manifest.config(manifest.kept(previous?.optJSONObject("config") ?: JSONObject()))
            val target = File(root, hash)
            val reuse = target.exists() && hash in loadedHashes
            if (target.exists()) {
                require(previous?.optString("hash") != hash) { "This package is already installed" }
                if (reuse) {
                    // Never rewrite files that a class loader may still reference.
                    for (file in staging.walkTopDown().filter { it.isFile }) {
                        require(File(target, file.relativeTo(staging).path).readBytes().contentEquals(file.readBytes())) {
                            "Previously loaded package failed its integrity check. Restart Kiosk Satellite before reinstalling it."
                        }
                    }
                } else {
                    check(target.deleteRecursively()) { "Cannot remove unused package" }
                }
            }
            if (!reuse) check(staging.renameTo(target)) { "Cannot install plugin package" }
            val wasEnabled = previous?.optBoolean("enabled") == true
            val wasRunning = sessions.containsKey(manifest.id)
            val record = JSONObject().put("hash", hash).put("enabled", wasEnabled)
                .put("config", JSONObject(config)).put("error", "").put("source", source)
                .put("actionOptions", PluginActionOptions.retain(manifest, previous?.optJSONObject("actionOptions")))
                .put("jarSha256", PluginPackage.sha256(File(target, "plugin.jar").readBytes()))
                .put("manifestSha256", PluginPackage.sha256(File(target, PluginPackage.MANIFEST_NAME).readBytes()))
            val nativeDigests = JSONObject()
            for (file in PluginPackage.nativeFiles(target)) nativeDigests.put(file.relativeTo(target).invariantSeparatorsPath, PluginPackage.sha256(file.readBytes()))
            record.put("nativeSha256", nativeDigests)
            val assetDigests = JSONObject()
            for (file in PluginPackage.assetFiles(target)) assetDigests.put(file.relativeTo(target.canonicalFile).invariantSeparatorsPath, PluginPackage.sha256(file.readBytes()))
            record.put("assetSha256", assetDigests)
            var committed = false
            try {
                // Validate and prepare the replacement before interrupting the active plugin.
                if (wasRunning) {
                    try { stopSession(manifest.id) } catch (error: Throwable) {
                        previous!!.put("enabled", false).put("error", "Update canceled because the plugin did not stop cleanly. Restart Kiosk Satellite before trying again.")
                        save()
                        throw IllegalStateException(previous.getString("error"), error)
                    }
                }
                records.put(manifest.id, record)
                try {
                    save()
                    if (wasEnabled && pluginsEnabled) enable(manifest.id)
                    committed = true
                } catch (error: Throwable) {
                    // Restore the previous package and settings if activation fails.
                    if (previous == null) records.remove(manifest.id) else {
                        previous.put("enabled", wasEnabled && manifest.id !in restartRequired)
                        records.put(manifest.id, previous)
                    }
                    save()
                    var recovery = "The previous version was retained."
                    if (previous != null && manifest.id in restartRequired) {
                        recovery = "The previous version was retained but is disabled. Restart Kiosk Satellite before enabling it."
                    } else if (wasRunning) {
                        try {
                            enable(manifest.id)
                            recovery = "The previous version is running again."
                        } catch (resumeError: Throwable) {
                            recovery = "The previous version could not restart: ${resumeError.message}"
                        }
                    }
                    val message = "Plugin update failed: ${error.message}. $recovery"
                    previous?.put("error", message)
                    save()
                    throw IllegalStateException(message, error)
                }
            } finally {
                if (!committed && !reuse && hash !in loadedHashes) target.deleteRecursively()
            }
            previous?.optString("hash")?.takeIf { it != hash && it !in loadedHashes }
                ?.let { File(root, it).deleteRecursively() }
            previous?.optString("hash")?.takeIf { it != hash }?.let { File(packages, "$it.zip").delete() }
            // A package that cannot be kept still installs: a fleet leader
            // then reports it cannot pass this plugin on.
            try { keepPackage(hash, bytes) } catch (_: Throwable) { File(packages, "$hash.zip").delete() }
            return snapshot()
        } finally { staging.deleteRecursively() }
    }

    private fun enable(id: String) {
        check(pluginsEnabled) { "Enable Plugins first" }
        check(id !in restartRequired) { "This plugin did not stop cleanly. Restart Kiosk Satellite before enabling it." }
        if (sessions.containsKey(id)) return
        val record = records.getJSONObject(id)
        var session: Session? = null
        try {
            val dir = directory(id)
            val jar = File(dir, "plugin.jar")
            require(PluginPackage.sha256(jar.readBytes()) == record.getString("jarSha256") &&
                PluginPackage.sha256(PluginPackage.installedManifest(dir).readBytes()) == record.getString("manifestSha256")) { "Installed plugin failed its integrity check. Reinstall it." }
            val manifest = manifest(id)
            require(manifest.minAndroidSdk <= Build.VERSION.SDK_INT) { "Android version is too old" }
            requireScreen(manifest)
            requireAppVersion(manifest)
            val config = manifest.config(record.optJSONObject("config") ?: JSONObject())
            check(jar.setReadOnly())
            val digests = record.optJSONObject("nativeSha256") ?: JSONObject()
            val nativeFiles = PluginPackage.nativeFiles(dir)
            require(nativeFiles.size == digests.length()) { "Installed native libraries failed their integrity check" }
            for (file in nativeFiles) require(PluginPackage.sha256(file.readBytes()) == digests.getString(file.relativeTo(dir).invariantSeparatorsPath)) { "Installed native library failed its integrity check" }
            PluginPackage.verifyAssets(dir, record.optJSONObject("assetSha256") ?: JSONObject())
            val current = Session(id, manifest, dir)
            session = current
            sessions[id] = current
            emit("hostSession", mapOf("id" to id, "session" to current.token, "capabilities" to manifest.capabilities.toList()), current.alive)
            // The choices kept from the last session show until the plugin lists new ones.
            if (current.setup.hasChoices()) current.notifySetup()
            loadedIds.add(id)
            loadedHashes.add(record.getString("hash"))
            if ("shizuku" in manifest.capabilities) shizuku.state()
            current.call {
                val optimized = File(context.codeCacheDir, "plugins/${record.getString("hash")}").apply { mkdirs() }
                val loader = DexClassLoader(jar.absolutePath, optimized.absolutePath, current.nativeDir.absolutePath, KioskPlugin::class.java.classLoader)
                current.loader = loader
                val plugin = loader.loadClass(manifest.entryClass).getDeclaredConstructor().newInstance() as KioskPlugin
                current.plugin = plugin
                plugin.start(current.host, Collections.unmodifiableMap(config))
            }
            record.put("enabled", true).put("error", "")
            save()
        } catch (error: Throwable) {
            session?.alive?.set(false)
            fail(id, error)
            throw error
        }
    }

    /**
     * On a device without a screen, a plugin that only shows overlays or
     * screensavers would run for nothing, so it neither installs nor starts.
     * This also turns away a fleet leader's push.
     */
    private fun requireScreen(manifest: PluginManifest) =
        require(!headless || !manifest.needsScreen) { "This plugin needs a screen" }

    private fun requireAppVersion(manifest: PluginManifest) {
        val required = manifest.minAppVersion ?: return
        require(PluginManifest.appVersionAtLeast(appVersion, required)) { "Plugin needs Kiosk Satellite $required or newer. This kiosk runs $appVersion." }
    }

    private fun stopSession(id: String) {
        val session = sessions.remove(id) ?: return
        session.alive.set(false)
        session.closeShizuku(); session.closeCharts(); session.closeStatusTiles(); session.triggers.close(); session.actionBudget.close(); session.closeEntities(); session.closeScreensavers(); session.overlays.close(); session.closeSetup()
        session.subscriptions.clear()
        endCamera(session, null, "closed", notifyApp = true)
        session.scan?.let { scan ->
            emit("barcodeCancel", mapOf("id" to id, "session" to session.token, "scan" to scan.id))
            finishScan(scan, false, null, "canceled")
        }
        emit("hostSessionClosed", mapOf("id" to id, "session" to session.token))
        emit("hideWindow", mapOf("id" to id))
        try { session.call { session.plugin?.stop() } }
        catch (error: Throwable) {
            restartRequired.add(id)
            throw error
        }
        finally {
            session.executor.shutdownNow()
            session.closeCameraThread()
        }
    }

    private fun fail(id: String, error: Throwable) {
        records.getJSONObject(id).put("enabled", false).put("error", error.message ?: error.javaClass.simpleName)
        try { save() } finally {
            try { stopSession(id) } catch (_: Throwable) { /* Host callbacks are already revoked. */ }
        }
    }

    private fun disable(id: String) {
        records.getJSONObject(id).put("enabled", false)
        save()
        try { stopSession(id) } catch (error: Throwable) { fail(id, error) }
    }

    private fun remove(id: String) {
        disable(id)
        val dir = directory(id)
        records.remove(id)
        save()
        File(packages, "${dir.name}.zip").delete()
        if (dir.name !in loadedHashes) dir.deleteRecursively()
        File(pluginData, id).deleteRecursively()
    }

    private fun keepPackage(hash: String, bytes: ByteArray) {
        val partial = File(packages, ".$hash.partial")
        partial.writeBytes(bytes)
        check(partial.renameTo(File(packages, "$hash.zip"))) { "Cannot keep the plugin package" }
    }

    private fun packageFile(id: String): File? =
        File(packages, "${records.getJSONObject(id).getString("hash")}.zip").takeIf { it.isFile }

    /**
     * What a fleet leader passes on for each plugin: the package hash and
     * source, whether it runs, its settings with the secrets in the clear
     * and where its actions show. Only the fleet sync reads this, never an
     * admin listing.
     */
    private fun fleetState(): List<Any?> = records.keys().asSequence().sorted().mapNotNull { id ->
        try {
            val record = records.getJSONObject(id)
            val manifest = manifest(id)
            mapOf(
                "id" to id,
                "name" to manifest.json.optString("name", id),
                "version" to manifest.json.optString("version"),
                "sha256" to record.getString("hash"),
                "source" to jsonValue(record.optJSONObject("source")),
                "enabled" to record.optBoolean("enabled"),
                "config" to jsonValue(record.optJSONObject("config") ?: JSONObject()),
                "actionOptions" to jsonValue(record.optJSONObject("actionOptions") ?: JSONObject()),
                "secretKeys" to manifest.secretKeys.sorted(),
                "kept" to (packageFile(id) != null),
            )
        } catch (_: Throwable) {
            null
        }
    }.toList()

    /**
     * Takes what the fleet leader holds for one plugin: its settings, where
     * its actions show and whether it runs. A secret the leader did not
     * send keeps this kiosk's own value. Whether plugins run at all stays
     * this kiosk's choice: with Enable Plugins off the plugin is marked
     * enabled and starts once it is switched on.
     */
    private fun fleetConfigure(id: String, args: Map<String, Any?>) {
        val manifest = manifest(id)
        val record = records.getJSONObject(id)
        val saved = record.optJSONObject("config") ?: JSONObject()
        val incoming = JSONObject(args["config"] as? Map<*, *> ?: throw IllegalArgumentException("Missing settings"))
        for (key in manifest.secretKeys) {
            if (incoming.has(key)) continue
            if (saved.has(key)) incoming.put(key, saved.get(key))
        }
        val config = manifest.config(incoming)
        val options = JSONObject()
        (args["actionOptions"] as? Map<*, *>)?.forEach { (command, value) ->
            if (command is String && manifest.hasCommand(command) && value is Map<*, *>) {
                options.put(command, JSONObject()
                    .put("drawer", value["drawer"] == true).put("homeAssistant", value["homeAssistant"] == true))
            }
        }
        val enabled = args["enabled"] as? Boolean ?: throw IllegalArgumentException("Missing enabled flag")
        val next = JSONObject(config)
        if (next.toString() != saved.toString()) {
            sessions[id]?.let { session ->
                try { session.call { session.plugin!!.configure(Collections.unmodifiableMap(config)) } }
                catch (error: Throwable) { fail(id, error); throw error }
            }
        }
        record.put("config", next).put("actionOptions", options)
        save()
        val wasEnabled = record.optBoolean("enabled")
        when {
            enabled && !wasEnabled && pluginsEnabled -> enable(id)
            enabled && !wasEnabled -> { record.put("enabled", true).put("error", ""); save() }
            !enabled && wasEnabled -> disable(id)
        }
    }

    /**
     * Saves settings from an admin page. With patch, [args] holds only the
     * settings that changed and the rest keep their saved values, so an edit
     * never writes back a value the plugin changed in the meantime.
     */
    private fun configure(id: String, args: Map<String, Any?>) {
        val values = args["values"] as? Map<*, *> ?: throw IllegalArgumentException("Missing settings")
        val manifest = manifest(id)
        val saved = records.getJSONObject(id).optJSONObject("config") ?: JSONObject()
        val unmasked = manifest.unmasked(JSONObject(values), saved)
        val config = manifest.config(if (args["patch"] == true) manifest.merged(saved, unmasked) else unmasked)
        sessions[id]?.let { session ->
            try { session.call { session.plugin!!.configure(Collections.unmodifiableMap(config)) } }
            catch (error: Throwable) { fail(id, error); throw error }
        }
        records.getJSONObject(id).put("config", JSONObject(config))
        save()
    }

    private fun configureAction(id: String, args: Map<String, Any?>) {
        val record = records.getJSONObject(id)
        val options = PluginActionOptions.configure(manifest(id), record.optJSONObject("actionOptions"), args)
        record.put("actionOptions", options)
        save()
    }

    private fun execute(id: String, args: Map<String, Any?>) {
        check(pluginsEnabled) { "Enable Plugins first" }
        val session = sessions[id] ?: throw IllegalStateException("Enable the plugin first")
        val command = args["command"] as? String ?: throw IllegalArgumentException("Missing command")
        require(session.manifest.hasCommand(command)) { "Unknown plugin command" }
        try { session.call { session.plugin!!.execute(command, emptyMap()) } }
        catch (error: Throwable) { fail(id, error); throw error }
    }

    /**
     * Starts a settings button or a choices refresh. The plugin hears
     * settings.button {id, run} or settings.choices {key, run} and answers
     * through setupResult. A run still going on the same target is replaced.
     */
    private fun setupRun(id: String, args: Map<String, Any?>): Map<String, Any?> {
        check(pluginsEnabled) { "Enable Plugins first" }
        val session = sessions[id] ?: throw IllegalStateException("Enable the plugin first")
        val manifest = session.manifest
        val key = args["key"] as? String ?: throw IllegalArgumentException("Missing setup target")
        val config = records.getJSONObject(id).optJSONObject("config") ?: JSONObject()
        val (target, event, field) = when (args["target"]) {
            "button" -> {
                require(manifest.buttonVisible(key, config)) { "Unknown or hidden button" }
                Triple("button:$key", "settings.button", "id")
            }
            "choices" -> {
                require(manifest.choicesVisible(key, config)) { "Unknown or hidden choices setting" }
                require(session.setup.choicesEnabled(key)) { "The plugin turned this choice off" }
                Triple("choices:$key", "settings.choices", "key")
            }
            else -> throw IllegalArgumentException("Unknown setup target")
        }
        val (run, replaced) = session.setup.start(target, args["origin"] as? String ?: "remote", SystemClock.elapsedRealtime())
        session.notifySetup()
        session.watchSetup()
        replaced?.let { deliverSetup(session, "settings.cancel", mapOf("run" to it.run, "reason" to it.reason)) }
        try { session.call { session.plugin!!.onEvent(event, mapOf(field to key, "run" to run.id)) } }
        catch (error: Throwable) { fail(id, error); throw error }
        return mapOf("run" to run.id)
    }

    private fun setupCancel(id: String, args: Map<String, Any?>) {
        val session = sessions[id] ?: return
        val run = args["run"] as? String ?: throw IllegalArgumentException("Missing run")
        if (!session.setup.cancel(run)) return
        session.notifySetup()
        deliverSetup(session, "settings.cancel", mapOf("run" to run, "reason" to "canceled"))
    }

    private fun setupConfirm(id: String, args: Map<String, Any?>) {
        val session = sessions[id] ?: return
        val run = args["run"] as? String ?: throw IllegalArgumentException("Missing run")
        if (!session.setup.answer(run, SystemClock.elapsedRealtime())) return
        session.notifySetup()
        deliverSetup(session, "settings.confirm", mapOf("run" to run, "accepted" to (args["accepted"] == true)))
    }

    /**
     * The app saw the plugin's settings page open or close. The plugin hears
     * settings.page {open} once per change, and a session that starts while
     * the page is open hears it open.
     */
    private fun settingsPage(args: Map<String, Any?>) {
        val session = (args["id"] as? String)?.let { sessions[it] } ?: return
        val open = args["open"] == true
        if (session.settingsPageOpen == open) return
        session.settingsPageOpen = open
        deliverSetup(session, "settings.page", mapOf("open" to open))
    }

    /** Tells the plugin about its run. A plugin that throws is stopped like any failed callback. */
    private fun deliverSetup(session: Session, event: String, payload: Map<String, Any?>) {
        if (!session.alive.get() || sessions[session.id] !== session) return
        try { session.call { session.plugin!!.onEvent(event, payload) } }
        catch (error: Throwable) { fail(session.id, error); emit("changed", snapshot()) }
    }

    private fun windowEvent(id: String, args: Map<String, Any?>) {
        val event = args["event"] as? String
        require(event == "window.action" || event == "window.closed") { "Unknown window event" }
        val session = sessions[id] ?: return
        try { session.call { session.plugin!!.onEvent(event, emptyMap()) } }
        catch (error: Throwable) { fail(id, error); throw error }
    }

    /** Back closed an overlay. Stale requests for a replaced overlay are ignored. */
    private fun overlayClosed(args: Map<String, Any?>) {
        val session = (args["id"] as? String)?.let { sessions[it] } ?: return
        val key = args["key"] as? String ?: return
        val generation = (args["generation"] as? Number)?.toInt() ?: return
        if (!session.alive.get() || session.token != args["session"] || !session.overlays.closed(key, generation)) return
        session.notifyOverlays()
        try { session.call { session.plugin!!.onEvent("overlay.closed", mapOf("key" to key)) } }
        catch (error: Throwable) { fail(session.id, error); emit("changed", snapshot()); throw error }
    }

    /**
     * A plugin's own threads and its overlay views run outside the
     * callbacks KS guards, so an exception there ends the process. Before
     * the crash goes on to the journal and Android, the plugin whose class
     * threw is switched off. Otherwise a broken overlay would crash the
     * kiosk again on every start.
     */
    private fun installCrashGuard() {
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            try {
                val loaders = sessions.values.mapNotNull { session -> session.loader?.let { session.id to it } }
                culprit(error, loaders)?.let { id ->
                    records.optJSONObject(id)?.put("enabled", false)
                        ?.put("error", "Disabled after it crashed Kiosk Satellite: ${error.message ?: error.javaClass.simpleName}")
                    prefs.edit().putString("installed", records.toString()).commit()
                }
            } catch (_: Throwable) {
                // Never mask the crash itself.
            }
            previous?.uncaughtException(thread, error)
        }
    }

    private val keysQueued = AtomicInteger()

    /**
     * Every press goes out on its own, never coalesced: a down and its up
     * are separate occurrences. A plugin too slow to keep up loses presses
     * past 16 queued, so a held key cannot pile up work on the worker.
     */
    private fun hardwareKey(event: KeyEvent) {
        if (event.action != KeyEvent.ACTION_DOWN && event.action != KeyEvent.ACTION_UP) return
        val time = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            .apply { timeZone = TimeZone.getTimeZone("UTC") }.format(Date())
        val payload = PluginHostPolicy.keyPayload(
            KeyEvent.keyCodeToString(event.keyCode), event.keyCode, event.scanCode,
            event.action == KeyEvent.ACTION_DOWN, event.repeatCount,
            event.isPrintingKey, KeyEvent.isModifierKey(event.keyCode), time
        ) ?: return
        if (keysQueued.incrementAndGet() > 16) { keysQueued.decrementAndGet(); return }
        worker.execute {
            try {
                sessions.values.toList().filter { it.alive.get() && "device.key" in it.subscriptions }.forEach { session ->
                    try { session.call { session.plugin?.onEvent("ks.device.key", payload) } }
                    catch (error: Throwable) { fail(session.id, error); emit("changed", snapshot()) }
                }
            } finally { keysQueued.decrementAndGet() }
        }
    }

    private fun emit(method: String, value: Any?, alive: AtomicBoolean? = null) {
        main.post { if (alive == null || alive.get()) channel.invokeMethod(method, value) }
    }
}
