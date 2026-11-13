package me.jxl.kiosk_satellite

/**
 * Available memory from the text of /proc/meminfo.
 *
 * A kernel older than 3.14 has no MemAvailable line (issue #1429: a Galaxy
 * View on a 3.10 kernel under Android 16). Android reads the same line for
 * ActivityManager.MemoryInfo.availMem, so on such a kernel availMem is 0 and
 * is no fallback at all. The estimate below is the kernel's own MemAvailable
 * formula without the zone watermarks, which an app cannot read: free pages
 * plus the file cache and the reclaimable slab. It reads a few MB high.
 */
internal object MemAvailable {
    /** Bytes and whether they are the estimate. Null when the text has neither. */
    fun parse(meminfo: String): Reading? {
        val kb = HashMap<String, Long>()
        for (line in meminfo.lineSequence()) {
            val colon = line.indexOf(':')
            if (colon <= 0) continue
            val value = line.substring(colon + 1).trim().substringBefore(' ').toLongOrNull()
            if (value != null) kb[line.substring(0, colon)] = value
        }
        kb["MemAvailable"]?.let { return Reading(it * 1024, estimated = false) }
        val free = kb["MemFree"] ?: return null
        val cache = (kb["Active(file)"] ?: 0) + (kb["Inactive(file)"] ?: 0)
        val slab = kb["SReclaimable"] ?: 0
        return Reading((free + cache + slab) * 1024, estimated = true)
    }

    data class Reading(val bytes: Long, val estimated: Boolean)
}
