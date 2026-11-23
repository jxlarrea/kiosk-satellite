package me.jxl.kiosk_satellite

import android.content.Context
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.Camera
import androidx.camera.core.CameraState
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The camera flashlight (issue #1574), for FlashlightManager in Dart
 * (channel `kiosk_satellite/flashlight`): `describe` says whether the
 * device has one, `set` turns it on or off. The native side calls
 * `changed` when something else switched it, such as the quick settings
 * tile.
 *
 * Android only lets [CameraManager.setTorchMode] drive the torch while no
 * one has its camera open. While the app's own session holds that camera
 * (streaming, motion detection, a snapshot), the torch goes through that
 * session's CameraX control instead: the sessions report their camera
 * through [attach]. Opening the camera turns the torch off and closing it
 * makes it available again, so the torch callback puts it back on after
 * every session that ends while the flashlight should be lit.
 *
 * Main thread only: the torch callback, the CameraX binds and the channel
 * all run there.
 */
object Flashlight {
    private const val TAG = "Flashlight"

    /** How long after our own write a torch report is taken as its echo
     *  rather than someone else's switch. */
    private const val OWN_WRITE_ECHO_MS = 1_000L

    /** The torch reads as available a moment before a closing camera has
     *  let go of it, so a write that finds it still in use tries again
     *  this often, this many times. */
    private const val RETRY_MS = 250L
    private const val RETRIES = 12

    private var manager: CameraManager? = null
    private var channel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    /** The camera whose flash unit is the flashlight, back first. */
    private var torchId: String? = null

    /** Whether the flashlight should be lit. */
    private var wanted = false

    /** Whether the torch callback has reported at least once. */
    private var known = false

    /** Whether no one has the torch's camera open, per the torch callback. */
    private var torchAvailable = false

    /** The app's own session on the torch's camera, while it has one. */
    private var bound: Camera? = null
    private var ownWriteAt = 0L
    private var retriesLeft = 0
    private val retry = Runnable {
        // A session or another app opened the camera meanwhile: the
        // torch callback or the session lights it instead.
        if (wanted && torchAvailable && bound == null) apply()
    }

    val present: Boolean get() = torchId != null

    fun register(context: Context, messenger: BinaryMessenger) {
        val cameras = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
        manager = cameras
        torchId = cameras?.let(::findTorch)
        val id = torchId
        if (cameras != null && id != null) {
            try {
                cameras.registerTorchCallback(object : CameraManager.TorchCallback() {
                    override fun onTorchModeChanged(cameraId: String, enabled: Boolean) {
                        if (cameraId == id) onTorchChanged(enabled)
                    }

                    override fun onTorchModeUnavailable(cameraId: String) {
                        if (cameraId != id) return
                        known = true
                        torchAvailable = false
                    }
                }, mainHandler)
            } catch (e: Exception) {
                Log.w(TAG, "torch callback unavailable: ${e.message}")
            }
            Log.i(TAG, "flashlight on camera $id")
        }
        channel = MethodChannel(messenger, "kiosk_satellite/flashlight").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "describe" -> result.success(mapOf("present" to present))
                    "set" -> {
                        set(call.argument<Boolean>("on") == true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun findTorch(cameras: CameraManager): String? = try {
        val withFlash = cameras.cameraIdList.filter { id ->
            try {
                cameras.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            } catch (_: Exception) {
                false
            }
        }
        withFlash.firstOrNull { id ->
            try {
                cameras.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
            } catch (_: Exception) {
                false
            }
        } ?: withFlash.firstOrNull()
    } catch (e: Exception) {
        Log.w(TAG, "camera list unavailable: ${e.message}")
        null
    }

    fun set(on: Boolean) {
        if (torchId == null) return
        wanted = on
        retriesLeft = RETRIES
        apply()
    }

    private fun apply() {
        val id = torchId ?: return
        val session = bound
        if (session != null && !torchAvailable) {
            session.cameraControl.enableTorch(wanted)
            return
        }
        try {
            ownWriteAt = SystemClock.elapsedRealtime()
            manager?.setTorchMode(id, wanted)
        } catch (e: Exception) {
            val inUse = e is CameraAccessException && e.reason == CameraAccessException.CAMERA_IN_USE
            if (inUse && torchAvailable && retriesLeft-- > 0) {
                mainHandler.removeCallbacks(retry)
                mainHandler.postDelayed(retry, RETRY_MS)
                return
            }
            // Another app has the camera. The torch callback tries again
            // once it lets go.
            Log.w(TAG, "flashlight unavailable now: ${e.message}")
        }
    }

    private fun onTorchChanged(enabled: Boolean) {
        val first = !known
        val reopened = known && !torchAvailable
        known = true
        torchAvailable = true
        if (first) return
        if (reopened) {
            // A camera session just closed and took the torch with it.
            bound = null
            if (wanted && !enabled) {
                retriesLeft = RETRIES
                apply()
            }
            return
        }
        if (enabled == wanted) return
        if (SystemClock.elapsedRealtime() - ownWriteAt < OWN_WRITE_ECHO_MS) return
        // The quick settings tile or another app switched it.
        wanted = enabled
        channel?.invokeMethod("changed", mapOf("on" to enabled))
    }

    /**
     * A session of the app's bound [camera]. On the torch's camera the
     * session now drives the flashlight, lighting it as soon as the camera
     * opens. The observer goes away with [owner].
     */
    @OptIn(ExperimentalCamera2Interop::class)
    fun attach(camera: Camera, owner: LifecycleOwner) {
        val id = torchId ?: return
        val cameraId = try {
            Camera2CameraInfo.from(camera.cameraInfo).cameraId
        } catch (_: Exception) {
            return
        }
        if (cameraId != id || !camera.cameraInfo.hasFlashUnit()) return
        bound = camera
        camera.cameraInfo.cameraState.observe(owner) { state ->
            if (state.type == CameraState.Type.OPEN && bound === camera && wanted) {
                camera.cameraControl.enableTorch(true)
            }
        }
    }
}
