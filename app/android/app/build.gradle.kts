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

    // LiteRT for the screensaver's face detection (FaceDetector.kt). The
    // runtime is already in the APK through tflite_flutter (0.12.1 pins
    // this exact version), but that plugin declares it as an implementation
    // dependency, so the app's own Kotlin cannot see it without naming it
    // here. Keep the version in lockstep with the plugin's, or the build
    // ships two copies.
    implementation("com.google.ai.edge.litert:litert:1.4.0")

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
