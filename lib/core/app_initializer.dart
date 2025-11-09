// lib/core/app_initializer.dart
// 段階的な初期化を管理するクラス

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/locale_helper.dart';
import '../utils/performance_monitor.dart';
import '../services/hive_service.dart';
import '../services/app_preferences.dart';
import '../services/in_app_purchase_service.dart';
import '../services/trial_service.dart';
import '../repositories/medication_repository.dart';
import '../repositories/calendar_repository.dart';
import '../repositories/backup_repository.dart';
import '../repositories/alarm_repository.dart';
import '../models/medication_memo.dart';
import '../models/adapters/medication_memo_adapter.dart';

/// 段階的な初期化を管理するクラス
class AppInitializer {
  // 初期化状態を管理（重複実行を防止）
  static bool _isHiveInitializing = false;
  static bool _isAdaptersRegistered = false;
  
  /// フェーズ1: 最小限の初期化（UI表示に必要なもの）
  /// Hive初期化を最優先で実行（Repositoryの依存関係のため）
  /// 注意: このメソッドはinitializeCriticalAndEssential()から呼ばれるため、
  /// 直接呼ばれる場合はHive初期化が完了していることを確認
  static Future<void> initializeCritical() async {
    return await PerformanceMonitor.measure('critical_init', () async {
      // ステップ1: Hive初期化を最優先で実行（順次実行）
      await _initializeHive();
      
      // ステップ2: Adapter登録（Hive初期化後）
      await _registerAdapters();
      
      // ステップ3: Locale初期化（Hive依存しないので並列化可能）
      // この時点でHiveは初期化済みなので、他の処理と並列実行可能
      await _initializeLocale();
    });
  }

  /// フェーズ2: UIスプラッシュ後に初期化
  /// Hive初期化完了後にRepositoryを初期化
  /// 改善: 並列実行で高速化
  static Future<void> initializeEssential() async {
    return await PerformanceMonitor.measure('essential_init', () async {
      // Hive初期化が完了していることを確認（最大5秒待機）
      if (!HiveService.isInitialized) {
        if (kDebugMode) {
          debugPrint('⚠️ Hive初期化が完了していません。待機します...');
        }
        int waitCount = 0;
        while (!HiveService.isInitialized && waitCount < 50) {
          await Future.delayed(const Duration(milliseconds: 100));
          waitCount++;
        }
        
        // 待機後も初期化されていない場合は再初期化を試みる
        if (!HiveService.isInitialized) {
          if (kDebugMode) {
            debugPrint('⚠️ Hive初期化が完了していません。再初期化を試みます...');
          }
          await _initializeHive();
          await _registerAdapters();
        }
      }
      
      // 改善: すべての処理を並列実行（最大時間のみ待機）
      // Hive依存のRepositoryとHive依存しない処理を同時に実行
      await Future.wait([
        // Hive依存のRepository（並列実行）
        _initializeMedicationRepository(),
        _initializeCalendarRepository(),
        _initializeAlarmRepository(),
        // Hive依存しない処理（並列実行）
        _loadUserPreferences(),
      ], eagerError: false);
    });
  }
  
  /// フェーズ1とフェーズ2を並列実行（最適化版）
  /// critical_initとessential_initを並列実行（Hive初期化後）
  static Future<void> initializeCriticalAndEssential() async {
    return await PerformanceMonitor.measure('phase2_parallel', () async {
      // ステップ1: Hive初期化を最優先で実行（必須）
      await _initializeHive();
      await _registerAdapters();
      
      // ステップ1.5: AppPreferences初期化（Hive初期化後、Repository初期化前）
      // これにより、phase2_parallelの計測時間から除外される
      await _loadUserPreferences();
      
      // ステップ2: すべての処理を並列実行（高速化）
      // Hive初期化完了後なので、並列実行可能
      // ⭐ 重要: すべての処理を同じレベルのFuture.waitで並列実行
      if (kDebugMode) {
        debugPrint('🔍 phase2_parallel開始: Repository初期化を並列実行');
      }
      
      final stopwatch = Stopwatch()..start();
      await Future.wait([
        // critical_initの残り（Locale初期化など）
        _measureTask('Locale初期化', _initializeLocale),
        // essential_init（すべてのRepositoryを並列初期化）
        _measureTask('MedicationRepository', _initializeMedicationRepository),
        _measureTask('CalendarRepository', _initializeCalendarRepository),
        _measureTask('AlarmRepository', _initializeAlarmRepository),
        _measureTask('BackupRepository', _initializeBackupRepository),
      ], eagerError: false);
      
      if (kDebugMode) {
        debugPrint('🔍 phase2_parallel完了: すべてのRepository初期化完了 (${stopwatch.elapsedMilliseconds}ms)');
      }
    });
  }
  
  /// タスクの処理時間を計測（デバッグ用）
  static Future<void> _measureTask(String name, Future<void> Function() task) async {
    final stopwatch = Stopwatch()..start();
    await task();
    if (kDebugMode) {
      debugPrint('  ├─ $name: ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  /// フェーズ3: バックグラウンドで初期化（遅延OK）
  /// 改善: アプリ表示後に完全にバックグラウンドで実行（起動時間に影響しない）
  static void initializeDeferred() {
    // 改善: アプリ表示後に3秒待ってから実行（完全にバックグラウンド化）
    // 課金初期化は完全に遅延化（ユーザーが課金画面を開くまで待機可能）
    // 計測は行わない（起動時間に影響しないため）
    Future.delayed(const Duration(seconds: 3), () async {
      // Hive初期化完了を待機（最大10秒）
      int waitCount = 0;
      while (!HiveService.isInitialized && waitCount < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      
      // 改善: BackupRepository、TrialServiceを先に実行（並列）
      // これらは軽量なので先に実行
      await Future.wait([
        _initializeBackupRepository(),
        _initializeTrialService(),
      ], eagerError: false);
      
      // 改善: 課金初期化はさらに遅延（5秒後、完全にバックグラウンド）
      // 計測は行わない（起動時間に影響しないため）
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          await _initializeInAppPurchase();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ 課金初期化エラー（継続可能）: $e');
          }
          // エラーでもアプリは使用可能
        }
      });
    });
  }

  // プライベートメソッド

  static Future<void> _initializeLocale() async {
    try {
      // 非同期で実行してメインスレッドをブロックしない
      await Future.microtask(() async {
        final systemLocale = PlatformDispatcher.instance.locale;
        final systemTag = systemLocale.toLanguageTag();
        await LocaleHelper.initializeLocale(systemTag);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Locale初期化エラー: $e');
      }
    }
  }

  static Future<void> _initializeHive() async {
    try {
      // 既に初期化済みの場合はスキップ
        if (HiveService.isInitialized) {
          // ログを出さない（サイレント、二重初期化の警告を削減）
          return;
        }
      
      // 初期化中の場合は待機（重複実行を防止）
      if (_isHiveInitializing) {
        if (kDebugMode) {
          debugPrint('⏳ Hive初期化中...待機します');
        }
        // 初期化完了まで待機（最大5秒）
        int waitCount = 0;
        while (!HiveService.isInitialized && waitCount < 50) {
          await Future.delayed(const Duration(milliseconds: 100));
          waitCount++;
        }
        if (HiveService.isInitialized) {
          if (kDebugMode) {
            debugPrint('✅ Hive初期化完了（待機後）');
          }
          return;
        }
      }
      
      // 初期化フラグを設定
      _isHiveInitializing = true;
      
      try {
        // フレーム分散で初期化（UIスレッドをブロックしない）
        await _processWithFrameDistribution(() async {
          await HiveService.initialize();
        });
        
        if (kDebugMode) {
          debugPrint('✅ Hive初期化完了');
        }
      } finally {
        // 初期化フラグをリセット
        _isHiveInitializing = false;
      }
    } catch (e) {
      _isHiveInitializing = false;
      if (kDebugMode) {
        debugPrint('❌ Hive初期化エラー: $e');
      }
      rethrow;
    }
  }

  static Future<void> _registerAdapters() async {
    try {
      // 既に登録済みの場合はスキップ
      if (_isAdaptersRegistered) {
        if (kDebugMode) {
          debugPrint('✅ Adapterは既に登録済み（スキップ）');
        }
        return;
      }
      
      // Adapter登録（typeId 0と2をチェック）
      final adapter = MedicationMemoAdapter();
      final typeId = adapter.typeId;
      
      if (!Hive.isAdapterRegistered(typeId)) {
        Hive.registerAdapter(adapter);
        if (kDebugMode) {
          debugPrint('✅ MedicationMemoAdapter登録完了 (typeId: $typeId)');
        }
      } else {
        // 警告を出さない（サイレント）
        // 既に登録済みの場合は正常な状態なので、ログを出さない
      }
      
      // 登録フラグを設定
      _isAdaptersRegistered = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Adapter登録エラー: $e');
      }
      // エラー時もフラグを設定（重複登録を防止）
      _isAdaptersRegistered = true;
    }
  }

  static Future<void> _initializeMedicationRepository() async {
    try {
      // Hive初期化確認
      if (!HiveService.isInitialized) {
        throw Exception('Hive初期化が完了していません');
      }
      
      // 直接初期化（フレーム分散を削除して高速化）
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
  
  /// フレーム分散で処理を実行（UIスレッドの負荷を軽減）
  /// 改善: フレーム待機を最小限に（処理時間を短縮）
  static Future<void> _processWithFrameDistribution(Future<void> Function() task) async {
    // 現在のフレームが終了するまで待機
    await SchedulerBinding.instance.endOfFrame;
    // タスクを実行（非同期で実行してUIスレッドをブロックしない）
    await task();
    // 次のフレームまで待機（UIスレッドに制御を返す）
    await SchedulerBinding.instance.endOfFrame;
  }

  static Future<void> _initializeCalendarRepository() async {
    try {
      // Hive初期化確認
      if (!HiveService.isInitialized) {
        throw Exception('Hive初期化が完了していません');
      }
      
      // 直接初期化（フレーム分散を削除して高速化）
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

  static Future<void> _initializeBackupRepository() async {
    try {
      // Hive初期化確認（最大5秒待機）
      if (!HiveService.isInitialized) {
        if (kDebugMode) {
          debugPrint('⏳ BackupRepository: Hive初期化完了を待機中...');
        }
        int waitCount = 0;
        while (!HiveService.isInitialized && waitCount < 50) {
          await Future.delayed(const Duration(milliseconds: 100));
          waitCount++;
        }
        
        if (!HiveService.isInitialized) {
          if (kDebugMode) {
            debugPrint('❌ BackupRepository: Hive初期化が完了していません（タイムアウト）');
          }
          return; // エラーをスローせず、スキップ
        }
      }
      
      // 直接初期化（フレーム分散を削除して高速化）
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

  static Future<void> _initializeAlarmRepository() async {
    try {
      // Hive初期化確認（AlarmRepositoryはHive依存しない場合もあるが、念のため確認）
      // Hive依存しない場合はスキップ可能
      
      // 直接初期化（フレーム分散を削除して高速化）
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

  static Future<void> _loadUserPreferences() async {
    try {
      await AppPreferences.init();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserPreferences読み込みエラー: $e');
      }
    }
  }

  // 課金初期化の重複実行を防ぐフラグ
  static bool _isInAppPurchaseInitializing = false;
  static bool _isInAppPurchaseInitialized = false;

  static Future<void> _initializeInAppPurchase() async {
    // 重複実行を防止
    if (_isInAppPurchaseInitializing || _isInAppPurchaseInitialized) {
      if (kDebugMode) {
        debugPrint('ℹ️ 課金初期化は既に実行中または完了済み（スキップ）');
      }
      return;
    }
    
    _isInAppPurchaseInitializing = true;
    
    try {
      final bool isMobilePlatform = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android);
      if (isMobilePlatform) {
        // タイムアウト付きで初期化（10秒でタイムアウト、ネットワーク遅延を考慮）
        try {
          final bool isAvailable = await InAppPurchase.instance.isAvailable()
              .timeout(const Duration(seconds: 10), onTimeout: () {
            if (kDebugMode) {
              debugPrint('⚠️ 課金初期化タイムアウト（10秒、オフラインモードで続行）');
            }
            return false;
          });
          
          if (isAvailable) {
            // 購入履歴復元は1回だけ実行（重複防止）
            // タイムアウトを10秒に設定（ネットワークが遅い場合を考慮）
            await InAppPurchaseService.restorePurchases()
                .timeout(const Duration(seconds: 10), onTimeout: () {
              if (kDebugMode) {
                debugPrint('⚠️ 購入履歴復元タイムアウト（10秒、継続可能）');
              }
            });
            
            if (kDebugMode) {
              debugPrint('✅ アプリ内課金初期化完了');
            }
          } else {
            if (kDebugMode) {
              debugPrint('ℹ️ アプリ内課金が利用できません（オフラインモード）');
            }
          }
        } on TimeoutException {
          if (kDebugMode) {
            debugPrint('⚠️ 課金初期化タイムアウト（オフラインモードで続行）');
          }
          // タイムアウトでもアプリは使用可能
        }
      }
      
      _isInAppPurchaseInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ アプリ内課金初期化エラー（継続可能）: $e');
      }
      // エラーでもアプリは使用可能（課金機能は後で利用可能）
    } finally {
      _isInAppPurchaseInitializing = false;
    }
  }

  static Future<void> _initializeTrialService() async {
    try {
      if (kDebugMode) {
        await TrialService.resetTrial();
        if (kDebugMode) {
          debugPrint('✅ トライアル期間をリセットしました (debug)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ トライアルリセットエラー: $e');
      }
    }
  }
}

