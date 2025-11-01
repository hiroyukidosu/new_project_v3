import 'package:intl/intl.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';

/// メディケーション統計計算ヘルパー
class MedicationStatsCalculator {
  /// 日別の服用統計を計算
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
    
    return {
      'total': totalMedications,
      'taken': takenMedications,
    };
  }
  
  /// 選択された日の服用統計を計算
  static Map<String, int> calculateSelectedDayStats({
    required DateTime selectedDay,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> medicationMemos,
    required Map<String, bool> medicationMemoStatus,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
  }) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final weekday = selectedDay.weekday % 7;
    
    int totalCount = 0;
    int takenCount = 0;
    
    // 動的薬リストの統計
    if (medicationData.containsKey(dateStr)) {
      final dayData = medicationData[dateStr]!;
      totalCount += dayData.length;
      takenCount += dayData.values.where((info) => info.checked).length;
    }
    
    // 服用メモの統計
    for (final memo in medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalCount += memo.dosageFrequency;
        
        // 服用メモのステータスをチェック
        if (medicationMemoStatus[memo.id] == true) {
          takenCount += memo.dosageFrequency;
        } else if (weekdayMedicationStatus.containsKey(dateStr) &&
                   weekdayMedicationStatus[dateStr]!.containsKey(memo.id) &&
                   weekdayMedicationStatus[dateStr]![memo.id] == true) {
          takenCount += memo.dosageFrequency;
        }
      }
    }
    
    return {
      'total': totalCount,
      'taken': takenCount,
    };
  }
  
  /// 服用メモのチェック数を取得
  static int getMedicationMemoCheckedCount({
    required String memoId,
    required String dateStr,
    required Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus,
    required int dosageFrequency,
  }) {
    if (weekdayMedicationDoseStatus.containsKey(dateStr) &&
        weekdayMedicationDoseStatus[dateStr]!.containsKey(memoId)) {
      final doseStatus = weekdayMedicationDoseStatus[dateStr]![memoId]!;
      return doseStatus.values.where((checked) => checked).length;
    }
    return 0;
  }
}

