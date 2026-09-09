package me.jxl.kiosk_satellite

/** Maps the app's faders into the available output range. */
internal object PlaybackVolume {
    fun compensation(masterDb: Float, callDb: Float): Float =
        Math.pow(10.0, (masterDb.toDouble() - callDb) / 20.0)
            .coerceAtMost(Float.MAX_VALUE.toDouble()).toFloat()

    fun level(base: Float, assistant: Float, compensation: Float): Float =
        // Compensation can exceed one without amplifying the final signal
        // above one. Clamp after applying the faders to preserve that range.
        (base.toDouble() * assistant * compensation).coerceIn(0.0, 1.0).toFloat()
}
