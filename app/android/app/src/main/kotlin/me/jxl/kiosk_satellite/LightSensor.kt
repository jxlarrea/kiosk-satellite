package me.jxl.kiosk_satellite

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

/**
 * The ambient light sensor as a stream of lux values, so Home Assistant can
 * automate screen brightness from the light in the room.
 *
 * Damped at the source: a light sensor fires on every flicker and passing
 * shadow, and each event crossing the platform channel wakes Dart. An event
 * is forwarded when the value moved at least 5 lx and 10% since the last one
 * sent, and at most every 2 seconds; the first reading always passes so the
 * entity is never blank. Coarser rate limiting for the MQTT recorder lives on
 * the Dart side.
 *
 * TYPE_LIGHT needs no permission on any Android version. Devices without the
 * sensor (several Fire tablets) answer hasSensor=false and never get a
 * stream, so the entity is simply absent rather than dead.
 */
class LightSensor(context: Context, messenger: BinaryMessenger) {
    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val sensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)

    private val methods = MethodChannel(messenger, "kiosk_satellite/light_sensor")
    private val events = EventChannel(messenger, "kiosk_satellite/light_sensor_stream")

    private var listener: SensorEventListener? = null
    private var lastSent = -1f
    private var lastSentAt = 0L

    init {
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSensor" -> result.success(sensor != null)
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                val s = sensor
                if (s == null) {
                    sink.endOfStream()
                    return
                }
                val l = object : SensorEventListener {
                    override fun onSensorChanged(event: SensorEvent) {
                        val lux = event.values.firstOrNull() ?: return
                        val now = SystemClock.elapsedRealtime()
                        if (lastSent >= 0) {
                            val delta = abs(lux - lastSent)
                            if (now - lastSentAt < 2000 ||
                                delta < 5f || delta < lastSent * 0.1f) {
                                return
                            }
                        }
                        lastSent = lux
                        lastSentAt = now
                        sink.success(lux.toDouble())
                    }

                    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                }
                listener = l
                sensorManager.registerListener(
                    l, s, SensorManager.SENSOR_DELAY_NORMAL)
            }

            override fun onCancel(args: Any?) {
                listener?.let { sensorManager.unregisterListener(it) }
                listener = null
                lastSent = -1f
            }
        })
    }

    fun dispose() {
        listener?.let { sensorManager.unregisterListener(it) }
        listener = null
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }
}
