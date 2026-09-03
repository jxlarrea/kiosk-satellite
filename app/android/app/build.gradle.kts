import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The release signing identity. Local builds read android/key.properties
// (git-ignored); CI provides the same four values through the environment.
// Neither present means a contributor build: it falls back to the debug
// key, which runs fine but cannot update a released install.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun signing(name: String): String? =
    keystoreProperties.getProperty(name) ?: System.getenv(
        "ANDROID_" + name.replace(Regex("([A-Z])"), "_$1").uppercase()
    )

android {
    namespace = "me.jxl.kiosk_satellite"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // The face detection model (FaceDetector.kt) is memory-mapped straight
    // out of the APK, which only works on an asset stored uncompressed.
    androidResources {
        noCompress.add("tflite")
        noCompress.add("task")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "me.jxl.kiosk_satellite"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // onnxruntime AAR requires API 24+; also fine for kiosk tablets.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        externalNativeBuild {
            cmake {
                arguments("-DANDROID_STL=c++_static")
            }
        }
    }

    // Native SendSpin engine (sendspin-cpp + JNI bridge).
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    signingConfigs {
        create("release") {
            val storeFilePath = signing("storeFile")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = signing("storePassword")
                keyAlias = signing("keyAlias")
                keyPassword = signing("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (signing("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Only ADDS the JNI keep rules; the R8 baseline the Flutter
            // plugin configures stays as it was.
            proguardFiles("proguard-rules.pro")
        }
        // Same signing as release so a profile build installs OVER the
        // release app (keeping its data) when profiling on a test device.
        getByName("profile") {
            signingConfig = if (signing("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// See the LiteRT note in dependencies: tflite_flutter pins 1.4.0, the one
// release whose native library cannot load on Android 7.
val litertVersion = "1.4.2"

configurations.all {
    resolutionStrategy {
        force(
            "com.google.ai.edge.litert:litert:$litertVersion",
            "com.google.ai.edge.litert:litert-gpu:$litertVersion",
        )
    }
}

dependencies {
    // CameraX for low-cost motion detection (YUV luminance analysis only).
    // Ceiling: 1.5.x is the last line whose Camera2Config is the legacy
    // camera2 backend. 1.6.0 replaced it with camera-pipe (CXCP) with no
    // opt-out, and on some LIMITED-level HALs that backend pegs a core for
    // as long as the camera is bound (issue #164, Galaxy Tab S6 Lite).
    // mobile_scanner asks for 1.6.1; the root build.gradle.kts forces every
    // subproject onto this version, so bump the two together only after
    // camera-pipe is proven out on limited hardware.
    val cameraxVersion = "1.5.1"
    implementation("androidx.camera:camera-core:$cameraxVersion")
    implementation("androidx.camera:camera-camera2:$cameraxVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraxVersion")

    // LiteRT for the screensaver's face detection (FaceDetector.kt) and,
    // through tflite_flutter, the wake word engine. The plugin (0.12.1)
    // pins 1.4.0 as an implementation dependency, so the app's own Kotlin
    // cannot see it without naming it here, and the force below keeps the
    // build on one copy.
    //
    // The version is constrained by Android 7 (issue #331): the native
    // library of 1.4.0 alone imports strtod_l, a libc call bionic only
    // grew at API 26, so on API 24/25 it cannot be loaded at all (1.3.0,
    // 1.4.1 and 1.4.2 are clean). Before bumping, check the new AAR:
    //   readelf --dyn-syms -W jni/arm64-v8a/libtensorflowlite_jni.so \
    //     | grep strtod_l
    // must print nothing, on every ABI. VisionRuntime.kt probes the load
    // on Android 7 and both settings surfaces say so when it fails.
    //
    // The second constraint is devices that take CPU cores offline at idle
    // (the MediaTek Echo Shows, issue #416). Every 1.x release bundles a
    // Ruy older than its November 2023 cpuinfo null checks, so the first
    // matrix multiply a built-in kernel runs walks the cache topology and
    // dereferences null when a core sharing a cache is offline at that
    // moment: SIGSEGV at TfLiteInterpreterInvoke, one cold start in three
    // on an Echo Show 8. XNNPACK does not use Ruy, so the wake word isolate
    // applies XNNPACK by hand with variable operators on, which takes every
    // node of the microWakeWord models (xnnpack_variable_ops.dart); 1.4.0
    // happened to delegate them fully by default, 1.3.0, 1.4.1 and 1.4.2 do
    // not. Before bumping, repeat the check on an Echo Show with the cores
    // held offline (adb root): echo 0 > /proc/hps/enabled, echo 0 >
    // /sys/devices/system/cpu/cpu{1,2,3}/online, then restart the app on
    // microWakeWord a few times and read logcat -b crash; the probeMww
    // command with compare: true shows both setups' outputs side by side.
    // Put hps back to 1 afterwards.
    implementation("com.google.ai.edge.litert:litert:$litertVersion")
    // MediaPipe Tasks: the hand landmarker (palm detection, tracking,
    // smoothing and the full landmark model in one graph) behind the Show
    // fingers gesture. Same constraint as LiteRT above: 0.10.28 and later
    // import strtod_l (libmediapipe_tasks_vision_jni.so) and fail to load
    // on Android 7; 0.10.26.1 is the newest clean release.
    implementation("com.google.mediapipe:tasks-vision:0.10.26.1")

    // Media3 ExoPlayer for streamed Voice Satellite sounds (TTS): its whole
    // pipeline runs in-process, so the output is an app-owned AudioTrack
    // whose device pin OEM audio policies honor where MediaPlayer's is
    // ignored (issue #93). Only the core module: sounds are progressive
    // audio, no DASH/HLS/UI.
    implementation("androidx.media3:media3-exoplayer:1.10.1")

    // SendSpin synchronized-audio player (me.jxl.kiosk_satellite.sendspin).
    // kotlinx-serialization-json is used only through its JSON tree API
    // (buildJsonObject / parseToJsonElement), so the serialization compiler
    // plugin is not required.
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // Bluetooth proxy (me.jxl.kiosk_satellite.btproxy): the ESPHome native
    // API requires Noise_NNpsk0_25519_ChaChaPoly_SHA256, and the platform
    // JCA only grows X25519 at API 33 (minSdk is 24). BouncyCastle's
    // lightweight (non-JCA) API provides X25519 + ChaCha20Poly1305 on every
    // supported level; R8 strips all but the referenced primitives from the
    // release build.
    implementation("org.bouncycastle:bcprov-jdk18on:1.78.1")

    // The btproxy protocol layer is deliberately Android-free so it runs
    // under plain JVM unit tests, where a real aioesphomeapi client can
    // exercise the wire format end to end.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit:2.3.20")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
}
