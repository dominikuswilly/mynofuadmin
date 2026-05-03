# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Custom rules for your app
# Add any specific rules here for third-party libraries if needed.

# Ignore missing Play Core classes (common in Flutter R8 builds)
-dontwarn com.google.android.play.core.**
