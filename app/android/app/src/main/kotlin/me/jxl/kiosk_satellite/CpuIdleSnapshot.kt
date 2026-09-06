package me.jxl.kiosk_satellite

/** Idle residency in microseconds, timed against the CPU's awake clock. */
internal class CpuIdleSnapshot(
    val elapsedNanos: Long,
    val awakeNanos: Long,
    val idleUs: Map<String, Long>,
    val entries: Map<String, Long>,
    val online: Map<String, Boolean>,
) {
    /**
     * CPU utilization while awake, averaged over cores. Suspend advances
     * elapsed time without advancing the idle counters, so it must not be
     * part of the utilization window (issue #459).
     */
    fun usageSince(before: CpuIdleSnapshot): Double? {
        val awakeUs = (awakeNanos - before.awakeNanos) / 1000.0
        if (awakeUs <= 0) return null
        var busySum = 0.0
        var n = 0
        for ((name, idleNow) in idleUs) {
            val idleBefore = before.idleUs[name] ?: continue
            // Hotplugging governors freeze parked cores' counters. Keep
            // counting those cores as free capacity (issue #76).
            val offlineAtEdge = before.online[name] == false || online[name] == false
            val frozen = idleNow == idleBefore && entries[name] == before.entries[name]
            val busy = when {
                offlineAtEdge -> 0.0
                // A reset is not a measurement of work. Wait for the next
                // interval to include this core again.
                idleNow < idleBefore -> continue
                frozen -> 1.0
                else -> (1.0 - (idleNow - idleBefore) / awakeUs).coerceIn(0.0, 1.0)
            }
            busySum += busy
            n++
        }
        return if (n == 0) null else busySum / n * 100.0
    }
}
