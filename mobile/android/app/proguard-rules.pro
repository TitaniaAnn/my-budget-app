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
