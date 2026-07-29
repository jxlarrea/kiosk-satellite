package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Size
import android.view.Surface
import android.view.WindowManager
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Single-shot stills from the device's own camera (the Camera settings
 * section), sharing the sensor with [CameraMotion] instead of fighting it
 * for it.
 *
 * Android gives a camera to one open session at a time, so the two features
 * coordinate through this class:
 *
 *  - While motion detection has the camera bound, it also pre-binds an
 *    [ImageCapture] use case and parks it here ([sharedCapture]). A snapshot
 *    then rides the existing session: no second open, no session
 *    reconfigure, and no auto-exposure resettle. That last one is the
 *    important one: binding a use case on demand instead would make AE
 *    resettle, and a global luminance swing is exactly what the motion
 *    analyzer reads as motion, so every snapshot would wake the screensaver.
 *    A dormant ImageCapture costs nothing until takePicture is called.
 *
 *  - With no motion session up, a snapshot opens the camera, takes one
 *    frame, and releases everything. Nothing stays open between snapshots,
 *    so interval snapshots cost only the captures themselves.
 */
class DeviceCamera(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "kiosk_satellite/camera"
        private const val TAG = "DeviceCamera"

        // The default target (the 480p tier): fine for a Home Assistant
        // still, and a lightweight MQTT payload. The Dart side passes the
        // configured tier's size with every call, so this only backstops
        // missing arguments.
        private val DEFAULT_TARGET = Size(640, 480)
        private const val JPEG_QUALITY = 80
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    /** The motion session's pre-bound capture use case. Main thread only;
     *  set by [CameraMotion] while its session is up. */
    var sharedCapture: ImageCapture? = null

    /** Whether [CameraMotion] currently owns the camera. Main thread only.
     *  With this up and no [sharedCapture] (hardware that could not fit
     *  both use cases in one session), snapshots refuse rather than evict
     *  the motion stream. */
    var motionSessionActive = false

    /** One capture at a time; the Dart side serializes too, this is the
     *  native-side backstop. Main thread only. */
    private var busy = false

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    /** The capture use case both the ephemeral path and [CameraMotion]'s
     *  pre-bind use, so the output is identical either way. CameraX maps
     *  [target] to the nearest size the camera actually offers. */
    fun buildCapture(target: Size = DEFAULT_TARGET): ImageCapture =
        ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            .setResolutionSelector(
                ResolutionSelector.Builder()
                    .setResolutionStrategy(
                        ResolutionStrategy(
                            target,
                            ResolutionStrategy.FALLBACK_RULE_CLOSEST_LOWER_THEN_HIGHER,
                        ),
                    )
                    .build(),
            )
            .setJpegQuality(JPEG_QUALITY)
            .build()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "snapshot" -> {
                val facing = if (call.argument<String>("camera") == "back") {
                    CameraSelector.DEFAULT_BACK_CAMERA
                } else {
                    CameraSelector.DEFAULT_FRONT_CAMERA
                }
                val target = Size(
                    call.argument<Int>("width") ?: DEFAULT_TARGET.width,
                    call.argument<Int>("height") ?: DEFAULT_TARGET.height,
                )
                mainHandler.post { snapshot(facing, target, result) }
            }
            else -> result.notImplemented()
        }
    }

    private fun snapshot(
        facing: CameraSelector,
        target: Size,
        result: MethodChannel.Result,
    ) {
        if (busy) {
            result.error("busy", "a snapshot is already in progress", null)
            return
        }
        busy = true
        val done = { bytes: ByteArray?, error: String? ->
            busy = false
            if (bytes != null) {
                result.success(bytes)
            } else {
                result.error("camera", error ?: "capture failed", null)
            }
        }

        // Motion session up: ride it. The selector and target are ignored
        // on purpose; motion and snapshots share one camera choice and one
        // resolution setting (Camera settings), so the pre-bound capture
        // already matches the request.
        sharedCapture?.let {
            take(it, cleanup = null, done)
            return
        }
        if (motionSessionActive) {
            done(null, "camera busy with motion detection")
            return
        }

        // Idle: open, take one frame, release.
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            val provider = try {
                future.get()
            } catch (e: Exception) {
                done(null, "camera provider unavailable: ${e.message}")
                return@addListener
            }
            // The motion session may have started while the provider future
            // resolved; opening now would evict it mid-bind.
            if (motionSessionActive) {
                val shared = sharedCapture
                if (shared != null) take(shared, cleanup = null, done)
                else done(null, "camera busy with motion detection")
                return@addListener
            }
            val selector = resolveCameraSelector(provider, facing)
            if (selector == null) {
                done(null, NO_CAMERA_MESSAGE)
                return@addListener
            }
            val capture = buildCapture(target)
            val owner = CameraLifecycle()
            try {
                provider.bindToLifecycle(owner, selector, capture)
                owner.resume()
            } catch (e: Exception) {
                owner.destroy()
                done(null, "could not open camera: ${e.message}")
                return@addListener
            }
            take(capture, cleanup = {
                owner.destroy()
                provider.unbind(capture)
            }, done)
        }, ContextCompat.getMainExecutor(context))
    }

    private fun take(
        capture: ImageCapture,
        cleanup: (() -> Unit)?,
        done: (ByteArray?, String?) -> Unit,
    ) {
        capture.targetRotation = displayRotation()
        capture.takePicture(
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageCapturedCallback() {
                override fun onCaptureSuccess(image: ImageProxy) {
                    val bytes = try {
                        jpegBytes(image)
                    } finally {
                        image.close()
                    }
                    cleanup?.invoke()
                    if (bytes != null) {
                        Log.i(TAG, "snapshot: ${bytes.size} bytes")
                        done(bytes, null)
                    } else {
                        done(null, "unexpected capture format")
                    }
                }

                override fun onError(e: ImageCaptureException) {
                    cleanup?.invoke()
                    done(null, "capture failed: ${e.message}")
                }
            },
        )
    }

    /** takePicture's in-memory callback delivers a JPEG in plane 0, with
     *  the orientation recorded in its EXIF header. */
    private fun jpegBytes(image: ImageProxy): ByteArray? {
        if (image.format != android.graphics.ImageFormat.JPEG) return null
        val buffer = image.planes[0].buffer
        val bytes = ByteArray(buffer.remaining())
        buffer.get(bytes)
        return bytes
    }

    private fun displayRotation(): Int = try {
        @Suppress("DEPRECATION")
        (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager)
            .defaultDisplay.rotation
    } catch (_: Exception) {
        Surface.ROTATION_0
    }
}

/** What a missing camera means in practice, said plainly: on devices with
 *  a hardware privacy shutter (Echo Show), the switch disconnects the
 *  camera so completely that Android enumerates zero cameras. */
internal const val NO_CAMERA_MESSAGE =
    "no camera is available on this device (a camera privacy shutter, " +
        "if there is one, disconnects it completely)"

/** The requested selector when the device can satisfy it, the only camera
 *  present otherwise (single-camera hardware where the configured facing
 *  does not exist), or null when no camera is usable at all. */
internal fun resolveCameraSelector(
    provider: ProcessCameraProvider,
    requested: CameraSelector,
): CameraSelector? {
    val hasRequested = try {
        provider.hasCamera(requested)
    } catch (_: Exception) {
        false
    }
    if (hasRequested) return requested
    val fallback = provider.availableCameraInfos.firstOrNull()?.cameraSelector
    if (fallback != null) {
        Log.w("DeviceCamera", "configured camera missing; using the camera present")
    }
    return fallback
}

/**
 * A self-driven lifecycle so a camera binding's lifetime is exactly its
 * owner's chosen span, independent of the Activity. Mutated only on the
 * main thread. Shared by [DeviceCamera]'s ephemeral snapshots and
 * [CameraMotion]'s listen span.
 */
internal class CameraLifecycle : LifecycleOwner {
    private val registry = LifecycleRegistry(this)
    override val lifecycle: Lifecycle get() = registry

    fun resume() {
        registry.currentState = Lifecycle.State.RESUMED
    }

    fun destroy() {
        // A registry that never left INITIALIZED (bindToLifecycle threw, so
        // resume() was skipped) cannot move down: AndroidX throws "no event
        // down from INITIALIZED", a fatal main-thread crash. Step up to
        // CREATED first; from there DESTROYED is legal.
        if (registry.currentState == Lifecycle.State.INITIALIZED) {
            registry.currentState = Lifecycle.State.CREATED
        }
        registry.currentState = Lifecycle.State.DESTROYED
    }
}
