package me.jxl.kiosk_satellite.btproxy

/**
 * When [BleScanEngine] may restart the adapter and how often it may start a
 * new scan session after registration trouble. Plain logic with the clock
 * passed in, so tests can run it at any Android level. Every rule here is
 * reached only after a failure: a device that registers on time keeps the
 * two minute rotation and never restarts its adapter.
 *
 * Android 8.0 to 9 have a bug that makes one late registration permanent.
 * BluetoothLeScanner gives up on a registration after 2 seconds. A late
 * success then calls unregisterClient, not unregisterScanner, which frees the
 * stack's id and leaves the dead scanner in GattService's scanner map. The
 * stack hands out the lowest free id, so a later scanner gets the same one,
 * and GattService finds the dead entry first. It counts every result and
 * sends it to the dead scanner, which drops it. The scan looks healthy, no
 * error arrives and dumpsys counts results while the app hears nothing.
 * Stopping the scan removes only the first match, so an entry always stays
 * behind. Only an adapter restart clears the map. Android 10 fixed the call.
 */
internal class ScanRecoveryPolicy(private val sdkInt: Int) {
    private companion object {
        /** Android 8.0 to 9, the releases with the unregisterClient bug. */
        val STALE_SCANNER_SDKS = 26..28
        /** The last release that lets an app turn the adapter off. */
        const val MAX_ADAPTER_RESTART_SDK = 32
        const val FAILURES_BEFORE_RESTART = 3
        /** Each restart drops the proxy's GATT connections. */
        const val RESTART_COOLDOWN_MS = 30 * 60_000L
        /** After a restart that never brought results back. */
        const val UNPROVEN_RESTART_COOLDOWN_MS = 2 * 60 * 60_000L
        /**
         * Android gives up at 2 seconds and a healthy stack answers within
         * a few milliseconds, so this leaves room on both sides.
         */
        const val SLOW_START_MS = 1_000L
        /** One slow start can be a stalled main thread. Two in a row are not. */
        const val SLOW_STARTS_TO_STRETCH = 2
        const val SLOW_ROTATION_MS = 30 * 60_000L
    }

    private val staleScannerBug = sdkInt in STALE_SCANNER_SDKS
    private var lastRestartAt: Long? = null
    private var restartRecovered = false
    // Stays set when results flow: a scanner with another id does not hear
    // the dead entry, but a later one that gets its id goes deaf. Only an
    // adapter restart clears the entry.
    private var staleScannerPossible = false
    private var slowStarts = 0
    private var lastStartAt = 0L

    /** Read on the scan callback's binder thread to decide whether to post. */
    @Volatile var awaitingResults = false
        private set

    /** True while the engine is rotating at the slow pace. */
    val registrationSlow: Boolean get() = slowStarts >= SLOW_STARTS_TO_STRETCH

    /** The stack refused or timed out a registration. */
    fun recordRegistrationFailure() {
        if (staleScannerBug) staleScannerPossible = true
    }

    fun shouldRestartAfterFailures(consecutiveFailures: Int, nowMs: Long): Boolean =
        consecutiveFailures >= FAILURES_BEFORE_RESTART && restartAllowed(nowMs)

    /** A silent scan after a timeout is the deaf state described above. */
    fun shouldRestartOnSilence(nowMs: Long): Boolean =
        staleScannerPossible && restartAllowed(nowMs)

    fun recordAdapterRestart(nowMs: Long) {
        lastRestartAt = nowMs
        restartRecovered = false
        awaitingResults = true
    }

    /** The adapter came back, so GattService started with an empty map. */
    fun recordAdapterOn() {
        staleScannerPossible = false
    }

    /** Advertisements reached the app after a restart. */
    fun recordResults() {
        awaitingResults = false
        restartRecovered = true
    }

    /** Records a start. Returns true when [registrationSlow] changed. */
    fun recordStart(durationMs: Long, nowMs: Long): Boolean {
        lastStartAt = nowMs
        if (!staleScannerBug) return false
        val wasSlow = registrationSlow
        slowStarts = if (durationMs >= SLOW_START_MS) slowStarts + 1 else 0
        return registrationSlow != wasSlow
    }

    /**
     * Every rotation is a new registration and on these releases one late
     * registration costs an adapter restart, so a slow stack rotates less.
     * The next start measures it again, so a false alarm ends by itself.
     */
    fun shouldRotate(nowMs: Long): Boolean =
        !registrationSlow || nowMs - lastStartAt >= SLOW_ROTATION_MS

    private fun restartAllowed(nowMs: Long): Boolean {
        if (sdkInt > MAX_ADAPTER_RESTART_SDK) return false
        val last = lastRestartAt ?: return true
        val elapsed = nowMs - last
        // A restart that brought nothing back will not help on a loop,
        // except where the stale entry can return on the first registration
        // after the restart, and then it gets a long wait.
        return when {
            restartRecovered -> elapsed >= RESTART_COOLDOWN_MS
            staleScannerBug -> elapsed >= UNPROVEN_RESTART_COOLDOWN_MS
            else -> false
        }
    }
}
