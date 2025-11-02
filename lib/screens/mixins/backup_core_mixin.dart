// lib/screens/mixins/backup_core_mixin.dart
// バックアップ/復元のコア機能（データ作成、暗号化、基本操作）

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../models/medicine_data.dart';
import '../../models/medication_info.dart';
import '../../services/backup_utils.dart';
import '../../services/backup_history_service.dart';

/// バックアップ/復元のコア機能のMixin
/// このmixinを使用するクラスは、必要な状態変数とメソッドを提供する必要があります
mixin BackupCoreMixin<T extends StatefulWidget> on State<T> {
  // 抽象ゲッター/セッター（実装クラスで提供する必要がある）
  DateTime? get selectedDay;
  DateTime? get focusedDay;
  DateTime? get lastOperationTime;
  List<MedicationMemo> get medicationMemos;
  List<Map<String, dynamic>> get addedMedications;
  List<MedicineData> get medicines;
  Map<String, Map<String, MedicationInfo>> get medicationData;
  Map<String, Map<String, bool>> get weekdayMedicationStatus;
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus;
  Map<String, bool> get medicationMemoStatus;
  Map<String, Color> get dayColors;
  List<Map<String, dynamic>> get alarmList;
  Map<String, dynamic> get alarmSettings;
  Map<String, double> get adherenceRates;
  TextEditingController get memoController;
  ValueNotifier<String> get memoTextNotifier;
  ValueNotifier<Map<String, Color>> get dayColorsNotifier;
  Key get alarmTabKey;
  
  set selectedDay(DateTime? value);
  set focusedDay(DateTime value);
  set lastOperationTime(DateTime? value);
  void setMedicationMemos(List<MedicationMemo> memos);
  void setAddedMedications(List<Map<String, dynamic>> medications);
  void setMedicines(List<MedicineData> medicinesList);
  void setMedicationData(Map<String, Map<String, MedicationInfo>> data);
  void setWeekdayMedicationStatus(Map<String, Map<String, bool>> status);
  void setWeekdayMedicationDoseStatus(Map<String, Map<String, Map<int, bool>>> status);
  void setMedicationMemoStatus(Map<String, bool> status);
  void setDayColors(Map<String, Color> colors);
  void setAlarmList(List<Map<String, dynamic>> alarms);
  void setAlarmSettings(Map<String, dynamic> settings);
  void setAdherenceRates(Map<String, double> rates);
  void setAlarmTabKey(Key key);
  void setDayColorsNotifierValue(Map<String, Color> value);
  void setMemoControllerText(String text);
  void setMemoTextNotifierValue(String value);
  
  // 抽象メソッド（実装クラスで提供する必要がある）
  Future<void> saveAllData();
  Future<void> saveDayColors();
  Future<void> updateMedicineInputsForSelectedDate();
  Future<void> loadMemoForSelectedDate();
  Future<void> calculateAdherenceStats();
  void updateCalendarMarks();

  // 直前の変更が存在するか（スナップショット有無）
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

  // 変更前スナップショット保存
  Future<void> saveSnapshotBeforeChange(String operationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshotKey = 'snapshot_${DateTime.now().millisecondsSinceEpoch}';
      final backupData = await createSafeBackupData('スナップショット_$operationType');
      final jsonStr = await safeJsonEncode(backupData);
      final encrypted = await encryptDataAsync(jsonStr);
      await prefs.setString(snapshotKey, encrypted);
      await prefs.setString('last_snapshot_key', snapshotKey);
      lastOperationTime = DateTime.now();
      debugPrint('✅ スナップショット保存: $snapshotKey');
    } catch (e) {
      debugPrint('❌ スナップショット保存エラー: $e');
    }
  }

  // 1つ前の状態に復元（最新スナップショットから）
  Future<void> undoLastChange() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastKey = prefs.getString('last_snapshot_key');
      if (lastKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('復元可能なスナップショットがありません'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final encryptedData = prefs.getString(lastKey);
      if (encryptedData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('スナップショットデータが見つかりません'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final decryptedData = await decryptDataAsync(encryptedData);
      final backupData = jsonDecode(decryptedData) as Map<String, dynamic>;
      
      await restoreDataAsync(backupData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('1つ前の状態に復元しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('復元エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 手動復元を実行
  Future<void> performManualRestore() async {
    await undoLastChange();
  }

  // 手動バックアップ作成機能
  Future<void> createManualBackup() async {
    if (!mounted) return;
    
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
      await performBackup(result);
    }
  }

  // 統合されたバックアップ作成メソッド（1回で完了）
  Future<void> performBackup(String backupName) async {
    if (!mounted) return;
    
    try {
      // バックアップデータ作成
      final backupData = await createSafeBackupData(backupName);
      
      // JSONエンコード
      final jsonStr = await safeJsonEncode(backupData);
      
      // 暗号化
      final encrypted = await encryptDataAsync(jsonStr);
      
      // SharedPreferencesに保存
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(backupKey, encrypted);
      
      // 履歴に追加
      await updateBackupHistory(backupName, backupKey);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップ「$backupName」を作成しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップ作成エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 型安全なバックアップデータ作成
  Future<Map<String, dynamic>> createSafeBackupData(String backupName) async {
    final now = DateTime.now();
    final dateStr = selectedDay != null 
        ? DateFormat('yyyy-MM-dd').format(selectedDay!) 
        : DateFormat('yyyy-MM-dd').format(now);
    
    return {
      'version': '2.0',
      'name': backupName,
      'createdAt': now.toIso8601String(),
      'selectedDay': dateStr,
      
      // 服用メモ（JSON安全）
      'medicationMemos': medicationMemos.map((memo) => memo.toJson()).toList(),
      
      // 動的薬リスト（プリミティブ型のみ）
      'addedMedications': addedMedications.map((med) => {
        'id': med['id'],
        'name': med['name'],
        'type': med['type'],
        'dosage': med['dosage'],
        'color': (med['color'] as Color).value, // Color → int
        'notes': med['notes'],
        'isChecked': med['isChecked'] ?? false,
        'takenTime': med['takenTime']?.toIso8601String(),
      }).toList(),
      
      // 薬品データ（JSON安全）
        'medicines': medicines.map((medicine) => medicine.toJson()).toList(),
      
      // 服用データ（MedicationInfo → JSON）
        'medicationData': medicationData.map((dateKey, dayData) {
        return MapEntry(
          dateKey,
          dayData.map((medKey, medInfo) {
            return MapEntry(medKey, medInfo.toJson());
          }),
        );
      }),
      
      // チェック状態関連（プリミティブ型のみ）
        'weekdayMedicationStatus': weekdayMedicationStatus,
      'weekdayMedicationDoseStatus': weekdayMedicationDoseStatus.map((dateKey, memoStatus) {
        return MapEntry(
          dateKey,
          memoStatus.map((memoId, doseStatus) {
            return MapEntry(
              memoId,
              doseStatus.map((doseIndex, isChecked) {
                return MapEntry(doseIndex.toString(), isChecked);
              }),
            );
          }),
        );
      }),
        'medicationMemoStatus': medicationMemoStatus,
      
      // カレンダー色（Color → int）
        'dayColors': dayColors.map((key, value) => MapEntry(key, value.value)),
      
      // アラーム関連（必要な全フィールドを保存）
      'alarmList': alarmList.map((alarm) => {
        'name': alarm['name']?.toString(),
        'time': alarm['time']?.toString(),
        'repeat': alarm['repeat']?.toString(),
        'enabled': (alarm['enabled'] as bool?) ?? true,
        'alarmType': alarm['alarmType']?.toString(),
        'volume': (alarm['volume'] is int)
            ? alarm['volume'] as int
            : int.tryParse(alarm['volume']?.toString() ?? '80') ?? 80,
        'message': alarm['message']?.toString(),
        'isRepeatEnabled': (alarm['isRepeatEnabled'] as bool?) ?? false,
        'selectedDays': (alarm['selectedDays'] is List)
            ? List<bool>.from((alarm['selectedDays'] as List).map((e) => e == true))
            : [false, false, false, false, false, false, false],
      }).toList(),
      'alarmSettings': Map<String, dynamic>.from(alarmSettings),
      
      // 統計データ
        'adherenceRates': adherenceRates,
      };
  }

  // 安全なJSONエンコード（エラーハンドリング）
  Future<String> safeJsonEncode(Map<String, dynamic> data) async {
    return BackupUtils.safeJsonEncode(data);
  }

  // 非同期暗号化
  Future<String> encryptDataAsync(String data) async {
    return BackupUtils.encryptData(data);
  }

  // 非同期復号化
  Future<String> decryptDataAsync(String encryptedData) async {
    return BackupUtils.decryptData(encryptedData);
  }

  // データ復号化機能
  String decryptData(String encryptedData) {
    return BackupUtils.decryptDataSync(encryptedData);
  }

  // バックアップ履歴の更新（サービスに移動）
  Future<void> updateBackupHistory(String backupName, String backupKey, {String type = 'manual'}) async {
    await BackupHistoryService.updateBackupHistory(backupName, backupKey, type: type);
  }

  // 非同期でバックアップデータを読み込み
  Future<Map<String, dynamic>?> loadBackupDataAsync(String backupKey) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(backupKey);
    
    if (encryptedData == null) return null;
    
    // 非同期で復号化
    final decryptedData = await decryptDataAsync(encryptedData);
    return jsonDecode(decryptedData) as Map<String, dynamic>;
  }

  // バックアップ削除機能
  Future<void> deleteBackup(String backupKey, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // バックアップデータを削除
      await prefs.remove(backupKey);
      
      // 履歴から削除（サービスを使用）
      await BackupHistoryService.removeFromHistory(backupKey);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('バックアップを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 非同期データ復元（最適化版）- 実装クラスで実装が必要
  Future<void> restoreDataAsync(Map<String, dynamic> backupData);
  
  // バックアップ復元機能 - 実装クラスで実装が必要
  Future<void> restoreBackup(String backupKey);
  
  // バックアップ履歴表示 - 実装クラスで実装が必要
  Future<void> showBackupHistory();
  
  // バックアッププレビュー - 実装クラスで実装が必要
  Future<void> previewBackup(String backupKey);
}

