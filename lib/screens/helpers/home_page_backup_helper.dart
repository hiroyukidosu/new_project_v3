// バックアップ関連ヘルパー
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../models/medication_memo.dart';
import '../../models/medicine_data.dart';
import '../../models/medication_info.dart';
import '../../services/backup_utils.dart';
import '../../services/backup_history_service.dart';

class HomePageBackupHelper {
  static Future<Map<String, dynamic>> createSafeBackupData({
    required String backupName,
    required List<MedicationMemo> medicationMemos,
    required List<Map<String, dynamic>> addedMedications,
    required List<MedicineData> medicines,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus,
    required Map<String, bool> medicationMemoStatus,
    required Map<String, Color> dayColors,
    required List<Map<String, dynamic>> alarmList,
    required Map<String, dynamic> alarmSettings,
    required Map<String, double> adherenceRates,
  }) async {
    return {
      'name': backupName,
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'manual',
      'version': '1.0.0',
      'medicationMemos': medicationMemos.map((memo) => memo.toJson()).toList(),
      'addedMedications': addedMedications.map((med) => {
        'id': med['id'],
        'name': med['name'],
        'type': med['type'],
        'dosage': med['dosage'],
        'color': (med['color'] as Color).value,
        'notes': med['notes'],
        'isChecked': med['isChecked'] ?? false,
        'takenTime': med['takenTime']?.toIso8601String(),
      }).toList(),
      'medicines': medicines.map((medicine) => medicine.toJson()).toList(),
      'medicationData': medicationData.map((dateKey, dayData) {
        return MapEntry(
          dateKey,
          dayData.map((medKey, medInfo) {
            return MapEntry(medKey, medInfo.toJson());
          }),
        );
      }),
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
      'dayColors': dayColors.map((key, value) => MapEntry(key, value.value)),
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
      'adherenceRates': adherenceRates,
    };
  }

  static Future<String> safeJsonEncode(Map<String, dynamic> data) async {
    return BackupUtils.safeJsonEncode(data);
  }

  static Future<String> encryptDataAsync(String data) async {
    return BackupUtils.encryptData(data);
  }

  static Future<String> decryptDataAsync(String encryptedData) async {
    return BackupUtils.decryptData(encryptedData);
  }

  static String decryptData(String encryptedData) {
    return BackupUtils.decryptDataSync(encryptedData);
  }

  static Future<void> updateBackupHistory(String backupName, String backupKey, {String type = 'manual'}) async {
    await BackupHistoryService.updateBackupHistory(backupName, backupKey, type: type);
  }

  static Future<Map<String, dynamic>?> loadBackupDataAsync(String backupKey) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(backupKey);
    if (encryptedData == null) return null;
    final decryptedData = await decryptDataAsync(encryptedData);
    return jsonDecode(decryptedData);
  }

  static Future<Map<String, dynamic>> restoreDataAsync(Map<String, dynamic> backupData) async {
    // バージョンチェック
    final version = backupData['version'] as String?;
    if (version == null) {
      debugPrint('警告: バックアップバージョン情報がありません');
    }
    
    return {
      'restoredMemos': (backupData['medicationMemos'] as List? ?? [])
          .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
          .toList(),
      'restoredAddedMedications': (backupData['addedMedications'] as List? ?? [])
          .map((med) => {
            'id': med['id'],
            'name': med['name'],
            'type': med['type'],
            'dosage': med['dosage'],
            'color': Color(med['color'] as int),
            'notes': med['notes'],
            'isChecked': med['isChecked'] ?? false,
            'takenTime': med['takenTime'] != null 
                ? DateTime.parse(med['takenTime'] as String)
                : null,
          })
          .cast<Map<String, dynamic>>()
          .toList(),
      'restoredMedicines': (backupData['medicines'] as List? ?? [])
          .map((json) => MedicineData.fromJson(json as Map<String, dynamic>))
          .toList(),
      'restoredMedicationData': _restoreMedicationData(backupData),
      'restoredWeekdayStatus': _restoreWeekdayStatus(backupData),
      'restoredWeekdayDoseStatus': _restoreWeekdayDoseStatus(backupData),
      'restoredMemoStatus': backupData['medicationMemoStatus'] != null
          ? Map<String, bool>.from(backupData['medicationMemoStatus'] as Map)
          : <String, bool>{},
      'restoredDayColors': _restoreDayColors(backupData),
      'restoredAlarmList': (backupData['alarmList'] as List? ?? [])
          .map((alarm) => Map<String, dynamic>.from(alarm as Map))
          .toList(),
      'restoredAlarmSettings': backupData['alarmSettings'] != null
          ? Map<String, dynamic>.from(backupData['alarmSettings'] as Map)
          : <String, dynamic>{},
      'restoredAdherenceRates': backupData['adherenceRates'] != null
          ? Map<String, double>.from(backupData['adherenceRates'] as Map)
          : <String, double>{},
    };
  }

  static Map<String, Map<String, MedicationInfo>> _restoreMedicationData(Map<String, dynamic> backupData) {
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
    return restoredMedicationData;
  }

  static Map<String, Map<String, bool>> _restoreWeekdayStatus(Map<String, dynamic> backupData) {
    final restoredWeekdayStatus = <String, Map<String, bool>>{};
    if (backupData['weekdayMedicationStatus'] != null) {
      final statusMap = backupData['weekdayMedicationStatus'] as Map<String, dynamic>;
      for (final entry in statusMap.entries) {
        restoredWeekdayStatus[entry.key] = Map<String, bool>.from(entry.value as Map);
      }
    }
    return restoredWeekdayStatus;
  }

  static Map<String, Map<String, Map<int, bool>>> _restoreWeekdayDoseStatus(Map<String, dynamic> backupData) {
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
    return restoredWeekdayDoseStatus;
  }

  static Map<String, Color> _restoreDayColors(Map<String, dynamic> backupData) {
    final restoredDayColors = <String, Color>{};
    if (backupData['dayColors'] != null) {
      final colorsMap = backupData['dayColors'] as Map<String, dynamic>;
      for (final entry in colorsMap.entries) {
        restoredDayColors[entry.key] = Color(entry.value as int);
      }
    }
    return restoredDayColors;
  }
}

