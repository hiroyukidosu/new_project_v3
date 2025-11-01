// lib/screens/medication_home/use_cases/medication/mark_as_taken_use_case.dart

import '../../../../models/medication_memo.dart';
import '../../../../core/result.dart';
import '../../../../utils/logger.dart';
import '../../../repositories/medication_repository.dart';

/// 服用メモを「服用済み」としてマークするUseCase
class MarkAsTakenUseCase {
  final MedicationRepository _repository;

  MarkAsTakenUseCase(this._repository);

  /// メモを服用済みとしてマーク
  Future<Result<MedicationMemo>> execute({
    required MedicationMemo memo,
    required DateTime date,
    required Map<String, bool> currentStatus,
  }) async {
    try {
      // ステータスを更新
      final dateKey = date.toIso8601String().split('T')[0];
      final statusKey = '${memo.id}_$dateKey';
      
      final updatedStatus = Map<String, bool>.from(currentStatus);
      updatedStatus[statusKey] = true;

      // ステータスを保存
      final saveStatusResult = await _repository.saveMemoStatus(updatedStatus);
      
      if (saveStatusResult.isError) {
        final error = saveStatusResult as Error<void>;
        return Error(error.message, error.error);
      }

      // メモも保存（最新状態を保持）
      final saveMemoResult = await _repository.saveMemo(memo);
      
      if (saveMemoResult.isSuccess) {
        Logger.info('服用済みマーク成功: ${memo.name} (${dateKey})');
        return Success(memo);
      } else {
        final error = saveMemoResult as Error<void>;
        Logger.error('服用済みマーク失敗: ${error.message}');
        return Error(error.message, error.error);
      }
    } catch (e, stackTrace) {
      Logger.error('服用済みマークエラー', e, stackTrace);
      return Error('服用済みマークに失敗しました: $e', e);
    }
  }
}

