// lib/screens/medication_home/use_cases/medication/add_medication_memo_use_case.dart

import '../../../../models/medication_memo.dart';
import '../../../../core/result.dart';
import '../../../../utils/logger.dart';
import '../../../repositories/medication_repository.dart';
import '../../../../screens/helpers/home_page_utils_helper.dart';

/// 服用メモを追加するUseCase
class AddMedicationMemoUseCase {
  final MedicationRepository _repository;
  final int maxMemos;

  AddMedicationMemoUseCase(
    this._repository, {
    this.maxMemos = 500,
  });

  /// メモを追加
  Future<Result<MedicationMemo>> execute({
    required MedicationMemo memo,
    required List<MedicationMemo> existingMemos,
  }) async {
    try {
      // バリデーション：最大件数チェック
      if (existingMemos.length >= maxMemos) {
        Logger.warning('メモ追加エラー: 最大件数に達しています ($maxMemos件)');
        return Error(
          'メモは最大$maxMemos件まで設定できます',
        );
      }

      // タイトル自動生成（空の場合）
      String finalName = memo.name.trim();
      if (finalName.isEmpty) {
        final existingTitles = existingMemos.map((m) => m.name).toList();
        finalName = HomePageUtilsHelper.generateDefaultTitle(existingTitles);
        Logger.debug('タイトル自動生成: $finalName');
      }

      // メモを作成
      final memoToSave = MedicationMemo(
        id: memo.id,
        name: finalName,
        doses: memo.doses,
        weekdays: memo.weekdays,
        startDate: memo.startDate,
        endDate: memo.endDate,
        notes: memo.notes,
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
      Logger.error('メモ追加エラー', e, stackTrace);
      return Error('メモの追加に失敗しました: $e', e);
    }
  }
}

