plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin must come last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mansour.wordmaze2"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.mansour.wordmaze2"
        minSdk = 21
        targetSdk = 35
        versionCode = 5
        versionName = "1.0.5"
    }

    signingConfigs {
    create("release") {
        keyAlias = "wordmaze_key"
        keyPassword = "Firfly@6870"
        storeFile = file("D:/dev/word_maze/keystore.jks")
        storePassword = "Firfly@6870"
    }
}


 buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = false       // <- turn this off
        isShrinkResources = false     // <- also off
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

flutter {
    source = "../.."
}
