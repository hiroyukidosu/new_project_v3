import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';

/// 遵守率計算ヘルパー
class AdherenceCalculator {
  /// カスタム遵守率を計算
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
    final startDate = now.subtract(Duration(days: days));
    
    int totalDoses = 0;
    int takenDoses = 0;
    
    // 各日をループ
    for (int i = 0; i < days; i++) {
      final checkDate = startDate.add(Duration(days: i));
      final dateStr = _formatDate(checkDate);
      final weekday = checkDate.weekday % 7;
      
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
      
      // 服用メモの統計
      for (final memo in medicationMemos) {
        if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
          totalDoses += memo.dosageFrequency;
          
          // チェック済み回数を取得
          final checkedCount = getMedicationMemoCheckedCountForDate(memo.id, dateStr);
          takenDoses += checkedCount;
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
    final startDate = now.subtract(Duration(days: days));
    
    int totalDoses = 0;
    int takenDoses = 0;
    
    for (int i = 0; i < days; i++) {
      final checkDate = startDate.add(Duration(days: i));
      final weekday = checkDate.weekday % 7;
      
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

