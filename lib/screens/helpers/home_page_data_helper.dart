// データ読み込み/保存ヘルパー
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class HomePageDataHelper {
  static Future<void> saveCalendarMarks(Set<DateTime> selectedDates, List<Map<String, dynamic>> addedMedications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final marksJson = <String, dynamic>{};
      for (final date in selectedDates) {
        marksJson[date.toIso8601String()] = {
          'date': date.toIso8601String(),
          'hasData': addedMedications.isNotEmpty,
          'medicationCount': addedMedications.length,
        };
      }
      await prefs.setString('calendar_marks', jsonEncode(marksJson));
      await prefs.setString('calendar_marks_backup', jsonEncode(marksJson));
      await prefs.setInt('calendar_marks_count', selectedDates.length);
    } catch (e) {
      // エラー処理
    }
  }

  static Future<Set<DateTime>> loadCalendarMarks(DateTime Function(DateTime) normalizeDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? marksStr;
      final keys = ['calendar_marks', 'calendar_marks_backup'];
      for (final key in keys) {
        marksStr = prefs.getString(key);
        if (marksStr != null && marksStr.isNotEmpty) break;
      }
      if (marksStr != null && marksStr.isNotEmpty) {
        final marksJson = jsonDecode(marksStr) as Map<String, dynamic>;
        final dates = <DateTime>{};
        for (final entry in marksJson.entries) {
          dates.add(normalizeDate(DateTime.parse(entry.key)));
        }
        return dates;
      }
    } catch (e) {
      // エラー処理
    }
    return <DateTime>{};
  }

  static Future<void> saveUserPreferences({
    required DateTime? selectedDay,
    required bool isMemoSelected,
    required String? selectedMemoId,
    required bool isAlarmPlaying,
    required bool notificationError,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = <String, dynamic>{
        'selectedDay': selectedDay?.toIso8601String(),
        'isMemoSelected': isMemoSelected,
        'selectedMemoId': selectedMemoId,
        'isAlarmPlaying': isAlarmPlaying,
        'notificationError': notificationError,
        'lastSaveTime': DateTime.now().toIso8601String(),
      };
      await prefs.setString('user_preferences', jsonEncode(preferencesJson));
      await prefs.setString('user_preferences_backup', jsonEncode(preferencesJson));
    } catch (e) {
      // エラー処理
    }
  }

  static Future<Map<String, dynamic>> loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? preferencesStr;
      final keys = ['user_preferences', 'user_preferences_backup'];
      for (final key in keys) {
        preferencesStr = prefs.getString(key);
        if (preferencesStr != null && preferencesStr.isNotEmpty) break;
      }
      if (preferencesStr != null && preferencesStr.isNotEmpty) {
        return jsonDecode(preferencesStr) as Map<String, dynamic>;
      }
    } catch (e) {
      // エラー処理
    }
    return {};
  }

  static Future<void> saveDayColors(Map<String, Color> dayColors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorsJson = <String, dynamic>{};
      for (final entry in dayColors.entries) {
        colorsJson[entry.key] = entry.value.value;
      }
      final jsonString = jsonEncode(colorsJson);
      // 複数のキーに保存（互換性のため）
      await prefs.setString('day_colors', jsonString);
      await prefs.setString('day_colors_backup', jsonString);
      await prefs.setString('day_colors_v2', jsonString);
    } catch (e) {
      // エラー処理
    }
  }

  static Future<Map<String, Color>> loadDayColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? colorsStr;
      // 複数のキーから読み込みを試行（互換性のため）
      final keys = ['day_colors', 'day_colors_backup', 'day_colors_v2'];
      for (final key in keys) {
        colorsStr = prefs.getString(key);
        if (colorsStr != null && colorsStr.isNotEmpty) break;
      }
      if (colorsStr != null && colorsStr.isNotEmpty) {
        final decoded = jsonDecode(colorsStr) as Map<String, dynamic>;
        return decoded.map((key, value) {
          final colorInt = value is int 
              ? value 
              : int.tryParse(value.toString());
          if (colorInt != null) {
            return MapEntry(key, Color(colorInt));
          }
          return MapEntry(key, Colors.transparent);
        });
      }
    } catch (e) {
      // エラー処理
    }
    return {};
  }

  static Future<void> saveStatistics(Map<String, double> adherenceRates, int totalMedications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statisticsJson = <String, dynamic>{
        'adherenceRates': adherenceRates,
        'totalMedications': totalMedications,
        'lastCalculation': DateTime.now().toIso8601String(),
      };
      await prefs.setString('statistics', jsonEncode(statisticsJson));
      await prefs.setString('statistics_backup', jsonEncode(statisticsJson));
    } catch (e) {
      // エラー処理
    }
  }

  static Future<Map<String, double>> loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? statisticsStr;
      final keys = ['statistics', 'statistics_backup'];
      for (final key in keys) {
        statisticsStr = prefs.getString(key);
        if (statisticsStr != null && statisticsStr.isNotEmpty) break;
      }
      if (statisticsStr != null && statisticsStr.isNotEmpty) {
        final statisticsJson = jsonDecode(statisticsStr) as Map<String, dynamic>;
        return Map<String, double>.from(statisticsJson['adherenceRates'] ?? {});
      }
    } catch (e) {
      // エラー処理
    }
    return {};
  }

  static Future<void> saveAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = <String, dynamic>{
        'appVersion': '1.0.1',
        'lastUpdate': DateTime.now().toIso8601String(),
        'dataVersion': 'flutter_3_29_3',
        'backupEnabled': true,
      };
      await prefs.setString('app_settings', jsonEncode(settingsJson));
      await prefs.setString('app_settings_backup', jsonEncode(settingsJson));
    } catch (e) {
      // エラー処理
    }
  }

  static Future<void> saveMedicationDoseStatus(Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doseStatusJson = <String, dynamic>{};
      for (final dateEntry in weekdayMedicationDoseStatus.entries) {
        final dateStr = dateEntry.key;
        final memoStatus = dateEntry.value;
        final memoStatusJson = <String, dynamic>{};
        for (final memoEntry in memoStatus.entries) {
          final memoId = memoEntry.key;
          final doseStatus = memoEntry.value;
          final doseStatusJson = <String, dynamic>{};
          for (final doseEntry in doseStatus.entries) {
            doseStatusJson[doseEntry.key.toString()] = doseEntry.value;
          }
          memoStatusJson[memoId] = doseStatusJson;
        }
        doseStatusJson[dateStr] = memoStatusJson;
      }
      await prefs.setString('medication_dose_status', jsonEncode(doseStatusJson));
      await prefs.setString('medication_dose_status_backup', jsonEncode(doseStatusJson));
    } catch (e) {
      // エラー処理
    }
  }

  static Future<Map<String, Map<String, Map<int, bool>>>> loadMedicationDoseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doseStatusStr = prefs.getString('medication_dose_status') ?? 
                           prefs.getString('medication_dose_status_backup') ?? '{}';
      final doseStatusJson = jsonDecode(doseStatusStr) as Map<String, dynamic>;
      final result = <String, Map<String, Map<int, bool>>>{};
      for (final dateEntry in doseStatusJson.entries) {
        final dateStr = dateEntry.key;
        final memoStatus = dateEntry.value as Map<String, dynamic>;
        final memoStatusMap = <String, Map<int, bool>>{};
        for (final memoEntry in memoStatus.entries) {
          final memoId = memoEntry.key;
          final doseStatus = memoEntry.value as Map<String, dynamic>;
          final doseStatusMap = <int, bool>{};
          for (final doseEntry in doseStatus.entries) {
            doseStatusMap[int.parse(doseEntry.key)] = doseEntry.value as bool;
          }
          memoStatusMap[memoId] = doseStatusMap;
        }
        result[dateStr] = memoStatusMap;
      }
      return result;
    } catch (e) {
      // エラー処理
    }
    return {};
  }

  static Future<List<Map<String, dynamic>>> loadMedicationList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? medicationListStr;
      final keys = ['medicationList', 'medicationList_backup'];
      for (final key in keys) {
        medicationListStr = prefs.getString(key);
        if (medicationListStr != null && medicationListStr.isNotEmpty) break;
      }
      if (medicationListStr != null && medicationListStr.isNotEmpty) {
        final medicationListJson = jsonDecode(medicationListStr) as Map<String, dynamic>;
        final medications = <Map<String, dynamic>>[];
        final count = prefs.getInt('medicationList_count') ?? 0;
        for (int i = 0; i < count; i++) {
          final medKey = 'medication_$i';
          if (medicationListJson.containsKey(medKey)) {
            final medData = medicationListJson[medKey] as Map<String, dynamic>;
            medications.add({
              'id': medData['id'],
              'name': medData['name'],
              'type': medData['type'],
              'dosage': medData['dosage'],
              'color': medData['color'],
              'taken': medData['taken'],
              'takenTime': medData['takenTime'] != null ? DateTime.parse(medData['takenTime']) : null,
              'notes': medData['notes'],
            });
          }
        }
        return medications;
      }
    } catch (e) {
      // エラー処理
    }
    return [];
  }
}

