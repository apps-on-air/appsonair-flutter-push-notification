group = "com.logicwind.appsonair_flutter_apppush"
version = "0.0.2-alpha"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // AppsOnAir Core, a transitive dependency of the native push SDK, is published on JitPack.
        maven("https://jitpack.io")
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "com.logicwind.appsonair_flutter_apppush"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        // Matches the native AppPushService SDK's floor — it requires AppsOnAir Core (minSdk 24).
        minSdk = 24
    }
}

dependencies {
    api("com.github.apps-on-air:appsonair-android-push-notification:0.0.3-alpha")
}
