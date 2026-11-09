package me.jxl.kiosk_satellite

/**
 * Whether the ROM runs pryond, the service for Amazon's wake word engine on
 * the pryond socket (PryonCatalog).
 *
 * The Echo Dot and Echo Show images say so with `ro.kiosk_satellite.pryon`.
 * The service is the same with a screen and without one. Whether it has
 * anything to listen with is up to the files installed on the device, which
 * the service reports in its hello.
 */
object PryonService {
    const val PROPERTY = "ro.kiosk_satellite.pryon"

    fun detect(property: (String) -> String): Boolean = property(PROPERTY) == "1"

    val available: Boolean by lazy { detect(Headless::property) }
}
