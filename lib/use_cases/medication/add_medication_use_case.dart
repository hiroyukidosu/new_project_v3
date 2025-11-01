import '../../core/result.dart';
import '../../models/medication_memo.dart';
import '../../repositories/medication_repository.dart';
import '../../config/app_constants.dart';

/// メディケーション追加のUseCase
class AddMedicationUseCase {
  final MedicationRepository _repository;
  
  AddMedicationUseCase(this._repository);
  
  /// メディケーションを追加
  Future<Result<void>> execute(MedicationMemo memo) async {
    try {
      // バリデーション
      if (memo.name.trim().isEmpty) {
        return const Error('薬名を入力してください');
      }
      
      if (memo.name.length > AppConstants.maxMedicationNameLength) {
        return Error('薬名は${AppConstants.maxMedicationNameLength}文字以内で入力してください');
      }
      
      // メモリストの最大数チェック
      final existingMemos = await _repository.getMemos();
      if (existingMemos.length >= AppConstants.maxMemos) {
        return Error('メモの最大数（${AppConstants.maxMemos}件）に達しています');
      }
      
      // 保存
      await _repository.saveMemo(memo);
      return const Success(null);
    } catch (e) {
      return Error('メディケーションの追加に失敗しました', e);
    }
  }
}

