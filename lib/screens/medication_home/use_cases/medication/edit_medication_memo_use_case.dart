// lib/screens/medication_home/use_cases/medication/edit_medication_memo_use_case.dart

import '../../../../models/medication_memo.dart';
import '../../../../core/result.dart';
import '../../../../utils/logger.dart';
import '../../../repositories/medication_repository.dart';
import '../../../../screens/helpers/home_page_utils_helper.dart';

/// 服用メモを編集するUseCase
class EditMedicationMemoUseCase {
  final MedicationRepository _repository;

  EditMedicationMemoUseCase(this._repository);

  /// メモを編集
  Future<Result<MedicationMemo>> execute({
    required MedicationMemo originalMemo,
    required MedicationMemo updatedMemo,
    required List<MedicationMemo> existingMemos,
  }) async {
    try {
      // タイトル自動生成（空の場合）
      String finalName = updatedMemo.name.trim();
      if (finalName.isEmpty) {
        final otherTitles = existingMemos
            .where((m) => m.id != originalMemo.id)
            .map((m) => m.name)
            .toList();
        finalName = HomePageUtilsHelper.generateDefaultTitle(otherTitles);
        Logger.debug('タイトル自動生成: $finalName');
      }

      // メモを更新
      final memoToSave = MedicationMemo(
        id: originalMemo.id,
        name: finalName,
        doses: updatedMemo.doses,
        weekdays: updatedMemo.weekdays,
        startDate: updatedMemo.startDate,
        endDate: updatedMemo.endDate,
        notes: updatedMemo.notes,
      );

      // 保存
      final saveResult = await _repository.saveMemo(memoToSave);
      
      if (saveResult.isSuccess) {
        return Success(memoToSave);
      } else {
        final error = saveResult as Error<void>;
        return Error(error.message, error.error);
      }
    } catch (e, stackTrace) {
      Logger.error('メモ編集エラー', e, stackTrace);
      return Error('メモの編集に失敗しました: $e', e);
    }
  }
}

