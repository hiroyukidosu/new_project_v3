import 'dart:async';
import '../utils/logger.dart';

/// パフォーマンス測定機能 - アプリの性能を監視・最適化
class PerformanceMeasurement {
  static final Map<String, Stopwatch> _stopwatches = {};
  static final Map<String, List<Duration>> _measurements = {};
  static final Map<String, int> _operationCounts = {};
  
  /// パフォーマンス測定の開始
  static void startMeasurement(String operationName) {
    _stopwatches[operationName] = Stopwatch()..start();
    Logger.performance('測定開始: $operationName');
  }
  
  /// パフォーマンス測定の終了
  static Duration endMeasurement(String operationName) {
    final stopwatch = _stopwatches.remove(operationName);
    if (stopwatch == null) {
      Logger.warning('測定が見つかりません: $operationName');
      return Duration.zero;
    }
    
    stopwatch.stop();
    final duration = stopwatch.elapsed;
    
    // 測定結果を記録
    _measurements.putIfAbsent(operationName, () => []).add(duration);
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
    
    Logger.performance('測定完了: $operationName (${duration.inMilliseconds}ms)');
    return duration;
  }
  
  /// パフォーマンス測定の実行（自動で開始・終了）
  static Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startMeasurement(operationName);
    try {
      final result = await operation();
      endMeasurement(operationName);
      return result;
    } catch (e) {
      endMeasurement(operationName);
      rethrow;
    }
  }
  
  /// 同期操作の測定
  static T measureSyncOperation<T>(
    String operationName,
    T Function() operation,
  ) {
    startMeasurement(operationName);
    try {
      final result = operation();
      endMeasurement(operationName);
      return result;
    } catch (e) {
      endMeasurement(operationName);
      rethrow;
    }
  }
  
  /// 平均実行時間の取得
  static Duration getAverageDuration(String operationName) {
    final measurements = _measurements[operationName];
    if (measurements == null || measurements.isEmpty) {
      return Duration.zero;
    }
    
    final totalMs = measurements.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ measurements.length);
  }
  
  /// 最小実行時間の取得
  static Duration getMinDuration(String operationName) {
    final measurements = _measurements[operationName];
    if (measurements == null || measurements.isEmpty) {
      return Duration.zero;
    }
    
    return measurements.reduce((a, b) => a < b ? a : b);
  }
  
  /// 最大実行時間の取得
  static Duration getMaxDuration(String operationName) {
    final measurements = _measurements[operationName];
    if (measurements == null || measurements.isEmpty) {
      return Duration.zero;
    }
    
    return measurements.reduce((a, b) => a > b ? a : b);
  }
  
  /// 実行回数の取得
  static int getOperationCount(String operationName) {
    return _operationCounts[operationName] ?? 0;
  }
  
  /// パフォーマンス統計の取得
  static Map<String, dynamic> getPerformanceStats(String operationName) {
    final measurements = _measurements[operationName];
    if (measurements == null || measurements.isEmpty) {
      return {};
    }
    
    final count = measurements.length;
    final totalMs = measurements.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    final averageMs = totalMs ~/ count;
    final minMs = measurements.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final maxMs = measurements.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
    
    return {
      'operationName': operationName,
      'count': count,
      'totalMs': totalMs,
      'averageMs': averageMs,
      'minMs': minMs,
      'maxMs': maxMs,
      'averageDuration': Duration(milliseconds: averageMs),
      'minDuration': Duration(milliseconds: minMs),
      'maxDuration': Duration(milliseconds: maxMs),
    };
  }
  
  /// 全パフォーマンス統計の取得
  static Map<String, Map<String, dynamic>> getAllPerformanceStats() {
    final stats = <String, Map<String, dynamic>>{};
    
    for (final operationName in _measurements.keys) {
      stats[operationName] = getPerformanceStats(operationName);
    }
    
    return stats;
  }
  
  /// パフォーマンスレポートの生成
  static String generatePerformanceReport() {
    final report = StringBuffer();
    report.writeln('=== パフォーマンスレポート ===');
    report.writeln('生成日時: ${DateTime.now()}');
    report.writeln();
    
    final stats = getAllPerformanceStats();
    if (stats.isEmpty) {
      report.writeln('測定データがありません。');
      return report.toString();
    }
    
    // 実行時間でソート
    final sortedStats = stats.entries.toList()
      ..sort((a, b) => b.value['averageMs'].compareTo(a.value['averageMs']));
    
    for (final entry in sortedStats) {
      final operationName = entry.key;
      final stat = entry.value;
      
      report.writeln('操作: $operationName');
      report.writeln('  実行回数: ${stat['count']}');
      report.writeln('  平均時間: ${stat['averageMs']}ms');
      report.writeln('  最小時間: ${stat['minMs']}ms');
      report.writeln('  最大時間: ${stat['maxMs']}ms');
      report.writeln('  総時間: ${stat['totalMs']}ms');
      report.writeln();
    }
    
    return report.toString();
  }
  
  /// パフォーマンスデータのクリア
  static void clearMeasurements() {
    _stopwatches.clear();
    _measurements.clear();
    _operationCounts.clear();
    Logger.info('パフォーマンス測定データをクリアしました');
  }
  
  /// 特定の操作の測定データをクリア
  static void clearOperationMeasurements(String operationName) {
    _stopwatches.remove(operationName);
    _measurements.remove(operationName);
    _operationCounts.remove(operationName);
    Logger.info('操作の測定データをクリア: $operationName');
  }
}

/// メモリ使用量の監視
class MemoryMonitor {
  static final List<MemorySnapshot> _snapshots = [];
  static Timer? _monitoringTimer;
  
  /// メモリ監視の開始
  static void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(interval, (_) {
      _takeSnapshot();
    });
    Logger.info('メモリ監視を開始しました（間隔: ${interval.inSeconds}秒）');
  }
  
  /// メモリ監視の停止
  static void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    Logger.info('メモリ監視を停止しました');
  }
  
  /// メモリスナップショットの取得
  static void _takeSnapshot() {
    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      // 実際のメモリ使用量の取得は実装が必要
      heapSize: 0, // 実装が必要
      externalSize: 0, // 実装が必要
    );
    
    _snapshots.add(snapshot);
    
    // 古いスナップショットを削除（最新100件のみ保持）
    if (_snapshots.length > 100) {
      _snapshots.removeAt(0);
    }
    
    Logger.performance('メモリスナップショット: ${snapshot.heapSize}MB');
  }
  
  /// メモリ使用量の統計
  static Map<String, dynamic> getMemoryStats() {
    if (_snapshots.isEmpty) {
      return {};
    }
    
    final heapSizes = _snapshots.map((s) => s.heapSize).toList();
    final externalSizes = _snapshots.map((s) => s.externalSize).toList();
    
    return {
      'snapshotCount': _snapshots.length,
      'heapSize': {
        'current': heapSizes.last,
        'average': heapSizes.reduce((a, b) => a + b) / heapSizes.length,
        'min': heapSizes.reduce((a, b) => a < b ? a : b),
        'max': heapSizes.reduce((a, b) => a > b ? a : b),
      },
      'externalSize': {
        'current': externalSizes.last,
        'average': externalSizes.reduce((a, b) => a + b) / externalSizes.length,
        'min': externalSizes.reduce((a, b) => a < b ? a : b),
        'max': externalSizes.reduce((a, b) => a > b ? a : b),
      },
    };
  }
  
  /// メモリ監視データのクリア
  static void clearSnapshots() {
    _snapshots.clear();
    Logger.info('メモリ監視データをクリアしました');
  }
}

/// メモリスナップショット
class MemorySnapshot {
  final DateTime timestamp;
  final double heapSize;
  final double externalSize;
  
  const MemorySnapshot({
    required this.timestamp,
    required this.heapSize,
    required this.externalSize,
  });
}

/// パフォーマンス最適化の提案
class PerformanceOptimizer {
  /// パフォーマンス問題の検出
  static List<String> detectPerformanceIssues() {
    final issues = <String>[];
    final stats = PerformanceMeasurement.getAllPerformanceStats();
    
    for (final entry in stats.entries) {
      final operationName = entry.key;
      final stat = entry.value;
      final averageMs = stat['averageMs'] as int;
      final maxMs = stat['maxMs'] as int;
      
      // 平均実行時間が1秒を超える場合
      if (averageMs > 1000) {
        issues.add('$operationName の平均実行時間が長すぎます: ${averageMs}ms');
      }
      
      // 最大実行時間が5秒を超える場合
      if (maxMs > 5000) {
        issues.add('$operationName の最大実行時間が長すぎます: ${maxMs}ms');
      }
      
      // 実行回数が多すぎる場合
      final count = stat['count'] as int;
      if (count > 1000) {
        issues.add('$operationName の実行回数が多すぎます: $count回');
      }
    }
    
    return issues;
  }
  
  /// 最適化の提案
  static List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    final issues = detectPerformanceIssues();
    
    if (issues.isNotEmpty) {
      suggestions.add('以下のパフォーマンス問題を修正してください:');
      suggestions.addAll(issues);
    }
    
    // 一般的な最適化提案
    suggestions.add('LazyLoadingの実装を検討してください');
    suggestions.add('Isolate処理の活用を検討してください');
    suggestions.add('画像キャッシュの最適化を検討してください');
    suggestions.add('不要な再描画を避けるため、RepaintBoundaryを使用してください');
    
    return suggestions;
  }
}
