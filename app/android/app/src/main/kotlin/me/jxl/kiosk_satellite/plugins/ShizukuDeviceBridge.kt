package me.jxl.kiosk_satellite.plugins

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** Device actions share the Shizuku connection but never belong to a plugin session. */
internal class ShizukuDeviceBridge(private val context: Context, messenger: BinaryMessenger, private val access: () -> PluginShizuku) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/shizuku")
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor { task -> Thread(task, "shizuku-device").apply { isDaemon = true } }
    private val busy = AtomicBoolean(false)
    fun changed(state: Map<String, Any>) { main.post { channel.invokeMethod("state", state) } }
    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "state" -> result.success(access().state())
                    "requestPermission" -> { access().requestPermission(); result.success(access().state()) }
                    "runAction" -> {
                        val args = call.arguments as? Map<*, *> ?: error("Missing action")
                        val action = args["action"] as? String ?: error("Missing action")
                        val permissions = if (action == "grantAll") {
                            val raw = args["permissions"] as? List<*> ?: error("Missing permissions")
                            require(raw.size <= 12 && raw.all { it is String })
                            raw.filterIsInstance<String>().distinct()
                        } else if (action == "identity") emptyList() else listOf(action)
                        val plan = permissions.associateWith { ShizukuPermissionPlan.commands(it, Build.VERSION.SDK_INT, context.packageName) }
                        check(busy.compareAndSet(false, true)) { "A Shizuku device action is already running" }
                        worker.execute {
                            val client = access().client()
                            try {
                                check(access().state()["granted"] == true) { "Grant Shizuku access first" }
                                fun execute(command: Array<String>): Map<String, Any> {
                                    val done = CountDownLatch(1)
                                    var data: Map<String, Any>? = null
                                    var failure: String? = null
                                    client.execute(command, 3000) { ok, value, error -> data = if (ok) value else null; failure = error; done.countDown() }
                                    check(done.await(11, TimeUnit.SECONDS)) { "Shizuku command did not respond" }
                                    val value = data ?: error(failure ?: "Shizuku command failed")
                                    Thread.sleep(260)
                                    return value
                                }
                                val response = if (action == "identity") execute(arrayOf("/system/bin/id")) else {
                                    val results = plan.map { (key, commands) ->
                                        var error: String? = null
                                        try {
                                            fun checked(command: Array<String>): Map<String, Any> {
                                                val value = execute(command)
                                                check(value["exitCode"] == 0 && value["timedOut"] != true) {
                                                    if (value["timedOut"] == true) "Command timed out" else (value["stderr"] as? String)?.trim()?.take(300).orEmpty().ifEmpty { "Android rejected the request" }
                                                }
                                                return value
                                            }
                                            if (key == "uiGuard") {
                                                val current = checked(commands.single())
                                                check(current["truncated"] != true) { "Cannot safely read existing accessibility services" }
                                                for (command in ShizukuPermissionPlan.enableUiGuard(context.packageName, current["stdout"] as String)) checked(command)
                                            } else {
                                                for (command in commands) checked(command)
                                            }
                                        } catch (failure: Exception) {
                                            error = failure.message ?: "Android rejected the request"
                                        }
                                        mapOf("key" to key, "ok" to (error == null), "error" to error)
                                    }
                                    mapOf("results" to results)
                                }
                                main.post { result.success(response) }
                            } catch (error: Exception) { main.post { result.error("shizuku_error", error.message, null) } }
                            finally { client.close(); busy.set(false) }
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) { result.error("shizuku_error", error.message, null) }
        }
    }
}
