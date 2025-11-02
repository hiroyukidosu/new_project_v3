// lib/screens/home/controllers/backup_controller.dart
// バックアップ関連のビジネスロジックを管理

import 'package:flutter/material.dart';
import '../state/home_page_state_manager.dart';
import '../handlers/backup_handler.dart';
import '../../../../services/backup_history_service.dart';

/// バックアップコントローラー
/// バックアップの作成、復元、履歴管理を処理
class BackupController {
  final HomePageStateManager stateManager;
  final BackupHandler backupHandler;
  final BuildContext context;
  final Function(String) showSnackBar;

  BackupController({
    required this.stateManager,
    required this.backupHandler,
    required this.context,
    required this.showSnackBar,
  });

  /// バックアップデータ作成
  Future<Map<String, dynamic>> createBackupData(String label) async {
    return {
      'medicationMemos': stateManager.medicationMemos.map((m) => m.toJson()).toList(),
      'medicationMemoStatus': stateManager.medicationMemoStatus,
      'weekdayMedicationStatus': stateManager.weekdayMedicationStatus,
      'weekdayMedicationDoseStatus': stateManager.weekdayMedicationDoseStatus,
      'addedMedications': stateManager.addedMedications,
      'dayColors': stateManager.dayColors.map((k, v) => MapEntry(k, v.value)),
      'adherenceRates': stateManager.adherenceRates,
      'label': label,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// バックアップ実行
  Future<void> createBackup(String label) async {
    try {
      final backupData = await createBackupData(label);
      await backupHandler.performBackup(label, context);
      showSnackBar('バックアップを作成しました');
    } catch (e) {
      debugPrint('バックアップ作成エラー: $e');
      showSnackBar('バックアップの作成に失敗しました');
    }
  }

  /// バックアップ復元
  Future<void> restoreBackup(String backupKey) async {
    try {
      await backupHandler.restoreBackup(backupKey, context);
      showSnackBar('バックアップを復元しました');
    } catch (e) {
      debugPrint('バックアップ復元エラー: $e');
      showSnackBar('バックアップの復元に失敗しました');
    }
  }

  /// バックアップ履歴取得
  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    return await BackupHistoryService.getBackupHistory();
  }
}

