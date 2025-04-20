plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin – musi być po Android i Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // Włączamy wtyczkę Google Services (Firebase)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.moj_pierszy_projekt"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.moj_pierszy_projekt"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("C:/Users/onysz/keystore/my-release-key.jks") // Ścieżka do Twojego keystore
            storePassword = "Hh5_HAjCNBDHDS" // Hasło do keystore
            keyAlias = "my-key-alias"         // Alias klucza
            keyPassword = "Hh5_HAjCNBDHDS"     // Hasło do klucza
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            // Debug signing zazwyczaj nie wymaga zmiany – konfiguracja debug jest domyślna.
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.." // Ścieżka do źródeł Fluttera – upewnij się, że jest poprawna
}

dependencies {
    // Używamy Firebase BoM, by zapewnić spójność wersji wszystkich pakietów Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    implementation("com.google.firebase:firebase-firestore-ktx")
    // Odkomentuj poniższe, jeśli chcesz korzystać z dodatkowych usług Firebase:
    // implementation("com.google.firebase:firebase-auth-ktx")
    // implementation("com.google.firebase:firebase-analytics-ktx")
}
