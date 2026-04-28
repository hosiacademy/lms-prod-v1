pluginManagement {
    // Flutter SDK path resolution
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    // CRITICAL: Plugin repositories - MUST include google()
    repositories {
        google()              // Android plugins
        gradlePluginPortal()  // Gradle plugins
        mavenCentral()        // Maven dependencies
    }
    
    // Explicit Android plugin resolution
    resolutionStrategy {
        eachPlugin {
            if (requested.id.namespace == "com.android") {
                useModule("com.android.tools.build:gradle:${requested.version ?: "8.11.1"}")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // Add library plugin for your integration_test module
    id("com.android.library") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

// Ensure this matches your root project name from error: 'integrationTest'
rootProject.name = "integrationTest"

// Include your modules
include(":app")