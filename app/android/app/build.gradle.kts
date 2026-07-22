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
    val cameraxVersion = "1.3.4"
    implementation("androidx.camera:camera-core:$cameraxVersion")
    implementation("androidx.camera:camera-camera2:$cameraxVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraxVersion")

    // SendSpin synchronized-audio player (me.jxl.kiosk_satellite.sendspin).
    // kotlinx-serialization-json is used only through its JSON tree API
    // (buildJsonObject / parseToJsonElement), so the serialization compiler
    // plugin is not required.
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
}
