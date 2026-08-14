package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Short clicks and ticks on the vibration motor, for the dashboard's
 * button-haptics setting (see haptics_script.dart).
 *
 * The vibrator is driven directly rather than through
 * View.performHapticFeedback: the view path is silently vetoed by the
 * system's own "touch vibration" setting, which wall-mounted panels often
 * have off — a toggle that only works when a second, hidden toggle agrees
 * is a support thread waiting to happen.
 *
 * Two kinds at three strengths, mapped onto the platform's hardware-tuned
 * effects where they exist (API 29+): a button 'tap' plays TICK, CLICK or
 * HEAVY_CLICK for light/medium/strong, and a slider 'tick' always sits one
 * level softer (TICK, TICK, CLICK) so a drag across steps reads as texture
 * under the finger rather than a burst of taps. Older devices approximate
 * with amplitude-scaled one-shots; pre-O gets plain timed buzzes.
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
                    play(
                        call.argument<String>("kind") ?: "tap",
                        call.argument<String>("strength") ?: "medium",
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun play(kind: String, strength: String) {
        val v = vibrator ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val effect = if (kind == "tick") {
                    when (strength) {
                        "strong" -> VibrationEffect.EFFECT_CLICK
                        else -> VibrationEffect.EFFECT_TICK
                    }
                } else {
                    when (strength) {
                        "light" -> VibrationEffect.EFFECT_TICK
                        "strong" -> VibrationEffect.EFFECT_HEAVY_CLICK
                        else -> VibrationEffect.EFFECT_CLICK
                    }
                }
                v.vibrate(VibrationEffect.createPredefined(effect))
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val (ms, amp) = if (kind == "tick") {
                    when (strength) {
                        "light" -> 8L to 80
                        "strong" -> 15L to 180
                        else -> 10L to 120
                    }
                } else {
                    when (strength) {
                        "light" -> 12L to 120
                        "strong" -> 35L to 255
                        else -> 20L to 200
                    }
                }
                v.vibrate(VibrationEffect.createOneShot(ms, amp))
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(if (kind == "tick") 10 else 20)
            }
        } catch (_: Exception) {
            // A motor that declines is a silent tap, never an error.
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
