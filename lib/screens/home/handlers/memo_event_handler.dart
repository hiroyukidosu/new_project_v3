// lib/screens/home/handlers/memo_event_handler.dart

import '../../../models/medication_memo.dart';
import '../persistence/medication_data_persistence.dart';
import '../business/pagination_manager.dart';
import '../../../utils/logger.dart';
import '../../../screens/helpers/home_page_utils_helper.dart';

/// メモイベントハンドラー
class MemoEventHandler {
  final MedicationDataPersistence persistence;
  final PaginationManager paginationManager;
  final Function(MedicationMemo) onMemoAdded;
  final Function(MedicationMemo) onMemoUpdated;
  final Function(String) onMemoDeleted;
  final Function(String) onShowSnackBar;
  final Future<void> Function(String) onSaveSnapshotBeforeChange;
  final Future<void> Function(MedicationMemo) saveMedicationMemo;

  MemoEventHandler({
    required this.persistence,
    required this.paginationManager,
    required this.onMemoAdded,
    required this.onMemoUpdated,
    required this.onMemoDeleted,
    required this.onShowSnackBar,
    required this.onSaveSnapshotBeforeChange,
    required this.saveMedicationMemo,
  });

  /// メモを追加
  Future<void> addMemo(
    MedicationMemo memo,
    List<MedicationMemo> medicationMemos,
    int maxMemos,
    Future<void> Function() saveAllData,
  ) async {
    try {
      // 制限チェック
      if (medicationMemos.length >= maxMemos) {
        onShowSnackBar('メモは最大$maxMemos件まで設定できます');
        return;
      }

      // 変更前スナップショット
      await onSaveSnapshotBeforeChange('メモ追加_${memo.name.isEmpty ? '無題' : memo.name}');

      // タイトルが空なら自動連番で補完
      MedicationMemo memoToSave = memo;
      final rawTitle = memo.name.trim();
      if (rawTitle.isEmpty) {
        final titles = medicationMemos.map((m) => m.name).toList();
        final autoTitle = HomePageUtilsHelper.generateDefaultTitle(titles);
        memoToSave = MedicationMemo(
          id: memo.id,
          name: autoTitle,
          type: memo.type,
          dosage: memo.dosage,
          notes: memo.notes,
          createdAt: memo.createdAt,
          lastTaken: memo.lastTaken,
          color: memo.color,
          selectedWeekdays: memo.selectedWeekdays,
          dosageFrequency: memo.dosageFrequency,
        );
      }

      // メモを保存
      await persistence.saveMedicationMemo(memoToSave);

      // コールバックで親に通知
      onMemoAdded(memoToSave);

      // データを保存
      await saveAllData();

      onShowSnackBar('服用メモを追加しました');
    } catch (e) {
      Logger.error('メモ追加エラー', e);
      onShowSnackBar('メモの追加に失敗しました: $e');
    }
  }

  /// メモを編集
  Future<void> editMemo(
    MedicationMemo originalMemo,
    MedicationMemo updatedMemo,
    List<MedicationMemo> medicationMemos,
    Future<void> Function() saveAllData,
  ) async {
    try {
      // 変更前スナップショット
      await onSaveSnapshotBeforeChange('メモ編集_${originalMemo.name.isEmpty ? '無題' : originalMemo.name}');

      // タイトルが空なら自動連番で補完
      MedicationMemo memoToSave = updatedMemo;
      final rawTitle = updatedMemo.name.trim();
      if (rawTitle.isEmpty) {
        final titles = medicationMemos.where((m) => m.id != originalMemo.id).map((m) => m.name).toList();
        final autoTitle = HomePageUtilsHelper.generateDefaultTitle(titles);
        memoToSave = MedicationMemo(
          id: updatedMemo.id,
          name: autoTitle,
          type: updatedMemo.type,
          dosage: updatedMemo.dosage,
          notes: updatedMemo.notes,
          createdAt: updatedMemo.createdAt,
          lastTaken: updatedMemo.lastTaken,
          color: updatedMemo.color,
          selectedWeekdays: updatedMemo.selectedWeekdays,
          dosageFrequency: updatedMemo.dosageFrequency,
        );
      }

      // メモを保存
      await persistence.saveMedicationMemo(memoToSave);

      // コールバックで親に通知
      onMemoUpdated(memoToSave);

      // データを保存
      await saveAllData();

      onShowSnackBar('服用メモを更新しました');
    } catch (e) {
      Logger.error('メモ編集エラー', e);
      onShowSnackBar('メモの更新に失敗しました: $e');
    }
  }

  /// メモを削除
  Future<void> deleteMemo(
    String memoId,
    MedicationMemo? targetMemo,
    List<MedicationMemo> medicationMemos,
    Future<void> Function(String) deleteMedicationMemoWithBackup,
    Future<void> Function() saveAllData,
  ) async {
    try {
      // 変更前スナップショット
      final memo = targetMemo ?? 
        medicationMemos.firstWhere(
          (m) => m.id == memoId,
          orElse: () => MedicationMemo(
            id: memoId,
            name: '無題',
            type: '薬品',
            createdAt: DateTime.now(),
          ),
        );
      await onSaveSnapshotBeforeChange('メモ削除_${memo.name}');

      // メモを削除
      await deleteMedicationMemoWithBackup(memoId);

      // コールバックで親に通知
      onMemoDeleted(memoId);

      // データを保存
      await saveAllData();

      onShowSnackBar('メモを削除しました');
    } catch (e) {
      Logger.error('メモ削除エラー', e);
      onShowSnackBar('削除に失敗しました: $e');
    }
  }

  /// メモを服用済みとしてマーク
  Future<void> markAsTaken(
    MedicationMemo memo,
    Function(MedicationMemo) onMemoUpdated,
  ) async {
    try {
      final updatedMemo = MedicationMemo(
        id: memo.id,
        name: memo.name,
        type: memo.type,
        dosage: memo.dosage,
        notes: memo.notes,
        createdAt: memo.createdAt,
        lastTaken: DateTime.now(),
        color: memo.color,
        selectedWeekdays: memo.selectedWeekdays,
        dosageFrequency: memo.dosageFrequency,
      );

      // メモを保存
      await saveMedicationMemo(updatedMemo);

      // コールバックで親に通知
      onMemoUpdated(updatedMemo);

      onShowSnackBar('${memo.name}の服用を記録しました');
    } catch (e) {
      Logger.error('服用記録エラー', e);
      onShowSnackBar('服用記録に失敗しました: $e');
    }
  }
}

