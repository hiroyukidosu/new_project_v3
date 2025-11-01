// lib/screens/home/business/medication_calculator.dart

import 'package:intl/intl.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';

/// メディケーション統計計算クラス
class MedicationCalculator {
  /// 選択された日の服用統計を計算
  static Map<String, int> calculateMedicationStats({
    required DateTime? selectedDay,
    required List<Map<String, dynamic>> addedMedications,
    required List<MedicationMemo> medicationMemos,
    required Map<String, bool> medicationMemoStatus,
    required Map<String, Map<String, MedicationInfo>> medicationData,
  }) {
    if (selectedDay == null) return {'total': 0, 'taken': 0};
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final weekday = selectedDay.weekday % 7;
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    totalMedications += addedMedications.length;
    takenMedications += addedMedications.where((med) => med['isChecked'] == true).length;
    
    // 動的薬データの統計
    if (medicationData.containsKey(dateStr)) {
      final dayData = medicationData[dateStr]!;
      totalMedications += dayData.length;
      takenMedications += dayData.values.where((info) => info.checked).length;
    }
    
    // 服用メモの統計
    for (final memo in medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications += memo.dosageFrequency;
        if (medicationMemoStatus[memo.id] == true) {
          takenMedications += memo.dosageFrequency;
        }
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  /// 日別の服用統計を計算（既存のMedicationStatsCalculatorと統合）
  static Map<String, int> calculateDayMedicationStats({
    required DateTime day,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> medicationMemos,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    if (medicationData.containsKey(dateStr)) {
      final dayData = medicationData[dateStr]!;
      totalMedications += dayData.length;
      takenMedications += dayData.values.where((info) => info.checked).length;
    }
    
    // 服用メモの統計
    for (final memo in medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications += memo.dosageFrequency;
        final checkedCount = getMedicationMemoCheckedCountForDate(memo.id, dateStr);
        takenMedications += checkedCount;
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  /// 遵守率を計算
  static double calculateAdherenceRate({
    required int total,
    required int taken,
  }) {
    if (total == 0) return 0.0;
    return (taken / total * 100).clamp(0.0, 100.0);
  }

  /// 遵守率の状態を判定（色やアイコンの決定に使用）
  static AdherenceStatus getAdherenceStatus(double rate) {
    if (rate >= 80) return AdherenceStatus.excellent;
    if (rate >= 60) return AdherenceStatus.good;
    if (rate >= 40) return AdherenceStatus.fair;
    return AdherenceStatus.poor;
  }
}

/// 遵守率の状態
enum AdherenceStatus {
  excellent, // 80%以上
  good,     // 60-79%
  fair,     // 40-59%
  poor,     // 40%未満
}

