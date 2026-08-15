plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.lb_partner"

    // 🔥 Required by plugins (Android 15+ ready)
    compileSdk = 36

    // 🔥 Required for 16 KB page size support
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // ✅ REQUIRED for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.lb_partner"
        minSdk = flutter.minSdkVersion
        targetSdk = 35   // OK to keep 35; 36 also fine

        versionCode = 10
        versionName = "1.0.10"

        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }

        // Required for 16 KB memory page size support
        manifestPlaceholders["android.maxAspectRatio"] = "2.1"
    }

    buildTypes {
        release {
            // keep your real signing config if you have one
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}


/* 🔴 THIS BLOCK WAS MISSING */
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
