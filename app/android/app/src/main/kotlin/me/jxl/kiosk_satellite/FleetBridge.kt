package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import me.jxl.kiosk_satellite.fleet.FleetDiscovery

/**
 * Flutter bridge for the fleet discovery (the other kiosks on the network,
 * for the remote admin's kiosk switcher).
 *
 * Methods:
 *  - start {name, port, hostname, fleet}: announces this kiosk and, with
 *    `fleet` on, listens for the others. `hostname` is the label this
 *    kiosk answers to as `<hostname>.local`, empty for none. Idempotent;
 *    a changed name, port or hostname goes out at once. Whether the mDNS
 *    port could be had comes with the snapshots, once known.
 *  - stop: says goodbye and stops listening. Idempotent.
 *  - snapshot: this kiosk as announced plus every peer heard.
 *  - nudge: re-announce and ask again, after a network change.
 *
 * The stream carries the same snapshot every time the set of peers
 * changes. The Dart manager owns the policy (the remote admin's switch and
 * the discovery switch); this bridge only executes. Registered in
 * KioskApplication so discovery runs with no Activity attached.
 */
class FleetBridge(context: Context, messenger: BinaryMessenger) {
    private val methods = MethodChannel(messenger, "kiosk_satellite/fleet")
    private val events = EventChannel(messenger, "kiosk_satellite/fleet_stream")
    private val mainHandler = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null

    private val discovery = FleetDiscovery(context) { snapshot ->
        mainHandler.post { sink?.success(snapshot.toMap()) }
    }

    init {
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    discovery.start(
                        name = call.argument<String>("name") ?: "",
                        port = call.argument<Int>("port") ?: 2324,
                        hostname = call.argument<String>("hostname") ?: "",
                        fleet = call.argument<Boolean>("fleet") ?: true,
                    )
                    result.success(null)
                }
                "stop" -> { discovery.stop(); result.success(null) }
                "snapshot" -> result.success(discovery.snapshot().toMap())
                "nudge" -> { discovery.nudge(); result.success(null) }
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, s: EventChannel.EventSink) {
                sink = s
                s.success(discovery.snapshot().toMap())
            }

            override fun onCancel(args: Any?) { sink = null }
        })
    }
}
