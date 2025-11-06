import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';
import 'package:flutter/foundation.dart';

/// 遵守率計算ヘルパー（完全再構築版 - 徹底的に作り直し）
/// カレンダーページのチェック100%を確実に反映する
class AdherenceCalculator {
  /// カスタム遵守率を計算（完全再構築版 - 過去から今日まで）
  /// weekdayMedicationDoseStatusから実際のチェック済み回数を確実に取得
  /// 重要: selectedWeekdaysは0=月曜日, 1=火曜日, ..., 6=日曜日
  /// DateTime.weekdayは1=月曜日, 2=火曜日, ..., 7=日曜日
  /// 変換: weekday - 1 で selectedWeekdays の形式に変換
  static double calculateCustomAdherence({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> medicationMemos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, bool> medicationMemoStatus,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) {
    if (days <= 0) return 0.0;
    
    final now = DateTime.now();
    // 今日の日付（時刻を0:00:00に正規化）
    final today = DateTime(now.year, now.month, now.day);
    // 開始日を計算（days日前から今日まで、今日を含む）
    // 例: days=1の場合、今日のみ。days=7の場合、6日前から今日まで（計7日）
    final startDate = today.subtract(Duration(days: days - 1));
    // 終了日は今日まで（未来の日付は含めない）
    final endDate = today;
    
    int totalDoses = 0;
    int takenDoses = 0;
    
    // 日付の事前計算（過去から今日まで）
    // startDateからendDateまで（両方を含む）の日付リストを生成
    final dateRange = endDate.difference(startDate).inDays + 1;
    final dates = List.generate(
      dateRange,
      (i) => startDate.add(Duration(days: i)),
    );
    
    // 各日をループ（過去から今日まで、未来は含めない）
    for (final checkDate in dates) {
      // 未来の日付はスキップ
      if (checkDate.isAfter(today)) continue;
      final dateStr = _formatDate(checkDate);
      // Dartのweekdayは1(月)～7(日)
      // selectedWeekdaysは0(月)～6(日)なので、weekday - 1で変換
      final weekday = checkDate.weekday - 1;
      
      // 動的薬リストの統計
      if (medicationData.containsKey(dateStr)) {
        final dayData = medicationData[dateStr]!;
        for (final info in dayData.values) {
          totalDoses++;
          if (info.checked) {
            takenDoses++;
          }
        }
      }
      
      // 服用メモの統計（重要：weekdayMedicationDoseStatusとweekdayMedicationStatusの両方を使用）
      for (final memo in medicationMemos) {
        // その日の曜日が選択されているか確認
        if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
          // その日の服用回数分をtotalDosesに追加
          totalDoses += memo.dosageFrequency;
          
          // 方法1: weekdayMedicationDoseStatusから個別のチェック回数を取得
          final checkedCount = getMedicationMemoCheckedCountForDate(memo.id, dateStr);
          
          if (checkedCount > 0) {
            // 個別チェック回数が取得できた場合
            takenDoses += checkedCount;
          } else {
            // 方法2: weekdayMedicationStatusで完全服用かどうかを確認（フォールバック）
            // カレンダーページで100%チェックされた場合のフラグを使用
            final isFullyTaken = weekdayMedicationStatus[dateStr]?[memo.id] ?? false;
            if (isFullyTaken) {
              // 完全服用の場合は服用回数分をカウント
              takenDoses += memo.dosageFrequency;
            }
          }
        }
      }
    }
    
    
    if (totalDoses == 0) return 0.0;
    return (takenDoses / totalDoses) * 100;
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
  
  /// 特定のメモの遵守率を計算
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
    // 今日の日付（時刻を0:00:00に正規化）
    final today = DateTime(now.year, now.month, now.day);
    // 開始日を計算（days日前から今日まで、今日を含む）
    final startDate = today.subtract(Duration(days: days - 1));
    
    int totalDoses = 0;
    int takenDoses = 0;
    
    // 日付の事前計算（パフォーマンス最適化）
    final dates = List.generate(
      days,
      (i) => startDate.add(Duration(days: i)),
    );
    
    for (final checkDate in dates) {
      // Dartのweekdayは1(月)～7(日)
      // selectedWeekdaysは0(月)～6(日)なので、weekday - 1で変換
      final weekday = checkDate.weekday - 1;
      
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
