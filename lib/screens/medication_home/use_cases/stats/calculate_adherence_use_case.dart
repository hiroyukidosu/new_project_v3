// lib/screens/medication_home/use_cases/stats/calculate_adherence_use_case.dart

import '../../../../models/medication_memo.dart';
import '../../../../models/medication_info.dart';
import '../../../../core/result.dart';
import '../../../../utils/logger.dart';
import '../../../helpers/calculations/adherence_calculator.dart';

/// 遵守率を計算するUseCase
class CalculateAdherenceUseCase {
  /// 遵守率を計算（期間別）
  Future<Result<Map<String, double>>> execute({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> memos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, bool> medicationMemoStatus,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) async {
    try {
      final adherenceRates = AdherenceCalculator.calculatePeriodAdherence(
        days: days,
        medicationData: medicationData,
        medicationMemos: memos,
        weekdayMedicationStatus: weekdayMedicationStatus,
        medicationMemoStatus: medicationMemoStatus,
        getMedicationMemoCheckedCountForDate: getMedicationMemoCheckedCountForDate,
      );

      Logger.info('遵守率計算成功: ${adherenceRates.length}件');
      return Success(adherenceRates);
    } catch (e, stackTrace) {
      Logger.error('遵守率計算エラー', e, stackTrace);
      return Error('遵守率の計算に失敗しました: $e', e);
    }
  }
}

