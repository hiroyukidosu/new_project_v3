// lib/screens/home/handlers/medication_event_handler.dart

import '../../../utils/logger.dart';
import '../../home/persistence/medication_data_persistence.dart';

/// メディケーション関連のイベントを処理するクラス
class MedicationEventHandler {
  final MedicationDataPersistence _persistence;
  final Function(String, bool) onStatusUpdate;
  final Function(String, int, bool) onDoseStatusUpdate;

  MedicationEventHandler({
    required MedicationDataPersistence persistence,
    required this.onStatusUpdate,
    required this.onDoseStatusUpdate,
  }) : _persistence = persistence;

  /// メディケーションメモのチェック状態を変更
  Future<void> onMedicationChecked(String memoId, bool isChecked) async {
    try {
      Logger.debug('メモチェック状態変更: $memoId = $isChecked');
      
      // 状態を更新
      onStatusUpdate(memoId, isChecked);
      
      // 永続化
      final status = <String, bool>{memoId: isChecked};
      await _persistence.saveMedicationMemoStatus(status);
    } catch (e) {
      Logger.error('メモチェック状態変更エラー', e);
    }
  }

  /// 服用回数のチェック状態を変更
  Future<void> onDosageChecked(
    String memoId, 
    int doseIndex, 
    bool isChecked, 
    String dateStr,
    Map<String, Map<String, Map<int, bool>>>? fullDoseStatus,
  ) async {
    try {
      Logger.debug('服用回数チェック状態変更: $memoId, 回数=$doseIndex, 日付=$dateStr');
      
      // 状態を更新
      onDoseStatusUpdate(memoId, doseIndex, isChecked);
      
      // 永続化（全体の状態を保存）
      if (fullDoseStatus != null) {
        // 全体の状態を保存（既存のデータとマージされる）
        await _persistence.saveMedicationDoseStatus(fullDoseStatus);
        Logger.debug('服用回数別ステータス保存完了（全体）: ${fullDoseStatus.length}件の日付');
      } else {
        // 全体の状態が提供されない場合は、単一の日付のみ保存
        final doseStatus = <String, Map<String, Map<int, bool>>>{
          dateStr: {
            memoId: {doseIndex: isChecked}
          }
        };
        await _persistence.saveMedicationDoseStatus(doseStatus);
        Logger.debug('服用回数別ステータス保存完了（単一日付）: $dateStr');
      }
    } catch (e) {
      Logger.error('服用回数チェック状態変更エラー', e);
    }
  }

  /// メモを追加
  Future<void> onMemoAdded(dynamic memo) async {
    try {
      Logger.debug('メモ追加: ${memo.toString()}');
      await _persistence.saveMedicationMemo(memo);
    } catch (e) {
      Logger.error('メモ追加エラー', e);
      rethrow;
    }
  }

  /// メモを削除
  Future<void> onMemoDeleted(String memoId) async {
    try {
      Logger.debug('メモ削除: $memoId');
      await _persistence.deleteMedicationMemo(memoId);
    } catch (e) {
      Logger.error('メモ削除エラー', e);
      rethrow;
    }
  }

  /// メモを更新
  Future<void> onMemoUpdated(dynamic memo) async {
    try {
      Logger.debug('メモ更新: ${memo.toString()}');
      await _persistence.saveMedicationMemo(memo);
    } catch (e) {
      Logger.error('メモ更新エラー', e);
      rethrow;
    }
  }
}

