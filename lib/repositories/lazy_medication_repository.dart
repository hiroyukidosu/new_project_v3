// 遅延初期化リポジトリパターン
// リポジトリを必要になったときに初期化します

import 'package:flutter/foundation.dart';
import '../repositories/medication_repository.dart';
import '../utils/performance_monitor.dart';

/// 遅延初期化MedicationRepository
class LazyMedicationRepository {
  static MedicationRepository? _instance;
  static Future<MedicationRepository>? _initFuture;

  /// リポジトリインスタンスを取得（必要になったときに初期化）
  static Future<MedicationRepository> get instance async {
    // 既に初期化済みなら即座に返す
    if (_instance != null) return _instance!;

    // 既に初期化中なら待つ
    if (_initFuture != null) return _initFuture!;

    // 初期化開始
    _initFuture = _initialize();
    _instance = await _initFuture!;
    return _instance!;
  }

  /// リポジトリの初期化
  static Future<MedicationRepository> _initialize() async {
    PerformanceMonitor.start('medication_repository_init');
    
    if (kDebugMode) {
      debugPrint('🔄 MedicationRepository初期化開始');
    }
    
    final repo = MedicationRepository();
    await repo.initialize();
    
    PerformanceMonitor.end('medication_repository_init');
    
    if (kDebugMode) {
      debugPrint('✅ MedicationRepository初期化完了');
    }
    
    return repo;
  }

  /// リポジトリをリセット（テスト用）
  static void reset() {
    _instance = null;
    _initFuture = null;
  }

  /// 初期化済みかどうか
  static bool get isInitialized => _instance != null;

  /// 初期化中かどうか
  static bool get isInitializing => _initFuture != null && _instance == null;
}

