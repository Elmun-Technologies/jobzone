allprojects {
    repositories {
        google()
        mavenCentral()
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
// Force every Android library subproject to compile against at least SDK 36.
// Runs in afterEvaluate so it overrides the plugin's own build.gradle value.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
            ?.let { ext ->
                if ((ext.compileSdk ?: 0) < 36) {
                    ext.compileSdk = 36
                }
            }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
