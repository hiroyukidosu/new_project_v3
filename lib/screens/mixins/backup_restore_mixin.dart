// lib/screens/mixins/backup_restore_mixin.dart
// バックアップ復元機能を分離

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../models/medicine_data.dart';
import '../../models/medication_info.dart';
import '../../services/backup_history_service.dart';
import 'backup_core_mixin.dart';

/// バックアップ復元機能のMixin
/// このmixinを使用するクラスは、BackupCoreMixinを実装する必要があります
mixin BackupRestoreMixin<T extends StatefulWidget> on State<T>, BackupCoreMixin<T> {
  @override
  Future<void> restoreDataAsync(Map<String, dynamic> backupData) async {
    try {
      // バージョンチェック
      final version = backupData['version'] as String?;
      if (version == null) {
        debugPrint('警告: バックアップバージョン情報がありません');
      }
      
      // 1. 服用メモの復元
      final restoredMemos = (backupData['medicationMemos'] as List? ?? [])
          .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
          .toList();
      setMedicationMemos(restoredMemos);
      
      // 2. 動的薬リストの復元
      final restoredAddedMeds = (backupData['addedMedications'] as List? ?? [])
          .map((med) => {
            'id': med['id'],
            'name': med['name'],
            'type': med['type'],
            'dosage': med['dosage'],
            'color': Color(med['color'] as int), // int → Color
            'notes': med['notes'],
            'isChecked': med['isChecked'] ?? false,
            'takenTime': med['takenTime'] != null 
                ? DateTime.parse(med['takenTime'] as String)
                : null,
          })
          .toList();
      setAddedMedications(restoredAddedMeds);
      
      // 3. 薬品データの復元
      final restoredMedicines = (backupData['medicines'] as List? ?? [])
          .map((json) => MedicineData.fromJson(json as Map<String, dynamic>))
          .toList();
      setMedicines(restoredMedicines);
      
      // 4. 服用データの復元（MedicationInfo）
      final restoredMedData = <String, Map<String, MedicationInfo>>{};
      final medData = backupData['medicationData'] as Map<String, dynamic>? ?? {};
      for (final entry in medData.entries) {
        restoredMedData[entry.key] = (entry.value as Map<String, dynamic>).map(
          (medKey, json) => MapEntry(medKey, MedicationInfo.fromJson(json)),
        );
      }
      setMedicationData(restoredMedData);
      
      // 5. チェック状態の復元
      setWeekdayMedicationStatus(
        Map<String, Map<String, bool>>.from(
          (backupData['weekdayMedicationStatus'] as Map? ?? {}).map(
            (key, value) => MapEntry(
              key.toString(),
              Map<String, bool>.from(value as Map),
            ),
          ),
        ),
      );
      
      // 6. 服用回数別チェック状態の復元
      final restoredDoseStatus = <String, Map<String, Map<int, bool>>>{};
      final doseStatus = backupData['weekdayMedicationDoseStatus'] as Map? ?? {};
      for (final dateEntry in doseStatus.entries) {
        final memoStatus = <String, Map<int, bool>>{};
        for (final memoEntry in (dateEntry.value as Map).entries) {
          final doseMap = <int, bool>{};
          for (final doseEntry in (memoEntry.value as Map).entries) {
            doseMap[int.parse(doseEntry.key.toString())] = doseEntry.value as bool;
          }
          memoStatus[memoEntry.key.toString()] = doseMap;
        }
        restoredDoseStatus[dateEntry.key.toString()] = memoStatus;
      }
      setWeekdayMedicationDoseStatus(restoredDoseStatus);
      
      // 7. メモ状態の復元
      setMedicationMemoStatus(
        Map<String, bool>.from(backupData['medicationMemoStatus'] as Map? ?? {}),
      );
      
      // 8. カレンダー色の復元
      final restoredDayColors = <String, Color>{};
      final dayColorsMap = backupData['dayColors'] as Map? ?? {};
      for (final entry in dayColorsMap.entries) {
        restoredDayColors[entry.key.toString()] = Color(entry.value as int);
      }
      setDayColors(restoredDayColors);
      setDayColorsNotifierValue(restoredDayColors);
      
      // 9. アラームリストの復元
      final restoredAlarmList = (backupData['alarmList'] as List? ?? [])
          .map((alarm) => Map<String, dynamic>.from(alarm as Map))
          .toList();
      setAlarmList(restoredAlarmList);
      setAlarmTabKey(UniqueKey()); // 強制再構築
      
      // 10. アラーム設定の復元
      setAlarmSettings(
        Map<String, dynamic>.from(backupData['alarmSettings'] as Map? ?? {}),
      );
      
      // 11. 統計データの復元
      setAdherenceRates(
        Map<String, double>.from(
          (backupData['adherenceRates'] as Map? ?? {}).map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          ),
        ),
      );
      
      // 12. メモコントローラーの復元
      final selectedDayStr = backupData['selectedDay'] as String?;
      if (selectedDayStr != null) {
        final day = DateTime.parse(selectedDayStr);
        selectedDay = day;
        focusedDay = day;
        setMemoControllerText('');
        setMemoTextNotifierValue('');
        await loadMemoForSelectedDate();
      }
      
      // 13. UI更新
      await updateMedicineInputsForSelectedDate();
      await calculateAdherenceStats();
      updateCalendarMarks();
      
      // 14. 全データ保存
      await saveAllData();
      await saveDayColors();
      
      debugPrint('アラーム復元完了（強制再構築）: ${restoredAlarmList.length}件');
      debugPrint('バックアップ復元完了: ${restoredMemos.length}件のメモ');
    } catch (e) {
      debugPrint('データ復元エラー: $e');
      rethrow;
    }
  }

  @override
  Future<void> restoreBackup(String backupKey) async {
    if (!mounted) return;
    
    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バックアップを復元'),
        content: const Text(
          '現在のデータは上書きされます。\n'
          '復元してもよろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('復元する'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      // 非同期でバックアップデータを読み込み
      final backupData = await loadBackupDataAsync(backupKey);
      
      if (backupData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('バックアップデータが見つかりません'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // 新しい最適化された復元処理を使用
      await restoreDataAsync(backupData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('バックアップを復元しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップの復元に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

