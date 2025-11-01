// lib/screens/medication_home/use_cases/medication/delete_medication_memo_use_case.dart

import '../../../../core/result.dart';
import '../../../../utils/logger.dart';
import '../../../repositories/medication_repository.dart';

/// 服用メモを削除するUseCase
class DeleteMedicationMemoUseCase {
  final MedicationRepository _repository;

  DeleteMedicationMemoUseCase(this._repository);

  /// メモを削除
  Future<Result<void>> execute(String memoId) async {
    try {
      final deleteResult = await _repository.deleteMemo(memoId);
      
      if (deleteResult.isSuccess) {
        Logger.info('メモ削除成功: $memoId');
        return const Success(null);
      } else {
        final error = deleteResult as Error<void>;
        Logger.error('メモ削除失敗: ${error.message}');
        return Error(error.message, error.error);
      }
    } catch (e, stackTrace) {
      Logger.error('メモ削除エラー', e, stackTrace);
      return Error('メモの削除に失敗しました: $e', e);
    }
  }
}

