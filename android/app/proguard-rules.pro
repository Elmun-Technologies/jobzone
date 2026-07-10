# R8 / ProGuard keep rules for the release (minified) build.
#
# Flutter's engine ships its own keep rules and most plugins bundle consumer
# rules (Firebase, flutter_local_notifications, Yandex), so these are mostly
# belt-and-suspenders: keep the reflection/JNI-heavy SDKs intact and silence
# "missing class" warnings for optional deps that aren't on the classpath.

# --- Flutter embedding -------------------------------------------------------
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# --- Yandex MapKit (native SDK, heavy JNI + reflection) ----------------------
-keep class com.yandex.** { *; }
-keep class com.yandex.runtime.** { *; }
-dontwarn com.yandex.**

# --- Firebase / Google Play services (messaging, core) -----------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- flutter_local_notifications (GSON-serialized scheduled models) ----------
-keep class com.dexterous.** { *; }

# --- Play Core (referenced by Flutter deferred components; usually absent) ---
# Without this, R8 fails the build with "Missing class com.google.android.play.core…".
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# --- GSON / reflection generics ----------------------------------------------
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod, RuntimeVisibleAnnotations
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# --- Kotlin metadata ---------------------------------------------------------
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }
