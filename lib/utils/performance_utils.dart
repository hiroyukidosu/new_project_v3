import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// パフォーマンス最適化ユーティリティ
/// 
/// 既存機能に影響を与えずにパフォーマンスを改善
class PerformanceUtils {
  /// デバウンス処理
  /// 
  /// 既存のデバウンス処理を改善
  static Timer? _debounceTimer;
  
  static void debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// 重い処理を非同期で実行
  /// 
  /// UIをブロックしないように重い処理を分離
  static Future<T> runInBackground<T>(
    Future<T> Function() computation,
  ) async {
    return await compute(_runComputation, computation);
  }

  static Future<T> _runComputation<T>(
    Future<T> Function() computation,
  ) async {
    return await computation();
  }

  /// メモリ効率的なリストビルダー
  /// 
  /// 大量のデータを効率的に表示
  static Widget buildEfficientListView({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // パフォーマンス最適化
      cacheExtent: 200.0, // キャッシュ範囲を制限
      addAutomaticKeepAlives: false, // 自動保持を無効化
      addRepaintBoundaries: true, // 再描画境界を追加
    );
  }

  /// 条件付き再描画
  /// 
  /// 必要な時のみ再描画を実行
  static Widget conditionalRepaint({
    required Widget child,
    required bool shouldRepaint,
  }) {
    if (shouldRepaint) {
      return RepaintBoundary(child: child);
    }
    return child;
  }

  /// 画像の最適化
  /// 
  /// 画像のメモリ使用量を削減
  static Widget buildOptimizedImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      // メモリ最適化
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      isAntiAlias: true,
      filterQuality: FilterQuality.medium,
    );
  }

  /// アニメーションの最適化
  /// 
  /// 不要なアニメーションを避ける
  static Widget buildOptimizedAnimation({
    required Widget child,
    required AnimationController controller,
    bool shouldAnimate = true,
  }) {
    if (!shouldAnimate) {
      return child;
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return child!;
      },
      child: child,
    );
  }
}

/// パフォーマンス監視
/// 
/// 開発時にパフォーマンス問題を検出
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _durations = {};

  /// 処理時間を計測開始
  static void startTiming(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// 処理時間を計測終了
  static void endTiming(String operation) {
    final startTime = _startTimes[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _durations.putIfAbsent(operation, () => []).add(duration);
      
      if (kDebugMode) {
        debugPrint('[$operation] 実行時間: ${duration.inMilliseconds}ms');
      }
    }
  }

  /// 平均実行時間を取得
  static Duration getAverageTime(String operation) {
    final durations = _durations[operation];
    if (durations == null || durations.isEmpty) {
      return Duration.zero;
    }

    final totalMs = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  /// パフォーマンス統計をリセット
  static void reset() {
    _startTimes.clear();
    _durations.clear();
  }
}
