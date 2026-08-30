package me.jxl.kiosk_satellite

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * The GPS receiver as a stream of fixes, so a kiosk that travels (a tablet
 * in an RV, issue #363) can tell Home Assistant where it is.
 *
 * `support` says whether the device has a receiver at all and why not
 * when it has none: kiosk-class tablets mostly ship without one, and the
 * settings switch renders disabled with the reason there. `last` is the
 * receiver's last known fix, so the entities have a position the moment
 * the stream starts rather than after the first cold fix. The stream
 * itself asks the GPS provider (never the network one: the point is the
 * receiver, and a Wi-Fi guess in a moving vehicle is worse than nothing)
 * for a fix every `intervalMs`, and forwards each one as a map.
 *
 * Both need the fine location permission: without it the stream fails at
 * once with `denied` and the Dart side says so under the switch. A
 * receiver switched off in the device settings takes the request and
 * delivers nothing until it is on; the Dart side reads that state from the
 * permission rows.
 */
class LocationSensor(private val context: Context, messenger: BinaryMessenger) {
    private val locationManager =
        context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    private val methods = MethodChannel(messenger, "kiosk_satellite/location")
    private val events = EventChannel(messenger, "kiosk_satellite/location_stream")

    private var listener: LocationListener? = null

    private fun hasReceiver(): Boolean =
        context.packageManager.hasSystemFeature(PackageManager.FEATURE_LOCATION_GPS) ||
            locationManager.allProviders.contains(LocationManager.GPS_PROVIDER)

    private fun support(): Map<String, Any?> =
        if (hasReceiver()) {
            mapOf("supported" to true)
        } else {
            mapOf(
                "supported" to false,
                "hint" to "Not available on this device: it has no GPS receiver.",
            )
        }

    private fun granted(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    private fun encode(l: Location): Map<String, Any?> = mapOf(
        "latitude" to l.latitude,
        "longitude" to l.longitude,
        "time" to l.time,
        "accuracy" to if (l.hasAccuracy()) l.accuracy.toDouble() else null,
        "altitude" to if (l.hasAltitude()) l.altitude else null,
        "speed" to if (l.hasSpeed()) l.speed.toDouble() else null,
        "provider" to l.provider,
    )

    /** The receiver's last fix, null without one or without the grant. */
    private fun last(): Map<String, Any?>? = try {
        if (!granted() || !hasReceiver()) null
        else locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)?.let(::encode)
    } catch (_: Exception) {
        null
    }

    init {
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "support" -> result.success(support())
                "last" -> result.success(last())
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                if (!hasReceiver()) {
                    sink.error("absent", "no GPS receiver", null)
                    return
                }
                if (!granted()) {
                    sink.error("denied", "location permission not granted", null)
                    return
                }
                detach()
                val interval = ((args as? Map<*, *>)?.get("intervalMs") as? Number)
                    ?.toLong()?.coerceAtLeast(1000L) ?: 60_000L
                val l = object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        sink.success(encode(location))
                    }

                    // The three below are abstract on Android 9 and older.
                    @Deprecated("Deprecated in Java")
                    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                    override fun onProviderEnabled(provider: String) {}
                    override fun onProviderDisabled(provider: String) {}
                }
                try {
                    locationManager.requestLocationUpdates(
                        LocationManager.GPS_PROVIDER, interval, 0f, l, Looper.getMainLooper(),
                    )
                    listener = l
                } catch (e: SecurityException) {
                    sink.error("denied", e.message ?: "location permission not granted", null)
                } catch (e: Exception) {
                    sink.error("failed", e.message ?: e.javaClass.simpleName, null)
                }
            }

            override fun onCancel(args: Any?) = detach()
        })
    }

    private fun detach() {
        listener?.let { locationManager.removeUpdates(it) }
        listener = null
    }
}
