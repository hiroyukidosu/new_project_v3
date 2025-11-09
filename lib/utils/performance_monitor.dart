// パフォーマンス計測ユーティリティ
// 初期化やデータ読み込みの時間を計測します

import 'package:flutter/foundation.dart';

/// パフォーマンス計測クラス
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, int> _counters = {};

  /// 計測開始
  static void start(String name) {
    _timers[name] = Stopwatch()..start();
  }

  /// 計測終了
  static void end(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      if (kDebugMode) {
        debugPrint('⏱️ [$name] ${timer.elapsedMilliseconds}ms');
      }
      _timers.remove(name);
    }
  }

  /// カウンターをインクリメント
  static void increment(String name) {
    _counters[name] = (_counters[name] ?? 0) + 1;
  }

  /// カウンターの値を取得
  static int getCount(String name) {
    return _counters[name] ?? 0;
  }

  /// カウンターをリセット
  static void resetCounter(String name) {
    _counters.remove(name);
  }

  /// すべてのタイマーをクリア
  static void clear() {
    _timers.clear();
    _counters.clear();
  }

  /// タスクの実行時間を計測（改善版）
  static Future<T> measure<T>(
    String label,
    Future<T> Function() task,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await task();
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('⏱️ [$label] ${stopwatch.elapsedMilliseconds}ms');
      }
      return result;
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('❌ [$label] Failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      rethrow;
    }
  }

  /// 同期的なタスクの実行時間を計測
  static T measureSync<T>(
    String label,
    T Function() task,
  ) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = task();
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('⏱️ [$label] ${stopwatch.elapsedMilliseconds}ms');
      }
      return result;
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('❌ [$label] Failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      rethrow;
    }
  }
}
