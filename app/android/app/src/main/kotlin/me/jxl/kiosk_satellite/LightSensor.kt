package me.jxl.kiosk_satellite

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
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
 * is forwarded when the value moved at least 1 lx and 10% since the last one
 * sent, and at most every 2 seconds; the first reading always passes so the
 * entity is never blank. The 1 lx floor is what adaptive brightness needs
 * at the dark end of its curve, where 1 lx and 4 lx are different rooms.
 * Coarser rate limiting for the MQTT recorder lives on the Dart side.
 *
 * TYPE_LIGHT needs no permission on any Android version. Devices without the
 * sensor (several Fire tablets) answer hasSensor=false and never get a
 * stream, so the entity is simply absent rather than dead.
 *
 * Some devices (the Lenovo Smart Clock, issue #290) expose their light
 * sensor only through the dynamic sensor API: getDefaultSensor returns null
 * while getDynamicSensorList carries a working TYPE_LIGHT sensor. The
 * default sensor is preferred; a dynamic one is the fallback, and a
 * DynamicSensorCallback re-attaches the stream when a dynamic sensor comes
 * or goes while it is live.
 */
class LightSensor(context: Context, messenger: BinaryMessenger) {
    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    private val methods = MethodChannel(messenger, "kiosk_satellite/light_sensor")
    private val events = EventChannel(messenger, "kiosk_satellite/light_sensor_stream")

    private var sensor: Sensor? = null
    private var listener: SensorEventListener? = null
    private var sink: EventChannel.EventSink? = null
    private var lastSent = -1f
    private var lastSentAt = 0L
    private val handler = Handler(Looper.getMainLooper())

    /** Set by the first delivered sample; the register nudge stops on it. */
    @Volatile private var receivedAny = false

    /** The default TYPE_LIGHT sensor, else the first dynamic one. */
    private fun findSensor(): Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)
            ?: sensorManager.getDynamicSensorList(Sensor.TYPE_LIGHT).firstOrNull()

    // Delivered on [handler] (the main looper), same thread as the channel
    // callbacks, so sensor/listener/sink need no locking.
    private val dynamicCallback = object : SensorManager.DynamicSensorCallback() {
        override fun onDynamicSensorConnected(connected: Sensor) {
            if (connected.type != Sensor.TYPE_LIGHT) return
            if (sensor != null) return
            reattach()
        }

        override fun onDynamicSensorDisconnected(disconnected: Sensor) {
            if (disconnected !== sensor) return
            listener?.let { sensorManager.unregisterListener(it) }
            listener = null
            sensor = null
            reattach()
        }
    }

    /** Point a live stream at whatever light sensor exists now, if any. */
    private fun reattach() {
        val target = sink ?: return
        val s = findSensor() ?: return
        attach(s, target)
    }

    private fun attach(s: Sensor, sink: EventChannel.EventSink) {
        listener?.let { sensorManager.unregisterListener(it) }
        sensor = s
        lastSent = -1f
        receivedAny = false
        val l = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val lux = event.values.firstOrNull() ?: return
                receivedAny = true
                val now = SystemClock.elapsedRealtime()
                if (lastSent >= 0) {
                    val delta = abs(lux - lastSent)
                    if (now - lastSentAt < 2000 ||
                        delta < 1f || delta < lastSent * 0.1f) {
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
        // On-change sensors owe one sample at registration, but some
        // drivers (the Echo Show's amazon-oss one) lose it when the
        // register races boot. In a room where the light then never
        // changes, that silence lasts until morning and the entity
        // sits on "unknown". Re-registering coerces the initial
        // sample; give the driver a few chances, then leave it to
        // the first genuine change.
        fun nudge(remaining: Int) {
            handler.postDelayed({
                if (receivedAny || listener !== l) return@postDelayed
                sensorManager.unregisterListener(l)
                sensorManager.registerListener(
                    l, s, SensorManager.SENSOR_DELAY_NORMAL)
                if (remaining > 1) nudge(remaining - 1)
            }, 4_000)
        }
        nudge(3)
    }

    init {
        sensorManager.registerDynamicSensorCallback(dynamicCallback, handler)
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSensor" -> result.success(findSensor() != null)
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                this@LightSensor.sink = sink
                val s = findSensor()
                if (s == null) {
                    // A dynamic sensor answered hasSensor and has since
                    // gone away. Keep the stream open rather than ending
                    // it; dynamicCallback attaches when one returns.
                    sensor = null
                    return
                }
                attach(s, sink)
            }

            override fun onCancel(args: Any?) {
                listener?.let { sensorManager.unregisterListener(it) }
                listener = null
                sensor = null
                sink = null
                lastSent = -1f
            }
        })
    }

    fun dispose() {
        sink = null
        listener?.let { sensorManager.unregisterListener(it) }
        listener = null
        sensorManager.unregisterDynamicSensorCallback(dynamicCallback)
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }
}
