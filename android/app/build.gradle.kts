import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    val rawProps = Properties()
    keystorePropertiesFile.reader(Charsets.UTF_8).use { reader ->
        rawProps.load(reader)
    }
    for (key in rawProps.stringPropertyNames()) {
        val cleanKey = key.trim().replace("\uFEFF", "")
        rawProps.getProperty(key)?.let { value ->
            keystoreProperties.setProperty(cleanKey, value.trim())
        }
    }
}


android {
    namespace = "com.wealthanalyzer.wealth_projector"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.wealthanalyzer.wealth_projector"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePath = keystoreProperties.getProperty("storeFile")
                ?: System.getenv("ANDROID_KEYSTORE_PATH")
            val resolvedStoreFile = if (keystorePath != null) {
                val directFile = file(keystorePath)
                if (directFile.exists()) {
                    directFile
                } else {
                    val rootRelativeFile = rootProject.file(keystorePath)
                    if (rootRelativeFile.exists()) {
                        rootRelativeFile
                    } else {
                        null
                    }
                }
            } else null

            if (resolvedStoreFile != null) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                    ?: System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: System.getenv("ANDROID_KEY_PASSWORD")
                storeFile = resolvedStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                    ?: System.getenv("ANDROID_STORE_PASSWORD")
            } else {
                // Graceful fallback to debug signing config when keystore is not provided
                initWith(signingConfigs.getByName("debug"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

