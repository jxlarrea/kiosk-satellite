package me.jxl.kiosk_satellite

import android.content.Context
import android.util.Base64
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import me.jxl.kiosk_satellite.btproxy.BluetoothProxyRuntime

/**
 * Flutter bridge for the Bluetooth proxy.
 *
 * Methods:
 *  - start {friendlyName, psk (base64, 32 bytes), port, projectVersion}:
 *    boots the runtime and its foreground service. Idempotent.
 *  - stop: tears both down. Idempotent.
 *  - status: runtime counters and recent log lines for diagnostics.
 *
 * The Dart manager owns policy (the enable setting, PSK generation, restart
 * on settings change); this bridge only executes. Registered in
 * KioskApplication so the proxy keeps running with no Activity attached.
 */
class BluetoothProxyBridge(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/bluetooth_proxy")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    try {
                        val psk = Base64.decode(
                            call.argument<String>("psk") ?: "", Base64.DEFAULT)
                        require(psk.size == 32) { "psk must decode to 32 bytes" }
                        BluetoothProxyRuntime.start(
                            context,
                            BluetoothProxyRuntime.Config(
                                friendlyName = call.argument<String>("friendlyName")
                                    ?: "Kiosk Satellite",
                                psk = psk,
                                port = call.argument<Int>("port") ?: 6053,
                                projectVersion = call.argument<String>("projectVersion") ?: "0",
                                connections = call.argument<Boolean>("connections") ?: false,
                            ),
                        )
                        BluetoothProxyService.start(context)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("start_failed", e.message, null)
                    }
                }
                "stop" -> {
                    BluetoothProxyRuntime.stop()
                    BluetoothProxyService.stop(context)
                    result.success(null)
                }
                "status" -> result.success(BluetoothProxyRuntime.status())
                "nearby" -> result.success(BluetoothProxyRuntime.nearbyDevices())
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        BluetoothProxyRuntime.stop()
        BluetoothProxyService.stop(context)
    }
}
