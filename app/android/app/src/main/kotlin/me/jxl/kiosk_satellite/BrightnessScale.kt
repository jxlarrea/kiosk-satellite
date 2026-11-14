package me.jxl.kiosk_satellite

import kotlin.math.roundToInt

/**
 * The panel's brightness scale, in the raw units `Settings.System` stores.
 *
 * 0..255 is only the common case. The range is a per-device framework
 * constant and OEM panels routinely use 0..1023, 0..2047 or wider, so a
 * 0..255 write on one of those asks for a tenth of the brightness the caller
 * meant — which on a gamma-mapped backlight is indistinguishable from the
 * screen going black (issue #270) — and a read reports every value above 255
 * as full. Every conversion between the app's 0..1 level and the setting
 * goes through the device's real range instead.
 */
internal data class BrightnessScale(val min: Int, val max: Int) {
    fun toLevel(raw: Int): Double = if (max <= min) {
        0.0
    } else {
        ((raw - min).toDouble() / (max - min)).coerceIn(0.0, 1.0)
    }

    // Never below the panel's own floor, zero included. A write under it
    // gains nothing (the display clamps to the floor anyway) and on Android
    // 14+ it leaves the framework's brightness synchronizer with a preferred
    // value the panel can never show, after which it treats every later
    // write as a conflict and reverts it to the floor: the restore after a
    // screensaver dimmed to 0% never landed, and the tablet stayed dark
    // until adaptive brightness was toggled. The black screensaver's dark
    // panel is the floor on such a panel, which is as dark as it goes.
    fun toRaw(level: Double): Int {
        val clamped = level.coerceIn(0.0, 1.0)
        return (min + clamped * (max - min)).roundToInt().coerceIn(min, max)
    }

    /**
     * This scale grown to hold [raw], or null when it already does. A value
     * the scale calls impossible says the framework constant undersold the
     * panel, and whatever set it (quick settings, the OS) knows the panel
     * better than we do: better a scale that grows into the truth than one
     * that pins every level to a fraction of what was asked for.
     */
    fun widenedTo(raw: Int): BrightnessScale? =
        if (raw > max) copy(max = raw) else null

    companion object {
        /** Android's historical scale, and the fallback for a silent ROM. */
        val default = BrightnessScale(0, 255)

        private const val MAX_SANE = 65535

        /**
         * The scale a device reports, with nonsense refused: a maximum of
         * zero (or an implausibly huge one) and a minimum that swallows most
         * of the scale are a ROM misreporting its own constants, and would
         * make every level mean something other than what it says.
         */
        fun of(min: Int?, max: Int?): BrightnessScale {
            val top = max?.takeIf { it in 1..MAX_SANE } ?: default.max
            val floor = min?.takeIf { it in 0..(top / 4) } ?: 0
            return BrightnessScale(floor, top)
        }

        private const val TIRAMISU = 33

        /**
         * Whether [max], the maximum a device reports, is one its own
         * Android does not use. Xiaomi tablets on Android 13 and newer
         * report 2047 or 4095 and convert the setting on 0..255 all the
         * same: a Redmi Pad 2 was at full brightness from 2% of the slider
         * up (issue #1430), and a Xiaomi Pad 5 had every write above 255
         * put back to 255. A Redmi Pad SE reports 255, so this goes by the
         * reported value and not by the model. Older Xiaomi builds, and
         * the realme of issue #270, report a wide maximum and mean it.
         */
        fun overstates(max: Int?, manufacturer: String?, sdk: Int): Boolean =
            max != null && max > default.max && sdk >= TIRAMISU &&
                manufacturer.equals("Xiaomi", ignoreCase = true)
    }
}
