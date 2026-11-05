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
import java.io.File
import java.util.Locale

/**
 * The proximity sensor as a stream of near/far transitions, so the
 * screensaver can wake (or hold off) when something comes close to the
 * panel without running the camera.
 *
 * `support` says whether the device has one at all and what it is called:
 * the name matters more here than for any other sensor. Kiosk-class
 * tablets mostly have none, and modern phones tend to expose a virtual
 * "palm" proximity sensor that only reacts to a hand on the screen during
 * a call, which never notices someone walking up. Both settings surfaces
 * show the name next to the switch so a person can tell the two apart.
 *
 * Android reports proximity as a distance in cm, but nearly every sensor
 * is binary: 0 for near and a positive value for far. Some drivers report
 * 1 for far even though their advertised maximum range is larger. When
 * the resolution spans the whole range, treat the readings as flags.
 * Sensors with finer resolution keep their distance-based near test.
 * Some panels (the NSPanel Pro) report raw reflected-light counts that
 * rise as something comes closer, far past the advertised range. See
 * [ProximityClassifier] for how those are read.
 * The NSPanel Pro's kernels differ by model (#1081): the 86P reports the
 * raw count, the 120P a 0/1 flag where 1 means near, and both advertise
 * the same range and resolution. Where a Rockchip Sensortek driver is
 * bound (see [findSensortekDriver]) the raw count is read from its sysfs
 * file instead, so every model goes through the same raw-count path, and
 * the sensor stays registered only to keep the driver polling.
 * The Lenovo Smart Clock reports raw counts in its own events (#1315), so
 * it is matched by name instead (see [isRawCountSensor]).
 * Each event carries the raw reading so the log shows a sensor's shape.
 * The first sample after registering is the resting state (flagged
 * `initial`), not an approach: something resting on the sensor must not
 * wake the screensaver every time it starts.
 *
 * Diagnostics ride the same stream as `diagnostic` events, so the app log
 * shows which source a session used and a summary of what it read.
 *
 * TYPE_PROXIMITY needs no permission on any Android version.
 */
class ProximitySensor(context: Context, messenger: BinaryMessenger) {
    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    private val methods = MethodChannel(messenger, "kiosk_satellite/proximity_sensor")
    private val events = EventChannel(messenger, "kiosk_satellite/proximity_sensor_stream")

    private val main = Handler(Looper.getMainLooper())
    private var session: Session? = null

    /** Probed once: the bound drivers cannot change while the app runs. */
    private val sensortek: SensortekDriver? by lazy { findSensortekDriver() }

    /** The default TYPE_PROXIMITY sensor, else the first dynamic one. */
    private fun findSensor(): Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
            ?: sensorManager.getDynamicSensorList(Sensor.TYPE_PROXIMITY).firstOrNull()

    private fun support(): Map<String, Any?> {
        val s = findSensor()
            ?: return mapOf(
                "supported" to false,
                "hint" to "Not available on this device: it has no proximity sensor.",
            )
        return mapOf(
            "supported" to true,
            "name" to s.name,
            "vendor" to s.vendor,
            "maximumRange" to s.maximumRange,
            "resolution" to s.resolution,
            "driver" to sensortek?.name,
            "rawFile" to sensortek?.rawFile?.path,
        )
    }

    init {
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "support" -> result.success(support())
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                val s = findSensor()
                if (s == null) {
                    sink.error("absent", "no proximity sensor", null)
                    return
                }
                detach()
                session = Session(s, sink).also { it.start() }
            }

            override fun onCancel(args: Any?) = detach()
        })
    }

    /**
     * One registration. Everything runs on the main looper: the listener is
     * registered from it without a handler, the raw file is polled on it
     * and the channel callbacks arrive on it, so nothing here needs locking.
     */
    private inner class Session(
        private val sensor: Sensor,
        private val sink: EventChannel.EventSink,
    ) : SensorEventListener {
        private val driver = sensortek
        private val rawCountSensor = isRawCountSensor(sensor.name, sensor.vendor)
        private val classifier = ProximityClassifier(
            sensor.maximumRange,
            sensor.resolution,
            risingCounts = driver != null || rawCountSensor,
        )
        private var last: Boolean? = null
        private var polling = driver?.rawFile != null

        // Counters for the periodic summary.
        private var windowStart = SystemClock.elapsedRealtime()
        private var summaryAt = windowStart + FIRST_SUMMARY_MS
        private var samples = 0
        private var lowest = Float.MAX_VALUE
        private var highest = -Float.MAX_VALUE
        private var sensorEvents = 0
        private var lastSensorValue: Float? = null

        private val poll = object : Runnable {
            override fun run() {
                val file = driver?.rawFile ?: return
                val value = try {
                    parseRawCount(file.readText())
                } catch (e: Exception) {
                    polling = false
                    diagnostic(
                        "raw file ${file.path} unreadable (${e.message}), " +
                            "reading sensor events instead",
                        warning = true,
                    )
                    return
                }
                sample(value, SystemClock.elapsedRealtimeNanos())
                main.postDelayed(this, RAW_POLL_MS)
            }
        }

        fun start() {
            diagnostic(describeSource())
            sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
            // The file holds the last session's reading until the driver
            // polls again, so give it a few polls before the resting sample.
            if (polling) main.postDelayed(poll, RAW_FIRST_READ_MS)
        }

        fun stop() {
            main.removeCallbacks(poll)
            sensorManager.unregisterListener(this)
        }

        private fun describeSource(): String = when {
            driver == null && rawCountSensor ->
                "source: sensor events as rising raw counts (${sensor.name})"
            driver == null -> "source: sensor events"
            polling -> "source: raw counts from ${driver.rawFile?.path} " +
                "(driver ${driver.name}), polled every $RAW_POLL_MS ms"
            else -> "source: sensor events as rising raw counts " +
                "(driver ${driver.name}, no raw file)"
        }

        override fun onSensorChanged(event: SensorEvent) {
            val value = event.values.firstOrNull() ?: return
            sensorEvents++
            lastSensorValue = value
            if (polling) {
                summarize()
                return
            }
            sample(value, event.timestamp)
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

        private fun sample(value: Float, nanos: Long) {
            samples++
            if (value < lowest) lowest = value
            if (value > highest) highest = value
            val near = classifier.near(value, nanos)
            val initial = last == null
            if (initial || near != last) {
                last = near
                val resting = classifier.restingLevel
                sink.success(
                    buildMap {
                        put("near", near)
                        put("initial", initial)
                        put("distance", value)
                        if (resting != null) put("resting", resting)
                    },
                )
            }
            summarize()
        }

        /** What the session read since the last summary, for follow-up reports. */
        private fun summarize() {
            if (driver == null && !rawCountSensor) return
            val now = SystemClock.elapsedRealtime()
            if (now < summaryAt) return
            summaryAt = now + SUMMARY_MS
            val range = if (samples > 0) "min $lowest, max $highest" else "no readings"
            val resting = classifier.restingLevel?.let { ", resting %.1f".format(Locale.ROOT, it) } ?: ""
            diagnostic(
                "last ${(now - windowStart) / 1000} s: $samples readings, $range$resting; " +
                    "$sensorEvents sensor events, last ${lastSensorValue ?: "none"}",
            )
            windowStart = now
            samples = 0
            lowest = Float.MAX_VALUE
            highest = -Float.MAX_VALUE
            sensorEvents = 0
        }

        private fun diagnostic(message: String, warning: Boolean = false) {
            sink.success(
                mapOf("diagnostic" to message, "level" to if (warning) "warn" else "info"),
            )
        }
    }

    private fun detach() {
        session?.stop()
        session = null
    }

    fun dispose() {
        detach()
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }

    private companion object {
        /** How often the raw file is read, the rate the listener is registered at. */
        const val RAW_POLL_MS = 200L

        /** How long after registering the raw file is first read. */
        const val RAW_FIRST_READ_MS = 400L

        /** When a session's first summary is logged, so a short test still shows one. */
        const val FIRST_SUMMARY_MS = 30_000L

        /** How often a session's summary is logged after the first. */
        const val SUMMARY_MS = 300_000L
    }
}

/** A bound Rockchip Sensortek proximity driver and its raw count file, if it has one. */
internal data class SensortekDriver(val name: String, val rawFile: File?)

private val SENSORTEK_DRIVERS = setOf("ps_stk3a5x", "ps_stk3x3x")

/**
 * The Rockchip Sensortek proximity driver bound on this device, or null on
 * every other device.
 *
 * The NSPanel Pro's kernels name their I2C clients after the driver: the
 * 120P has `ps_stk3a5x`, the 86P either that or `ps_stk3x3x` depending on
 * the board. Both drivers report a value that rises as something comes
 * closer, raw counts on the 86P and a 0/1 flag on the 120P. Their 4.x
 * kernels also publish the raw count in [rawFile], world-readable, which
 * the driver creates only once its chip has answered. Requiring a bound
 * driver as well keeps a leftover file from passing for a live one.
 * Anything unreadable (a stricter SELinux policy elsewhere) reads as no
 * driver, so other devices keep the sensor's own events.
 */
internal fun findSensortekDriver(
    devices: File = File("/sys/bus/i2c/devices"),
    rawFile: File = File("/sys/class/st_psensor/psensor_value"),
): SensortekDriver? = try {
    val name = devices.listFiles()?.firstNotNullOfOrNull { device ->
        val name = File(device, "name").takeIf { it.isFile }?.readText()?.trim()
        name?.takeIf { it in SENSORTEK_DRIVERS && File(device, "driver").exists() }
    }
    name?.let { SensortekDriver(it, rawFile.takeIf { f -> f.isFile && f.canRead() }) }
} catch (_: Exception) {
    null
}

/** The name and vendor of each sensor listed for [isRawCountSensor]. */
private val RAW_COUNT_SENSORS = setOf("Ltr578 Ambient Light Sensor" to "Liteon")

/**
 * Whether this proximity sensor is known to report raw counts that rise as
 * something comes closer, in its own events.
 *
 * The Lenovo Smart Clock's HAL (#1315) rests at about 73 and reaches the
 * hundreds or thousands for a hand. It is reported to advertise a range of
 * 0, which the classifier's test against the range skips. The match is on
 * the exact name and vendor because the same chip can report normal flags under
 * another HAL, and a sensor reporting real distances would read backwards
 * as counts. The HAL gives the proximity sensor the light sensor's name,
 * which is what makes this pair specific.
 */
internal fun isRawCountSensor(name: String, vendor: String): Boolean =
    (name to vendor) in RAW_COUNT_SENSORS

/** The raw file's text, a decimal count and a newline. */
internal fun parseRawCount(text: String): Float =
    text.trim().toIntOrNull()?.takeIf { it >= 0 }?.toFloat()
        ?: throw IllegalArgumentException("not a count: \"${text.trim().take(16)}\"")

internal fun proximityNearThreshold(maximumRange: Float, resolution: Float): Float = when {
    maximumRange <= 0f -> 0.5f
    // A binary driver's far flag need not match its advertised range (#579).
    resolution >= maximumRange -> minOf(maximumRange, 1f) / 2f
    else -> maximumRange
}

/**
 * Reads one registration's samples as near or far.
 *
 * A reading of more than twice the advertised range cannot be a distance.
 * Such a sensor reports raw counts that rise as something comes closer
 * (#980: range 9, 46 to 50 at rest with the odd blip to 60, 70 at 20 cm,
 * several hundred for a hand). From that reading on, near means a clear
 * rise over the resting level instead of a short distance.
 *
 * The resting level follows the far readings slowly, faster downward than
 * upward, so a lifted cover is learned in seconds while a single low blip
 * barely moves it. Snapping to a low blip made ordinary resting noise read
 * as near and held it there. A near that lasts [STUCK_NEAR_NANOS] is taken
 * for a new resting level, so a shift in the readings cannot hold the
 * sensor near for good.
 *
 * [risingCounts] starts in that mode for a sensor known to read higher as
 * something comes closer (see [findSensortekDriver] and [isRawCountSensor]).
 * Such a sensor may rest at 0 and blip to a few counts, which would otherwise
 * read as near and far flags (#980).
 */
internal class ProximityClassifier(
    private val maximumRange: Float,
    resolution: Float,
    risingCounts: Boolean = false,
) {
    private val nearBelow = proximityNearThreshold(maximumRange, resolution)
    private var counts = risingCounts
    private var baseline = 0f
    private var previous: Float? = null
    private var near = false
    private var nearSince = 0L

    /** The resting level in raw-count mode, null while reading distances. */
    val restingLevel: Float?
        get() = if (counts) baseline else null

    /** [nanos] is the sample's timestamp, any monotonic clock in nanoseconds. */
    fun near(value: Float, nanos: Long): Boolean {
        if (counts && previous == null) baseline = value
        if (!counts && maximumRange > 0f && value > maximumRange * 2f) {
            counts = true
            // The reading before the jump is the resting level, so a hand
            // that brings the first big reading still counts as near.
            baseline = previous ?: value
            near = false
        }
        previous = value
        if (!counts) return value < nearBelow
        if (near && nanos - nearSince >= STUCK_NEAR_NANOS) {
            baseline = value
            near = false
            return false
        }
        val margin = (baseline * COUNTS_RISE).coerceIn(COUNTS_MIN_RISE, COUNTS_MAX_RISE)
        val wasNear = near
        near = if (near) {
            value >= baseline + margin / 2f
        } else {
            value >= baseline + margin
        }
        if (near && !wasNear) nearSince = nanos
        if (!near) {
            val rate = if (value < baseline) COUNTS_DRIFT_DOWN else COUNTS_DRIFT_UP
            baseline += (value - baseline) * rate
        }
        return near
    }

    private companion object {
        /** The rise over the resting level that reads as near, as a fraction. */
        const val COUNTS_RISE = 0.25f

        /** The smallest rise that reads as near, clear of resting noise. */
        const val COUNTS_MIN_RISE = 15f

        /**
         * The largest rise needed to read as near. The 120P's own driver
         * calls 50 over its lowest reading near, and some panels rest at
         * 1000 to 4000 counts, where a quarter would miss a hand.
         */
        const val COUNTS_MAX_RISE = 50f

        /** How fast the resting level follows lower far readings. */
        const val COUNTS_DRIFT_DOWN = 0.1f

        /** How fast the resting level follows higher far readings. */
        const val COUNTS_DRIFT_UP = 0.01f

        /** How long a near may last before its reading becomes the resting level. */
        const val STUCK_NEAR_NANOS = 60_000_000_000L
    }
}
