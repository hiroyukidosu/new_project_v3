// lib/screens/medication_home/use_cases/stats/calculate_custom_adherence_use_case.dart

import '../../../../models/medication_memo.dart';
import '../../../../models/medication_info.dart';
import '../../../../core/result.dart';
import '../../../../utils/logger.dart';
import '../../../helpers/calculations/adherence_calculator.dart';

/// カスタム期間の遵守率を計算するUseCase
class CalculateCustomAdherenceUseCase {
  /// カスタム期間の遵守率を計算
  Future<Result<double>> execute({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> memos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, bool> medicationMemoStatus,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) async {
    try {
      if (days <= 0) {
        return Error('日数は1以上である必要があります');
      }

      final adherenceRate = AdherenceCalculator.calculateCustomAdherence(
        days: days,
        medicationData: medicationData,
        medicationMemos: memos,
        weekdayMedicationStatus: weekdayMedicationStatus,
        medicationMemoStatus: medicationMemoStatus,
        getMedicationMemoCheckedCountForDate: getMedicationMemoCheckedCountForDate,
      );

      Logger.info('カスタム遵守率計算成功: ${adherenceRate.toStringAsFixed(1)}% (${days}日間)');
      return Success(adherenceRate);
    } catch (e, stackTrace) {
      Logger.error('カスタム遵守率計算エラー', e, stackTrace);
      return Error('カスタム遵守率の計算に失敗しました: $e', e);
    }
  }
}

