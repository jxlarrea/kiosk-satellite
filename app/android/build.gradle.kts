allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Keep CameraX on the legacy camera2 backend everywhere. Plugins pull
    // 1.6.x (mobile_scanner asks for 1.6.1), whose Camera2Config is the
    // camera-pipe rewrite with no way back to the old implementation; on
    // some LIMITED-level camera HALs that backend burns a full core while
    // the motion camera is bound (issue #164). Forcing the version at
    // resolution time also makes plugins compile against 1.5.1, so an API
    // they need that 1.5.1 lacks fails the build instead of crashing at
    // runtime. Keep in lockstep with cameraxVersion in app/build.gradle.kts.
    configurations.all {
        resolutionStrategy {
            force(
                "androidx.camera:camera-core:1.5.1",
                "androidx.camera:camera-camera2:1.5.1",
                "androidx.camera:camera-lifecycle:1.5.1",
            )
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Some plugins (e.g. onnxruntime 1.4.1) hardcode an old compileSdk that AGP 9
// + modern androidx reject. Force every Android subproject up to compileSdk 36
// so the build's AAR-metadata check passes. Registered before the
// evaluationDependsOn block below so it isn't added post-evaluation.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            val android = ext as com.android.build.gradle.BaseExtension
            val current = android.compileSdkVersion?.substringAfter("-")?.toIntOrNull()
            if (current == null || current < 36) {
                android.compileSdkVersion(36)
            }
            // Older plugins (e.g. tflite_flutter 0.12.1) pin Java to 11 while
            // their Kotlin follows the JDK we build with, and AGP 9 rejects the
            // mismatch outright ("Inconsistent JVM-target compatibility").
            // Pull both onto the app's target rather than let the plugin decide.
            android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
            android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
            )
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
