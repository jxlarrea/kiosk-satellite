package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Build

/**
 * How Kiosk Satellite introduces itself on the wire from the native side.
 *
 * The Dart half has its own copy of this string (core/app_identity.dart)
 * and hands it to every dart:io client; the players and sockets that live
 * in Kotlin have their own HTTP stacks (OkHttp, Media3) that would
 * otherwise announce themselves as the library rather than the app. Same
 * shape either way, so one log line reads the same wherever it came from.
 *
 * [configure] runs from the Activity, which is the only place with a
 * Context guaranteed to be up before anything connects; callers deep in
 * the audio stack just read [userAgent], which falls back to the bare
 * product name if it is somehow read first.
 */
object AppIdentity {
    private const val PRODUCT = "KioskSatellite"
    private const val HOMEPAGE = "https://github.com/jxlarrea/kiosk-satellite"

    @Volatile
    private var cached: String? = null

    /** `KioskSatellite/2026.8.14 (Android 12; +https://github.com/...)`. */
    val userAgent: String get() = cached ?: PRODUCT

    /**
     * No device model in the string: it reaches servers the app does not
     * own, and the model is a fingerprint they have no business collecting.
     */
    fun configure(context: Context) {
        if (cached != null) return
        val version = try {
            context.packageManager
                .getPackageInfo(context.packageName, 0).versionName ?: "unknown"
        } catch (_: Exception) {
            "unknown"
        }
        cached = "$PRODUCT/$version (Android ${Build.VERSION.RELEASE}; +$HOMEPAGE)"
    }
}
