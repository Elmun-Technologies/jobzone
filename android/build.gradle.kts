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
