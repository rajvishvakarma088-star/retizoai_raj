# Epson ePOS SDK ProGuard Rules
# Required for release builds to prevent code obfuscation issues

# Keep all Epson SDK classes
-keep class com.epson.** { *; }
-dontwarn com.epson.**
