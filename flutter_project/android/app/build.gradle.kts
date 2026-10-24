import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Signing
//
// `key.properties` (git-ignored) holds the release credentials so nothing
// secret lands in source control. Missing file => fall back to the debug key
// so `flutter run --release` keeps working on a fresh clone.
// ---------------------------------------------------------------------------
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.lahorebus"
    // The original app targeted SDK 36 (Android 16).
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Flutter's release builds are already heavily optimised; keep core
        // library desugaring available for any plugin that needs it.
        isCoreLibraryDesugaringEnabled = false
    }

    signingConfigs {
        if (keystoreProperties.getProperty("storeFile") != null) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.lahorebus"
        // minSdk 24 matches the original APK.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Drop the unsupported ABIs and keep the two that are worth shipping.
        ndk {
            abiFilters += setOf("arm64-v8a", "armeabi-v7a")
        }

        vectorDrawables { useSupportLibrary = true }
    }

    buildTypes {
        release {
            // Production signing when a keystore is configured, debug otherwise.
            signingConfig =
                if (signingConfigs.names.contains("release")) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }

            // Production hardening: code shrinking, resource shrinking and
            // obfuscation. This is what turns a debug-shaped artifact into a
            // shippable release.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )

            // Deterministic, reproducible output where the toolchain allows it.
            isPseudoLocalesEnabled = false
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "/META-INF/{AL2.0,LGPL2.1}",
                "/META-INF/DEPENDENCIES",
                "META-INF/*.kotlin_module",
            )
        }
    }

    bundle {
        language { enableSplit = false }
        density { enableSplit = false }
        abi { enableSplit = true }
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
