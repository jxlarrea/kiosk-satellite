package me.jxl.kiosk_satellite

import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Base64
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import me.jxl.kiosk_satellite.btproxy.BluetoothProxyRuntime
import me.jxl.kiosk_satellite.btproxy.EspEntity
import me.jxl.kiosk_satellite.btproxy.EspService

/**
 * Flutter bridge for the Bluetooth proxy.
 *
 * Methods:
 *  - start {friendlyName, psk (base64, 32 bytes), port, projectVersion,
 *    nodeName, ...}: boots the runtime and answers with the node name it
 *    came up under. Idempotent. The process is kept alive for it by
 *    KioskSatelliteService, which the Dart side tells about the server
 *    through its reasons.
 *  - stop: tears it down. Idempotent.
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
                        val services =
                            (call.argument<List<Map<String, Any?>>>("services")
                                ?: emptyList()).map { EspService.fromMap(it) }
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
                                scanDuty = call.argument<String>("scanDuty")
                                    ?: "balanced",
                                entities = entities,
                                services = services,
                                macOverride = call.argument<String>("macOverride"),
                                nodeName = call.argument<String>("nodeName") ?: "",
                                webserverPort =
                                    call.argument<Int>("webserverPort") ?: 0,
                                // Session reader threads land here; the Dart
                                // side of the channel only exists on main.
                                onEntityCommand = { objectId, value ->
                                    mainHandler.post {
                                        channel.invokeMethod("entityCommand",
                                            mapOf("objectId" to objectId,
                                                "value" to value))
                                    }
                                },
                                onServiceCall = { name, args, reply ->
                                    mainHandler.post {
                                        // Dart answers with the action's
                                        // response data as a JSON string,
                                        // or null for none.
                                        channel.invokeMethod("serviceCall",
                                            mapOf("name" to name,
                                                "args" to args),
                                            object : MethodChannel.Result {
                                                override fun success(result: Any?) =
                                                    reply(true, null, result as? String)
                                                override fun error(
                                                    code: String,
                                                    message: String?,
                                                    details: Any?,
                                                ) = reply(false, message ?: code, null)
                                                override fun notImplemented() =
                                                    reply(false, "not implemented", null)
                                            })
                                    }
                                },
                            ),
                        )
                        // The name it came up under: the Dart side writes
                        // it back into settings, so the node name a user
                        // sees is the one on the wire.
                        result.success(BluetoothProxyRuntime.nodeName)
                    } catch (e: Exception) {
                        result.error("start_failed", e.message, null)
                    }
                }
                "stop" -> {
                    BluetoothProxyRuntime.stop()
                    result.success(null)
                }
                "scanDuty" -> {
                    BluetoothProxyRuntime.setScanDuty(call.argument<String>("duty"))
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
                "cameraImage" -> {
                    call.argument<ByteArray>("jpeg")?.let {
                        BluetoothProxyRuntime.publishCameraImage(
                            call.argument<String>("objectId") ?: "", it)
                    }
                    result.success(null)
                }
                // Whether the device's Bluetooth adapter is on: the settings
                // pages gray themselves out and say so while it is not,
                // whatever state the proxy itself is in.
                "adapterOn" -> result.success(
                    (context.getSystemService(Context.BLUETOOTH_SERVICE)
                        as? BluetoothManager)?.adapter?.isEnabled == true)
                "bleSupport" -> result.success(bleSupport())
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Whether this device can scan for Bluetooth LE at all, and why not
     * when it cannot. Android binds its GATT service only on builds that
     * declare the Bluetooth LE feature; without it every scan fails the
     * instant it starts with SCAN_FAILED_INTERNAL_ERROR, whatever the scan
     * settings, permissions or retries (issue #326, a Facebook Portal on
     * Android 9; the same missing declaration on a LineageOS Echo Show).
     * Nothing an app does changes that, so the Dart side keeps the proxy
     * switched off and the settings rows say why. The answer cannot change
     * without a reboot.
     */
    private fun bleSupport(): Map<String, Any?> {
        val adapter = (context.getSystemService(Context.BLUETOOTH_SERVICE)
            as? BluetoothManager)?.adapter
        val hint = when {
            adapter == null -> "Not available on this device: it has no Bluetooth."
            !context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE) ->
                "Not available on this device: its Android build has no " +
                    "Bluetooth LE support."
            else -> null
        }
        return mapOf("supported" to (hint == null), "hint" to hint)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        BluetoothProxyRuntime.stop()
    }
}
