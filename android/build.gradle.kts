allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // The yandex_mapkit 4.2.1 plugin ALWAYS compiles its `lite` controller,
    // which imports traffic + user-location listeners that only ship in the
    // `full` MapKit bundle. The plugin otherwise pulls maps.mobile:4.22.0-lite,
    // and Gradle even prefers `-lite` over `-full` in conflict resolution
    // ("lite" > "full" as a string). Force the module to -full, which carries
    // those classes (verified present in the -full AAR). NOTE: the APK CI also
    // applies this via a Gradle init script — repo-level hooks here did not
    // always reach the plugin subproject's own configuration.
    configurations.all {
        resolutionStrategy {
            force("com.yandex.android:maps.mobile:4.22.0-full")
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
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (e.g. yandex_mapkit 4.2.1) hardcode an older compileSdk (35) than
// newer transitive deps require (flutter_plugin_android_lifecycle needs 36).
// Bump every Android library subproject to at least SDK 36.
//
// `evaluationDependsOn(":app")` above can leave some projects already evaluated
// by the time this runs, so calling afterEvaluate would throw; guard on
// state.executed and apply directly in that case. Library extensions only — the
// app module is already on 36 (Flutter default) and isn't a LibraryExtension.
subprojects {
    val proj = this
    val bumpCompileSdk: () -> Unit = {
        proj.extensions
            .findByType(com.android.build.api.dsl.LibraryExtension::class.java)
            ?.let { ext -> if ((ext.compileSdk ?: 0) < 36) ext.compileSdk = 36 }
        Unit
    }
    if (proj.state.executed) bumpCompileSdk() else proj.afterEvaluate { bumpCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
