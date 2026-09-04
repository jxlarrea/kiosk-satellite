package me.jxl.kiosk_satellite

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
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
        // still, and a lightweight payload. The Dart side passes the
        // configured tier's size with every call, so this only backstops
        // missing arguments.
        private val DEFAULT_TARGET = Size(640, 480)
        private const val JPEG_QUALITY = 80

        /** How long a capture (or the provider behind it) may take before
         *  the caller gets an error instead of silence. Generous: a cold
         *  camera open plus capture is a few seconds at worst. */
        private const val PROVIDER_TIMEOUT_MS = 20_000L
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
     *  [target] to the nearest size the camera actually offers. The display
     *  rotation is baked in at build time: assigning targetRotation on a
     *  bound use case resets its pipeline, which fragile legacy HALs have
     *  answered by silently dropping the in-flight capture. */
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
            .setTargetRotation(displayRotation())
            .build()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "snapshot" -> {
                val cameraName = call.argument<String>("camera")
                val facing = if (cameraName == "back") {
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
            // Whether the device has a usable camera at all: hardware
            // with no camera service (e-ink tablets) and a privacy shutter
            // that unplugs the camera both get warnings in the settings
            // instead of switches that can only fail. Camera2's plain
            // enumeration is the whole answer. CameraX is never touched
            // here: on cameraless hardware its camera presence tracking
            // (CameraX 1.5+) registers availability callbacks that make
            // the platform retry the missing camera service every second,
            // forever - a log line and a binder attempt per second that
            // pegged a weak SoC at 100% CPU (issue #193). And where a
            // camera exists, asking CameraX to confirm gave an answer that
            // depended on timing: a fast initialization failure said no
            // while a slow one fell back to Camera2 and said yes, so a
            // tablet with a phantom camera in its HAL showed its camera
            // entities on some boots and not others. A camera Camera2
            // lists but CameraX cannot open reports that plainly when it
            // is used.
            "hasCamera" -> result.success(cameraFacings(context).isNotEmpty())
            // The lens facings that exist, for pickers that should not
            // offer a camera the device does not have.
            "facings" -> result.success(cameraFacings(context))
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
        var completed = false
        // The idle path parks its teardown here so that EVERY exit — a
        // frame, a capture error, or the watchdog below — releases the
        // camera. A timed-out attempt that stayed bound poisoned all later
        // ones: the next bind detached the leaked use case mid-capture,
        // a session reset fragile HALs answer by silently dropping the
        // in-flight request.
        var cleanup: (() -> Unit)? = null
        val done = done@{ bytes: ByteArray?, error: String? ->
            if (completed) return@done
            completed = true
            busy = false
            cleanup?.invoke()
            if (bytes != null) {
                result.success(bytes)
            } else {
                result.error("camera", error ?: "capture failed", null)
            }
        }
        // Self-heal: a capture that never completes (a CameraX init that
        // never resolves its provider, a HAL that never delivers) must not
        // wedge `busy` until app restart and leave the caller waiting on
        // silence. `done` is idempotent, so a late real completion is a
        // no-op after this fires.
        mainHandler.postDelayed(
            { done(null, "the camera did not answer in time") },
            PROVIDER_TIMEOUT_MS,
        )

        // Motion session up: ride it. The selector and target are ignored
        // on purpose; motion and snapshots share one camera choice and one
        // resolution setting (Camera settings), so the pre-bound capture
        // already matches the request.
        sharedCapture?.let {
            take(it, done)
            return
        }
        if (motionSessionActive) {
            done(null, "camera busy with motion detection")
            return
        }

        // No camera hardware: answer plainly without waking CameraX, whose
        // presence tracking would retry the missing camera service forever
        // (see the hasCamera comment, issue #193).
        if (cameraFacings(context).isEmpty()) {
            done(null, NO_CAMERA_MESSAGE)
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
                if (shared != null) take(shared, done)
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
            // Parked before the bind: whichever way this attempt ends,
            // done() tears the session down (unbinding a use case that
            // never bound is a no-op).
            cleanup = {
                owner.destroy()
                provider.unbind(capture)
            }
            try {
                provider.bindToLifecycle(owner, selector, capture)
                owner.resume()
            } catch (e: Exception) {
                done(null, "could not open camera: ${e.message}")
                return@addListener
            }
            take(capture, done)
        }, ContextCompat.getMainExecutor(context))
    }

    private fun take(
        capture: ImageCapture,
        done: (ByteArray?, String?) -> Unit,
    ) {
        // Only assign on an actual change (a rotated kiosk since the use
        // case was built): the assignment itself resets a bound pipeline,
        // which fragile legacy HALs answer by dropping the capture.
        val rotation = displayRotation()
        if (capture.targetRotation != rotation) {
            capture.targetRotation = rotation
        }
        capture.takePicture(
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageCapturedCallback() {
                override fun onCaptureSuccess(image: ImageProxy) {
                    val bytes = try {
                        jpegBytes(image)
                    } finally {
                        image.close()
                    }
                    if (bytes != null) {
                        Log.i(TAG, "snapshot: ${bytes.size} bytes")
                        done(bytes, null)
                    } else {
                        done(null, "unexpected capture format")
                    }
                }

                override fun onError(e: ImageCaptureException) {
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

/** The lens facings Camera2 reports, as "front"/"back" strings (external
 *  cameras ignored). Camera2 only, no CameraX: safe to call before — or
 *  instead of — CameraX init, which is exactly what [KioskApplication]'s
 *  limiter and the settings pickers need. */
internal fun cameraFacings(context: Context): List<String> = try {
    val manager =
        context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    manager.cameraIdList.mapNotNull { id ->
        when (
            manager.getCameraCharacteristics(id)
                .get(CameraCharacteristics.LENS_FACING)
        ) {
            CameraCharacteristics.LENS_FACING_FRONT -> "front"
            CameraCharacteristics.LENS_FACING_BACK -> "back"
            else -> null
        }
    }.distinct()
} catch (_: Exception) {
    emptyList()
}

/** The cameras whose lens facing CameraX can read, as the selector for
 *  [KioskApplication]'s availableCamerasLimiter. Some HALs pad the camera
 *  list with a phantom device carrying garbage static metadata (a Unisoc
 *  wall tablet: one real front camera plus an id 1 whose LENS_FACING is
 *  255), and CameraX's own lens-facing filter throws on the first facing
 *  it cannot read instead of skipping it, which failed initialization
 *  outright and took the real camera down with the phantom. Filtering per
 *  camera drops only the ones that cannot be read. */
internal fun readableCamerasSelector(): CameraSelector =
    CameraSelector.Builder()
        .addCameraFilter { infos ->
            val readable = withReadableFacing(infos) { it.lensFacing }
            if (readable.size != infos.size) {
                Log.w(
                    "DeviceCamera",
                    "skipping ${infos.size - readable.size} camera(s) whose lens facing cannot be read",
                )
            }
            readable
        }
        .build()

/** The [items] whose [facing] reads without throwing, in order. */
internal fun <T> withReadableFacing(items: List<T>, facing: (T) -> Int): List<T> =
    items.filter { item ->
        try {
            facing(item)
            true
        } catch (_: Exception) {
            false
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
