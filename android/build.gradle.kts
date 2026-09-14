group = "com.appsonair.flutter_push_notification"
version = "1.0-SNAPSHOT"

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
        // AppsOnAir Core, a transitive dependency of com.appsonair:push, is published on JitPack.
        maven("https://jitpack.io")
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "com.appsonair.flutter_push_notification"

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
        // Matches the native AppsOnAir-Android-Push SDK's floor (Play Store minimum as of 2024).
        minSdk = 23
    }
}

dependencies {
    // `api`, not `implementation` — this plugin's public class implements native
    // interfaces (PushListener, INotificationClickListener, ...), so consuming apps'
    // GeneratedPluginRegistrant needs those types on its own compile classpath.
    api("com.appsonair:push:0.0.1-alpha")
}
