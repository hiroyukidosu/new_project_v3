// アプリケーションのルートウィジェット
// アプリケーションのテーマ、ロケール、およびホーム画面を設定します

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import '../services/trial_service.dart';
import '../services/hive_lifecycle_service.dart';
import '../services/in_app_purchase_service.dart';
import '../services/key_backup_manager.dart';
import '../utils/logger.dart';
import '../widgets/tutorial_widgets.dart';
// 新しいアーキテクチャを使用する場合は、以下のコメントを外してください
// import '../pages/integrated_home_page.dart';

/// アプリケーションのルートウィジェット
/// テーマとロケールを設定し、ホーム画面を表示します
/// アプリライフサイクルを管理して安全なクリーンアップを実行します
class MedicationAlarmApp extends StatefulWidget {
  const MedicationAlarmApp({super.key});

  @override
  State<MedicationAlarmApp> createState() => _MedicationAlarmAppState();
}

class _MedicationAlarmAppState extends State<MedicationAlarmApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 非同期クリーンアップを実行（完了を待たない）
    // 注意: dispose()は同期的である必要があるため、クリーンアップは非同期で実行
    // アプリ終了時は時間制限があるため、重要な処理のみ同期実行
    _cleanupResourcesSync();
    super.dispose();
  }
  
  /// 同期クリーンアップ（重要な処理のみ）
  void _cleanupResourcesSync() {
    try {
      // キーバックアップマネージャーのクリーンアップ（Timerを停止）
      KeyBackupManager.dispose();
      
      // アプリ内課金サービスのクリーンアップ（StreamSubscriptionを解放）
      InAppPurchaseService.dispose();
      
      Logger.debug('同期クリーンアップ完了');
    } catch (e) {
      Logger.error('同期クリーンアップエラー', e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // アプリがバックグラウンドに移動した時
        Logger.debug('アプリがバックグラウンドに移動しました');
        break;
      case AppLifecycleState.inactive:
        // アプリが非アクティブになった時
        break;
      case AppLifecycleState.resumed:
        // アプリが再開された時
        Logger.debug('アプリが再開されました');
        break;
      case AppLifecycleState.detached:
        // アプリが終了する直前
        Logger.info('アプリ終了処理を開始します');
        // 非同期クリーンアップを実行（完了を待つ）
        // 注意: detached状態では時間制限があるため、可能な限り早く完了させる
        _cleanupResources().catchError((e, stackTrace) async {
          Logger.error('アプリ終了時クリーンアップエラー', e);
          // FirebaseCrashlyticsに記録（初期化済みの場合、タイムアウト付き）
          try {
            if (Firebase.apps.isNotEmpty) {
              await FirebaseCrashlytics.instance.recordError(
                e,
                stackTrace,
                reason: 'アプリ終了時クリーンアップエラー',
                fatal: false,
              ).timeout(
                const Duration(seconds: 2),
                onTimeout: () {
                  // タイムアウト時はログのみ
                  Logger.warning('Crashlytics記録がタイムアウトしました');
                },
              );
            }
          } catch (_) {
            // Crashlytics記録失敗時は無視
          }
        });
        break;
      case AppLifecycleState.hidden:
        // アプリが非表示になった時（iOS 14+）
        break;
    }
  }

  /// リソースのクリーンアップ
  Future<void> _cleanupResources() async {
    try {
      Logger.info('📦 アプリリソースクリーンアップ開始...');
      
      // 1. キーバックアップマネージャーのクリーンアップ（Timerを停止）
      KeyBackupManager.dispose();
      
      // 2. アプリ内課金サービスのクリーンアップ（StreamSubscriptionを解放）
      InAppPurchaseService.dispose();
      
      // 3. Hiveライフサイクルサービスのクリーンアップ（最後に実行）
      await HiveLifecycleService.dispose();
      
      Logger.info('✅ アプリリソースクリーンアップ完了');
    } catch (e, stackTrace) {
      Logger.error('アプリリソースクリーンアップエラー', e);
      // Crashlyticsに記録（初期化済みの場合）
      try {
        // Firebase初期化状態を確認
        if (Firebase.apps.isNotEmpty) {
          await FirebaseCrashlytics.instance.recordError(
            e,
            stackTrace,
            reason: 'アプリリソースクリーンアップエラー',
            fatal: false,
          );
        }
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'サプリ＆おくすりスケジュール管理帳',
      locale: const Locale('ja', 'JP'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F7A5C),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16.0)),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F7A5C),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16.0)),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
      themeMode: ThemeMode.system,
      home: TutorialWrapper(
        child: const MedicationHomePage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
  
  /// フォントサイズを取得（後方互換性のため）
  static Future<double> getFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('fontSize') ?? 16.0;
    } catch (e) {
      return 16.0;
    }
  }
}

