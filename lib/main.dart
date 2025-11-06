// アプリケーションのエントリーポイント
// 初期化処理とエラーハンドリングを設定します

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'firebase_options.dart';
import 'utils/locale_helper.dart';
import 'models/medication_memo.dart';
import 'services/app_preferences.dart';
import 'services/in_app_purchase_service.dart';
import 'services/trial_service.dart';
import 'services/hive_lifecycle_service.dart';
import 'screens/medication_alarm_app.dart';
import 'repositories/repository_manager.dart';
import 'utils/logger.dart';

/// Firebase初期化状態
bool _isFirebaseInitialized = false;

/// アプリケーションのエントリーポイント
/// 初期化処理とエラーハンドリングを設定
void main() async {
  // Zone mismatchを避けるため、runZonedGuarded内で初期化とrunAppを実行
  await runZonedGuarded(() async {
    // パフォーマンス最適化：最小限の初期化のみ実行
    WidgetsFlutterBinding.ensureInitialized();
  
    // 1. 最優先: SharedPreferences初期化（Firebase初期化で使用するため）
    try {
      await AppPreferences.init();
    } catch (e, stackTrace) {
      Logger.error('SharedPreferences初期化エラー', e);
      _logError('SharedPreferences初期化エラー', e, stackTrace);
    }
    
    // 2. Firebase初期化（Crashlyticsを使用する前に必ず実行）
    await _initializeAppSyncEarly();
    
    // 3. 日付のローカライゼーション初期化（システムロケールを尊重）
    final systemLocale = PlatformDispatcher.instance.locale;
    final systemTag = systemLocale.toLanguageTag();
    await LocaleHelper.initializeLocale(systemTag);
    
    // 4. アプリを起動（ProviderScopeでラップ）
    // パフォーマンス最適化：重い初期化処理の前にアプリを起動
    runApp(
      const ProviderScope(
        child: MedicationAlarmApp(),
      ),
    );
    
    // 5. 重い初期化処理は非同期で実行（メインスレッドのブロッキングを回避）
    // 注意: 未処理のFutureを避けるため、エラーハンドリングを追加
    Future.microtask(() async {
      try {
        // Hive初期化（パフォーマンス最適化）
        await HiveLifecycleService.initialize();
        
        // ボックス確認
        final memoBox = HiveLifecycleService.getBox<MedicationMemo>('medication_memos');
        Logger.debug(memoBox != null 
          ? '✅ ボックス確認完了: ${memoBox.length}件のデータ'
          : '⚠️ medication_memosボックスが開いていません');
        
        // トライアル期間をリセット（開発・テスト用のみ）
        if (kDebugMode) {
          try {
            await TrialService.resetTrial();
            Logger.debug('✅ トライアル期間をリセットしました (debug)');
          } catch (e) {
            Logger.error('トライアルリセットエラー', e);
          }
        }
        
        // リポジトリの初期化（並列実行で高速化）
        await _initializeRepositories();
        
        // その他の非同期初期化処理
        await _initializeAppAsync();
      } catch (e, stackTrace) {
        Logger.error('非同期初期化エラー（microtask）', e);
        _logError('非同期初期化エラー（microtask）', e, stackTrace);
      }
    });
  }, (error, stack) async {
    // Firebase初期化チェック
    if (_isFirebaseInitialized) {
      try {
        await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {
        // Crashlytics記録失敗時はログのみ
        Logger.error('Crashlytics記録エラー', error);
      }
    } else {
      // Firebase未初期化時はLoggerのみ
      Logger.error('未処理例外（Firebase未初期化）', error);
    }
  });
}

/// 早期に必要な同期/準同期初期化（エラーハンドラ、Firebase/Crashlyticsなど）
/// 最優先で実行される（他の処理でCrashlyticsを使用する前に必須）
Future<void> _initializeAppSyncEarly() async {
  if (_isFirebaseInitialized) {
    return; // 既に初期化済み
  }
  
  try {
    // Firebase を最優先で初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
    
    // Crashlytics 収集はリリースビルドのみ有効化（同意取得は別途）
    // AppPreferencesは既に初期化済み（main()の最初で実行）
    final consent = AppPreferences.isInitialized 
      ? AppPreferences.getBool('crashlytics_consent', defaultValue: false)
      : false;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(kReleaseMode && consent);

    // Flutter フレームワークのエラーハンドラ
    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      // release でのみ Crashlytics 送信（開発ノイズ回避）
      if (kReleaseMode && _isFirebaseInitialized) {
        try {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        } catch (_) {
          // Crashlytics記録失敗時はコンソールに出力
          FlutterError.dumpErrorToConsole(errorDetails);
        }
      } else {
        FlutterError.dumpErrorToConsole(errorDetails);
      }
    };

    // エンジンレベルの未処理例外を捕捉
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (kReleaseMode && _isFirebaseInitialized) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {
          // Crashlytics記録失敗時はLoggerに出力
          Logger.error('未処理例外（Crashlytics記録失敗）', error);
        }
      } else {
        // Firebase未初期化時はLoggerに出力
        Logger.error('未処理例外（Firebase未初期化）', error);
      }
      return true;
    };
    
    Logger.debug('✅ Firebase初期化完了');
  } catch (e, stackTrace) {
    // Firebase初期化失敗は致命的だが、アプリは続行を試みる
    Logger.error('Firebase初期化エラー', e);
    _isFirebaseInitialized = false;
    // この時点ではCrashlyticsが使えないため、Loggerのみ
  }
}

/// 非同期初期化処理（パフォーマンス最適化）
Future<void> _initializeAppAsync() async {
  try {
    // その他の重い初期化処理
    await _initializeHeavyServices();
    
  } catch (e, stackTrace) {
    // 初期化失敗時はログのみ出力（アプリは継続動作）
    Logger.error('非同期初期化エラー', e);
    _logError('非同期初期化エラー', e, stackTrace);
  }
}

/// リポジトリの初期化（並列実行で高速化）
Future<void> _initializeRepositories() async {
  try {
    final results = await RepositoryManager.initializeAll();
    
    // 初期化失敗したリポジトリを確認
    final failedRepos = <String>[];
    results.forEach((key, success) {
      if (!success) {
        failedRepos.add(key);
      }
    });
    
    // 失敗したリポジトリがある場合はログに記録
    if (failedRepos.isNotEmpty) {
      Logger.warning('⚠️ 一部のリポジトリ初期化に失敗: ${failedRepos.join(", ")}');
      // ユーザーには通知しない（アプリは継続動作）
    }
  } catch (e, stackTrace) {
    Logger.error('リポジトリ初期化エラー', e);
    _logError('リポジトリ初期化エラー', e, stackTrace);
  }
}

/// エラーログを記録（Crashlytics使用）
/// Firebase初期化済みの場合のみCrashlyticsに記録
Future<void> _logError(String reason, dynamic error, StackTrace stackTrace) async {
  if (!_isFirebaseInitialized) {
    // Firebase未初期化時はLoggerのみ
    Logger.error(reason, error);
    return;
  }
  
  try {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  } catch (_) {
    // Crashlytics記録失敗時は無視
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
          Logger.debug('アプリ内課金初期化完了');
        }
      }
    } catch (e, stackTrace) {
      Logger.error('アプリ内課金初期化エラー', e);
      _logError('アプリ内課金初期化エラー', e, stackTrace);
    }
    
  } catch (e, stackTrace) {
    Logger.error('重いサービス初期化エラー', e);
    _logError('重いサービス初期化エラー', e, stackTrace);
  }
}
