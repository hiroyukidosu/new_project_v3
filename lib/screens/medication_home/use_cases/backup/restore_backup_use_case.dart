// lib/screens/medication_home/use_cases/backup/restore_backup_use_case.dart

import '../../../../core/result.dart';
import '../../../../utils/logger.dart';
import '../../../repositories/backup_repository.dart';

/// バックアップを復元するUseCase
class RestoreBackupUseCase {
  final BackupRepository _repository;

  RestoreBackupUseCase(this._repository);

  /// バックアップを復元
  Future<Result<Map<String, dynamic>>> execute(String backupKey) async {
    try {
      // バックアップデータを読み込み
      final loadResult = await _repository.loadBackupData(backupKey);
      
      if (loadResult.isError) {
        return loadResult as Error<Map<String, dynamic>>;
      }

      final backupData = (loadResult as Success<Map<String, dynamic>?>).data;
      
      if (backupData == null) {
        return Error('バックアップデータが見つかりません');
      }

      // バックアップを復元
      final restoreResult = await _repository.restoreBackupData(backupData);
      
      if (restoreResult.isSuccess) {
        final restored = (restoreResult as Success<Map<String, dynamic>>).data;
        Logger.info('バックアップ復元成功: $backupKey');
        return Success(restored);
      } else {
        final error = restoreResult as Error<Map<String, dynamic>>;
        Logger.error('バックアップ復元失敗: ${error.message}');
        return Error(error.message, error.error);
      }
    } catch (e, stackTrace) {
      Logger.error('バックアップ復元エラー', e, stackTrace);
      return Error('バックアップの復元に失敗しました: $e', e);
    }
  }
}

