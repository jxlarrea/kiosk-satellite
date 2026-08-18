package me.jxl.kiosk_satellite.btproxy

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * The BLE scanner feeding the Bluetooth proxy, built around the ways Android
 * scanning actually dies in the field:
 *
 *  - The stack stops delivering callbacks without any error (MediaTek and
 *    Fire/Echo hardware are notorious). A silence watchdog restarts the scan
 *    when a busy home goes quiet for too long: a home with any BLE device is
 *    never silent for 45 seconds.
 *  - The adapter turns off (user toggle, stack crash and restart, airplane
 *    mode). Prior proxies' watchdogs only recovered a RUNNING scanner, so
 *    one adapter bounce left them dead until an app restart. Here an
 *    ACTION_STATE_CHANGED receiver restarts scanning the moment the adapter
 *    returns while demand exists.
 *  - Android throttles apps that start scans more than 5 times in 30
 *    seconds, silently delivering nothing afterwards. Every start funnels
 *    through a rate gate that defers, never drops, a restart.
 *  - Android 8.1+ blocks unfiltered scans while the screen is off. A single
 *    match-everything filter satisfies the "filtered" requirement and keeps
 *    full discovery running on a dark kiosk.
 *  - Unrecoverable stack errors (SCAN_FAILED_INTERNAL_ERROR on some Echo
 *    Show builds) are retried with escalating backoff and surfaced as a
 *    FAILED state instead of a tight retry loop flooding the log.
 *
 * ESPHome's scanner mode (passive/active) has no Android equivalent: the
 * platform scanner always performs active scanning and offers no SCAN_REQ
 * control. The requested mode is stored and echoed back to HA (some
 * integrations read it), but the radio behavior is the same either way;
 * kiosks are wall-powered so the duty cycle stays at LOW_LATENCY.
 *
 * All state lives on the main-looper handler; public entry points post.
 */
internal class BleScanEngine(
    private val context: Context,
    private val onAdvertisement: (BleAdvertisement) -> Unit,
    private val onStateChange: (ScannerState, ScannerMode) -> Unit,
    private val onLog: (String) -> Unit = {},
) {
    private companion object {
        const val TAG = "KsBtProxy"
        /** Stay under Android's 5-per-30s undocumented scan-start throttle. */
        const val MAX_STARTS = 4
        const val START_WINDOW_MS = 30_000L
        const val WATCHDOG_INTERVAL_MS = 10_000L
        const val SILENCE_RESTART_MS = 45_000L
        /**
         * Proactive scan-session rotation. Two minutes, not a keep-fresh
         * half hour: some controllers (Samsung's BLE5 stacks, found live
         * with a Yale lock) report each static advertiser roughly ONCE per
         * scan session and then suppress its duplicates, whatever the
         * filter setup and match settings say. Chatty payload-changing
         * devices keep flowing, quiet ones go silent minutes into every
         * session, and Home Assistant marks them unavailable once its
         * staleness window (about three minutes) runs dry. Restarting the
         * session re-reports everything, so a cadence comfortably inside
         * that window keeps slow advertisers continuously visible. One
         * start per two minutes is far under the 4-per-30s budget, and the
         * restart gap is milliseconds.
         */
        const val ROTATION_MS = 120_000L
        val FAILURE_BACKOFF_MS = longArrayOf(5_000, 15_000, 60_000, 300_000)
    }

    private val handler = Handler(Looper.getMainLooper())
    private val startTimestamps = ArrayDeque<Long>()

    private var demanded = false
    private var scanning = false
    private var mode = ScannerMode.PASSIVE
    // While > 0 the scan stays down: GATT connection establishment and a
    // LOW_LATENCY scan fight over the radio, and on shared-antenna chips
    // the connect loses. Guarded by the handler thread like everything else.
    private var gattHolds = 0
    // Volatile: written on the handler thread, peeked from the scan
    // callback's binder thread to decide whether a reset post is needed.
    @Volatile private var consecutiveFailures = 0
    @Volatile private var lastCallbackAt = 0L
    @Volatile private var receiverRegistered = false
    // Sticky within a run, never walked back on success: if the rich scan
    // settings are what the stack objects to, re-trying them after every
    // recovery would just re-break the scanner on a cycle (issue #239).
    private var minimalSettings = false

    val isScanning: Boolean get() = scanning
    val lastAdvertisementAt: Long get() = lastCallbackAt

    private val adapter: BluetoothAdapter?
        get() = (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    // A failure worth showing the user, not just logcat: these lines reach
    // the runtime's ring log and with it btProxyStatus and the remote
    // admin, where "scanning but hearing nothing" is otherwise invisible
    // (issue #240: a SecurityException-killed scan looked exactly like a
    // healthy one from every surface the reporter could reach).
    private fun note(line: String) {
        Log.w(TAG, line)
        onLog(line)
    }

    fun requestStart(requestedMode: ScannerMode) {
        handler.post {
            mode = requestedMode
            demanded = true
            startScanIfNeeded("demand")
        }
    }

    fun requestStop() {
        handler.post {
            demanded = false
            stopScanInternal(ScannerState.STOPPED)
        }
    }

    /**
     * A GATT connect window opened (true) or closed (false). Reference
     * counted: overlapping connects keep the scan down until the last one
     * resolves, then the ordinary demand logic brings it back through the
     * rate gate.
     */
    fun setGattBusy(busy: Boolean) {
        handler.post {
            gattHolds = (gattHolds + if (busy) 1 else -1).coerceAtLeast(0)
            if (gattHolds > 0) {
                if (scanning) stopScanInternal(ScannerState.STOPPING)
            } else if (demanded && !scanning) {
                startScanIfNeeded("gatt idle")
            }
        }
    }

    fun setMode(requestedMode: ScannerMode) {
        handler.post {
            // No Android knob changes with the mode; record and re-report so
            // HA's scanner entity reflects the request. No scan restart: the
            // radio behavior is identical, and restarting here is the exact
            // churn that broke other proxies on HA's post-subscribe set-mode.
            mode = requestedMode
            onStateChange(if (scanning) ScannerState.RUNNING else ScannerState.IDLE, mode)
        }
    }

    fun shutdown() {
        handler.post {
            demanded = false
            stopScanInternal(ScannerState.STOPPED)
            if (receiverRegistered) {
                receiverRegistered = false
                runCatching { context.unregisterReceiver(adapterReceiver) }
            }
            handler.removeCallbacks(watchdog)
            handler.removeCallbacks(rotation)
        }
    }

    private val callback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            lastCallbackAt = android.os.SystemClock.elapsedRealtime()
            // The first delivered result is the real success signal: an
            // Android scan can "start" cleanly and fail asynchronously a
            // moment later (seen on the Echo Show 8 while its adapter was
            // still turning on), so resetting the failure counter at start
            // time keeps the retry backoff pinned to its shortest step.
            if (consecutiveFailures != 0) handler.post { consecutiveFailures = 0 }
            val advertisement = toAdvertisement(result) ?: return
            onAdvertisement(advertisement)
        }

        override fun onScanFailed(errorCode: Int) {
            handler.post { handleScanFailure(errorCode) }
        }
    }

    private val adapterReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            if (intent.action != BluetoothAdapter.ACTION_STATE_CHANGED) return
            when (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1)) {
                BluetoothAdapter.STATE_OFF -> handler.post {
                    // The scan died with the adapter; reflect it and wait for
                    // STATE_ON rather than burn restart budget on a dead radio.
                    if (scanning) {
                        scanning = false
                        onStateChange(ScannerState.FAILED, mode)
                        note("adapter off, scanner suspended")
                    }
                }
                BluetoothAdapter.STATE_ON -> handler.post {
                    consecutiveFailures = 0
                    if (demanded) {
                        Log.i(TAG, "adapter back on, resuming scan")
                        startScanIfNeeded("adapter recovered")
                    }
                }
            }
        }
    }

    private val watchdog = object : Runnable {
        override fun run() {
            if (demanded && scanning) {
                val silence = android.os.SystemClock.elapsedRealtime() - lastCallbackAt
                if (lastCallbackAt != 0L && silence > SILENCE_RESTART_MS) {
                    note("no advertisements for ${silence / 1000}s, restarting scan")
                    restartScan("silence watchdog")
                }
            }
            handler.postDelayed(this, WATCHDOG_INTERVAL_MS)
        }
    }

    private val rotation = object : Runnable {
        override fun run() {
            if (demanded && scanning) {
                Log.i(TAG, "rotating scan session")
                restartScan("session rotation")
            }
            handler.postDelayed(this, ROTATION_MS)
        }
    }

    @SuppressLint("MissingPermission")
    private fun startScanIfNeeded(reason: String) {
        if (scanning || !demanded || gattHolds > 0) return
        if (!receiverRegistered) {
            receiverRegistered = true
            context.registerReceiver(
                adapterReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
            handler.postDelayed(watchdog, WATCHDOG_INTERVAL_MS)
            handler.postDelayed(rotation, ROTATION_MS)
        }
        val bluetoothAdapter = adapter
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            onStateChange(ScannerState.FAILED, mode)
            note("cannot scan: adapter ${if (bluetoothAdapter == null) "absent" else "disabled"}")
            return // the STATE_ON receiver resumes us
        }
        val scanner = bluetoothAdapter.bluetoothLeScanner
        if (scanner == null) {
            onStateChange(ScannerState.FAILED, mode)
            return
        }

        // Rate gate: defer, never skip, when the 30s start budget is spent.
        val now = android.os.SystemClock.elapsedRealtime()
        while (startTimestamps.isNotEmpty() && now - startTimestamps.first() > START_WINDOW_MS) {
            startTimestamps.removeFirst()
        }
        if (startTimestamps.size >= MAX_STARTS) {
            val waitMs = START_WINDOW_MS - (now - startTimestamps.first()) + 500
            Log.i(TAG, "scan start budget spent, deferring ${waitMs}ms ($reason)")
            handler.postDelayed({ startScanIfNeeded(reason) }, waitMs)
            return
        }

        onStateChange(ScannerState.STARTING, mode)
        val settings = ScanSettings.Builder().apply {
            setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
            setReportDelay(0)
            // Everything below is a refinement some stacks reject outright:
            // a Meta Portal answered every start with SCAN_FAILED_INTERNAL_
            // ERROR forever (issue #239). Once repeated failures push the
            // engine into the minimal tier, the plain settings above are
            // the whole request; a degraded scanner beats a dead one.
            if (!minimalSettings) {
                if (Build.VERSION.SDK_INT >= 23) {
                    setMatchMode(ScanSettings.MATCH_MODE_AGGRESSIVE)
                    setNumOfMatches(ScanSettings.MATCH_NUM_MAX_ADVERTISEMENT)
                }
                if (Build.VERSION.SDK_INT >= 26 &&
                    bluetoothAdapter.isLeExtendedAdvertisingSupported) {
                    // Without this, BLE 5 extended advertisers are invisible.
                    setLegacy(false)
                    // 1M only, NOT PHY_LE_ALL_SUPPORTED: all-PHY scanning makes
                    // the controller time-slice its scan windows between 1M and
                    // Coded, and the lost duty makes slow advertisers (a
                    // battery lock beaconing at long intervals) statistically
                    // invisible while chatty ones still land. Found live: two
                    // BLE5 tablets sitting next to a Yale lock never heard it
                    // while a legacy-only Echo across the house did. Extended
                    // advertisers overwhelmingly use 1M as their primary PHY,
                    // so this keeps them visible at full scan duty.
                    setPhy(android.bluetooth.BluetoothDevice.PHY_LE_1M)
                }
            }
        }.build()
        // One match-everything filter. An empty filter LIST is an
        // "unfiltered" scan, which Android 8.1+ suppresses whenever the
        // screen is off; a list with one criteria-less filter counts as
        // filtered and keeps advertisements flowing on a dark kiosk.
        // (Filter choice does NOT influence the per-session duplicate
        // suppression some stacks apply; the short session rotation above
        // is what handles that.)
        val filters = listOf(ScanFilter.Builder().build())
        try {
            scanner.startScan(filters, settings, callback)
            startTimestamps.addLast(now)
            scanning = true
            lastCallbackAt = now // arm the silence watchdog from start time
            // consecutiveFailures deliberately NOT reset here: startScan
            // returning is no proof of success (the failure arrives async
            // via onScanFailed), and resetting early kept the backoff at
            // its shortest step through an endless failure loop. The first
            // onScanResult resets it instead.
            onStateChange(ScannerState.RUNNING, mode)
            Log.i(TAG, "scan started ($reason)")
        } catch (e: Exception) {
            note("startScan threw: $e")
            handleScanFailure(-1)
        }
    }

    @SuppressLint("MissingPermission")
    private fun stopScanInternal(finalState: ScannerState) {
        if (scanning) {
            scanning = false
            runCatching { adapter?.bluetoothLeScanner?.stopScan(callback) }
        }
        onStateChange(finalState, mode)
    }

    private fun restartScan(reason: String) {
        stopScanInternal(ScannerState.STOPPING)
        startScanIfNeeded(reason)
    }

    private fun handleScanFailure(errorCode: Int) {
        scanning = false
        onStateChange(ScannerState.FAILED, mode)
        if (!demanded) return
        val backoff = when (errorCode) {
            // Already-started means our bookkeeping desynced from the stack:
            // stop and retry cheaply.
            ScanCallback.SCAN_FAILED_ALREADY_STARTED -> {
                runCatching { adapter?.bluetoothLeScanner?.stopScan(callback) }
                1_000L
            }
            // The platform's own too-frequent throttle: wait out the window.
            6 -> START_WINDOW_MS + 5_000
            else -> {
                val step = consecutiveFailures.coerceAtMost(FAILURE_BACKOFF_MS.size - 1)
                FAILURE_BACKOFF_MS[step]
            }
        }
        consecutiveFailures++
        note("scan failed (code=$errorCode, attempt=$consecutiveFailures), retry in ${backoff}ms")
        // Three straight refusals with the rich settings: from here on ask
        // for the plainest scan Android knows. Some old stacks (a Meta
        // Portal, issue #239) reject the match-mode and PHY refinements
        // with INTERNAL_ERROR on every attempt, forever.
        if (!minimalSettings && consecutiveFailures >= 3) {
            minimalSettings = true
            note("scan keeps failing, retrying with minimal scan settings")
        }
        handler.postDelayed({ startScanIfNeeded("failure retry") }, backoff)
    }

    /**
     * Converts a platform scan result to the wire form. Android pads
     * ScanRecord bytes to a fixed 62 with zeros; ESPHome expects the packet
     * trimmed at the last real AD structure, so walk the structures and cut
     * where they end. A malformed record (structure running past the buffer)
     * is dropped entirely rather than forwarded truncated.
     */
    private fun toAdvertisement(result: ScanResult): BleAdvertisement? {
        val raw = result.scanRecord?.bytes ?: return null
        var index = 0
        while (index < raw.size) {
            val len = raw[index].toInt() and 0xFF
            if (len == 0) break // zero-length structure = padding from here
            if (index + 1 + len > raw.size) return null // malformed
            index += 1 + len
        }
        if (index == 0) return null
        val limit = index.coerceAtMost(62)
        val address = result.device.address
            .replace(":", "")
            .toLongOrNull(16) ?: return null
        return BleAdvertisement(
            address = address,
            rssi = result.rssi,
            addressType = addressTypeOf(result),
            data = raw.copyOfRange(0, limit),
        )
    }

    /**
     * Address type: the platform only exposes it on API 35+. Below that,
     * fall back to the BLE address convention (two MSBs 0b11 = static
     * random, 0b01 = resolvable private): imperfect for exotic public OUIs
     * but right for the phones and beacons that matter for presence.
     */
    private fun addressTypeOf(result: ScanResult): Int {
        if (Build.VERSION.SDK_INT >= 35) {
            runCatching {
                return if (result.device.addressType ==
                    android.bluetooth.BluetoothDevice.ADDRESS_TYPE_RANDOM) 1 else 0
            }
        }
        val msb = result.device.address.substringBefore(":").toIntOrNull(16) ?: return 0
        return if (msb and 0xC0 == 0xC0 || msb and 0xC0 == 0x40) 1 else 0
    }
}
