# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter関連のルール
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Hive関連のルール
-keep class hive_flutter.** { *; }
-keep class **$HiveFieldAdapter { *; }
-keep class **$TypeAdapter { *; }

# SharedPreferences関連のルール
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$** { *; }

# Firebase関連のルール（使用している場合）
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core関連のルール
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# 通知関連のルール
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# 音声再生関連のルール
-keep class com.ryanheise.just_audio.** { *; }

# バイブレーション関連のルール
-keep class com.dexterous.** { *; }

# パーミッション関連のルール
-keep class com.baseflow.permissionhandler.** { *; }

# デバイス情報関連のルール
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# パッケージ情報関連のルール
-keep class dev.fluttercommunity.plus.package_info.** { *; }

# パスプロバイダー関連のルール
-keep class io.flutter.plugins.pathprovider.** { *; }

# シェア関連のルール
-keep class dev.fluttercommunity.plus.share.** { *; }

# CSV関連のルール
-keep class com.opencsv.** { *; }

# タイムゾーン関連のルール
-keep class net.time4j.** { *; }

# アプリ固有のクラス
-keep class com.hirochaso.medication_schedule.** { *; }

# リフレクションを使用するクラス
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# シリアライゼーション関連
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 例外クラス
-keep public class * extends java.lang.Exception

# ネイティブメソッド
-keepclasseswithmembernames class * {
    native <methods>;
}

# 列挙型
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# パラメータ化された型
-keepattributes Signature
-keepattributes *Annotation*

# デバッグ情報の保持
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
