import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing credentials from key.properties (never committed to source control).
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.mybudgetapp.mobile"
    // Audit 2026-05-26 C7: pin SDK levels literally instead of
    // inheriting from `flutter.*`. A future Flutter SDK bump
    // would otherwise silently shift targetSdk and change
    // behaviour for runtime permissions / background services
    // / scoped storage on every build. Play Store requires
    // targetSdk=35 as of Aug 2025. compileSdk is bumped to 36
    // because androidx.browser:1.9.0 (transitive via
    // plaid_flutter) requires it; targetSdk stays at 35 to
    // keep runtime behaviour deliberate.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications to use modern
        // java.time + java.util.function APIs on minSdk < 26.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = keyProperties["storeFile"]?.let { file(it) }
            storePassword = keyProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.mybudgetapp.mobile"
        // C7: literal pins. minSdk=23 (Android 6) is the floor
        // Flutter currently supports for most plugins. targetSdk
        // tracks the compileSdk pin above.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Audit 2026-05-26 C8: dev / prod flavors. Without them, a
    // debug build pointed at the local Supabase stack installs
    // OVER a production build because they share an
    // applicationId — the user finds themselves signed into the
    // wrong environment with no visible warning. Each flavor
    // gets its own applicationId suffix and label so both apps
    // can coexist on the device.
    //
    // - dev:  applicationId com.mybudgetapp.mobile.dev,
    //         label "MyBudget Dev", version "<x.y.z>-dev"
    // - prod: applicationId com.mybudgetapp.mobile (default)
    //
    // Every flutter command MUST now pass --flavor: the build
    // fails fast on a missing flavor flag rather than picking
    // a default and surprising someone.
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "MyBudget Dev")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "MyBudget")
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
