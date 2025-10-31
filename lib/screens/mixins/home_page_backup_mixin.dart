// バックアップ/復元機能のMixin
// home_page.dartからバックアップ関連の機能を分離

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../models/medicine_data.dart';
import '../../models/medication_info.dart';
import '../../services/backup_utils.dart';
import '../../services/backup_history_service.dart';

/// バックアップ/復元機能のMixin
/// このmixinを使用するクラスは、必要な状態変数とメソッドを提供する必要があります
mixin HomePageBackupMixin<T extends StatefulWidget> on State<T> {
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

  // 操作後5分以内の手動復元機能
  Future<void> showManualRestoreDialog() async {
    if (!mounted) return;
    
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
  
  // 手動復元を実行
  Future<void> performManualRestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 操作スナップショット（直近保存時に常に更新）を参照
      final lastBackupKey = prefs.getString('last_snapshot_key');
      
      if (lastBackupKey != null) {
        debugPrint('🔄 手動復元を実行: $lastBackupKey');
        await restoreBackup(lastBackupKey);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 操作前の状態に復元しました'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 復元可能なスナップショットが見つかりません'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ 手動復元エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 復元エラー: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // バックアップ機能を実装
  Future<void> showBackupDialog() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.orange),
            SizedBox(width: 8),
            Text('バックアップ'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⏱ バックアップ間隔\n\n'
                  '・毎日深夜2:00（自動）- フルバックアップ\n'
                  '・手動保存（任意）- 任意タイミングで保存',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await createManualBackup();
                },
                icon: const Icon(Icons.save),
                label: const Text('手動バックアップを作成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await showBackupHistory();
                },
                icon: const Icon(Icons.history),
                label: const Text('保存履歴を見る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<bool>(
                future: hasUndoAvailable(),
                builder: (context, snapshot) {
                  final available = snapshot.data ?? false;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: available
                          ? () async {
                              Navigator.of(context).pop();
                              await undoLastChange();
                            }
                          : null,
                      icon: const Icon(Icons.undo),
                      label: const Text('1つ前の状態に復元'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: available ? Colors.teal : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final prefs = await SharedPreferences.getInstance();
                    // 最新フルバックアップを参照
                    final key = prefs.getString('last_full_backup_key');
                    if (key != null) {
                      await restoreBackup(key);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('フルバックアップが見つかりません'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.restore_page),
                  label: const Text('フルバックアップを復元（最新）'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            ),
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

  // 1つ前の状態に復元（最新スナップショットから）
  Future<void> undoLastChange() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSnapshotKey = prefs.getString('last_snapshot_key');
      if (lastSnapshotKey == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('復元できる履歴がありません'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await restoreBackup(lastSnapshotKey);
      // 復元に使用したスナップショットは削除（1回使い切り）
      await prefs.remove(lastSnapshotKey);
      await prefs.remove('last_snapshot_key');
      if (mounted) {
        setState(() {
          focusedDay = selectedDay ?? DateTime.now();
          // メモフィールドを再同期
          if (selectedDay != null) {
            final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
            // 直近の保存内容を反映
            SharedPreferences.getInstance().then((p) {
              final memo = p.getString('memo_$dateStr');
              setMemoControllerText(memo ?? '');
              setMemoTextNotifierValue(memo ?? '');
            });
          }
          // アラームタブの完全再構築
          setAlarmTabKey(UniqueKey());
          // カレンダー色の再同期
          setDayColorsNotifierValue(Map<String, Color>.from(dayColors));
        });
        // カレンダーと入力を再評価
        await updateMedicineInputsForSelectedDate();
        await loadMemoForSelectedDate();
        // 統計の再計算
        await calculateAdherenceStats();
        // 服用記録の表示を強制更新
        updateCalendarMarks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ 1つ前の状態に復元しました'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 復元エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('復元に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget buildBackupRecommendation(String timing, String content, String reason, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(timing, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(content, style: const TextStyle(fontSize: 12)),
          Text(reason, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
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
    
    // ローディング表示
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
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. バックアップデータを直接作成（型安全な変換）
      final backupData = await createSafeBackupData(backupName);
      
      // 2. JSONエンコード（エラーハンドリング付き）
      final jsonString = await safeJsonEncode(backupData);
      
      // 3. 暗号化（非同期）
      final encryptedData = await encryptDataAsync(jsonString);
      
      // 4. 保存（1回で完了）
      await prefs.setString(backupKey, encryptedData);
      
      // 5. 履歴更新
      await updateBackupHistory(backupName, backupKey);
      
      if (!mounted) return;
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('✓ バックアップ「$backupName」を作成しました'),
            backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      debugPrint('バックアップ作成エラー: $e');
      if (!mounted) return;
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('バックアップの作成に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 型安全なバックアップデータ作成
  Future<Map<String, dynamic>> createSafeBackupData(String backupName) async {
      return {
        'name': backupName,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'manual',
      'version': '1.0.0', // バージョン情報を追加
      
      // 服用メモ関連（JSON安全）
        'medicationMemos': medicationMemos.map((memo) => memo.toJson()).toList(),
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

  // 非同期データ復元（最適化版）
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
      
      // 2. 追加薬品の復元（Color変換）
      final restoredAddedMedications = (backupData['addedMedications'] as List? ?? [])
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
          .cast<Map<String, dynamic>>()
          .toList();
      
      // 3. 薬品データの復元
      final restoredMedicines = (backupData['medicines'] as List? ?? [])
          .map((json) => MedicineData.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // 4. 服用データの復元（JSON → MedicationInfo）
      final restoredMedicationData = <String, Map<String, MedicationInfo>>{};
      if (backupData['medicationData'] != null) {
        final medicationDataMap = backupData['medicationData'] as Map<String, dynamic>;
        for (final entry in medicationDataMap.entries) {
          final dateKey = entry.key;
          final dayData = entry.value as Map<String, dynamic>;
          final medicationInfoMap = <String, MedicationInfo>{};
          
          for (final medEntry in dayData.entries) {
            final medKey = medEntry.key;
            final medData = medEntry.value as Map<String, dynamic>;
            medicationInfoMap[medKey] = MedicationInfo.fromJson(medData);
          }
          
          restoredMedicationData[dateKey] = medicationInfoMap;
        }
      }
      
      // 5. チェック状態の復元
      final restoredWeekdayStatus = <String, Map<String, bool>>{};
      if (backupData['weekdayMedicationStatus'] != null) {
        final statusMap = backupData['weekdayMedicationStatus'] as Map<String, dynamic>;
        for (final entry in statusMap.entries) {
          restoredWeekdayStatus[entry.key] = Map<String, bool>.from(entry.value as Map);
        }
      }
      
      final restoredWeekdayDoseStatus = <String, Map<String, Map<int, bool>>>{};
      if (backupData['weekdayMedicationDoseStatus'] != null) {
        final doseStatusMap = backupData['weekdayMedicationDoseStatus'] as Map<String, dynamic>;
        for (final dateEntry in doseStatusMap.entries) {
          final dateKey = dateEntry.key;
          final memoStatusMap = dateEntry.value as Map<String, dynamic>;
          final memoStatus = <String, Map<int, bool>>{};
          
          for (final memoEntry in memoStatusMap.entries) {
            final memoId = memoEntry.key;
            final doseStatusMap = memoEntry.value as Map<String, dynamic>;
            final doseStatus = <int, bool>{};
            
            for (final doseEntry in doseStatusMap.entries) {
              final doseIndex = int.parse(doseEntry.key);
              doseStatus[doseIndex] = doseEntry.value as bool;
            }
            
            memoStatus[memoId] = doseStatus;
          }
          
          restoredWeekdayDoseStatus[dateKey] = memoStatus;
        }
      }
      
      final restoredMemoStatus = backupData['medicationMemoStatus'] != null
          ? Map<String, bool>.from(backupData['medicationMemoStatus'] as Map)
          : <String, bool>{};
      
      // 6. カレンダー色の復元（int → Color）
      final restoredDayColors = <String, Color>{};
      if (backupData['dayColors'] != null) {
        final colorsMap = backupData['dayColors'] as Map<String, dynamic>;
        for (final entry in colorsMap.entries) {
          restoredDayColors[entry.key] = Color(entry.value as int);
        }
      }
      
      // 7. アラームの復元
      final restoredAlarmList = (backupData['alarmList'] as List? ?? [])
          .map((alarm) => Map<String, dynamic>.from(alarm as Map))
          .toList();
      
      final restoredAlarmSettings = backupData['alarmSettings'] != null
          ? Map<String, dynamic>.from(backupData['alarmSettings'] as Map)
          : <String, dynamic>{};
      
      // 8. 統計データの復元
      final restoredAdherenceRates = backupData['adherenceRates'] != null
          ? Map<String, double>.from(backupData['adherenceRates'] as Map)
          : <String, double>{};
      
      // 9. アラームをSharedPreferencesに保存
      final prefs = await SharedPreferences.getInstance();
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
        
        // 曜日データ（型安全に復元）
        final dynamic selectedDaysRaw = alarm['selectedDays'];
        final List<bool> selectedDays = selectedDaysRaw is List
            ? List<bool>.from(selectedDaysRaw.map((e) => e == true))
            : <bool>[false, false, false, false, false, false, false];
        for (int j = 0; j < 7; j++) {
          await prefs.setBool('alarm_${i}_day_$j', j < selectedDays.length ? selectedDays[j] : false);
        }
      }
      
      // 10. 一括setState（1回のみ）
      if (!mounted) return;
      
      setState(() {
        setMedicationMemos(restoredMemos);
        setAddedMedications(restoredAddedMedications);
        setMedicines(restoredMedicines);
        setMedicationData(restoredMedicationData);
        setWeekdayMedicationStatus(restoredWeekdayStatus);
        setWeekdayMedicationDoseStatus(restoredWeekdayDoseStatus);
        setMedicationMemoStatus(restoredMemoStatus);
        setDayColors(restoredDayColors);
        setAlarmList(restoredAlarmList);
        setAlarmSettings(restoredAlarmSettings);
        setAdherenceRates(restoredAdherenceRates);
        
        // SimpleAlarmAppを完全に再構築
        setAlarmTabKey(UniqueKey());  // 新しいキーで強制再構築
      });
      
      // 11. データ保存（復元後）
      await saveAllData();
      
      debugPrint('アラーム復元完了（強制再構築）: ${restoredAlarmList.length}件');
      debugPrint('バックアップ復元完了: ${restoredMemos.length}件のメモ');
    } catch (e) {
      debugPrint('データ復元エラー: $e');
      rethrow;
    }
  }

  // バックアップ履歴の更新（サービスに移動）
  Future<void> updateBackupHistory(String backupName, String backupKey, {String type = 'manual'}) async {
    await BackupHistoryService.updateBackupHistory(backupName, backupKey, type: type);
  }

  // バックアップ履歴表示機能（強化版）
  Future<void> showBackupHistory() async {
    if (!mounted) return;
    
    final history = await BackupHistoryService.getBackupHistory();
    
    // 自動バックアップも含めて全てのバックアップを取得
    final allBackups = <Map<String, dynamic>>[];
    
    // 手動バックアップ履歴を追加
    for (final backup in history) {
      allBackups.add({
        ...backup,
        'type': 'manual',
        'source': '履歴',
      });
    }
    
    // 自動バックアップを追加
    final autoBackupKey = await BackupHistoryService.getLastAutoBackupKey();
    if (autoBackupKey != null) {
      allBackups.add({
        'name': '自動バックアップ（最新）',
        'key': autoBackupKey,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'auto',
        'source': '自動',
      });
    }
    
    if (allBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('バックアップがありません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.blue),
            SizedBox(width: 8),
            Text('バックアップ一覧'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: ListView.builder(
            itemCount: allBackups.length,
            itemBuilder: (context, index) {
              final backup = allBackups[allBackups.length - 1 - index]; // 新しい順に表示
              final createdAt = DateTime.parse(backup['createdAt'] as String);
              final isAuto = backup['type'] == 'auto';
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isAuto ? Icons.schedule : Icons.backup,
                    color: isAuto ? Colors.green : Colors.orange,
                  ),
                  title: Text(backup['name'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('yyyy-MM-dd HH:mm').format(createdAt)),
                      Text(
                        '${backup['source']}バックアップ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAuto ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'restore':
                          await restoreBackup(backup['key'] as String);
                          break;
                        case 'delete':
                          if (!isAuto) {
                            await deleteBackup(backup['key'] as String, index);
                          }
                          break;
                        case 'preview':
                          await previewBackup(backup['key'] as String);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restore, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('復元'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.green),
                            SizedBox(width: 8),
                            Text('プレビュー'),
                          ],
                        ),
                      ),
                      if (!isAuto) const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('削除'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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

  // バックアッププレビュー機能
  Future<void> previewBackup(String backupKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = prefs.getString(backupKey);
      
      if (encryptedData == null) {
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
      
      final decryptedData = await decryptDataAsync(encryptedData);
      final backupData = jsonDecode(decryptedData);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('バックアッププレビュー'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('名前: ${backupData['name'] as String}'),
                  Text('作成日時: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(backupData['createdAt']))}'),
                  const SizedBox(height: 8),
                  const Text('📊 バックアップ内容:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('・服用メモ数: ${(backupData['medicationMemos'] as List).length}件'),
                  Text('・追加薬品数: ${(backupData['addedMedications'] as List).length}件'),
                  Text('・薬品データ数: ${(backupData['medicines'] as List).length}件'),
                  Text('・アラーム数: ${(backupData['alarmList'] as List).length}件'),
                  Text('・カレンダー色設定: ${(backupData['dayColors'] as Map).length}日分'),
                  Text('・チェック状態: ${(backupData['weekdayMedicationStatus'] as Map).length}日分'),
                  Text('・服用率データ: ${(backupData['adherenceRates'] as Map).length}件'),
                  const SizedBox(height: 16),
                  const Text('このバックアップを復元しますか？'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  restoreBackup(backupKey);
                },
                child: const Text('復元する'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プレビューの表示に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // バックアップ復元機能（最適化版）
  Future<void> restoreBackup(String backupKey) async {
    // ローディング表示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('バックアップを復元中...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
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

  // 非同期でバックアップデータを読み込み
  Future<Map<String, dynamic>?> loadBackupDataAsync(String backupKey) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(backupKey);
    
    if (encryptedData == null) return null;
    
    // 非同期で復号化
    final decryptedData = await decryptDataAsync(encryptedData);
    return jsonDecode(decryptedData);
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
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップの削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

