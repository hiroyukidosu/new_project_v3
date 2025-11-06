// lib/screens/home/controllers/medication_controller.dart
// 服用メモ関連のビジネスロジックを管理

import 'package:flutter/material.dart';
import '../../../models/medication_memo.dart';
import '../../../widgets/memo_dialog.dart';
import '../state/home_page_state_manager.dart';
import '../persistence/snapshot_persistence.dart';

/// 服用メモコントローラー
/// メモの追加、編集、削除、服用済みマークなどの操作を管理
class MedicationController {
  final HomePageStateManager stateManager;
  final BuildContext context;
  final SnapshotPersistence snapshotPersistence;
  final VoidCallback onStateChanged;

  MedicationController({
    required this.stateManager,
    required this.context,
    required this.snapshotPersistence,
    required this.onStateChanged,
  });

  /// メモ追加
  Future<void> addMemo() async {
    if (!stateManager.isInitialized) {
      debugPrint('⚠️ StateManagerが初期化されていません。');
      return;
    }

    await snapshotPersistence.saveSnapshotBeforeChange(
      'メモ追加',
      () async => _createBackupData('メモ追加前'),
    );

    final memos = stateManager.medicationMemos;
    const maxMemos = 500; // メモ上限
    showDialog(
      context: context,
      builder: (context) => MemoDialog(
        existingMemos: memos,
        onMemoAdded: (memo) async {
          await stateManager.memoEventHandler.addMemo(
            memo,
            stateManager.medicationMemos,
            maxMemos,
            () async => await stateManager.saveAllData(),
          );
          onStateChanged();
        },
      ),
    );
  }

  /// メモ編集
  Future<void> editMemo(MedicationMemo memo) async {
    if (!stateManager.isInitialized) return;

    await snapshotPersistence.saveSnapshotBeforeChange(
      'メモ編集_${memo.name}',
      () async => _createBackupData('メモ編集前_${memo.name}'),
    );

    final memos = stateManager.medicationMemos;
    showDialog(
      context: context,
      builder: (context) => MemoDialog(
        initialMemo: memo,
        existingMemos: memos,
        onMemoAdded: (updatedMemo) async {
          await stateManager.memoEventHandler.editMemo(
            memo,
            updatedMemo,
            stateManager.medicationMemos,
            () async => await stateManager.saveAllData(),
          );
          onStateChanged();
        },
      ),
    );
  }

  /// メモ削除
  Future<void> deleteMemo(String id) async {
    if (!stateManager.isInitialized) return;

    final memos = stateManager.medicationMemos;
    final target = memos.firstWhere(
      (m) => m.id == id,
      orElse: () => MedicationMemo(
        id: id,
        name: '無題',
        type: '薬品',
        createdAt: DateTime.now(),
      ),
    );

    await snapshotPersistence.saveSnapshotBeforeChange(
      'メモ削除_${target.name}',
      () async => _createBackupData('メモ削除前_${target.name}'),
    );

    await stateManager.memoEventHandler.deleteMemo(
      id,
      target,
      memos,
      (memoId) async {
        // バックアップ付き削除処理
        await _deleteMedicationMemoWithBackup(memoId);
      },
      () async => await stateManager.saveAllData(),
    );

    // 関連する状態も削除
    stateManager.medicationMemoStatus.remove(id);
    for (final dateStr in stateManager.weekdayMedicationStatus.keys) {
      stateManager.weekdayMedicationStatus[dateStr]?.remove(id);
    }
    for (final dateStr in stateManager.weekdayMedicationDoseStatus.keys) {
      stateManager.weekdayMedicationDoseStatus[dateStr]?.remove(id);
    }
    onStateChanged();
  }

  /// 服用済みにマーク
  Future<void> markAsTaken(MedicationMemo memo) async {
    if (!stateManager.isInitialized) return;

    await stateManager.memoEventHandler.markAsTaken(
      memo,
      (updatedMemo) {
        final index = stateManager.medicationMemos.indexWhere((m) => m.id == memo.id);
        if (index != -1) {
          stateManager.medicationMemos[index] = updatedMemo;
        }
        stateManager.paginationManager.setAllMemos(stateManager.medicationMemos);
        onStateChanged();
      },
    );
  }

  /// バックアップデータ作成
  Future<Map<String, dynamic>> _createBackupData(String label) async {
    return {
      'medicationMemos': stateManager.medicationMemos.map((m) => m.toJson()).toList(),
      'medicationMemoStatus': stateManager.medicationMemoStatus,
      'weekdayMedicationStatus': stateManager.weekdayMedicationStatus,
      'weekdayMedicationDoseStatus': stateManager.weekdayMedicationDoseStatus,
      'label': label,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// バックアップ付きメモ削除
  Future<void> _deleteMedicationMemoWithBackup(String memoId) async {
    // 実装は既存のロジックに従う
    await stateManager.memoEventHandler.deleteMemo(
      memoId,
      stateManager.medicationMemos.firstWhere(
        (m) => m.id == memoId,
        orElse: () => MedicationMemo(
          id: memoId,
          name: '無題',
          type: '薬品',
          createdAt: DateTime.now(),
        ),
      ),
      stateManager.medicationMemos,
      (id) async {},
      () async => await stateManager.saveAllData(),
    );
  }
}

