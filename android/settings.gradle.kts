pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP pinned to the 8.x line: the yandex_mapkit 4.2.1 plugin's build.gradle
    // uses the `compileSdkVersion` DSL that AGP 9 removed, which left the MapKit
    // AAR off the plugin's compile classpath (every MapKit class unresolved).
    // 8.7.3 restores it. Gradle 8.11.1 / Kotlin 2.1.0 match this AGP line.
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    // Firebase Cloud Messaging (push) — reads android/app/google-services.json.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
