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

subprojects {
    val configureAndroid = { proj: Project ->
        if (proj.hasProperty("android")) {
            val android = proj.extensions.getByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                // Force compileSdkVersion of all plugin subprojects to at least 34 to satisfy AAR requirements
                if (android.compileSdkVersion == null || 
                    android.compileSdkVersion == "android-33" || 
                    android.compileSdkVersion == "33" || 
                    android.compileSdkVersion == "android-32" || 
                    android.compileSdkVersion == "32") {
                    android.compileSdkVersion = "android-34"
                }
            }
        }
    }

    if (state.executed) {
        configureAndroid(this)
    } else {
        afterEvaluate {
            configureAndroid(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
