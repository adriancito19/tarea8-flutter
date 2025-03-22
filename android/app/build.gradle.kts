plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tarea8"
    compileSdk = 35  // Asumiendo que Flutter usa un compileSdkVersion de 33 por defecto, ajusta según corresponda.
    ndkVersion = "27.0.12077973"  // Actualiza manualmente la versión de NDK para evitar problemas de compatibilidad.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.tarea8"
        minSdk = 23  // Actualizado a 23 para ser compatible con el plugin que estás usando.
        targetSdk = 33  // Usa la misma versión de targetSdk que compileSdk.
        versionCode = 1  // Asegúrate de tener un versionCode válido.
        versionName = "1.0.0"  // Asegúrate de definir la versión correctamente.
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")  // Deberías actualizar con tus propias claves para producción.
        }
    }
}

flutter {
    source = "../.."  // Ruta del código fuente de Flutter.
}
