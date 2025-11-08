// lib/screens/helpers/backup_operations.dart
// バックアップ関連の操作を集約

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';
import '../../models/medicine_data.dart';
import 'home_page_backup_helper.dart';
import '../home/persistence/snapshot_persistence.dart';
import '../home/handlers/backup_handler.dart';
import '../home/widgets/dialogs/backup_dialog.dart';
import '../home/widgets/dialogs/backup_history_dialog.dart';
import '../home/widgets/dialogs/backup_preview_dialog.dart';
import '../home/state/home_page_state_manager.dart';

/// バックアップ操作を管理するクラス
/// home_page.dartからバックアップ関連メソッドを移動
class BackupOperations {
  final BuildContext context;
  final HomePageStateManager? stateManager;
  final SnapshotPersistence snapshotPersistence;
  final BackupHandler backupHandler;
  final DateTime? lastOperationTime;
  final Function(UniqueKey) onAlarmTabKeyChanged;
  final Future<void> Function() onUpdateMedicineInputsForSelectedDate;
  final Future<void> Function() onLoadMemoForSelectedDate;
  final Future<void> Function() onCalculateAdherenceStats;
  final void Function() onUpdateCalendarMarks;
  final bool Function() onMountedCheck;

  BackupOperations({
    required this.context,
    required this.stateManager,
    required this.snapshotPersistence,
    required this.backupHandler,
    required this.lastOperationTime,
    required this.onAlarmTabKeyChanged,
    required this.onUpdateMedicineInputsForSelectedDate,
    required this.onLoadMemoForSelectedDate,
    required this.onCalculateAdherenceStats,
    required this.onUpdateCalendarMarks,
    required this.onMountedCheck,
  });

  /// バックアップダイアログを表示
  Future<void> showBackupDialog() async {
    if (!onMountedCheck()) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => BackupDialog(
        onCreate: () async => await createManualBackup(),
        onShowHistory: () async => await showBackupHistory(),
      ),
    );
    if (result != null && result.startsWith('restore:')) {
      final key = result.split(':')[1];
      await restoreBackup(key);
    }
  }

  /// 直前の変更が存在するか（スナップショット有無）
  Future<bool> hasUndoAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastKey = prefs.getString('last_snapshot_key');
      if (lastKey == null) {
        debugPrint('⚠️ last_snapshot_key が null');
        return false;
      }
      final data = prefs.getString(lastKey);
      final available = data != null;
      if (!available) {
        debugPrint('⚠️ スナップショット実体が見つかりません: $lastKey');
      }
      return available;
    } catch (e) {
      debugPrint('❌ スナップショット確認エラー: $e');
      return false;
    }
  }

  /// 変更前スナップショット保存
  Future<void> saveSnapshotBeforeChange(String operationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final snapshotData = await createSafeBackupData('変更前_$operationType');
      final jsonString = await safeJsonEncode(snapshotData);
      final encryptedData = await encryptDataAsync(jsonString);
      final snapshotKey = 'snapshot_before_$timestamp';
      final ok1 = await prefs.setString(snapshotKey, encryptedData);
      final ok2 = await prefs.setString('last_snapshot_key', snapshotKey);
      if (!(ok1 && ok2)) {
        debugPrint('⚠️ スナップショット保存フラグがfalse: $ok1, $ok2');
      }
      debugPrint('✅ 変更前スナップショット保存完了: $operationType (key: $snapshotKey)');
    } catch (e) {
      debugPrint('❌ スナップショット保存エラー: $e');
    }
  }

  /// 1つ前の状態に復元（最新スナップショットから）
  Future<void> undoLastChange() async {
    try {
      final snapshotData = await snapshotPersistence.restoreLastSnapshot();
      
      if (snapshotData == null) {
        if (onMountedCheck()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('復元できる履歴がありません'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // スナップショットからの復元
      final restored = await HomePageBackupHelper.restoreDataAsync(snapshotData);
      
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
      
      // データ復元
      final restoredMemos = restored['restoredMedicationMemos'] as List<MedicationMemo>? ?? [];
      final restoredAddedMeds = restored['restoredAddedMedications'] as List<Map<String, dynamic>>? ?? [];
      final restoredMedicationData = restored['restoredMedicationData'] as Map<String, Map<String, MedicationInfo>>? ?? {};
      final restoredWeekdayStatus = restored['restoredWeekdayMedicationStatus'] as Map<String, Map<String, bool>>? ?? {};
      final restoredDoseStatus = restored['restoredWeekdayMedicationDoseStatus'] as Map<String, Map<String, Map<int, bool>>>? ?? {};
      final restoredMemoStatus = restored['restoredMedicationMemoStatus'] as Map<String, bool>? ?? {};
      final restoredDayColorsRaw = restored['restoredDayColors'] as Map<String, dynamic>? ?? {};
      final restoredDayColors = restoredDayColorsRaw.map((key, value) => MapEntry(key, value is Color ? value : Color(value as int)));
      final restoredAdherenceRates = restored['restoredAdherenceRates'] as Map<String, double>? ?? {};
      
      if (onMountedCheck() && stateManager != null) {
        stateManager!.focusedDay = stateManager!.selectedDay ?? DateTime.now();
        stateManager!.medicationMemos = restoredMemos;
        stateManager!.addedMedications = restoredAddedMeds;
        stateManager!.medicationData = restoredMedicationData;
        stateManager!.weekdayMedicationStatus = restoredWeekdayStatus;
        stateManager!.weekdayMedicationDoseStatus = restoredDoseStatus;
        stateManager!.medicationMemoStatus = restoredMemoStatus;
        stateManager!.dayColors = restoredDayColors;
        stateManager!.adherenceRates = restoredAdherenceRates;
        
        // メモフィールドを再同期
        if (stateManager!.selectedDay != null) {
          final dateStr = DateFormat('yyyy-MM-dd').format(stateManager!.selectedDay!);
          SharedPreferences.getInstance().then((p) {
            final memo = p.getString('memo_$dateStr');
            stateManager!.memoController.text = memo ?? '';
            stateManager!.notifiers.memoTextNotifier.value = memo ?? '';
          });
        }
        stateManager!.notifiers.dayColorsNotifier.value = Map<String, Color>.from(stateManager!.dayColors);
        
        // アラームタブキーを更新
        onAlarmTabKeyChanged(UniqueKey());
        
        // データ復元コールバックを呼び出し
        backupHandler.onDataRestored(restored);
        
        // カレンダーと入力を再評価
        await onUpdateMedicineInputsForSelectedDate();
        await onLoadMemoForSelectedDate();
        // 統計の再計算
        await onCalculateAdherenceStats();
        // 服用記録の表示を強制更新
        onUpdateCalendarMarks();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ 1つ前の状態に復元しました'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 復元エラー: $e');
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('バックアップ復元エラー: restoreBackup');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
      if (onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('復元に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 手動バックアップ作成機能
  Future<void> createManualBackup() async {
    if (!onMountedCheck()) return;
    
    // 保存名入力ダイアログ
    final TextEditingController nameController = TextEditingController();
    final now = DateTime.now();
    nameController.text = '${DateFormat('yyyy-MM-dd_HH-mm').format(now)}_手動保存';
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バックアップ名を入力'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '例: 2024-01-15_14-30_手動保存',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await backupHandler.performBackup(result, context);
    }
  }

  /// 型安全なバックアップデータ作成
  Future<Map<String, dynamic>> createSafeBackupData(String backupName) async {
    return HomePageBackupHelper.createSafeBackupData(
      backupName: backupName,
      medicationMemos: stateManager?.medicationMemos ?? [],
      addedMedications: stateManager?.addedMedications ?? [],
      medicines: stateManager?.medicines ?? [],
      medicationData: stateManager?.medicationData ?? {},
      weekdayMedicationStatus: stateManager?.weekdayMedicationStatus ?? {},
      weekdayMedicationDoseStatus: stateManager?.weekdayMedicationDoseStatus ?? {},
      medicationMemoStatus: stateManager?.medicationMemoStatus ?? {},
      dayColors: stateManager?.dayColors ?? {},
      alarmList: stateManager?.alarmList ?? [],
      alarmSettings: stateManager?.alarmSettings ?? {},
      adherenceRates: stateManager?.adherenceRates ?? {},
    );
  }

  /// 安全なJSONエンコード（エラーハンドリング）
  Future<String> safeJsonEncode(Map<String, dynamic> data) async {
    return HomePageBackupHelper.safeJsonEncode(data);
  }

  /// 非同期暗号化
  Future<String> encryptDataAsync(String data) async {
    return HomePageBackupHelper.encryptDataAsync(data);
  }

  /// バックアップ履歴の更新
  Future<void> updateBackupHistory(String backupName, String backupKey, {String type = 'manual'}) async {
    await backupHandler.updateBackupHistory(backupName, backupKey, type: type);
  }

  /// バックアップ履歴表示機能
  Future<void> showBackupHistory() async {
    if (!onMountedCheck()) return;
    
    showDialog(
      context: context,
      builder: (context) => BackupHistoryDialog(
        onRestore: (backupKey) async {
          await restoreBackup(backupKey);
        },
        onDelete: (backupKey, index) async {
          await deleteBackup(backupKey, index);
        },
        onPreview: (backupKey) async {
          await previewBackup(backupKey);
        },
      ),
    );
  }

  /// バックアッププレビュー機能
  Future<void> previewBackup(String backupKey) async {
    if (!onMountedCheck()) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BackupPreviewDialog(
        backupKey: backupKey,
        onRestore: (key) async {
          await restoreBackup(key);
        },
      ),
    );
  }

  /// バックアップ復元機能
  Future<void> restoreBackup(String backupKey) async {
    await backupHandler.restoreBackup(backupKey, context);
  }

  /// バックアップ削除機能
  Future<void> deleteBackup(String backupKey, int index) async {
    await backupHandler.deleteBackup(backupKey, context);
  }

  /// 操作後5分以内の手動復元機能
  Future<void> showManualRestoreDialog() async {
    if (!onMountedCheck()) return;
    
    final now = DateTime.now();
    final canRestore = lastOperationTime != null && 
        now.difference(lastOperationTime!).inMinutes <= 5;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.blue),
            SizedBox(width: 8),
            Text('手動復元'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canRestore ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  canRestore 
                    ? '✅ 操作後5分以内です\n最後の操作から${now.difference(lastOperationTime!).inMinutes}分経過'
                    : '⚠️ 操作後5分を過ぎています\n最後の操作から${lastOperationTime != null ? now.difference(lastOperationTime!).inMinutes : 0}分経過',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              if (canRestore) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await performManualRestore();
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('操作前の状態に復元'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                const Text(
                  '操作後5分以内に復元ボタンを押してください',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 手動復元を実行
  Future<void> performManualRestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupKey = prefs.getString('last_snapshot_key');
      
      if (lastBackupKey != null) {
        debugPrint('🔄 手動復元を実行: $lastBackupKey');
        await restoreBackup(lastBackupKey);
        
        if (onMountedCheck()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 操作前の状態に復元しました'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 手動復元エラー: $e');
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('手動復元エラー: performManualRestore');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
      if (onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('復元に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 手動バックアップ作成
  Future<void> createManualBackup() async {
    if (!onMountedCheck()) return;
    
    try {
      final backupKey = await backupHandler.createBackup();
      if (onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ バックアップを作成しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 手動バックアップ作成エラー: $e');
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('手動バックアップ作成エラー: createManualBackup');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
      if (onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップ作成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

