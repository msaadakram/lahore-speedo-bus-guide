# ---------------------------------------------------------------------------
# ProGuard / R8 rules for the Flutter release build.
# ---------------------------------------------------------------------------

# Flutter's engine entry points are looked up by name from native code.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Stripped classes are resolved reflectively by Flutter's plugin registrant.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ---------------------------------------------------------------------------
# Plugins used by this app
# ---------------------------------------------------------------------------

# geolocator: reads permission/accuracy enums reflectively.
-keep class com.baseflow.geolocator.** { *; }

# flutter_map / latlong2 / mgrs_dart / proj4dart / wkt_parser: pure Dart, but
# keep their public surfaces so reflection-free code is not removed.
-keep class org.qtproject.qt.** { *; }

# shared_preferences_android
-keep class dev.fluttercommunity.plus.sharedpreferences.** { *; }

# url_launcher_android
-keep class io.flutter.plugins.urllauncher.** { *; }

# share_plus_platform_interface / share_plus
-keep class dev.fluttercommunity.share_plus.** { *; }
-keep class com.example.share_plus.** { *; }

# http: keep the parsed modelless surface.
-dontwarn okhttp3.**
-dontwarn okio.**

# ---------------------------------------------------------------------------
# General Flutter hygiene
# ---------------------------------------------------------------------------
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep application entry points.
-keep class com.codez.lahore_speedo_bus_guide.MainActivity { *; }

# Dart is not Java: do not warn about unused JDK internals pulled in transitively.
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**

# Keep line numbers for release crash reports while still obfuscating.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ---------------------------------------------------------------------------
# Optional Flutter deferred-component (Play Core) classes.
#
# Play Core is a compileOnly dependency of the Flutter embedding: absent on a
# plain release device only when deferred components are actually used, which
# this app does not do. R8 still sees the references, so silence them.
# ---------------------------------------------------------------------------
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ---------------------------------------------------------------------------
# JNI bridge (package:jni / package:jni_flutter)
#
# These packages ship `consumerProguardFiles`, but the Flutter Gradle plugin
# wires plugins in as *project* dependencies rather than AARs, so AGP never
# applies a consumer module's ProGuard rules. Without these lines R8 deletes
# the whole `com.github.dart_lang.jni` package, because nothing in Java calls
# it: the Dart side resolves those classes and methods **by name** over JNI.
#
# Symptom when this is missing: `SharedPreferences.getInstance()` throws
# UnsatisfiedLinkError/NoClassDefFoundError during startup, `main()` never
# reaches `runApp()`, and the app shows a blank screen.
# ---------------------------------------------------------------------------
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-keepclasseswithmembernames class com.github.dart_lang.jni.** {
    native <methods>;
}
-keepclasseswithmembernames class com.github.dart_lang.jni_flutter.** {
    native <methods>;
}
# The native libraries that back the JNI bridge.
-keep class com.github.dart_lang.jni.** { *; }

# ---------------------------------------------------------------------------
# Flutter plugin v2 API registrars
#
# The Dart side resolves a plugin's Java API through a class literally named
# `<Plugin>ApiRegistrar`, looked up **by name** at runtime. No Java code
# references it, so R8 considers it dead and deletes it — which breaks the
# plugin at the first call with a NoSuchMethodError.
#
# Observed on-device: `io.flutter.plugins.sharedpreferences.SharedPreferencesApiRegistrar`
# was missing, so `SharedPreferences.getAll()` threw and the app fell back to
# in-memory preferences. `UrlLauncherApiRegistrar`, `SharePlusApiRegistrar` and
# `GeolocatorApiRegistrar` were missing too, which would have broken external
# links, the share sheet and the Nearby tab's location lookup.
# ---------------------------------------------------------------------------
-keep class **ApiRegistrar { *; }
-keep class io.flutter.plugins.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class com.baseflow.geolocator.** { *; }

# ---------------------------------------------------------------------------
# Classes the JNI bindings resolve by their literal JVM name.
#
# `package:jni` looks these up with JClass.forName("kotlin/coroutines/Continuation")
# and friends. R8 happily renames them, which changes the *descriptor* of the
# methods that take them — so the JNI lookup for
# `SharedPreferencesApiRegistrar.getAll(String, List, Continuation)` no longer
# matches and the plugin throws
#   NoSuchMethodError: no non-static method
#   "Lio/flutter/plugins/sharedpreferences/SharedPreferencesApiRegistrar;.getAll(...)"
#
# The java/* and kotlin/Result names are already stable (platform classes and
# Kotlin stdlib public API), but they are listed for completeness.
# ---------------------------------------------------------------------------
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$* { *; }
-keep class java.nio.Buffer { *; }
-keep class java.nio.ByteBuffer { *; }
