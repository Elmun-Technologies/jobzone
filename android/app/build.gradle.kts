plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Cloud Messaging (push) — reads google-services.json in this dir.
    id("com.google.gms.google-services")
}

android {
    namespace = "io.jobzone.jobzone"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (uses java.time APIs).
        isCoreLibraryDesugaringEnabled = true
        // Java 21 to match the toolchain AGP 9 runs on — plugin modules (e.g.
        // the official Yandex SDK) compile to 21 bytecode, and a 17-pinned app
        // javac can't read their classes ("wrong version 65.0, should be 61.0").
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.jobzone.jobzone"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // The official Yandex MapKit SDK (yandex_maps_mapkit_lite) requires
        // Android API 26+, so we pin it here over flutter's default (24).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Shrink + obfuscate the Java/Kotlin plugin layer (R8) and strip
            // unused Android resources, so the test APK downloads smaller. Keep
            // rules for the reflection/JNI-heavy SDKs live in proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Enables core library desugaring required by flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
