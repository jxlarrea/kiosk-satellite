package me.jxl.kiosk_satellite.plugins

import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import rikka.shizuku.Shizuku
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** Permission belongs to KS. Helpers and outstanding requests belong to one plugin session. */
internal class PluginShizuku(private val context: Context, private val changed: (Map<String, Any>) -> Unit) {
    private val main = Handler(Looper.getMainLooper())
    private val clients = java.util.concurrent.ConcurrentHashMap.newKeySet<Client>()
    private val received = Shizuku.OnBinderReceivedListener { notifyState() }
    private val dead = Shizuku.OnBinderDeadListener { clients.forEach { it.disconnect() }; notifyState() }
    private val permission = Shizuku.OnRequestPermissionResultListener { code, _ -> if (code == REQUEST) notifyState() }
    init {
        Shizuku.addBinderReceivedListenerSticky(received, main)
        Shizuku.addBinderDeadListener(dead, main)
        Shizuku.addRequestPermissionResultListener(permission, main)
    }
    fun state(): Map<String, Any> {
        try {
            if (!Shizuku.pingBinder()) return mapOf("available" to false, "granted" to false, "status" to "unavailable")
            if (Shizuku.isPreV11() || Shizuku.getVersion() < 13) return mapOf("available" to true, "granted" to false, "status" to "unsupported")
            val granted = Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
            return mapOf("available" to true, "granted" to granted,
                "status" to if (granted) "ready" else if (Shizuku.shouldShowRequestPermissionRationale()) "denied" else "permission_required",
                "uid" to Shizuku.getUid(), "version" to Shizuku.getVersion())
        } catch (_: Exception) { return mapOf("available" to false, "granted" to false, "status" to "unavailable") }
    }
    private fun notifyState() {
        val value = state()
        if (value["granted"] != true) clients.forEach { it.disconnect() }
        changed(value)
    }
    fun requestPermission() {
        val value = state()
        check(value["status"] == "permission_required" || value["granted"] == true) { "Start Shizuku 13 or later and allow Kiosk Satellite in Shizuku" }
        if (value["granted"] != true) main.post { try { Shizuku.requestPermission(REQUEST) } catch (_: Exception) { notifyState() } }
    }
    fun client(): Client = Client().also { clients.add(it) }

    inner class Client {
        private val closed = AtomicBoolean(false)
        private val busy = AtomicBoolean(false)
        private val io = Executors.newSingleThreadExecutor { task -> Thread(task, "plugin-shizuku").apply { isDaemon = true } }
        private var helper: Helper? = null
        private var lastRequest = 0L
        fun execute(command: Array<String>, timeoutMs: Int, result: (Boolean, Map<String, Any>?, String?) -> Unit) {
            PluginShizukuCommand.validate(command, timeoutMs)
            check(!closed.get()) { "Shizuku session has ended" }
            check(busy.compareAndSet(false, true)) { "One Shizuku command may be pending per plugin" }
            val args = command.copyOf()
            synchronized(this) {
                val now = System.nanoTime()
                if (now - lastRequest < 250_000_000L) { busy.set(false); error("At most four Shizuku commands per second") }
                lastRequest = now
            }
            try { io.execute {
                var watchdog: Runnable? = null
                val completed = AtomicBoolean(false)
                fun finish(ok: Boolean, data: Map<String, Any>?, error: String?) {
                    if (!completed.compareAndSet(false, true)) return
                    watchdog?.let { main.removeCallbacks(it) }
                    busy.set(false)
                    if (!closed.get()) result(ok, data, error)
                }
                try {
                    check(state()["granted"] == true) { "Shizuku access is not granted. Open this plugin's Shizuku access row in Settings." }
                    val connection = synchronized(this) { check(!closed.get()) { "Shizuku session has ended" }; helper ?: Helper().also { helper = it } }
                    watchdog = Runnable { disconnect(); finish(false, null, "Shizuku command timed out") }
                    main.postDelayed(watchdog!!, timeoutMs.toLong() + 7000)
                    val service = connection.awaitService()
                    check(!closed.get()) { "Shizuku session has ended" }
                    val value = service.execute(args, timeoutMs)
                    val data = mapOf<String, Any>("exitCode" to value.getInt("exitCode"), "stdout" to (value.getString("stdout") ?: ""),
                        "stderr" to (value.getString("stderr") ?: ""), "timedOut" to value.getBoolean("timedOut"), "truncated" to value.getBoolean("truncated"))
                    if (value.getBoolean("timedOut")) disconnect()
                    finish(true, data, null)
                } catch (error: Exception) { disconnect(); finish(false, null, error.message ?: "Shizuku connection failed") }
            } } catch (error: Exception) { busy.set(false); throw error }
        }
        @Synchronized fun disconnect() { helper?.close(); helper = null }
        fun close() {
            if (!closed.compareAndSet(false, true)) return
            disconnect(); io.shutdownNow(); clients.remove(this)
        }
        private inner class Helper : ServiceConnection {
            private val stopped = AtomicBoolean(false)
            private val latch = CountDownLatch(1)
            @Volatile private var service: IPluginShizukuService? = null
            private val args = Shizuku.UserServiceArgs(ComponentName(context, PluginShizukuService::class.java))
                .tag("kiosk-plugin-${UUID.randomUUID()}").daemon(false).version(1).processNameSuffix("plugin_shizuku")
            init { main.post {
                if (!stopped.get()) try { Shizuku.bindUserService(args, this) } catch (_: Exception) { latch.countDown() }
            } }
            override fun onServiceConnected(name: ComponentName, binder: IBinder) {
                if (stopped.get()) { destroy(IPluginShizukuService.Stub.asInterface(binder)); return }
                service = IPluginShizukuService.Stub.asInterface(binder); latch.countDown()
            }
            override fun onServiceDisconnected(name: ComponentName) { service = null; latch.countDown(); synchronized(this@Client) { if (helper === this) helper = null } }
            fun awaitService(): IPluginShizukuService {
                check(latch.await(5, TimeUnit.SECONDS) && !stopped.get()) { "Shizuku helper did not connect" }
                return service ?: error("Shizuku helper is unavailable")
            }
            private fun remove() { try { Shizuku.unbindUserService(args, this, true) } catch (_: Exception) {} }
            private fun destroy(target: IPluginShizukuService?) {
                Thread({
                    try { target?.destroy() } catch (_: Exception) { /* The helper exits during this call. */ }
                    main.post { remove() }
                }, "plugin-shizuku-stop").apply { isDaemon = true; start() }
            }
            fun close() { stopped.set(true); latch.countDown(); val target = service; service = null; destroy(target) }
        }
    }
    companion object { private const val REQUEST = 7421 }
}
