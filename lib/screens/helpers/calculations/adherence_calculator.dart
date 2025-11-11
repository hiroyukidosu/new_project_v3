import 'package:flutter/foundation.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';

/// 遵守率計算ヘルパー
class AdherenceCalculator {
  /// カスタム遵守率を計算（改善版：服用状況を確実に反映）
  static double calculateCustomAdherence({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> medicationMemos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, bool> medicationMemoStatus,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) {
    try {
      if (days <= 0 || days > 365) return 0.0;
      
      // 今日の日付を取得（時刻を0時に設定）
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      // 今日を含む過去days日間を計算
      // 例: days=7の場合、7日前から今日まで（合計7日間）
      final startDate = todayDate.subtract(Duration(days: days - 1));
      
      int totalDoses = 0;
      int takenDoses = 0;
      
      if (kDebugMode) {
        debugPrint('🔄 遵守率計算開始: ${days}日間、開始日: ${_formatDate(startDate)}, 終了日: ${_formatDate(todayDate)}');
      }
      
      // 各日をループ
      for (int i = 0; i < days; i++) {
        try {
          final checkDate = startDate.add(Duration(days: i));
          final dateStr = _formatDate(checkDate);
          // 重要: DateTime.weekdayは1=月曜日, 2=火曜日, ..., 7=日曜日
          // selectedWeekdaysは0=月曜日, 1=火曜日, ..., 6=日曜日
          // 変換: (weekday - 1) % 7 で 0-6 の範囲に変換
          final weekday = (checkDate.weekday - 1) % 7;
          
          // 動的薬リストの統計
          if (medicationData.containsKey(dateStr)) {
            final dayData = medicationData[dateStr];
            if (dayData != null) {
              for (final info in dayData.values) {
                if (info != null && info.medicine.isNotEmpty) {
                  totalDoses++;
                  if (info.checked) {
                    takenDoses++;
                  }
                }
              }
            }
          }
          
          // 服用メモの統計（重要: weekdayMedicationDoseStatusから直接取得）
          for (final memo in medicationMemos) {
            if (memo != null && 
                memo.selectedWeekdays.isNotEmpty && 
                memo.selectedWeekdays.contains(weekday)) {
              final frequency = memo.dosageFrequency;
              if (frequency > 0) {
                // 総服用回数に加算
                totalDoses += frequency;
                
                // チェック済み回数を取得（weekdayMedicationDoseStatusから）
                try {
                  final checkedCount = getMedicationMemoCheckedCountForDate(memo.id, dateStr);
                  // チェック済み回数が0以上、frequency以下であることを確認
                  if (checkedCount >= 0 && checkedCount <= frequency) {
                    takenDoses += checkedCount;
                    // デバッグモードのみ詳細ログを出力
                    if (kDebugMode && checkedCount > 0) {
                      if (checkedCount == frequency) {
                        debugPrint('  ✅ 日付: $dateStr, メモ: ${memo.name}, 100%チェック済み: $checkedCount/$frequency');
                      } else {
                        debugPrint('  ⚠️ 日付: $dateStr, メモ: ${memo.name}, 部分チェック: $checkedCount/$frequency');
                      }
                    }
                  } else {
                    // エラーは常にログに出力
                    if (kDebugMode) {
                      debugPrint('  ❌ 日付: $dateStr, メモ: ${memo.name}, チェック済み回数が範囲外: $checkedCount (最大: $frequency)');
                    }
                  }
                } catch (e) {
                  // エラーは常にログに出力
                  if (kDebugMode) {
                    debugPrint('  ❌ 日付: $dateStr, メモ: ${memo.name}, エラー: $e');
                  }
                }
              }
            }
          }
        } catch (e) {
          // エラーは常にログに出力
          if (kDebugMode) {
            debugPrint('  ❌ 日付ループエラー: $e');
          }
          // 日付ループ内のエラーは無視して続行
          continue;
        }
      }
      
      if (totalDoses == 0) {
        if (kDebugMode) {
          debugPrint('⚠️ 遵守率計算: 総服用回数が0のため、0%を返します');
        }
        return 0.0;
      }
      
      final rate = (takenDoses / totalDoses) * 100;
      final clampedRate = rate.clamp(0.0, 100.0);
      
      if (kDebugMode) {
        debugPrint('📊 遵守率計算結果: 総回数=$totalDoses, 服用済み=$takenDoses, 遵守率=${clampedRate.toStringAsFixed(2)}%');
      }
      
      return clampedRate;
    } catch (e, stackTrace) {
      // エラーは常にログに出力（本番環境でも重要）
      if (kDebugMode) {
        debugPrint('❌ 遵守率計算エラー: $e');
        debugPrint('スタックトレース: $stackTrace');
      }
      // エラー時は0を返す
      return 0.0;
    }
  }
  
  /// 日付を文字列にフォーマット
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 期間別の遵守率を計算
  static Map<String, double> calculatePeriodAdherence({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> medicationMemos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, bool> medicationMemoStatus,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) {
    final adherenceRates = <String, double>{};
    
    for (final memo in medicationMemos) {
      final rate = calculateMemoAdherence(
        memo: memo,
        days: days,
        medicationData: medicationData,
        weekdayMedicationStatus: weekdayMedicationStatus,
        medicationMemoStatus: medicationMemoStatus,
        getMedicationMemoCheckedCountForDate: getMedicationMemoCheckedCountForDate,
      );
      adherenceRates[memo.name] = rate;
    }
    
    return adherenceRates;
  }
  
  /// 特定のメモの遵守率を計算（改善版）
  static double calculateMemoAdherence({
    required MedicationMemo memo,
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, bool> medicationMemoStatus,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) {
    if (days <= 0 || memo.selectedWeekdays.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    
    int totalDoses = 0;
    int takenDoses = 0;
    
    for (int i = 0; i < days; i++) {
      final checkDate = startDate.add(Duration(days: i));
      // 重要: DateTime.weekdayは1=月曜日, 2=火曜日, ..., 7=日曜日
      // selectedWeekdaysは0=月曜日, 1=火曜日, ..., 6=日曜日
      // 変換: (weekday - 1) % 7 で 0-6 の範囲に変換
      final weekday = (checkDate.weekday - 1) % 7;
      
      if (memo.selectedWeekdays.contains(weekday)) {
        totalDoses += memo.dosageFrequency;
        final dateStr = _formatDate(checkDate);
        final checkedCount = getMedicationMemoCheckedCountForDate(memo.id, dateStr);
        takenDoses += checkedCount;
      }
    }
    
    if (totalDoses == 0) return 0.0;
    return (takenDoses / totalDoses) * 100;
  }
  
  /// 日付を文字列にフォーマット（外部アクセス用）
  static String formatDate(DateTime date) {
    return _formatDate(date);
  }
}

