// アプリケーションのエントリーポイント
// 初期化処理とエラーハンドリングを設定します

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'firebase_options.dart';
import 'utils/locale_helper.dart';
import 'utils/performance_monitor.dart';
import 'models/medication_memo.dart';
import 'models/adapters/medication_memo_adapter.dart';
import 'services/app_preferences.dart';
import 'services/hive_service.dart';
import 'services/in_app_purchase_service.dart';
import 'services/trial_service.dart';
import 'screens/medication_alarm_app.dart';
import 'repositories/medication_repository.dart';
import 'repositories/calendar_repository.dart';
import 'repositories/backup_repository.dart';
import 'repositories/alarm_repository.dart';

/// アプリケーションのエントリーポイント
/// 初期化処理とエラーハンドリングを設定
void main() {
  // Zone Mismatchを回避: すべての初期化とrunAppを同じZone内で実行
  runZonedGuarded(() async {
    PerformanceMonitor.start('app_startup');
    
    // パフォーマンス最適化：最小限の初期化のみ実行
    WidgetsFlutterBinding.ensureInitialized();
    
    // クリティカルな初期化のみ（UI表示に必要）
    await _initializeCritical();

    // エラーハンドラを runApp 前に設定し、Crashlytics を早期初期化
    await _initializeAppSyncEarly();

    // アプリを起動（ProviderScopeでラップ）- 同じZone内で実行
    runApp(
      const ProviderScope(
        child: MedicationAlarmApp(),
      ),
    );
    
    PerformanceMonitor.end('app_startup');
    
    // 非クリティカルな初期化はバックグラウンドで実行（メインスレッドをブロックしない）
    _initializeNonCritical();
  }, (error, stack) async {
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {
      // Crashlytics記録失敗時は無視
    }
  });
}

/// クリティカルな初期化（UI表示に必要、起動時に必須）
Future<void> _initializeCritical() async {
  PerformanceMonitor.start('critical_init');
  
  try {
    // 日付のローカライゼーション初期化（システムロケールを尊重）
    final systemLocale = PlatformDispatcher.instance.locale;
    final systemTag = systemLocale.toLanguageTag();
    await LocaleHelper.initializeLocale(systemTag);
    
    // Hive初期化（最適化版）
    await HiveService.initialize();
    
    // SharedPreferences初期化
    await AppPreferences.init();
    
    PerformanceMonitor.end('critical_init');
    
    if (kDebugMode) {
      debugPrint('⚡ クリティカル初期化完了');
    }
  } catch (e) {
    PerformanceMonitor.end('critical_init');
    if (kDebugMode) {
      debugPrint('❌ クリティカル初期化エラー: $e');
    }
    rethrow;
  }
}

/// 非クリティカルな初期化（バックグラウンドで実行）
void _initializeNonCritical() {
  Future.microtask(() async {
    PerformanceMonitor.start('non_critical_init');
    
    try {
      // トライアル期間をリセット（開発・テスト用のみ）
      if (kDebugMode) {
        try {
          await TrialService.resetTrial();
          if (kDebugMode) {
            debugPrint('✅ トライアル期間をリセットしました (debug)');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ トライアルリセットエラー: $e');
          }
        }
      }
      
      // リポジトリの初期化（遅延初期化パターンを使用）
      await _initializeRepositories();
      
      // その他の重い初期化処理
      await _initializeAppAsync();
      
      PerformanceMonitor.end('non_critical_init');
      
      if (kDebugMode) {
        debugPrint('⚡ 非クリティカル初期化完了');
      }
    } catch (e) {
      PerformanceMonitor.end('non_critical_init');
      if (kDebugMode) {
        debugPrint('非同期初期化エラー: $e');
      }
    }
  });
}

/// 早期に必要な同期/準同期初期化（エラーハンドラ、Firebase/Crashlyticsなど）
Future<void> _initializeAppSyncEarly() async {
  // Flutter フレームワークのエラーハンドラ（オーバーフローエラーも含む）
  FlutterError.onError = (FlutterErrorDetails errorDetails) {
    // オーバーフローエラーの検出
    final isOverflowError = errorDetails.exception.toString().contains('RenderFlex') ||
        errorDetails.exception.toString().contains('overflowed') ||
        errorDetails.exception.toString().contains('Overflow');
    
    // エラーの詳細情報をログに記録
    if (isOverflowError) {
      FirebaseCrashlytics.instance.log('UI Overflow Error: ${errorDetails.exception}');
      FirebaseCrashlytics.instance.log('Stack: ${errorDetails.stack}');
      FirebaseCrashlytics.instance.log('Context: ${errorDetails.context}');
    }
    
    // release でのみ Crashlytics 送信（開発ノイズ回避）
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } else {
      FlutterError.dumpErrorToConsole(errorDetails);
      // デバッグモードでもオーバーフローエラーは記録
      if (isOverflowError) {
        FirebaseCrashlytics.instance.log('Overflow Error (Debug): ${errorDetails.exception}');
      }
    }
  };

  // Firebase を先に初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics 収集はリリースビルドのみ有効化（同意取得は別途）
  // 同意 + リリースビルドで収集を有効化
  final consent = AppPreferences.getBool('crashlytics_consent') ?? false;
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(kReleaseMode && consent);

  // エンジンレベルの未処理例外を捕捉
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
}

/// 非同期初期化処理（パフォーマンス最適化）
Future<void> _initializeAppAsync() async {
  try {
    // その他の重い初期化処理
    await _initializeHeavyServices();
    
  } catch (e) {
    // 初期化失敗時はログのみ出力（アプリは継続動作）
    if (kDebugMode) {
      debugPrint('非同期初期化エラー: $e');
    }
  }
}

/// リポジトリの初期化（並列処理で高速化）
Future<void> _initializeRepositories() async {
  PerformanceMonitor.start('repositories_init');
  
  try {
    if (kDebugMode) {
      debugPrint('🗄️ リポジトリ初期化開始...');
    }
    
    // リポジトリを並列で初期化（高速化）
    await Future.wait([
      _initializeMedicationRepository(),
      _initializeCalendarRepository(),
      _initializeBackupRepository(),
      _initializeAlarmRepository(),
    ], eagerError: false);
    
    PerformanceMonitor.end('repositories_init');
    
    if (kDebugMode) {
      debugPrint('✅ 全リポジトリ初期化完了');
    }
  } catch (e) {
    PerformanceMonitor.end('repositories_init');
    if (kDebugMode) {
      debugPrint('❌ リポジトリ初期化エラー: $e');
    }
  }
}

/// メディケーションリポジトリの初期化
Future<void> _initializeMedicationRepository() async {
  try {
    final medicationRepo = MedicationRepository();
    await medicationRepo.initialize();
    if (kDebugMode) {
      debugPrint('✅ MedicationRepository初期化完了');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ MedicationRepository初期化エラー: $e');
    }
  }
}

/// カレンダーリポジトリの初期化
Future<void> _initializeCalendarRepository() async {
  try {
    final calendarRepo = CalendarRepository();
    await calendarRepo.initialize();
    if (kDebugMode) {
      debugPrint('✅ CalendarRepository初期化完了');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ CalendarRepository初期化エラー: $e');
    }
  }
}

/// バックアップリポジトリの初期化
Future<void> _initializeBackupRepository() async {
  try {
    final backupRepo = BackupRepository();
    await backupRepo.initialize();
    if (kDebugMode) {
      debugPrint('✅ BackupRepository初期化完了');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ BackupRepository初期化エラー: $e');
    }
  }
}

/// アラームリポジトリの初期化
Future<void> _initializeAlarmRepository() async {
  try {
    final alarmRepo = AlarmRepository();
    await alarmRepo.initialize();
    if (kDebugMode) {
      debugPrint('✅ AlarmRepository初期化完了');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ AlarmRepository初期化エラー: $e');
    }
  }
}

/// 重いサービスの初期化
Future<void> _initializeHeavyServices() async {
  try {
    // タイムゾーン初期化
    tz.initializeTimeZones();
    
    // アプリ内課金の初期化
    try {
      final bool isMobilePlatform = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android);
      if (isMobilePlatform) {
        final bool isAvailable = await InAppPurchase.instance.isAvailable();
        if (isAvailable) {
          await InAppPurchaseService.restorePurchases();
          if (kDebugMode) {
            debugPrint('アプリ内課金初期化完了');
          }
        }
      }
    } catch (e) {
      debugPrint('アプリ内課金初期化エラー: $e');
    }
    
  } catch (e) {
    debugPrint('重いサービス初期化エラー: $e');
  }
}
