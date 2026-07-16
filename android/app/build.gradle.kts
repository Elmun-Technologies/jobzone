import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Cloud Messaging (push) — reads google-services.json in this dir.
    id("com.google.gms.google-services")
}

// Release-signing config lives in android/key.properties (gitignored — never
// committed). Load it lazily: if the file is absent (fresh checkout, CI without
// the secret, `flutter run --release` on a dev box) `keystoreProperties` stays
// empty and the release buildType silently falls back to the debug keystore for
// local iteration. A real Play upload rejects debug-signed AABs, so
// `key.properties` MUST exist on the machine that produces the release artifact
// — see docs/android-signing.md.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile")?.isNotEmpty() == true

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

    // Register the release signing config only when key.properties supplies the
    // four required values. Without them Gradle would fail to resolve the block
    // at configure-time, breaking every task (including `flutter run --debug`).
    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // With key.properties present → sign with the upload keystore
            // registered above (Play Console accepts this). Without it → fall
            // back to the debug key so `flutter run --release` still works on
            // dev machines, but a Play upload will be rejected until the
            // developer follows docs/android-signing.md.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

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
