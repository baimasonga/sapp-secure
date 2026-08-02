plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gsit.saloneshield"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.gsit.saloneshield"
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

            // Without these rules R8 fails and no release artefact is produced
            // at all. See proguard-rules.pro for why the missing ML Kit
            // language recognisers are warned away rather than kept.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    testOptions {
        unitTests {
            // The notification guard is deliberately free of Android types so
            // it can be tested here rather than only on a device.
            isIncludeAndroidResources = false
        }
    }
}

dependencies {
    // NotificationCompat and NotificationManagerCompat, used by the
    // notification listener. Declared rather than inherited so an embedding
    // change cannot quietly remove it.
    implementation("androidx.core:core-ktx:1.13.1")

    testImplementation("junit:junit:4.13.2")
    // android.jar's org.json is a stub that throws; the real implementation is
    // needed to parse the rules asset under a JVM test.
    testImplementation("org.json:json:20240303")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
