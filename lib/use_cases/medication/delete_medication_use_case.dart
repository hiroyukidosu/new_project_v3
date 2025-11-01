import '../../core/result.dart';
import '../../repositories/medication_repository.dart';

/// メディケーション削除のUseCase
class DeleteMedicationUseCase {
  final MedicationRepository _repository;
  
  DeleteMedicationUseCase(this._repository);
  
  /// メディケーションを削除
  Future<Result<void>> execute(String id) async {
    try {
      // 既存のメモを確認
      final existingMemos = await _repository.getMemos();
      if (!existingMemos.any((m) => m.id == id)) {
        return const Error('削除対象のメモが見つかりません');
      }
      
      // 削除
      await _repository.deleteMemo(id);
      return const Success(null);
    } catch (e) {
      return Error('メディケーションの削除に失敗しました', e);
    }
  }
}

