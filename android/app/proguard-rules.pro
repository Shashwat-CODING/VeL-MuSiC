# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Keep your application class if you have one
-keep class com.example.test_app.MainActivity { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep setters in Views so that animations can still work.
-keepclassmembers public class * extends android.view.View {
   void set*(***);
   *** get*();
}

# For enumeration classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# To maintain custom components names that are used on layouts XML.
-keep public class custom.components.**

-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep parcelables
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep R
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
