pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    // PREFER_SETTINGS, not FAIL_ON_PROJECT_REPOS: the Flutter Gradle plugin adds its engine repository to every
    // project. The repositories below are the ones used.
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven("https://storage.googleapis.com/download.flutter.io")  // Flutter engine (ui_module)
    }
}
rootProject.name = "IslamicMute"
include(":app")

// Shared Flutter screens (../ui through ../ui_module, add-to-app from source; docs/UI_CONTRACT.md).
// `flutter pub get` in ui_module generates .android/ (not in git).
val flutterInclude = File(settingsDir.parentFile, "ui_module/.android/include_flutter.groovy")
if (!flutterInclude.isFile) throw GradleException("Run `flutter pub get` in ui_module first (creates $flutterInclude).")
apply(from = flutterInclude)
