// lib/screens/home/handlers/backup_handler.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../../models/medication_memo.dart';
import '../../../../models/medication_info.dart';
import '../../../../models/medicine_data.dart';
import '../../../../services/backup_history_service.dart';
import '../../../../utils/logger.dart';
import '../../helpers/home_page_backup_helper.dart';

/// バックアップ操作を管理するハンドラー
class BackupHandler {
  final Function(Map<String, dynamic>) onDataRestored;
  final Function(String) onShowSnackBar;
  final bool Function() onMountedCheck;
  final Future<Map<String, dynamic>> Function(String) createBackupData;
  final Function(UniqueKey)? onAlarmTabKeyChanged;
  final Future<void> Function()? onUpdateMedicineInputsForSelectedDate;
  final Future<void> Function()? onLoadMemoForSelectedDate;
  final Future<void> Function()? onCalculateAdherenceStats;
  final void Function()? onUpdateCalendarMarks;

  BackupHandler({
    required this.onDataRestored,
    required this.onShowSnackBar,
    required this.onMountedCheck,
    required this.createBackupData,
    this.onAlarmTabKeyChanged,
    this.onUpdateMedicineInputsForSelectedDate,
    this.onLoadMemoForSelectedDate,
    this.onCalculateAdherenceStats,
    this.onUpdateCalendarMarks,
  });

  /// 手動バックアップを作成
  Future<void> createManualBackup(
    String backupName,
    BuildContext? context,
  ) async {
    if (!onMountedCheck()) return;

    // ローディング表示
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text('バックアップを作成中...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';

      final backupData = await HomePageBackupHelper.createSafeBackupData(
        backupName: backupName,
        medicationMemos: [],
        addedMedications: [],
        medicines: [],
        medicationData: {},
        weekdayMedicationStatus: {},
        weekdayMedicationDoseStatus: {},
        medicationMemoStatus: {},
        dayColors: {},
        alarmList: [],
        alarmSettings: {},
        adherenceRates: {},
      );

      final jsonString = await HomePageBackupHelper.safeJsonEncode(backupData);
      final encryptedData = await HomePageBackupHelper.encryptDataAsync(jsonString);

      // 保存
      await prefs.setString(backupKey, encryptedData);

      await HomePageBackupHelper.updateBackupHistory(backupName, backupKey);

      if (context != null && onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ バックアップ「$backupName」を作成しました'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.error('バックアップ作成エラー', e);
      if (context != null && onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップの作成に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// バックアップを実行（実際のデータを使用）
  Future<void> performBackup(
    String backupName,
    BuildContext? context,
  ) async {
    if (!onMountedCheck()) return;

    // ローディング表示
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text('バックアップを作成中...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';

      final backupData = await createBackupData(backupName);
      final jsonString = await HomePageBackupHelper.safeJsonEncode(backupData);
      final encryptedData = await HomePageBackupHelper.encryptDataAsync(jsonString);

      // 保存
      await prefs.setString(backupKey, encryptedData);

      await HomePageBackupHelper.updateBackupHistory(backupName, backupKey);

      if (context != null && onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ バックアップ「$backupName」を作成しました'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.error('バックアップ作成エラー', e);
      if (context != null && onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップの作成に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// バックアップを復元
  Future<void> restoreBackup(
    String backupKey,
    BuildContext? context,
  ) async {
    // ローディング表示
    if (context != null && onMountedCheck()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text('バックアップを復元中...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      // 非同期でバックアップデータを読み込み
      final backupData = await HomePageBackupHelper.loadBackupDataAsync(backupKey);

      if (backupData == null) {
        if (context != null && onMountedCheck()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('バックアップデータが見つかりません'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // データを復元（コールバックで親に通知）
      final restored = await HomePageBackupHelper.restoreDataAsync(backupData);

      // アラームをSharedPreferencesに保存
      final prefs = await SharedPreferences.getInstance();
      final restoredAlarmList = restored['restoredAlarmList'] as List<Map<String, dynamic>>;
      await prefs.setInt('alarm_count', restoredAlarmList.length);

      for (int i = 0; i < restoredAlarmList.length; i++) {
        final alarm = restoredAlarmList[i];
        await prefs.setString('alarm_${i}_name', alarm['name']?.toString() ?? 'アラーム');
        await prefs.setString('alarm_${i}_time', alarm['time']?.toString() ?? '00:00');
        await prefs.setString('alarm_${i}_repeat', alarm['repeat']?.toString() ?? '一度だけ');
        await prefs.setString('alarm_${i}_alarmType', alarm['alarmType']?.toString() ?? 'sound');
        await prefs.setBool('alarm_${i}_enabled', alarm['enabled'] as bool? ?? true);
        await prefs.setBool('alarm_${i}_isRepeatEnabled', alarm['isRepeatEnabled'] as bool? ?? false);
        await prefs.setInt('alarm_${i}_volume', alarm['volume'] as int? ?? 80);

        final dynamic selectedDaysRaw = alarm['selectedDays'];
        final List<bool> selectedDays = selectedDaysRaw is List
            ? List<bool>.from(selectedDaysRaw.map((e) => e == true))
            : <bool>[false, false, false, false, false, false, false];
        for (int j = 0; j < 7; j++) {
          await prefs.setBool('alarm_${i}_day_$j', j < selectedDays.length ? selectedDays[j] : false);
        }
      }

      // 親に復元データを通知（StateManagerに反映）
      await onDataRestored(restored);
      
      // 復元後のUI更新（コールバックが設定されている場合）
      if (onMountedCheck()) {
        // アラームタブキーを更新（再構築のため）
        onAlarmTabKeyChanged?.call(UniqueKey());
        
        // カレンダーと入力を再評価
        await onUpdateMedicineInputsForSelectedDate?.call();
        
        // メモを再読み込み
        await onLoadMemoForSelectedDate?.call();
        
        // 統計の再計算
        await onCalculateAdherenceStats?.call();
        
        // 服用記録の表示を強制更新
        onUpdateCalendarMarks?.call();
      }

      if (context != null && onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('バックアップを復元しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      Logger.info('バックアップ復元完了');
    } catch (e) {
      Logger.error('バックアップ復元エラー', e);
      if (context != null && onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップの復元に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// バックアップを削除
  Future<void> deleteBackup(
    String backupKey,
    BuildContext? context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // バックアップデータを削除
      await prefs.remove(backupKey);

      // 履歴から削除（サービスを使用）
      await BackupHistoryService.removeFromHistory(backupKey);

      if (context != null && onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('バックアップを削除しました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Logger.error('バックアップ削除エラー', e);
      if (context != null && onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップの削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// バックアップ履歴を更新
  Future<void> updateBackupHistory(
    String backupName,
    String backupKey, {
    String type = 'manual',
  }) async {
    await HomePageBackupHelper.updateBackupHistory(backupName, backupKey, type: type);
  }
}

