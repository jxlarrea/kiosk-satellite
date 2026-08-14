package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * A short click on the vibration motor, for the dashboard's button-haptics
 * setting (see haptics_script.dart).
 *
 * The vibrator is driven directly rather than through
 * View.performHapticFeedback: the view path is silently vetoed by the
 * system's own "touch vibration" setting, which wall-mounted panels often
 * have off — a toggle that only works when a second, hidden toggle agrees
 * is a support thread waiting to happen. EFFECT_CLICK is the crisp
 * hardware-tuned click where the platform has one (API 29+); older
 * devices get a 20ms one-shot, which is the same thing slightly softer.
 *
 * [hasVibrator] lets Dart cache whether a motor exists at all, so devices
 * without one (most Fire tablets, Echo Shows) never send per-tap traffic.
 */
class HapticsBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/haptics")

    private val vibrator: Vibrator? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    } catch (_: Exception) {
        null
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasVibrator" -> result.success(vibrator?.hasVibrator() == true)
                "tap" -> {
                    tap()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun tap() {
        val v = vibrator ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK))
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(
                    VibrationEffect.createOneShot(20, VibrationEffect.DEFAULT_AMPLITUDE),
                )
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(20)
            }
        } catch (_: Exception) {
            // A motor that declines is a silent tap, never an error.
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
