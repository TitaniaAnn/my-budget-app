# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / Realtime websocket
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep all model classes used by json_serializable
-keep class com.mybudgetapp.mobile.** { *; }

# Prevent stripping of annotations used by Freezed / json_annotation
-keepattributes *Annotation*

# Flutter's embedding references Play Core split-install classes for
# deferred components. This app doesn't use deferred components, so
# the classes aren't on the classpath — silence R8's warnings rather
# than pulling in the dependency.
# See https://flutter.dev/to/r8-missing-classes
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
