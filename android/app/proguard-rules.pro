-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep WorkManager and Room database classes to prevent crash on release startup
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**

