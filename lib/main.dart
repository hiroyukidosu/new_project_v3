// アプリケーションのエントリーポイント
// 初期化処理とエラーハンドリングを設定します

import 'dart:async';
import 'dart:io';
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
import 'models/medication_memo.dart';
import 'models/adapters/medication_memo_adapter.dart';
import 'services/app_preferences.dart';
import 'services/in_app_purchase_service.dart';
import 'services/trial_service.dart';
import 'screens/medication_alarm_app.dart';
import 'repositories/medication_repository.dart';
import 'repositories/calendar_repository.dart';
import 'repositories/backup_repository.dart';
import 'repositories/alarm_repository.dart';

/// アプリケーションのエントリーポイント
/// 初期化処理とエラーハンドリングを設定
void main() async {
  // パフォーマンス最適化：最小限の初期化のみ実行
  WidgetsFlutterBinding.ensureInitialized();
  
  // 日付のローカライゼーション初期化
  await LocaleHelper.initializeLocale('ja_JP');
  
  // Hive初期化を先に完了させる
  try {
    debugPrint('📦 Hive初期化開始...');
    await Hive.initFlutter();
    
    // アダプター登録
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MedicationMemoAdapter());
      debugPrint('✅ MedicationMemoAdapter登録完了');
    }
    
    // ボックスを開く
    await Hive.openBox<MedicationMemo>('medication_memos');
    debugPrint('✅ medication_memosボックスを開きました');
    
    // ボックス確認
    if (Hive.isBoxOpen('medication_memos')) {
      final box = Hive.box<MedicationMemo>('medication_memos');
      debugPrint('✅ ボックス確認完了: ${box.length}件のデータ');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Hive初期化エラー: $e');
    debugPrint('スタックトレース: $stackTrace');
  }
  
  // SharedPreferences初期化も先に完了させる
  try {
    debugPrint('💾 SharedPreferences初期化開始...');
    await AppPreferences.init();
    debugPrint('✅ SharedPreferences初期化完了');
  } catch (e) {
    debugPrint('❌ SharedPreferences初期化エラー: $e');
  }
  
  // トライアル期間をリセット（開発・テスト用）
  try {
    await TrialService.resetTrial();
    debugPrint('✅ トライアル期間をリセットしました');
  } catch (e) {
    debugPrint('❌ トライアルリセットエラー: $e');
  }
  
  // リポジトリの初期化
  await _initializeRepositories();
  
  // アプリを起動（ProviderScopeでラップ）
  runApp(
    const ProviderScope(
      child: MedicationAlarmApp(),
    ),
  );
  
  // 重い初期化処理は非同期で実行
  Future.microtask(() async {
    await _initializeAppAsync();
  });
}

/// 非同期初期化処理（パフォーマンス最適化）
Future<void> _initializeAppAsync() async {
  try {
    // Firebase初期化（必須でない場合は遅延実行）
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Crashlytics初期化
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    
    // エラーハンドリング設定
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // その他の重い初期化処理
    await _initializeHeavyServices();
    
  } catch (e) {
    // 初期化失敗時はログのみ出力（アプリは継続動作）
    if (kDebugMode) {
      debugPrint('非同期初期化エラー: $e');
    }
  }
}

/// リポジトリの初期化
Future<void> _initializeRepositories() async {
  try {
    debugPrint('🗄️ リポジトリ初期化開始...');
    
    // メディケーションリポジトリの初期化
    try {
      final medicationRepo = MedicationRepository();
      await medicationRepo.initialize();
      debugPrint('✅ MedicationRepository初期化完了');
    } catch (e) {
      debugPrint('❌ MedicationRepository初期化エラー: $e');
    }
    
    // カレンダーリポジトリの初期化
    try {
      final calendarRepo = CalendarRepository();
      await calendarRepo.initialize();
      debugPrint('✅ CalendarRepository初期化完了');
    } catch (e) {
      debugPrint('❌ CalendarRepository初期化エラー: $e');
    }
    
    // バックアップリポジトリの初期化
    try {
      final backupRepo = BackupRepository();
      await backupRepo.initialize();
      debugPrint('✅ BackupRepository初期化完了');
    } catch (e) {
      debugPrint('❌ BackupRepository初期化エラー: $e');
    }
    
    // アラームリポジトリの初期化
    try {
      final alarmRepo = AlarmRepository();
      await alarmRepo.initialize();
      debugPrint('✅ AlarmRepository初期化完了');
    } catch (e) {
      debugPrint('❌ AlarmRepository初期化エラー: $e');
    }
    
    debugPrint('✅ 全リポジトリ初期化完了');
  } catch (e) {
    debugPrint('❌ リポジトリ初期化エラー: $e');
  }
}

/// 重いサービスの初期化
Future<void> _initializeHeavyServices() async {
  try {
    // タイムゾーン初期化
    tz.initializeTimeZones();
    
    // アプリ内課金の初期化
    try {
      final bool isAvailable = await InAppPurchase.instance.isAvailable();
      if (isAvailable) {
        await InAppPurchaseService.restorePurchases();
        if (kDebugMode) {
          debugPrint('アプリ内課金初期化完了');
        }
      }
    } catch (e) {
      debugPrint('アプリ内課金初期化エラー: $e');
    }
    
  } catch (e) {
    debugPrint('重いサービス初期化エラー: $e');
  }
}
