package me.jxl.kiosk_satellite

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var provisionChannel: MethodChannel? = null

    private var micRecorder: MicRecorder? = null
    private var background: BackgroundBridge? = null
    private var deviceDetails: DeviceDetails? = null
    private var cameraMotion: CameraMotion? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        micRecorder = MicRecorder(flutterEngine.dartExecutor.binaryMessenger)
        background = BackgroundBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        deviceDetails = DeviceDetails(this, flutterEngine.dartExecutor.binaryMessenger)
        cameraMotion = CameraMotion(this, flutterEngine.dartExecutor.binaryMessenger)
        provisionChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "kiosk_satellite/provision"
        )
        provisionChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // Settings JSON passed as a launch-intent extra:
                //   adb shell am start -n me.jxl.kiosk_satellite/.MainActivity \
                //     --es ks.provision '{"remote.enabled":true,...}'
                "getProvisionJson" -> result.success(intent?.getStringExtra("ks.provision"))
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        background?.dispose()
        background = null
        deviceDetails?.dispose()
        deviceDetails = null
        cameraMotion?.dispose()
        cameraMotion = null
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Activity already running (launchMode singleTop): push instead of pull.
        intent.getStringExtra("ks.provision")?.let {
            provisionChannel?.invokeMethod("provision", it)
        }
    }
}
