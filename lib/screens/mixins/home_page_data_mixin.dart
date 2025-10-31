// データ保存/読み込み機能のMixin
// home_page.dartからデータ管理関連の機能を分離

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';
import '../../services/app_preferences.dart';
import '../../services/medication_service.dart';
import '../../utils/logger.dart';

/// データ保存/読み込み機能のMixin
/// このmixinを使用するクラスは、以下の状態変数を提供する必要があります：
/// - _selectedDay, _selectedDates, _addedMedications
/// - _medicationMemos, _medicationMemoStatus, _weekdayMedicationStatus
/// - _weekdayMedicationDoseStatus, _medicationData, _adherenceRates
/// - _dayColors, _alarmList, _medicationMemoStatusKey, _backupSuffix
mixin HomePageDataMixin<T extends StatefulWidget> on State<T> {
  // 抽象ゲッター（実装クラスで提供する必要がある）
  DateTime? get selectedDay;
  Set<DateTime> get selectedDates;
  List<Map<String, dynamic>> get addedMedications;
  List<MedicationMemo> get medicationMemos;
  Map<String, bool> get medicationMemoStatus;
  Map<String, Map<String, bool>> get weekdayMedicationStatus;
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus;
  Map<String, Map<String, MedicationInfo>> get medicationData;
  Map<String, double> get adherenceRates;
  Map<String, Color> get dayColors;
  List<Map<String, dynamic>> get alarmList;
  String get medicationMemoStatusKey;
  String get backupSuffix;

  // セッター（実装クラスで提供する必要がある）
  set selectedDay(DateTime? value);
  void updateSelectedDates(DateTime date);
  void clearSelectedDates();
  void setMedicationMemoStatus(String id, bool value);
  void setWeekdayMedicationStatus(String dateStr, String memoId, bool value);
  void setWeekdayMedicationDoseStatus(String dateStr, String memoId, int doseIndex, bool value);
  void setDayColor(String dateStr, Color color);
  void setAdherenceRates(Map<String, double> rates);
  void clearMedicationData();
  void setMedicationData(String dateStr, Map<String, MedicationInfo> data);
  void addMedicationData(String dateStr, String key, MedicationInfo info);
  void setAlarmList(List<Map<String, dynamic>> alarms);

  DateTime normalizeDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  // 包括的データ保存システム：すべてのデータをローカル保存
  Future<void> saveAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. メモ状態の保存
      await saveMemoStatus();
      
      // 2. 服用薬データの保存
      await saveMedicationList();
      
      // 3. アラームデータの保存
      await saveAlarmData();
      
      // 4. カレンダーマークの保存
      await saveCalendarMarks();
      
      // 5. ユーザー設定の保存
      await saveUserPreferences();
      
      // 6. 服用データの保存
      await saveMedicationData();
      
      // 7. 日別色設定の保存
      await saveDayColors();
      
      // 8. 統計データの保存
      await saveStatistics();
      
      // 9. アプリ設定の保存
      await saveAppSettings();
      
      // 10. 服用回数別状態の保存
      await saveMedicationDoseStatus();
      
      Logger.debug('全データ保存完了（包括的ローカル保存）');
    } catch (e) {
      Logger.debug('全データ保存エラー: $e');
    }
  }

  // 包括的データ読み込みシステム：すべてのデータを復元
  Future<void> loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. メモ状態の読み込み
      await loadMemoStatus();
      
      // 2. 服用薬データの読み込み
      await loadMedicationList();
      
      // 3. アラームデータの読み込み
      await loadAlarmData();
      
      // 4. カレンダーマークの読み込み
      await loadCalendarMarks();
      
      // 5. ユーザー設定の読み込み
      await loadUserPreferences();
      
      // 6. 服用データの読み込み
      await loadMedicationData();
      
      // 7. 日別色設定の読み込み
      await loadDayColors();
      
      // 8. 統計データの読み込み
      await loadStatistics();
      
      // 9. 服用回数別状態の読み込み
      await loadMedicationDoseStatus();
      
      // 10. アプリ設定の読み込み
      await loadAppSettings();
      
      Logger.debug('全データ読み込み完了（包括的ローカル復元）');
    } catch (e) {
      Logger.debug('全データ読み込みエラー: $e');
    }
  }

  // カレンダーマークの保存
  Future<void> saveCalendarMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final marksJson = <String, dynamic>{};
      
      // 選択された日付を保存
      for (final date in selectedDates) {
        marksJson[date.toIso8601String()] = {
          'date': date.toIso8601String(),
          'hasData': addedMedications.isNotEmpty,
          'medicationCount': addedMedications.length,
        };
      }
      
      final success1 = await prefs.setString('calendar_marks', jsonEncode(marksJson));
      final success2 = await prefs.setString('calendar_marks_backup', jsonEncode(marksJson));
      final success3 = await prefs.setInt('calendar_marks_count', selectedDates.length);
      
      if (success1 && success2 && success3) {
        debugPrint('カレンダーマーク保存完了: ${selectedDates.length}件');
      } else {
        debugPrint('カレンダーマーク保存に失敗');
      }
    } catch (e) {
      debugPrint('カレンダーマーク保存エラー: $e');
    }
  }

  // カレンダーマークの読み込み
  Future<void> loadCalendarMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? marksStr;
      
      final keys = ['calendar_marks', 'calendar_marks_backup'];
      
      for (final key in keys) {
        try {
          marksStr = prefs.getString(key);
          if (marksStr != null && marksStr.isNotEmpty) {
            debugPrint('カレンダーマーク読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (marksStr != null && marksStr.isNotEmpty) {
        try {
          final marksJson = jsonDecode(marksStr) as Map<String, dynamic>;
          clearSelectedDates();
          
          for (final entry in marksJson.entries) {
            final dateStr = entry.key;
            final date = DateTime.parse(dateStr);
            updateSelectedDates(normalizeDate(date));
          }
          
          debugPrint('カレンダーマーク読み込み完了: ${selectedDates.length}件');
        } catch (e) {
          debugPrint('カレンダーマークJSONデコードエラー: $e');
          clearSelectedDates();
        }
      } else {
        debugPrint('カレンダーマークが見つかりません');
        clearSelectedDates();
      }
    } catch (e) {
      debugPrint('カレンダーマーク読み込みエラー: $e');
      clearSelectedDates();
    }
  }

  // 日別色設定の保存
  Future<void> saveDayColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorsJson = <String, dynamic>{};
      
      for (final entry in dayColors.entries) {
        colorsJson[entry.key] = entry.value.value;
      }
      
      final success1 = await prefs.setString('day_colors', jsonEncode(colorsJson));
      final success2 = await prefs.setString('day_colors_backup', jsonEncode(colorsJson));
      
      if (success1 && success2) {
        debugPrint('日別色設定保存完了: ${dayColors.length}件');
      } else {
        debugPrint('日別色設定保存に失敗');
      }
    } catch (e) {
      debugPrint('日別色設定保存エラー: $e');
    }
  }

  // 日別色設定の読み込み
  Future<void> loadDayColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? colorsStr;
      
      final keys = ['day_colors', 'day_colors_backup'];
      
      for (final key in keys) {
        try {
          colorsStr = prefs.getString(key);
          if (colorsStr != null && colorsStr.isNotEmpty) {
            debugPrint('日別色設定読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (colorsStr != null && colorsStr.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(colorsStr);
          for (final entry in decoded.entries) {
            setDayColor(entry.key, Color(entry.value));
          }
          debugPrint('日別色設定読み込み完了: ${dayColors.length}件');
        } catch (e) {
          debugPrint('日別色設定JSONデコードエラー: $e');
        }
      } else {
        debugPrint('日別色設定が見つかりません');
      }
    } catch (e) {
      debugPrint('日別色設定読み込みエラー: $e');
    }
  }

  // 統計データの保存
  Future<void> saveStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statisticsJson = <String, dynamic>{
        'adherenceRates': adherenceRates,
        'totalMedications': addedMedications.length,
        'lastCalculation': DateTime.now().toIso8601String(),
      };
      
      final success1 = await prefs.setString('statistics', jsonEncode(statisticsJson));
      final success2 = await prefs.setString('statistics_backup', jsonEncode(statisticsJson));
      
      if (success1 && success2) {
        debugPrint('統計データ保存完了');
      } else {
        debugPrint('統計データ保存に失敗');
      }
    } catch (e) {
      debugPrint('統計データ保存エラー: $e');
    }
  }

  // 統計データの読み込み
  Future<void> loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? statisticsStr;
      
      final keys = ['statistics', 'statistics_backup'];
      
      for (final key in keys) {
        try {
          statisticsStr = prefs.getString(key);
          if (statisticsStr != null && statisticsStr.isNotEmpty) {
            debugPrint('統計データ読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (statisticsStr != null && statisticsStr.isNotEmpty) {
        try {
          final statisticsJson = jsonDecode(statisticsStr) as Map<String, dynamic>;
          setAdherenceRates(Map<String, double>.from(statisticsJson['adherenceRates'] ?? {}));
          debugPrint('統計データ読み込み完了');
        } catch (e) {
          debugPrint('統計データJSONデコードエラー: $e');
        }
      } else {
        debugPrint('統計データが見つかりません');
      }
    } catch (e) {
      debugPrint('統計データ読み込みエラー: $e');
    }
  }

  // アプリ設定の保存
  Future<void> saveAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = <String, dynamic>{
        'appVersion': '1.0.1',
        'lastUpdate': DateTime.now().toIso8601String(),
        'dataVersion': 'flutter_3_29_3',
        'backupEnabled': true,
      };
      
      final success1 = await prefs.setString('app_settings', jsonEncode(settingsJson));
      final success2 = await prefs.setString('app_settings_backup', jsonEncode(settingsJson));
      
      if (success1 && success2) {
        debugPrint('アプリ設定保存完了');
      } else {
        debugPrint('アプリ設定保存に失敗');
      }
    } catch (e) {
      debugPrint('アプリ設定保存エラー: $e');
    }
  }

  // アプリ設定の読み込み
  Future<void> loadAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? settingsStr;
      
      final keys = ['app_settings', 'app_settings_backup'];
      
      for (final key in keys) {
        try {
          settingsStr = prefs.getString(key);
          if (settingsStr != null && settingsStr.isNotEmpty) {
            debugPrint('アプリ設定読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('アプリ設定読み込みエラー: $e');
    }
  }

  // 服用回数別状態の保存
  Future<void> saveMedicationDoseStatus() async {
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
      
      final success1 = await prefs.setString('medication_dose_status', jsonEncode(doseStatusJson));
      final success2 = await prefs.setString('medication_dose_status_backup', jsonEncode(doseStatusJson));
      
      if (success1 && success2) {
        debugPrint('服用回数別状態保存完了');
      } else {
        debugPrint('服用回数別状態保存に失敗');
      }
    } catch (e) {
      debugPrint('服用回数別状態保存エラー: $e');
    }
  }

  // 服用回数別状態の読み込み
  Future<void> loadMedicationDoseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doseStatusStr = prefs.getString('medication_dose_status') ?? 
                           prefs.getString('medication_dose_status_backup') ?? '{}';
      final doseStatusJson = jsonDecode(doseStatusStr) as Map<String, dynamic>;
      
      for (final dateEntry in doseStatusJson.entries) {
        final dateStr = dateEntry.key;
        final memoStatus = dateEntry.value as Map<String, dynamic>;
        
        for (final memoEntry in memoStatus.entries) {
          final memoId = memoEntry.key;
          final doseStatus = memoEntry.value as Map<String, dynamic>;
          
          for (final doseEntry in doseStatus.entries) {
            setWeekdayMedicationDoseStatus(dateStr, memoId, int.parse(doseEntry.key), doseEntry.value as bool);
          }
        }
      }
      
      debugPrint('服用回数別状態読み込み完了');
    } catch (e) {
      debugPrint('服用回数別状態読み込みエラー: $e');
    }
  }

  // メモの状態を保存（完全版）
  Future<void> saveMemoStatus() async {
    try {
      final memoStatusJson = <String, dynamic>{};
      
      for (final entry in medicationMemoStatus.entries) {
        memoStatusJson[entry.key] = entry.value;
      }
      
      // awaitを確実に付けて保存
      await AppPreferences.saveString('medicationMemoStatus', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('medication_memo_status', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('memo_status_backup', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('last_memo_save', DateTime.now().toIso8601String());
      
      debugPrint('メモ状態保存完了: ${memoStatusJson.length}件（完全版）');
    } catch (e) {
      debugPrint('メモ状態保存エラー: $e');
    }
  }

  // メモの状態を読み込み（完全版）
  Future<void> loadMemoStatus() async {
    try {
      String? memoStatusStr;
      
      // 複数キーから読み込み（優先順位付き）
      final keys = ['medicationMemoStatus', 'medication_memo_status', 'memo_status_backup'];
      
      for (final key in keys) {
        memoStatusStr = AppPreferences.getString(key);
        if (memoStatusStr != null && memoStatusStr.isNotEmpty) {
          debugPrint('メモ状態読み込み成功: $key（完全版）');
          break;
        }
      }
      
      if (memoStatusStr != null && memoStatusStr.isNotEmpty) {
        final memoStatusJson = jsonDecode(memoStatusStr) as Map<String, dynamic>;
        for (final entry in memoStatusJson.entries) {
          setMedicationMemoStatus(entry.key, entry.value as bool);
        }
        debugPrint('メモ状態読み込み完了: ${medicationMemoStatus.length}件');
        
        // UIに反映
        if (mounted) {
          setState(() {
            // 保存された値があればそれを使う
          });
        }
      } else {
        debugPrint('メモ状態データが見つかりません（初期値を使用）');
      }
    } catch (e) {
      debugPrint('メモ状態読み込みエラー: $e');
    }
  }

  // 服用薬データの保存
  Future<void> saveMedicationList() async {
    try {
      await MedicationService.saveMedicationData(medicationData);
      debugPrint('服用薬データ保存完了');
    } catch (e) {
      debugPrint('服用薬データ保存エラー: $e');
    }
  }

  // 服用薬データの読み込み
  Future<void> loadMedicationList() async {
    try {
      final data = await MedicationService.loadMedicationData();
      clearMedicationData();
      for (final entry in data.entries) {
        setMedicationData(entry.key, entry.value);
      }
      debugPrint('服用薬データ読み込み完了');
    } catch (e) {
      debugPrint('服用薬データ読み込みエラー: $e');
    }
  }

  // 服用データの保存
  Future<void> saveMedicationData() async {
    try {
      if (selectedDay == null) return;
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
      final medicationData = <String, MedicationInfo>{};
      
      // _addedMedicationsからMedicationInfoを作成
      for (final med in addedMedications) {
        final key = 'added_medication_${med.hashCode}';
        medicationData[key] = MedicationInfo(
          checked: med['isChecked'] as bool? ?? false,
          medicine: med['name'] as String? ?? '',
          actualTime: med['isChecked'] as bool? == true ? DateTime.now() : null,
        );
      }
      
      setMedicationData(dateStr, medicationData);
      await MedicationService.saveMedicationData(this.medicationData);
      debugPrint('服用データ保存完了: $dateStr');
    } catch (e) {
      debugPrint('服用データ保存エラー: $e');
    }
  }

  // 服用データの読み込み
  Future<void> loadMedicationData() async {
    try {
      final data = await MedicationService.loadMedicationData();
      for (final entry in data.entries) {
        setMedicationData(entry.key, entry.value);
      }
      debugPrint('服用データ読み込み完了');
    } catch (e) {
      debugPrint('服用データ読み込みエラー: $e');
    }
  }

  // アラームデータの保存（簡易版 - 詳細はalarm_mixinで実装）
  Future<void> saveAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('alarm_count', alarmList.length);
      await prefs.setString('alarm_list', jsonEncode(alarmList));
      debugPrint('アラームデータ保存完了: ${alarmList.length}件');
    } catch (e) {
      debugPrint('アラームデータ保存エラー: $e');
    }
  }

  // アラームデータの読み込み（簡易版 - 詳細はalarm_mixinで実装）
  Future<void> loadAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmListStr = prefs.getString('alarm_list');
      if (alarmListStr != null) {
        final List<dynamic> decoded = jsonDecode(alarmListStr);
        setAlarmList(decoded.cast<Map<String, dynamic>>().toList());
        debugPrint('アラームデータ読み込み完了: ${alarmList.length}件');
      }
    } catch (e) {
      debugPrint('アラームデータ読み込みエラー: $e');
    }
  }

  // ユーザー設定の保存（簡易版）
  Future<void> saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = <String, dynamic>{
        'selectedDay': selectedDay?.toIso8601String(),
        'lastSaveTime': DateTime.now().toIso8601String(),
      };
      
      final success1 = await prefs.setString('user_preferences', jsonEncode(preferencesJson));
      final success2 = await prefs.setString('user_preferences_backup', jsonEncode(preferencesJson));
      
      if (success1 && success2) {
        debugPrint('ユーザー設定保存完了');
      } else {
        debugPrint('ユーザー設定保存に失敗');
      }
    } catch (e) {
      debugPrint('ユーザー設定保存エラー: $e');
    }
  }

  // ユーザー設定の読み込み（簡易版）
  Future<void> loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? preferencesStr;
      
      final keys = ['user_preferences', 'user_preferences_backup'];
      
      for (final key in keys) {
        try {
          preferencesStr = prefs.getString(key);
          if (preferencesStr != null && preferencesStr.isNotEmpty) {
            debugPrint('ユーザー設定読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (preferencesStr != null && preferencesStr.isNotEmpty) {
        try {
          final preferencesJson = jsonDecode(preferencesStr) as Map<String, dynamic>;
          
          if (preferencesJson['selectedDay'] != null) {
            selectedDay = DateTime.parse(preferencesJson['selectedDay']);
          }
          
          debugPrint('ユーザー設定読み込み完了');
        } catch (e) {
          debugPrint('ユーザー設定JSONデコードエラー: $e');
        }
      } else {
        debugPrint('ユーザー設定が見つかりません');
      }
    } catch (e) {
      debugPrint('ユーザー設定読み込みエラー: $e');
    }
  }
}

