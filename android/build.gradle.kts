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

    // image_gallery_saver 2.0.3처럼 오래된 Android 플러그인은 AGP 8+ 필수값인
    // namespace가 빠져 있습니다. pub cache를 직접 고치지 않고 현재 프로젝트 빌드에서만 보정합니다.
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            if (namespace == null && project.name == "image_gallery_saver") {
                namespace = "com.example.imagegallerysaver"
            }

            // Flutter 3.38 템플릿은 Java/Kotlin 17을 기준으로 빌드하므로,
            // 오래된 플러그인의 Java 1.8 기본값과 Kotlin 17 사이의 불일치를 맞춥니다.
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
