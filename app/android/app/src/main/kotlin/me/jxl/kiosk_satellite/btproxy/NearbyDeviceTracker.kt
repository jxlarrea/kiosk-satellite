package me.jxl.kiosk_satellite.btproxy

/**
 * A bounded inventory of the devices the Bluetooth proxy hears, kept for
 * the "Nearby devices" list and its MQTT sensor.
 *
 * The proxy already handles every advertisement; this class only records
 * facts about each address (broadcast name, manufacturer company IDs,
 * service UUIDs, RSSI, when it was last heard). Identification, the part
 * that turns "company 76, frame 0x12" into "Apple Find My device", happens
 * on the Dart side where the vendor tables live under unit tests and the
 * optional online OUI lookup can join in. Raw facts here, judgment there.
 *
 * The expensive part, walking the AD structures, only happens when an
 * address's payload actually changed; the common case (the same sensor
 * repeating the same packet with a new RSSI) is two map hits. Android-free
 * so it runs under plain JVM tests.
 */
internal class NearbyDeviceTracker(
    private val clock: () -> Long = System::currentTimeMillis,
) {
    private companion object {
        /** Plenty for a home plus passing traffic; oldest-seen evicts first. */
        const val MAX_DEVICES = 400

        /**
         * An address unheard this long is gone: rotated away, out of range,
         * or switched off. BLE advertisers repeat every few seconds, so ten
         * minutes of silence is decisive. Without expiry a nine-hour soak
         * pinned the inventory at [MAX_DEVICES]: every Apple and Shield
         * address rotation added a row and nothing ever left, so the count
         * sensor read the cap and the list filled with dead appearances.
         */
        const val STALE_MS = 10 * 60_000L
    }

    private class Entry(val address: Long) {
        var addressType = 0
        var name: String? = null
        val companyIds = LinkedHashSet<Int>()
        /** Latest first data byte per company ID: Apple frame types etc. */
        val companyFirstByte = HashMap<Int, Int>()
        val serviceUuids = LinkedHashSet<String>()
        var rssi = 0
        var lastSeenAt = 0L
        var payloadHash = 0
        var count = 0L
    }

    private val lock = Any()
    private val devices = HashMap<Long, Entry>()

    fun observe(adv: BleAdvertisement) {
        val now = clock()
        synchronized(lock) {
            val entry = devices.getOrPut(adv.address) {
                if (devices.size >= MAX_DEVICES) {
                    prune(now)
                    if (devices.size >= MAX_DEVICES) {
                        devices.values.minByOrNull { it.lastSeenAt }?.let {
                            devices.remove(it.address)
                        }
                    }
                }
                Entry(adv.address)
            }
            entry.rssi = adv.rssi
            entry.lastSeenAt = now
            entry.addressType = adv.addressType
            entry.count++
            val hash = adv.data.contentHashCode()
            if (hash != entry.payloadHash) {
                entry.payloadHash = hash
                parseInto(entry, adv.data)
            }
        }
    }

    fun clear() = synchronized(lock) { devices.clear() }

    /** Callers hold [lock]. */
    private fun prune(now: Long, keep: Set<Long> = emptySet()) {
        devices.values.removeAll {
            it.address !in keep && now - it.lastSeenAt > STALE_MS
        }
    }

    /**
     * Snapshot for the bridge, newest first, stale entries expired: the
     * list and its count mean "heard in the last ten minutes", not "ever".
     * [connected] addresses are exempt from expiry and flagged: a device
     * with an active GATT link stops advertising, and expiring the row of
     * the one device the kiosk is actively serving would be absurd.
     * Plain maps: it crosses a MethodChannel.
     */
    fun snapshot(connected: Set<Long> = emptySet()): List<Map<String, Any?>> =
        synchronized(lock) {
        prune(clock(), keep = connected)
        devices.values
            .sortedByDescending { it.lastSeenAt }
            .map { entry ->
                mapOf(
                    "connected" to (entry.address in connected),
                    "address" to formatAddress(entry.address),
                    "addressType" to entry.addressType,
                    "name" to entry.name,
                    "companies" to entry.companyIds.toList(),
                    "firstBytes" to entry.companyFirstByte.entries
                        .associate { it.key.toString() to it.value },
                    "uuids" to entry.serviceUuids.toList(),
                    "rssi" to entry.rssi,
                    "lastSeenAt" to entry.lastSeenAt,
                    "count" to entry.count,
                )
            }
    }

    /**
     * Walks the AD structures of a (already length-sanitized) advertisement.
     * Malformed structures end the walk rather than corrupt the entry: the
     * scan engine drops truly broken records before they get here, but a
     * 62-byte truncation can still cut a structure short.
     */
    private fun parseInto(entry: Entry, data: ByteArray) {
        var index = 0
        while (index + 1 < data.size) {
            val length = data[index].toInt() and 0xFF
            if (length == 0) break
            val type = data[index + 1].toInt() and 0xFF
            val start = index + 2
            val end = index + 1 + length
            if (end > data.size) break
            when (type) {
                // Shortened (0x08) and complete (0x09) local name; complete wins.
                0x08 -> if (entry.name == null) entry.name = adString(data, start, end)
                0x09 -> entry.name = adString(data, start, end)
                // 16-bit service UUID lists, incomplete and complete.
                0x02, 0x03 -> {
                    var i = start
                    while (i + 1 < end) {
                        entry.serviceUuids.add(uuid16(data, i))
                        i += 2
                    }
                }
                // Service data with a 16-bit UUID identifies a device class
                // (BTHome, Eddystone, Find My) even when no UUID list is
                // advertised.
                0x16 -> if (start + 1 < end) entry.serviceUuids.add(uuid16(data, start))
                // 128-bit service UUID lists: recorded compactly, mostly to
                // show "custom service" rather than nothing.
                0x06, 0x07 -> if (start + 15 < end) {
                    entry.serviceUuids.add(uuid128(data, start))
                }
                0xFF -> if (start + 1 < end) {
                    val company = (data[start].toInt() and 0xFF) or
                        ((data[start + 1].toInt() and 0xFF) shl 8)
                    entry.companyIds.add(company)
                    if (start + 2 < end) {
                        entry.companyFirstByte[company] = data[start + 2].toInt() and 0xFF
                    }
                }
            }
            index = end
        }
    }

    // NUL-padded names are common on the wire; trim every control char.
    private fun adString(data: ByteArray, start: Int, end: Int): String =
        String(data, start, end - start, Charsets.UTF_8).trim { it <= ' ' }

    private fun uuid16(data: ByteArray, index: Int): String =
        "%04x".format(
            (data[index].toInt() and 0xFF) or ((data[index + 1].toInt() and 0xFF) shl 8))

    /** BLE 128-bit UUIDs arrive little-endian; render standard big-endian form. */
    private fun uuid128(data: ByteArray, start: Int): String {
        val bytes = ByteArray(16) { data[start + 15 - it] }
        val hex = bytes.joinToString("") { "%02x".format(it) }
        return "${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-" +
            "${hex.substring(16, 20)}-${hex.substring(20)}"
    }

    private fun formatAddress(address: Long): String =
        (5 downTo 0).joinToString(":") { "%02X".format((address shr (it * 8)) and 0xFF) }
}
