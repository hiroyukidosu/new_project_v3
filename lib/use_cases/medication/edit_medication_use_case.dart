import '../../core/result.dart';
import '../../models/medication_memo.dart';
import '../../repositories/medication_repository.dart';
import '../../config/app_constants.dart';

/// メディケーション編集のUseCase
class EditMedicationUseCase {
  final MedicationRepository _repository;
  
  EditMedicationUseCase(this._repository);
  
  /// メディケーションを編集
  Future<Result<void>> execute(MedicationMemo memo) async {
    try {
      // バリデーション
      if (memo.name.trim().isEmpty) {
        return const Error('薬名を入力してください');
      }
      
      if (memo.name.length > AppConstants.maxMedicationNameLength) {
        return Error('薬名は${AppConstants.maxMedicationNameLength}文字以内で入力してください');
      }
      
      // 既存のメモを確認
      final existingMemos = await _repository.getMemos();
      if (!existingMemos.any((m) => m.id == memo.id)) {
        return const Error('編集対象のメモが見つかりません');
      }
      
      // 更新
      await _repository.saveMemo(memo);
      return const Success(null);
    } catch (e) {
      return Error('メディケーションの編集に失敗しました', e);
    }
  }
}

