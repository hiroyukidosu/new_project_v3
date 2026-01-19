import 'package:flutter/material.dart';
import 'advanced_lazy_loading.dart';
import 'image_optimization.dart';
import 'isolate_processing.dart';
import 'performance_measurement.dart';
import '../utils/logger.dart';

/// パフォーマンス改善の統合実装例
class PerformanceImprovementsIntegration {
  
  /// 最適化されたメディケーションリストの構築
  static Widget buildOptimizedMedicationList({
    required List<dynamic> medications,
    required Widget Function(BuildContext, dynamic, int) itemBuilder,
    bool enableLazyLoading = true,
    bool enableImageOptimization = true,
  }) {
    if (enableLazyLoading) {
      return AdvancedLazyLoading.buildVirtualizedListView(
        items: medications,
        itemBuilder: (context, medication, index) {
          return _buildOptimizedMedicationItem(
            context: context,
            medication: medication,
            index: index,
            enableImageOptimization: enableImageOptimization,
          );
        },
        height: 400,
        cacheExtent: 500,
      );
    } else {
      return ListView.builder(
        itemCount: medications.length,
        cacheExtent: 500,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: true,
        addSemanticIndexes: true,
        itemBuilder: (context, index) {
          return _buildOptimizedMedicationItem(
            context: context,
            medication: medications[index],
            index: index,
            enableImageOptimization: enableImageOptimization,
          );
        },
      );
    }
  }
  
  /// 最適化されたメディケーションアイテムの構築
  static Widget _buildOptimizedMedicationItem({
    required BuildContext context,
    required dynamic medication,
    required int index,
    required bool enableImageOptimization,
  }) {
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ListTile(
          leading: enableImageOptimization
              ? ImageOptimization.buildOptimizedListImage(
                  imagePath: 'assets/icon/icon.png',
                  size: 40,
                )
              : const Icon(Icons.medication),
          title: Text(
            medication['name'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            medication['dosage'] ?? 'No dosage',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMedicationOptions(context, medication),
          ),
        ),
      ),
    );
  }
  
  /// メディケーションオプションの表示
  static void _showMedicationOptions(BuildContext context, dynamic medication) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('編集'),
              onTap: () {
                Navigator.pop(context);
                // 編集処理
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('削除'),
              onTap: () {
                Navigator.pop(context);
                // 削除処理
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// 最適化された統計計算の実行
  static Future<Map<String, double>> calculateOptimizedStats(
    Map<String, dynamic> medicationData,
  ) async {
    return await PerformanceMeasurement.measureOperation(
      '統計計算',
      () => IsolateProcessing.calculateStatsIsolate(medicationData),
    );
  }
  
  /// 最適化されたデータ分析の実行
  static Future<Map<String, dynamic>> analyzeOptimizedData(
    List<Map<String, dynamic>> rawData,
  ) async {
    return await PerformanceMeasurement.measureOperation(
      'データ分析',
      () => IsolateProcessing.analyzeDataIsolate(rawData),
    );
  }
  
  /// 最適化された大量データ処理の実行
  static Future<List<Map<String, dynamic>>> processOptimizedLargeData(
    List<Map<String, dynamic>> data,
  ) async {
    return await PerformanceMeasurement.measureOperation(
      '大量データ処理',
      () => IsolateProcessing.processLargeDataIsolate(data),
    );
  }
  
  /// パフォーマンス監視の開始
  static void startPerformanceMonitoring() {
    PerformanceMeasurement.clearMeasurements();
    MemoryMonitor.startMonitoring();
    Logger.info('パフォーマンス監視を開始しました');
  }
  
  /// パフォーマンス監視の停止
  static void stopPerformanceMonitoring() {
    MemoryMonitor.stopMonitoring();
    Logger.info('パフォーマンス監視を停止しました');
  }
  
  /// パフォーマンスレポートの生成と表示
  static void showPerformanceReport(BuildContext context) {
    final report = PerformanceMeasurement.generatePerformanceReport();
    final memoryStats = MemoryMonitor.getMemoryStats();
    final issues = PerformanceOptimizer.detectPerformanceIssues();
    final suggestions = PerformanceOptimizer.getOptimizationSuggestions();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パフォーマンスレポート'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('実行時間統計:\n$report'),
              const SizedBox(height: 16),
              Text('メモリ使用量:\n${_formatMemoryStats(memoryStats)}'),
              if (issues.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('検出された問題:\n${issues.join('\n')}'),
              ],
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('最適化提案:\n${suggestions.join('\n')}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportPerformanceReport(report, memoryStats);
            },
            child: const Text('エクスポート'),
          ),
        ],
      ),
    );
  }
  
  /// メモリ統計のフォーマット
  static String _formatMemoryStats(Map<String, dynamic> memoryStats) {
    if (memoryStats.isEmpty) {
      return 'メモリ統計データがありません';
    }
    
    final heapSize = memoryStats['heapSize'] as Map<String, dynamic>?;
    final externalSize = memoryStats['externalSize'] as Map<String, dynamic>?;
    
    final buffer = StringBuffer();
    buffer.writeln('スナップショット数: ${memoryStats['snapshotCount']}');
    
    if (heapSize != null) {
      buffer.writeln('ヒープサイズ:');
      buffer.writeln('  現在: ${heapSize['current']}MB');
      buffer.writeln('  平均: ${heapSize['average']}MB');
      buffer.writeln('  最小: ${heapSize['min']}MB');
      buffer.writeln('  最大: ${heapSize['max']}MB');
    }
    
    if (externalSize != null) {
      buffer.writeln('外部サイズ:');
      buffer.writeln('  現在: ${externalSize['current']}MB');
      buffer.writeln('  平均: ${externalSize['average']}MB');
      buffer.writeln('  最小: ${externalSize['min']}MB');
      buffer.writeln('  最大: ${externalSize['max']}MB');
    }
    
    return buffer.toString();
  }
  
  /// パフォーマンスレポートのエクスポート
  static void _exportPerformanceReport(String report, Map<String, dynamic> memoryStats) {
    // 実際の実装では、ファイルに保存するか、共有機能を使用
    Logger.info('パフォーマンスレポートをエクスポートしました');
    Logger.info('レポート:\n$report');
    Logger.info('メモリ統計:\n${_formatMemoryStats(memoryStats)}');
  }
}

/// パフォーマンス最適化のベストプラクティス
class PerformanceBestPractices {
  
  /// 最適化されたListViewの構築
  static Widget buildOptimizedListView({
    required List<dynamic> items,
    required Widget Function(BuildContext, dynamic, int) itemBuilder,
    ScrollController? controller,
    bool enableLazyLoading = true,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: items.length,
      cacheExtent: 500,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
  
  /// 最適化されたGridViewの構築
  static Widget buildOptimizedGridView({
    required List<dynamic> items,
    required Widget Function(BuildContext, dynamic, int) itemBuilder,
    int crossAxisCount = 2,
    double childAspectRatio = 1.0,
  }) {
    return GridView.builder(
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      cacheExtent: 200,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
  
  /// 最適化された画像の表示
  static Widget buildOptimizedImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return ImageOptimization.buildOptimizedAssetImage(
      assetPath: imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
    );
  }
  
  /// 最適化されたアイコンの表示
  static Widget buildOptimizedIcon({
    required IconData icon,
    double? size,
    Color? color,
  }) {
    return ImageOptimization.buildOptimizedIcon(
      icon: icon,
      size: size,
      color: color,
    );
  }
}
