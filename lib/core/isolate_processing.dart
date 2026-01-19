import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Isolate処理機能 - 重い計算を別スレッドで実行
class IsolateProcessing {
  /// 統計計算をIsolateで実行
  static Future<Map<String, double>> calculateStatsIsolate(
    Map<String, dynamic> medicationData,
  ) async {
    try {
      Logger.performance('統計計算開始（Isolate）');
      final startTime = DateTime.now();
      
      final result = await compute(_calculateAdherenceStats, medicationData);
      
      final duration = DateTime.now().difference(startTime);
      Logger.performance('統計計算完了（Isolate）: ${duration.inMilliseconds}ms');
      
      return result;
    } catch (e) {
      Logger.error('統計計算エラー（Isolate）', e);
      return {};
    }
  }
  
  /// データ分析をIsolateで実行
  static Future<Map<String, dynamic>> analyzeDataIsolate(
    List<Map<String, dynamic>> rawData,
  ) async {
    try {
      Logger.performance('データ分析開始（Isolate）');
      final startTime = DateTime.now();
      
      final result = await compute(_analyzeData, rawData);
      
      final duration = DateTime.now().difference(startTime);
      Logger.performance('データ分析完了（Isolate）: ${duration.inMilliseconds}ms');
      
      return result;
    } catch (e) {
      Logger.error('データ分析エラー（Isolate）', e);
      return {};
    }
  }
  
  /// 大量データの処理をIsolateで実行
  static Future<List<Map<String, dynamic>>> processLargeDataIsolate(
    List<Map<String, dynamic>> data,
  ) async {
    try {
      Logger.performance('大量データ処理開始（Isolate）');
      final startTime = DateTime.now();
      
      final result = await compute(_processLargeData, data);
      
      final duration = DateTime.now().difference(startTime);
      Logger.performance('大量データ処理完了（Isolate）: ${duration.inMilliseconds}ms');
      
      return result;
    } catch (e) {
      Logger.error('大量データ処理エラー（Isolate）', e);
      return [];
    }
  }
  
  /// カスタムIsolate処理
  static Future<T> runInIsolate<T>(
    T Function() computation,
    String operationName,
  ) async {
    try {
      Logger.performance('$operationName開始（Isolate）');
      final startTime = DateTime.now();
      
      final result = await compute((_) => computation(), null);
      
      final duration = DateTime.now().difference(startTime);
      Logger.performance('$operationName完了（Isolate）: ${duration.inMilliseconds}ms');
      
      return result;
    } catch (e) {
      Logger.error('$operationNameエラー（Isolate）', e);
      rethrow;
    }
  }
}

/// 統計計算関数（Isolate用）
Map<String, double> _calculateAdherenceStats(Map<String, dynamic> medicationData) {
  try {
    final stats = <String, double>{};
    
    // 服用率の計算
    final totalDays = medicationData['totalDays'] as int? ?? 1;
    final takenDays = medicationData['takenDays'] as int? ?? 0;
    stats['adherenceRate'] = (takenDays / totalDays) * 100;
    
    // 週間服用率の計算
    final weeklyData = medicationData['weeklyData'] as Map<String, dynamic>? ?? {};
    double weeklyTotal = 0;
    int weeklyCount = 0;
    
    for (final day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']) {
      final dayData = weeklyData[day] as Map<String, dynamic>?;
      if (dayData != null) {
        final dayTotal = dayData['total'] as int? ?? 0;
        final dayTaken = dayData['taken'] as int? ?? 0;
        if (dayTotal > 0) {
          weeklyTotal += (dayTaken / dayTotal) * 100;
          weeklyCount++;
        }
      }
    }
    
    stats['weeklyAdherenceRate'] = weeklyCount > 0 ? weeklyTotal / weeklyCount : 0;
    
    // 月間服用率の計算
    final monthlyData = medicationData['monthlyData'] as Map<String, dynamic>? ?? {};
    double monthlyTotal = 0;
    int monthlyCount = 0;
    
    for (final month in monthlyData.keys) {
      final monthData = monthlyData[month] as Map<String, dynamic>?;
      if (monthData != null) {
        final monthTotal = monthData['total'] as int? ?? 0;
        final monthTaken = monthData['taken'] as int? ?? 0;
        if (monthTotal > 0) {
          monthlyTotal += (monthTaken / monthTotal) * 100;
          monthlyCount++;
        }
      }
    }
    
    stats['monthlyAdherenceRate'] = monthlyCount > 0 ? monthlyTotal / monthlyCount : 0;
    
    // 平均服用時間の計算
    final timeData = medicationData['timeData'] as List<dynamic>? ?? [];
    if (timeData.isNotEmpty) {
      double totalMinutes = 0;
      for (final time in timeData) {
        final timeStr = time?.toString();
        if (timeStr != null && timeStr.isNotEmpty) {
          final parts = timeStr.split(':');
          if (parts.length == 2) {
            final hours = int.tryParse(parts[0]) ?? 0;
            final minutes = int.tryParse(parts[1]) ?? 0;
            totalMinutes += hours * 60 + minutes;
          }
        }
      }
      stats['averageTime'] = totalMinutes / timeData.length;
    }
    
    return stats;
  } catch (e) {
    Logger.error('統計計算エラー', e);
    return {};
  }
}

/// データ分析関数（Isolate用）
Map<String, dynamic> _analyzeData(List<Map<String, dynamic>> rawData) {
  try {
    final analysis = <String, dynamic>{};
    
    // データの基本統計
    analysis['totalRecords'] = rawData.length;
    
    // 日付範囲の分析
    if (rawData.isNotEmpty) {
      final dates = rawData.map((record) {
        final dateStr = record['date']?.toString();
        if (dateStr != null && dateStr.isNotEmpty) {
          return DateTime.tryParse(dateStr);
        }
        return null;
      }).where((date) => date != null).cast<DateTime>().toList();
      
      if (dates.isNotEmpty) {
        dates.sort();
        analysis['dateRange'] = {
          'start': dates.first.toIso8601String(),
          'end': dates.last.toIso8601String(),
          'days': dates.last.difference(dates.first).inDays + 1,
        };
      }
    }
    
    // 服用パターンの分析
    final patterns = <String, int>{};
    for (final record in rawData) {
      final pattern = record['pattern']?.toString();
      if (pattern != null && pattern.isNotEmpty) {
        patterns[pattern] = (patterns[pattern] ?? 0) + 1;
      }
    }
    analysis['patterns'] = patterns;
    
    // 時間帯の分析
    final timeSlots = <String, int>{};
    for (final record in rawData) {
      final time = record['time']?.toString();
      if (time != null && time.isNotEmpty) {
        final hour = int.tryParse(time.split(':')[0]) ?? 0;
        final slot = _getTimeSlot(hour);
        timeSlots[slot] = (timeSlots[slot] ?? 0) + 1;
      }
    }
    analysis['timeSlots'] = timeSlots;
    
    return analysis;
  } catch (e) {
    Logger.error('データ分析エラー', e);
    return {};
  }
}

/// 大量データ処理関数（Isolate用）
List<Map<String, dynamic>> _processLargeData(List<Map<String, dynamic>> data) {
  try {
    final processedData = <Map<String, dynamic>>[];
    
    for (final record in data) {
      // データの正規化
      final processedRecord = <String, dynamic>{};
      
      // 日付の正規化
      final dateStr = record['date']?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          processedRecord['date'] = date.toIso8601String();
          processedRecord['year'] = date.year;
          processedRecord['month'] = date.month;
          processedRecord['day'] = date.day;
          processedRecord['weekday'] = date.weekday;
        }
      }
      
      // 時間の正規化
      final timeStr = record['time']?.toString();
      if (timeStr != null && timeStr.isNotEmpty) {
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          final minutes = int.tryParse(parts[1]) ?? 0;
          processedRecord['time'] = timeStr;
          processedRecord['hour'] = hours;
          processedRecord['minute'] = minutes;
          processedRecord['timeSlot'] = _getTimeSlot(hours);
        }
      }
      
      // その他のフィールドをコピー
      for (final entry in record.entries) {
        if (!processedRecord.containsKey(entry.key)) {
          processedRecord[entry.key] = entry.value;
        }
      }
      
      processedData.add(processedRecord);
    }
    
    return processedData;
  } catch (e) {
    Logger.error('大量データ処理エラー', e);
    return [];
  }
}

/// 時間帯の取得
String _getTimeSlot(int hour) {
  if (hour >= 6 && hour < 12) return '朝';
  if (hour >= 12 && hour < 18) return '昼';
  if (hour >= 18 && hour < 22) return '夕方';
  return '夜';
}

/// Isolate処理の状態管理
class IsolateProcessingState {
  bool _isProcessing = false;
  String? _currentOperation;
  DateTime? _startTime;
  
  bool get isProcessing => _isProcessing;
  String? get currentOperation => _currentOperation;
  Duration? get processingTime => _startTime != null ? DateTime.now().difference(_startTime!) : null;
  
  void startProcessing(String operation) {
    _isProcessing = true;
    _currentOperation = operation;
    _startTime = DateTime.now();
    Logger.info('Isolate処理開始: $operation');
  }
  
  void stopProcessing() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      Logger.info('Isolate処理完了: $_currentOperation (${duration.inMilliseconds}ms)');
    }
    
    _isProcessing = false;
    _currentOperation = null;
    _startTime = null;
  }
  
  void reset() {
    _isProcessing = false;
    _currentOperation = null;
    _startTime = null;
  }
}
