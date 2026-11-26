# Keep rules for release builds (R8).
# PyTorch Lite loads native code that looks up these classes by name via JNI.
# If R8 renames or removes them, the app crashes at inference time with
# ExceptionInInitializerError / ClassNotFoundException: org.pytorch.PyTorchAndroid.
-keep class org.pytorch.** { *; }
-keep class com.facebook.jni.** { *; }
-keep class com.facebook.soloader.** { *; }
-keep class com.facebook.fbjni.** { *; }
-keepclassmembers class * {
    native <methods>;
}
-keep class com.abdelaziz_mahdy.pytorch_lite.** { *; }
-dontwarn org.pytorch.**
-dontwarn com.facebook.jni.**
