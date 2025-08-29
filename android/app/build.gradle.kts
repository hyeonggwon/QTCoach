plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// JSON 설정 파일 로더
fun loadConfig(env: String): Map<String, Any> {
    // android/ 기준으로 ../config/{env}.json을 읽음
    val configFile = file("${rootDir}/../config/${env}.json")
    if (!configFile.exists()) return emptyMap()
    val parsed = groovy.json.JsonSlurper().parse(configFile)
    @Suppress("UNCHECKED_CAST")
    return (parsed as Map<String, Any>?) ?: emptyMap()
}

android {
    // ... (파일 상단 내용)

    namespace = "com.qt.coach"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.qt.coach"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // manifestPlaceholders 기본값 초기화 (빌드타입별로 덮어씀)
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // release.json로부터 KAKAO_NATIVE_APP_KEY 주입
            val cfg = loadConfig("release")
            (cfg["KAKAO_NATIVE_APP_KEY"] as? String)?.let { key ->
                manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = key
            }
        }
        debug {
            // debug.json로부터 KAKAO_NATIVE_APP_KEY 주입
            val cfg = loadConfig("debug")
            (cfg["KAKAO_NATIVE_APP_KEY"] as? String)?.let { key ->
                manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = key
            }
        }
    }
}

flutter {
    source = "../.."
}
