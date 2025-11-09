// lib/utils/compute_helper.dart
// Isolateを使った重い計算処理のヘルパー

import 'package:flutter/foundation.dart';

/// Isolateを使った計算処理のヘルパークラス
class ComputeHelper {
  /// 重い計算処理をIsolateで実行
  static Future<T> computeTask<T>(
    ComputeCallback<dynamic, T> callback,
    dynamic message,
  ) async {
    return await compute(callback, message);
  }

  /// 日次ステータスの計算（Isolate使用）
  /// 使用例: final status = await ComputeHelper.computeDailyStatus(medications);
  static Future<List<DailyStatus>> computeDailyStatus(
    List<Map<String, dynamic>> medsData,
  ) async {
    return await compute(_calculateStatus, medsData);
  }

  /// ステータス計算の実装（Isolate内で実行）
  static List<DailyStatus> _calculateStatus(List<Map<String, dynamic>> medsData) {
    // 重い計算処理をここに実装
    // 例: 日次服用状況の集計など
    final now = DateTime.now();
    final results = <DailyStatus>[];
    
    // 過去30日分のステータスを計算
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      // 実際の計算ロジックを実装
      results.add(DailyStatus(
        date: date,
        totalMedications: medsData.length,
        takenMedications: 0, // 実際の計算が必要
        adherenceRate: 0.0, // 実際の計算が必要
      ));
    }
    
    return results;
  }
}

/// 日次ステータス（計算結果用）
class DailyStatus {
  final DateTime date;
  final int totalMedications;
  final int takenMedications;
  final double adherenceRate;

  DailyStatus({
    required this.date,
    required this.totalMedications,
    required this.takenMedications,
    required this.adherenceRate,
  });
}
