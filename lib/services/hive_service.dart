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

      // 必要なBoxだけ先に開く（並列処理で高速化）
      await Future.wait([
        _openBoxIfNeeded<MedicationMemo>('medication_memos'),
        _openBoxIfNeeded('medication_data'),
      ]);

      _isInitialized = true;
      PerformanceMonitor.end('hive_init');
      
      if (kDebugMode) {
        debugPrint('✅ Hive初期化完了');
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
}

