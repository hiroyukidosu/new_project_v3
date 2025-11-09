// アプリケーションのエントリーポイント
// 初期化処理とエラーハンドリングを設定します

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'utils/locale_helper.dart';
import 'utils/performance_monitor.dart';
import 'utils/preferences_cache.dart';
import 'core/app_initializer.dart';
import 'widgets/splash_screen.dart';
import 'screens/medication_alarm_app.dart';

/// アプリケーションのエントリーポイント
/// 初期化処理とエラーハンドリングを設定
void main() {
  // Zone Mismatchを回避: すべての初期化とrunAppを同じZone内で実行
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // 画面向きを固定（軽量処理のみ）
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // エラーハンドラを runApp 前に設定（軽量処理のみ）
    _setupErrorHandlers();

    // アプリを即座に起動（UIを先に表示）
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // バックグラウンドでFirebase初期化（UI表示をブロックしない）
    Future.microtask(() async {
      try {
        await _initializeAppSyncEarly();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Firebase初期化エラー: $e');
        }
      }
    });
  }, (error, stack) async {
    try {
      // Firebaseが初期化されていない場合でもエラーを記録
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    } catch (_) {
      // Crashlytics記録失敗時は無視
    }
  });
}

/// エラーハンドラを設定（同期的に実行）
void _setupErrorHandlers() {
  // Flutter フレームワークのエラーハンドラ（オーバーフローエラーも含む）
  FlutterError.onError = (FlutterErrorDetails errorDetails) {
    // オーバーフローエラーの検出
    final isOverflowError = errorDetails.exception.toString().contains('RenderFlex') ||
        errorDetails.exception.toString().contains('overflowed') ||
        errorDetails.exception.toString().contains('Overflow');
    
    // エラーの詳細情報をログに記録
    if (isOverflowError && Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.log('UI Overflow Error: ${errorDetails.exception}');
      FirebaseCrashlytics.instance.log('Stack: ${errorDetails.stack}');
      FirebaseCrashlytics.instance.log('Context: ${errorDetails.context}');
    }
    
    // release でのみ Crashlytics 送信（開発ノイズ回避）
    if (kReleaseMode && Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } else {
      FlutterError.dumpErrorToConsole(errorDetails);
      // デバッグモードでもオーバーフローエラーは記録
      if (isOverflowError && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.log('Overflow Error (Debug): ${errorDetails.exception}');
      }
    }
  };

  // エンジンレベルの未処理例外を捕捉
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kReleaseMode && Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
}

/// 早期に必要な同期/準同期初期化（エラーハンドラ、Firebase/Crashlyticsなど）
Future<void> _initializeAppSyncEarly() async {
  // Firebase を初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics 収集はリリースビルドのみ有効化（同意取得は別途）
  // 同意 + リリースビルドで収集を有効化
  try {
    // PreferencesCacheを使用（Lazy Loading）
    final prefs = await PreferencesCache.instance;
    final consent = prefs.getBool('crashlytics_consent') ?? false;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(kReleaseMode && consent);
  } catch (_) {
    // SharedPreferences取得失敗時は無視
  }
}

/// アプリケーションのルートウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'サプリ＆おくすりスケジュール管理帳',
      debugShowCheckedModeBanner: false,
      home: const OptimizedSplashScreen(),
    );
  }
}
