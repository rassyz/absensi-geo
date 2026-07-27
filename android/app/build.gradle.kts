plugins {
    id("com.android.application")
    id("kotlin-android")

    // Flutter Gradle Plugin harus berada setelah
    // plugin Android dan Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.absensi_geo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Wajib untuk flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.absensi_geo"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Mengantisipasi jumlah method yang bertambah
        // setelah Firebase dan notification package ditambahkan.
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Masih menggunakan debug signing.
            // Nanti ganti dengan release signing ketika build production.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Wajib untuk core library desugaring.
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )
}

flutter {
    source = "../.."
}