plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mobile_internet_scaner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mobile_internet_scaner"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    applicationVariants.all {
        outputs.all {
            val outputImpl = this
            if (outputImpl is com.android.build.gradle.internal.api.BaseVariantOutputImpl) {
                val buildType = name
                val appName = "mobile_internet_scaner"
                outputImpl.outputFileName = "${appName}-${buildType}.apk"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

tasks.register<Copy>("renameApk") {
    doFirst {
        val buildTypes = listOf("release", "debug")
        buildTypes.forEach { type ->
            val dir = file("$buildDir/outputs/apk/$type")
            val src = File(dir, "app-$type.apk")
            val dst = File(dir, "mobile_internet_scaner-$type.apk")
            if (src.exists()) {
                src.copyTo(dst, overwrite = true)
                src.delete()
            }
        }
    }
}

// Автоматический запуск renameApk после сборки
afterEvaluate {
    tasks.named("assembleRelease").configure {
        finalizedBy(tasks.named("renameApk"))
    }
    tasks.named("assembleDebug").configure {
        finalizedBy(tasks.named("renameApk"))
    }
}

// Гарантированное переименование apk после packageRelease и packageDebug
afterEvaluate {
    tasks.matching { it.name == "packageRelease" || it.name == "packageDebug" }.configureEach {
        doLast {
            val buildType = if (name.contains("Release")) "release" else "debug"
            val dir = file("$buildDir/outputs/apk/$buildType")
            val src = File(dir, "app-$buildType.apk")
            val dst = File(dir, "mobile_internet_scaner-$buildType.apk")
            if (src.exists()) {
                src.copyTo(dst, overwrite = true)
                src.delete()
            }
        }
    }
}
