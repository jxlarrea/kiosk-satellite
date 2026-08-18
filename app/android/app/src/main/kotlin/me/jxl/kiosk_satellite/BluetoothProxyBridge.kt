package me.jxl.kiosk_satellite

import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Base64
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import me.jxl.kiosk_satellite.btproxy.BluetoothProxyRuntime
import me.jxl.kiosk_satellite.btproxy.EspEntity

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
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    try {
                        val psk = Base64.decode(
                            call.argument<String>("psk") ?: "", Base64.DEFAULT)
                        require(psk.size == 32) { "psk must decode to 32 bytes" }
                        val entities =
                            (call.argument<List<Map<String, Any?>>>("entities")
                                ?: emptyList()).map { EspEntity.fromMap(it) }
                        BluetoothProxyRuntime.start(
                            context,
                            BluetoothProxyRuntime.Config(
                                friendlyName = call.argument<String>("friendlyName")
                                    ?: "Kiosk Satellite",
                                psk = psk,
                                port = call.argument<Int>("port") ?: 6053,
                                projectVersion = call.argument<String>("projectVersion") ?: "0",
                                bluetoothProxy =
                                    call.argument<Boolean>("bluetoothProxy") ?: true,
                                connections = call.argument<Boolean>("connections") ?: false,
                                minConnectRssi =
                                    call.argument<Int>("minConnectRssi") ?: 0,
                                entities = entities,
                                // Session reader threads land here; the Dart
                                // side of the channel only exists on main.
                                onEntityCommand = { objectId, value ->
                                    mainHandler.post {
                                        channel.invokeMethod("entityCommand",
                                            mapOf("objectId" to objectId,
                                                "value" to value))
                                    }
                                },
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
                "entityState" -> {
                    BluetoothProxyRuntime.updateEntityState(
                        call.argument<String>("objectId") ?: "",
                        call.argument<Any?>("value"))
                    result.success(null)
                }
                // Whether the device's Bluetooth adapter is on: the settings
                // pages gray themselves out and say so while it is not,
                // whatever state the proxy itself is in.
                "adapterOn" -> result.success(
                    (context.getSystemService(Context.BLUETOOTH_SERVICE)
                        as? BluetoothManager)?.adapter?.isEnabled == true)
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
