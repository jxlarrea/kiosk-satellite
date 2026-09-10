package me.jxl.kiosk_satellite.plugins

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import dalvik.system.DexClassLoader
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Collections
import java.util.UUID
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import me.jxl.kiosk.plugins.KioskPlugin
import me.jxl.kiosk.plugins.PluginHost
import org.json.JSONObject

/** Process-owned runtime for explicitly installed, trusted SDK 1 plugins. */
class PluginBridge(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/plugins")
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor { task -> Thread(task, "plugin-manager").apply { isDaemon = true } }
    private val prefs = context.getSharedPreferences("kiosk_plugins", Context.MODE_PRIVATE)
    private val root = File(context.filesDir, "plugins-v1").apply { mkdirs() }
    private var records = JSONObject(prefs.getString("installed", "{}") ?: "{}")
    @Volatile private var pluginsEnabled = prefs.getBoolean("pluginsEnabled", records.length() > 0)
    private var startupGeneration = 0
    private val sessions = mutableMapOf<String, Session>()
    private val loadedIds = mutableSetOf<String>()
    private val loadedHashes = mutableSetOf<String>()
    private val restartRequired = mutableSetOf<String>()
    private var initialized = false

    private inner class Session(val id: String, val manifest: PluginManifest) {
        val alive = AtomicBoolean(true)
        val executor = Executors.newSingleThreadExecutor { task -> Thread(task, "plugin-$id").apply { isDaemon = true } }
        var plugin: KioskPlugin? = null
        val host = object : PluginHost {
            override fun showWindow(title: String, message: String, buttonLabel: String) {
                require("overlay" in manifest.capabilities) { "Plugin did not declare overlay access" }
                require(title.length in 1..80 && message.length <= 4096 && buttonLabel.length <= 80) { "Window text is too long" }
                emit("window", mapOf("id" to id, "title" to title, "message" to message, "buttonLabel" to buttonLabel), alive)
            }
            override fun hideWindow() = emit("hideWindow", mapOf("id" to id), alive)
            override fun log(message: String) = emit("log", mapOf("id" to id, "message" to message.take(1000)), alive)
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

    init {
        channel.setMethodCallHandler { call, result ->
            worker.execute {
                try {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                    val value: Any? = when (call.method) {
                        "initialize" -> { initialize(); snapshot() }
                        "list" -> snapshot()
                        "setEnabled" -> {
                            val enabled = args["enabled"] as? Boolean ?: throw IllegalArgumentException("Missing enabled flag")
                            setEnabled(enabled)
                            snapshot()
                        }
                        "validateManifest" -> {
                            try {
                                val manifest = PluginManifest(JSONObject(args["manifest"] as String))
                                require(manifest.minAndroidSdk <= Build.VERSION.SDK_INT) { "Plugin needs Android API ${manifest.minAndroidSdk}" }
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
                        "execute" -> { execute(id(args), args); snapshot() }
                        "windowEvent" -> { windowEvent(id(args), args); null }
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
                .put("values", record.optJSONObject("config") ?: JSONObject())
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
        // Existing installations keep running. New installations start with plugins off.
        if (!prefs.contains("pluginsEnabled")) {
            check(prefs.edit().putBoolean("pluginsEnabled", pluginsEnabled).commit())
        }
        if (!pluginsEnabled) {
            check(prefs.edit().putBoolean("startupPending", false).commit())
            return
        }
        val enabled = enabledIds()
        if (prefs.getBoolean("startupPending", false)) {
            for (id in enabled) records.getJSONObject(id).put("enabled", false)
                .put("error", "Disabled after an incomplete plugin startup. Enable it to try again.")
            save()
            prefs.edit().putBoolean("startupPending", false).commit()
            return
        }
        startEnabled()
    }

    private fun enabledIds(): List<String> = records.keys().asSequence()
        .filter { records.getJSONObject(it).optBoolean("enabled") }.toList()

    private fun startEnabled() {
        val enabled = enabledIds()
        if (enabled.isEmpty()) return
        val generation = ++startupGeneration
        check(prefs.edit().putBoolean("startupPending", true).commit())
        for (id in enabled) {
            try { enable(id) } catch (_: Throwable) { /* Failure is recorded by enable. */ }
        }
        main.postDelayed({ worker.execute {
            if (startupGeneration == generation) prefs.edit().putBoolean("startupPending", false).commit()
        } }, 30_000)
    }

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
                emit("hideWindow", mapOf("id" to id))
            }
            for (id in sessions.keys.toList()) {
                try { stopSession(id) } catch (error: Throwable) {
                    records.getJSONObject(id).put("error", error.message ?: error.javaClass.simpleName)
                }
            }
            save()
            check(prefs.edit().putBoolean("startupPending", false).commit())
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
            require(manifest.id !in restartRequired) { "This plugin did not stop cleanly. Restart Kiosk Satellite before replacing it." }
            require(records.has(manifest.id) || records.length() < 8) { "At most 8 plugins can be installed" }
            val previous = records.optJSONObject(manifest.id)
            // Keep only settings still declared by the new version. Reject changed types.
            val previousConfig = previous?.optJSONObject("config") ?: JSONObject()
            val overrides = JSONObject()
            for (i in 0 until manifest.settings.length()) {
                val key = manifest.settings.getJSONObject(i).getString("key")
                if (previousConfig.has(key)) overrides.put(key, previousConfig.get(key))
            }
            val config = manifest.config(overrides)
            val target = File(root, hash)
            val reuse = target.exists() && hash in loadedHashes
            if (target.exists()) {
                require(previous?.optString("hash") != hash) { "This package is already installed" }
                if (reuse) {
                    // Never rewrite files that a class loader may still reference.
                    for (file in staging.listFiles() ?: emptyArray()) {
                        require(File(target, file.name).readBytes().contentEquals(file.readBytes())) {
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
                .put("jarSha256", PluginPackage.sha256(File(target, "plugin.jar").readBytes()))
                .put("manifestSha256", PluginPackage.sha256(File(target, PluginPackage.MANIFEST_NAME).readBytes()))
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
            val config = manifest.config(record.optJSONObject("config") ?: JSONObject())
            check(jar.setReadOnly())
            val current = Session(id, manifest)
            session = current
            sessions[id] = current
            loadedIds.add(id)
            loadedHashes.add(record.getString("hash"))
            current.call {
                val optimized = File(context.codeCacheDir, "plugins/${record.getString("hash")}").apply { mkdirs() }
                val loader = DexClassLoader(jar.absolutePath, optimized.absolutePath, null, KioskPlugin::class.java.classLoader)
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

    private fun stopSession(id: String) {
        val session = sessions.remove(id) ?: return
        session.alive.set(false)
        emit("hideWindow", mapOf("id" to id))
        try { session.call { session.plugin?.stop() } }
        catch (error: Throwable) {
            restartRequired.add(id)
            throw error
        }
        finally { session.executor.shutdownNow() }
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
        if (dir.name !in loadedHashes) dir.deleteRecursively()
    }

    private fun configure(id: String, args: Map<String, Any?>) {
        val values = args["values"] as? Map<*, *> ?: throw IllegalArgumentException("Missing settings")
        val manifest = manifest(id)
        val config = manifest.config(JSONObject(values))
        sessions[id]?.let { session ->
            try { session.call { session.plugin!!.configure(Collections.unmodifiableMap(config)) } }
            catch (error: Throwable) { fail(id, error); throw error }
        }
        records.getJSONObject(id).put("config", JSONObject(config))
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

    private fun windowEvent(id: String, args: Map<String, Any?>) {
        val event = args["event"] as? String
        require(event == "window.action" || event == "window.closed") { "Unknown window event" }
        val session = sessions[id] ?: return
        try { session.call { session.plugin!!.onEvent(event, emptyMap()) } }
        catch (error: Throwable) { fail(id, error); throw error }
    }

    private fun emit(method: String, value: Any?, alive: AtomicBoolean? = null) {
        main.post { if (alive == null || alive.get()) channel.invokeMethod(method, value) }
    }
}
