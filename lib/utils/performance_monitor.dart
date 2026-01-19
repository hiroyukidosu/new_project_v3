import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// パフォーマンス監視ユーティリティ
/// 
/// アプリのパフォーマンスを監視し、問題を特定
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _durations = {};
  static final Map<String, int> _operationCounts = {};
  
  /// 処理時間を計測開始
  static void startTiming(String operation) {
    _startTimes[operation] = DateTime.now();
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
  }
  
  /// 処理時間を計測終了
  static void endTiming(String operation) {
    final startTime = _startTimes[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _durations.putIfAbsent(operation, () => []).add(duration);
      
      if (kDebugMode) {
        debugPrint('[PERF] $operation: ${duration.inMilliseconds}ms');
      }
      
      // パフォーマンス警告
      if (duration.inMilliseconds > 1000) {
        debugPrint('[PERF WARNING] $operation took ${duration.inMilliseconds}ms (slow operation)');
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
  
  /// 最大実行時間を取得
  static Duration getMaxTime(String operation) {
    final durations = _durations[operation];
    if (durations == null || durations.isEmpty) {
      return Duration.zero;
    }
    
    return durations.reduce((a, b) => a > b ? a : b);
  }
  
  /// 操作回数を取得
  static int getOperationCount(String operation) {
    return _operationCounts[operation] ?? 0;
  }
  
  /// パフォーマンス統計を取得
  static Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final operation in _durations.keys) {
      stats[operation] = {
        'count': getOperationCount(operation),
        'averageMs': getAverageTime(operation).inMilliseconds,
        'maxMs': getMaxTime(operation).inMilliseconds,
        'totalMs': _durations[operation]!.fold<int>(
          0,
          (sum, duration) => sum + duration.inMilliseconds,
        ),
      };
    }
    
    return stats;
  }
  
  /// パフォーマンス統計をリセット
  static void reset() {
    _startTimes.clear();
    _durations.clear();
    _operationCounts.clear();
  }
  
  /// パフォーマンス統計を表示
  static void printStats() {
    if (kDebugMode) {
      debugPrint('=== パフォーマンス統計 ===');
      final stats = getPerformanceStats();
      
      for (final entry in stats.entries) {
        final operation = entry.key;
        final data = entry.value as Map<String, dynamic>;
        
        debugPrint('$operation:');
        debugPrint('  実行回数: ${data['count']}');
        debugPrint('  平均時間: ${data['averageMs']}ms');
        debugPrint('  最大時間: ${data['maxMs']}ms');
        debugPrint('  合計時間: ${data['totalMs']}ms');
        debugPrint('');
      }
    }
  }
}

/// パフォーマンス監視付きウィジェット
class PerformanceMonitoredWidget extends StatefulWidget {
  final Widget child;
  final String operationName;
  
  const PerformanceMonitoredWidget({
    super.key,
    required this.child,
    required this.operationName,
  });
  
  @override
  State<PerformanceMonitoredWidget> createState() => _PerformanceMonitoredWidgetState();
}

class _PerformanceMonitoredWidgetState extends State<PerformanceMonitoredWidget> {
  @override
  void initState() {
    super.initState();
    PerformanceMonitor.startTiming('${widget.operationName}_build');
  }
  
  @override
  void dispose() {
    PerformanceMonitor.endTiming('${widget.operationName}_build');
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// パフォーマンス監視付き関数実行
class PerformanceMonitoredFunction {
  /// パフォーマンス監視付きで関数を実行
  static Future<T?> execute<T>(
    Future<T> Function() function, {
    required String operationName,
  }) async {
    PerformanceMonitor.startTiming(operationName);
    
    try {
      final result = await function();
      PerformanceMonitor.endTiming(operationName);
      return result;
    } catch (e) {
      PerformanceMonitor.endTiming(operationName);
      rethrow;
    }
  }
  
  /// パフォーマンス監視付きで同期関数を実行
  static T? executeSync<T>(
    T Function() function, {
    required String operationName,
  }) {
    PerformanceMonitor.startTiming(operationName);
    
    try {
      final result = function();
      PerformanceMonitor.endTiming(operationName);
      return result;
    } catch (e) {
      PerformanceMonitor.endTiming(operationName);
      rethrow;
    }
  }
}

/// フレームレート監視
class FrameRateMonitor {
  static int _frameCount = 0;
  static DateTime _lastFrameTime = DateTime.now();
  static final List<double> _frameRates = [];
  
  /// フレームレートを記録
  static void recordFrame() {
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFrameTime).inMilliseconds;
    
    if (elapsed >= 1000) { // 1秒ごとに計算
      final frameRate = _frameCount * 1000.0 / elapsed;
      _frameRates.add(frameRate);
      
      if (kDebugMode && frameRate < 30) {
        debugPrint('[PERF] Low frame rate: ${frameRate.toStringAsFixed(1)} FPS');
      }
      
      _frameCount = 0;
      _lastFrameTime = now;
    }
  }
  
  /// 平均フレームレートを取得
  static double getAverageFrameRate() {
    if (_frameRates.isEmpty) return 0;
    
    final sum = _frameRates.fold<double>(0, (a, b) => a + b);
    return sum / _frameRates.length;
  }
  
  /// フレームレート統計をリセット
  static void reset() {
    _frameCount = 0;
    _lastFrameTime = DateTime.now();
    _frameRates.clear();
  }
}
