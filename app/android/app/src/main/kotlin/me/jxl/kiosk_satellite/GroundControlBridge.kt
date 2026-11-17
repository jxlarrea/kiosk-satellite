package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import me.jxl.kiosk_satellite.sendspin.discovery.NsdDiscoveryManager

/**
 * Finds Kiosk Satellite Ground Control on the network: the service advertises
 * `_ks-groundctl._tcp` over mDNS (its TXT record carries the version,
 * the speaker model and the API path).
 *
 * Methods: start, stop. Both idempotent.
 * The stream carries {event: found|lost, name, host, port, path}. The Dart
 * manager picks a service and owns the connection; this bridge only looks.
 * Registered in KioskApplication so it runs with no Activity attached.
 */
class GroundControlBridge(context: Context, messenger: BinaryMessenger) {
    private val methods = MethodChannel(messenger, "kiosk_satellite/ground_control")
    private val events = EventChannel(messenger, "kiosk_satellite/ground_control_stream")
    private val mainHandler = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private var running = false

    private val discovery = NsdDiscoveryManager(context, object : NsdDiscoveryManager.DiscoveryListener {
        override fun onServerDiscovered(name: String, host: String, port: Int, path: String, friendlyName: String) {
            post(mapOf("event" to "found", "name" to name, "host" to host, "port" to port, "path" to path))
        }

        override fun onServerLost(name: String) {
            post(mapOf("event" to "lost", "name" to name))
        }

        override fun onDiscoveryStarted() {}
        override fun onDiscoveryStopped() {}
        override fun onDiscoveryError(error: String) {
            post(mapOf("event" to "error", "message" to error))
        }
    }, SERVICE_TYPE)

    init {
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    if (!running) {
                        running = true
                        discovery.startDiscovery()
                    }
                    result.success(null)
                }
                "stop" -> {
                    if (running) {
                        running = false
                        discovery.stopDiscovery()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                sink = events
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
    }

    private fun post(event: Map<String, Any?>) {
        mainHandler.post { sink?.success(event) }
    }

    companion object {
        const val SERVICE_TYPE = "_ks-groundctl._tcp."
    }
}
