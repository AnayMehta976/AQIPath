import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    
}

val localProperties = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.tekzee.aqiapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" //flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // ✅ Enable core library desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
            create("release") {
                // Release signing values come from android/key.properties (not committed).
                if (hasReleaseKeystore) {
                    storeFile = file(keystoreProperties.getProperty("storeFile"))
                    storePassword = keystoreProperties.getProperty("storePassword")
                    keyAlias = keystoreProperties.getProperty("keyAlias")
                    keyPassword = keystoreProperties.getProperty("keyPassword")
                }
            }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tekzee.aqiapp"
        minSdk = flutter.minSdkVersion //flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 8
        versionName = "1.0.7"
        // Google Maps key from android/local.properties (MAPS_API_KEY=...) or the MAPS_API_KEY env var.
        manifestPlaceholders["MAPS_API_KEY"] =
            localProperties.getProperty("MAPS_API_KEY") ?: System.getenv("MAPS_API_KEY") ?: ""
    }

    buildTypes {
          getByName("release") {
            signingConfig = if (hasReleaseKeystore) signingConfigs.getByName("release")
                            else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
             }
    }
}

flutter {
    source = "../.."
}
dependencies {
   implementation(platform("com.google.firebase:firebase-bom:33.14.0"))
   implementation("com.google.firebase:firebase-auth-ktx")
   implementation("com.google.firebase:firebase-appcheck-playintegrity")
   implementation("com.google.android.gms:play-services-maps:17.0.0")
    // ✅ Add this line
   coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
   
}
