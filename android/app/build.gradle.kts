import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun readEnvKey(key: String): String? {
    val envFile = rootProject.file("../.env")
    if (!envFile.exists()) return null
    return envFile.readLines()
        .firstOrNull { it.startsWith("$key=") }
        ?.substringAfter("=")
        ?.trim()
}

val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) load(f.inputStream())
}
val mapsApiKey: String = localProps.getProperty("MAPS_API_KEY")
    ?: readEnvKey("GOOGLE_MAPS_KEY")
    ?: error("GOOGLE_MAPS_KEY bulunamadı. Repo köküne .env dosyası ekle.")

android {
    namespace = "com.bozappz.sanayi_servis_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bozappz.sanayi_servis_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
