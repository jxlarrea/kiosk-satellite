package me.jxl.kiosk_satellite

import android.content.Context
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Size
import android.view.Surface
import android.view.WindowManager
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import java.io.ByteArrayOutputStream
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

        /** How long a capture (or the provider behind it) may take before
         *  the caller gets an error instead of silence. Generous: a cold
         *  camera open plus capture is a few seconds at worst. */
        private const val PROVIDER_TIMEOUT_MS = 20_000L

        /** Frames skipped before the legacy path takes its picture: the
         *  stream's first frames arrive before auto-exposure settles and
         *  come out dark. */
        private const val WARMUP_FRAMES = 6
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
     *  bound use case resets its pipeline, and the legacy HAL shim (Echo
     *  Show 5) silently drops the in-flight capture on that reset — the
     *  request never completes and never errors. */
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
                mainHandler.post { snapshot(cameraName, facing, target, result) }
            }
            // Whether any camera exists at all. False on hardware whose ROM
            // ships no camera HAL (LineageOS ports on Echo Shows) - the
            // settings surfaces warn instead of offering switches that can
            // only fail. Answered from Camera2 directly, with a CameraX
            // provider timeout as the backstop: a wedged CameraX init must
            // not leave the Dart probe waiting forever.
            "hasCamera" -> {
                mainHandler.post {
                    var answered = false
                    val answer = { has: Boolean ->
                        if (!answered) {
                            answered = true
                            result.success(has)
                        }
                    }
                    mainHandler.postDelayed({
                        Log.w(TAG, "hasCamera: provider timed out")
                        answer(cameraFacings(context).isNotEmpty())
                    }, PROVIDER_TIMEOUT_MS)
                    val future = ProcessCameraProvider.getInstance(context)
                    future.addListener({
                        val has = try {
                            future.get().availableCameraInfos.isNotEmpty()
                        } catch (_: Exception) {
                            false
                        }
                        answer(has)
                    }, ContextCompat.getMainExecutor(context))
                }
            }
            // The lens facings that exist, for pickers that should not
            // offer a camera the device does not have.
            "facings" -> result.success(cameraFacings(context))
            else -> result.notImplemented()
        }
    }

    private fun snapshot(
        cameraName: String?,
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
        // and the legacy HAL shim (Echo Show 5) answers a session reset by
        // silently dropping the in-flight request.
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
            // LEGACY hardware runs the Camera1 shim, and some ROMs ship its
            // still-capture path broken: on the Echo Show 5 the ISP driver
            // never delivers takePicture's JPEG ("Hit timeout for jpeg
            // callback"), with no error surfaced to the app. The preview
            // stream works fine there, so grab a frame from an analysis
            // stream and encode the JPEG ourselves.
            if (isLegacyHardware(context, cameraName)) {
                val analysis = ImageAnalysis.Builder()
                    .setResolutionSelector(
                        ResolutionSelector.Builder()
                            .setResolutionStrategy(
                                ResolutionStrategy(
                                    target,
                                    ResolutionStrategy
                                        .FALLBACK_RULE_CLOSEST_LOWER_THEN_HIGHER,
                                ),
                            )
                            .build(),
                    )
                    .setBackpressureStrategy(
                        ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST,
                    )
                    .build()
                val owner = CameraLifecycle()
                cleanup = {
                    owner.destroy()
                    provider.unbind(analysis)
                }
                var frames = 0
                analysis.setAnalyzer(ContextCompat.getMainExecutor(context)) { image ->
                    if (++frames < WARMUP_FRAMES) {
                        image.close()
                        return@setAnalyzer
                    }
                    analysis.clearAnalyzer()
                    val bytes = try {
                        yuvJpegBytes(image)
                    } finally {
                        image.close()
                    }
                    if (bytes != null) {
                        Log.i(TAG, "snapshot (legacy path): ${bytes.size} bytes")
                        done(bytes, null)
                    } else {
                        done(null, "unexpected frame format")
                    }
                }
                try {
                    provider.bindToLifecycle(owner, selector, analysis)
                    owner.resume()
                } catch (e: Exception) {
                    done(null, "could not open camera: ${e.message}")
                }
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
        // which the legacy HAL shim answers by dropping the capture.
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

    /** A JPEG from a YUV_420_888 analysis frame (the legacy path), as the
     *  sensor delivered it. Deliberately NOT rotated by the frame's
     *  rotation metadata: the one legacy fleet this path exists for (Echo
     *  Show 5 on LineageOS) reports a phone-style 90-degree sensor
     *  orientation that is physically wrong — the raw frame is already
     *  upright on the landscape-mounted sensor, and "correcting" it turned
     *  the picture sideways on the device this was verified on. */
    private fun yuvJpegBytes(image: ImageProxy): ByteArray? {
        if (image.format != ImageFormat.YUV_420_888) return null
        val yuv = YuvImage(
            nv21Bytes(image), ImageFormat.NV21, image.width, image.height, null,
        )
        val out = ByteArrayOutputStream()
        if (!yuv.compressToJpeg(
                Rect(0, 0, image.width, image.height), JPEG_QUALITY, out,
            )
        ) {
            return null
        }
        return out.toByteArray()
    }

    /** YUV_420_888 planes to NV21, honoring row and pixel strides. */
    private fun nv21Bytes(image: ImageProxy): ByteArray {
        val width = image.width
        val height = image.height
        val nv21 = ByteArray(width * height * 3 / 2)
        val y = image.planes[0]
        var pos = 0
        for (row in 0 until height) {
            for (col in 0 until width) {
                nv21[pos++] = y.buffer.get(row * y.rowStride + col * y.pixelStride)
            }
        }
        val u = image.planes[1]
        val v = image.planes[2]
        for (row in 0 until height / 2) {
            for (col in 0 until width / 2) {
                nv21[pos++] = v.buffer.get(row * v.rowStride + col * v.pixelStride)
                nv21[pos++] = u.buffer.get(row * u.rowStride + col * u.pixelStride)
            }
        }
        return nv21
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

/** Whether [cameraName]'s ("front"/"back"; null or unmatched falls back to
 *  the first camera) hardware level is LEGACY — the Camera1 shim, whose
 *  still-capture path some ROMs ship broken (Echo Show 5: the ISP driver
 *  never delivers takePicture's JPEG). Capture paths route around
 *  takePicture entirely on these. */
internal fun isLegacyHardware(context: Context, cameraName: String?): Boolean = try {
    val manager =
        context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    val wanted = when (cameraName) {
        "front" -> CameraCharacteristics.LENS_FACING_FRONT
        "back" -> CameraCharacteristics.LENS_FACING_BACK
        else -> null
    }
    val ids = manager.cameraIdList
    val id = ids.firstOrNull { candidate ->
        wanted != null &&
            manager.getCameraCharacteristics(candidate)
                .get(CameraCharacteristics.LENS_FACING) == wanted
    } ?: ids.firstOrNull()
    id != null &&
        manager.getCameraCharacteristics(id)
            .get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL) ==
        CameraMetadata.INFO_SUPPORTED_HARDWARE_LEVEL_LEGACY
} catch (_: Exception) {
    false
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
