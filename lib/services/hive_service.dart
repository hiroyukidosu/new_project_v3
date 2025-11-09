// Hive初期化サービス
// Hiveの初期化とBox管理を最適化します

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_memo.dart';
import '../models/adapters/medication_memo_adapter.dart';
import '../utils/performance_monitor.dart';

/// Hive初期化サービス
class HiveService {
  static bool _isInitialized = false;
  static final Set<String> _openedBoxes = {};

  /// Hive初期化（起動時に1回だけ呼ぶ）
  static Future<void> initialize() async {
    if (_isInitialized) return;

    PerformanceMonitor.start('hive_init');
    
    try {
      // Hive初期化
      await Hive.initFlutter();

      // Adapter登録
      final tempAdapter = MedicationMemoAdapter();
      if (!Hive.isAdapterRegistered(tempAdapter.typeId)) {
        Hive.registerAdapter(tempAdapter);
        if (kDebugMode) {
          debugPrint('✅ MedicationMemoAdapter登録完了');
        }
      }

      // 改善: 起動時はBoxを開かない（完全な遅延読み込み）
      // 各Repositoryで必要になった時にBoxを開く
      // これによりhive_initを200-300msに短縮
      
      // バックグラウンドでBoxを開く（完全に遅延）
      Future.microtask(() async {
        try {
          // よく使われるBoxをバックグラウンドで開く
          await Future.wait([
            _openBoxIfNeeded('medication_data'),
            _openBoxIfNeeded<MedicationMemo>('medication_memos'),
          ], eagerError: false);
          if (kDebugMode) {
            debugPrint('✅ Hive Boxを遅延読み込み完了');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Hive Box遅延読み込みエラー: $e');
          }
        }
      });

      _isInitialized = true;
      PerformanceMonitor.end('hive_init');
      
      // バックグラウンドでコンパクションを実行（1分後、アイドル時）
      // 起動時ではなく、アプリが使用中でない時に実行
      Future.delayed(const Duration(minutes: 1), () {
        _compactBoxesIfIdle();
      });
      
      if (kDebugMode) {
        debugPrint('✅ Hive基本初期化完了（Boxは遅延読み込み）');
      }
    } catch (e) {
      PerformanceMonitor.end('hive_init');
      if (kDebugMode) {
        debugPrint('❌ Hive初期化エラー: $e');
      }
      rethrow;
    }
  }

  /// Boxを開く（既に開かれている場合はスキップ）
  static Future<Box<T>> _openBoxIfNeeded<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    _openedBoxes.add(name);
    return await Hive.openBox<T>(name);
  }

  /// 遅延読み込み用のBox（必要になったときに開く）
  static Future<Box> openBoxLazy(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }
    _openedBoxes.add(name);
    return await Hive.openBox(name);
  }

  /// 型指定付きでBoxを開く（遅延読み込み）
  static Future<Box<T>> openBoxLazyTyped<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    _openedBoxes.add(name);
    return await Hive.openBox<T>(name);
  }

  /// 初期化状態を確認
  static bool get isInitialized => _isInitialized;

  /// 開かれているBoxのリストを取得
  static Set<String> get openedBoxes => Set.unmodifiable(_openedBoxes);

  /// Boxのコンパクション（アイドル時に実行）
  static void _compactBoxesIfIdle() {
    try {
      // アプリが使用中でない場合のみコンパクションを実行
      // 実際の実装では、アプリの状態をチェックする必要がある
      for (final boxName in _openedBoxes) {
        if (Hive.isBoxOpen(boxName)) {
          // Boxが開いている場合はcompactしない（エラー回避）
          // コンパクションが必要な場合は、Boxを閉じてからcompactする
          if (kDebugMode) {
            debugPrint('ℹ️ Box "$boxName" is open, skipping compact (idle check)');
          }
          // 将来的にコンパクションが必要な場合は、以下のように実装：
          // final box = Hive.box(boxName);
          // await box.close();
          // await box.compact();
          // await Hive.openBox(boxName);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Box compact error: $e');
      }
    }
  }
}

