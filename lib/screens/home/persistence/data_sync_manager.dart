// lib/screens/home/persistence/data_sync_manager.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';
import '../../../models/medicine_data.dart';
import '../../../services/medication_service.dart';
import '../../../services/app_preferences.dart';
import '../../../services/daily_memo_service.dart';
import '../../../utils/logger.dart';
import 'medication_data_persistence.dart';
import 'alarm_data_persistence.dart';

/// データ同期管理クラス
class DataSyncManager {
  final MedicationDataPersistence _medicationPersistence;
  final AlarmDataPersistence _alarmPersistence;
  // 初期化中のデータ保存を抑制するフラグ
  static bool _isInitializing = true;

  DataSyncManager({
    required MedicationDataPersistence medicationPersistence,
    required AlarmDataPersistence alarmPersistence,
  })  : _medicationPersistence = medicationPersistence,
        _alarmPersistence = alarmPersistence;

  /// 初期化完了を通知（初期化後のデータ保存を有効化）
  static void completeInitialization() {
    _isInitializing = false;
    if (kDebugMode) {
      debugPrint('✅ 初期化完了、データ保存を有効化');
    }
  }

  /// すべてのデータを保存
  Future<void> saveAllData({
    required List<MedicationMemo> medicationMemos,
    required DateTime? selectedDay,
    required Map<String, bool> medicationMemoStatus,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus,
    required List<Map<String, dynamic>> addedMedications,
    required List<Map<String, dynamic>> alarmList,
    required Map<String, Color> dayColors,
    required String memoText,
    required Map<String, double> adherenceRates,
  }) async {
    // 初期化中は保存をスキップ（重複実行を防止）
    if (_isInitializing) {
      if (kDebugMode) {
        debugPrint('ℹ️ 初期化中のため保存をスキップ');
      }
      return;
    }
    
    try {
      // メモステータスを保存
      await _medicationPersistence.saveMedicationMemoStatus(medicationMemoStatus);
      
      // 追加薬品リストを保存
      await _saveMedicationList(addedMedications);
      
      // アラームデータを保存
      await _alarmPersistence.saveAlarmData(alarmList);
      
      // カレンダーマークを保存
      await _saveCalendarMarks(dayColors);
      
      // 統計を保存
      await _saveStatistics(adherenceRates);
      
      // 選択日の服用データを保存
      if (selectedDay != null) {
        await _saveMedicationDataForDay(selectedDay, addedMedications);
        
        // メモを保存（DailyMemoServiceを使用）
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
        await DailyMemoService.setMemo(dateStr, memoText);
        Logger.info('メモ保存完了: $dateStr');
      }
      
      Logger.info('全データ保存完了');
    } catch (e) {
      Logger.error('全データ保存エラー', e);
      rethrow;
    }
  }

  /// すべてのデータを読み込み
  Future<Map<String, dynamic>> loadAllData() async {
    try {
      final medicationStatus = await _medicationPersistence.loadMedicationMemoStatus();
      final addedMedications = await _loadMedicationList();
      final alarmList = await _loadAlarmList();
      final dayColors = await _loadCalendarMarks();
      final adherenceRates = await _loadStatistics();

      return {
        'medicationMemoStatus': medicationStatus,
        'addedMedications': addedMedications,
        'alarmList': alarmList,
        'dayColors': dayColors,
        'adherenceRates': adherenceRates,
      };
    } catch (e) {
      Logger.error('全データ読み込みエラー', e);
      rethrow;
    }
  }

  /// 選択日の服用データを保存
  Future<void> _saveMedicationDataForDay(
    DateTime day,
    List<Map<String, dynamic>> addedMedications,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final medicationData = <String, MedicationInfo>{};

      // _addedMedicationsからMedicationInfoを作成
      for (final med in addedMedications) {
        final name = med['name']?.toString() ?? '';
        final taken = med['taken'] is bool ? med['taken'] as bool : false;
        final takenTime = med['takenTime'] is DateTime
            ? med['takenTime'] as DateTime?
            : null;
        final notes = med['notes']?.toString() ?? '';

        medicationData[name] = MedicationInfo(
          checked: taken,
          medicine: name,
          actualTime: takenTime,
          notes: notes,
        );
      }

      await MedicationService.saveMedicationData({dateStr: medicationData});
      await _saveToSharedPreferences(dateStr, medicationData);
      
      Logger.info('服用データ保存完了: $dateStr');
    } catch (e) {
      Logger.error('服用データ保存エラー', e);
      rethrow;
    }
  }

  /// SharedPreferencesにバックアップ保存
  Future<void> _saveToSharedPreferences(
    String dateStr,
    Map<String, MedicationInfo> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = <String, dynamic>{};

      for (final entry in data.entries) {
        dataJson[entry.key] = entry.value.toJson();
      }

      await prefs.setString('medication_backup_$dateStr', jsonEncode(dataJson));
      await prefs.setString('last_save_date', dateStr);
      
      Logger.info('SharedPreferencesバックアップ保存完了: $dateStr');
    } catch (e) {
      Logger.error('SharedPreferences保存エラー', e);
      rethrow;
    }
  }

  /// 服用薬リストを保存
  Future<void> _saveMedicationList(List<Map<String, dynamic>> addedMedications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medicationListJson = <String, dynamic>{};

      for (int i = 0; i < addedMedications.length; i++) {
        final med = addedMedications[i];
        medicationListJson['medication_$i'] = {
          'id': med['id'],
          'name': med['name'],
          'type': med['type'],
          'dosage': med['dosage'],
          'color': med['color'],
          'taken': med['taken'],
          'takenTime': med['takenTime']?.toString(),
          'notes': med['notes'],
        };
      }

      await prefs.setString('medicationList', jsonEncode(medicationListJson));
      await prefs.setString('medicationList_backup', jsonEncode(medicationListJson));
      await prefs.setInt('medicationList_count', addedMedications.length);
      
      Logger.info('服用薬データ保存完了: ${addedMedications.length}件');
    } catch (e) {
      Logger.error('服用薬データ保存エラー', e);
      rethrow;
    }
  }

  /// 服用薬リストを読み込み
  Future<List<Map<String, dynamic>>> _loadMedicationList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('medicationList');
      
      if (jsonString == null) return [];

      final medicationListJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final medications = <Map<String, dynamic>>[];

      medicationListJson.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          medications.add(value);
        }
      });

      Logger.info('服用薬データ読み込み完了: ${medications.length}件');
      return medications;
    } catch (e) {
      Logger.error('服用薬データ読み込みエラー', e);
      return [];
    }
  }

  /// アラームリストを保存
  Future<void> _saveAlarmList(List<Map<String, dynamic>> alarmList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_list_v2', jsonEncode(alarmList));
      Logger.info('アラームデータ保存完了: ${alarmList.length}件');
    } catch (e) {
      Logger.error('アラームデータ保存エラー', e);
      rethrow;
    }
  }

  /// アラームリストを読み込み
  Future<List<Map<String, dynamic>>> _loadAlarmList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('alarm_list_v2');
      
      if (jsonString == null) return [];

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      Logger.info('アラームデータ読み込み完了: ${decoded.length}件');
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.error('アラームデータ読み込みエラー', e);
      return [];
    }
  }

  /// カレンダーマークを保存
  Future<void> _saveCalendarMarks(Map<String, Color> dayColors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorsJson = <String, String>{};

      dayColors.forEach((date, color) {
        colorsJson[date] = color.value.toString();
      });

      await prefs.setString('day_colors_v2', jsonEncode(colorsJson));
      
      Logger.info('カレンダーマーク保存完了');
    } catch (e) {
      Logger.error('カレンダーマーク保存エラー', e);
    }
  }

  /// カレンダーマークを読み込み
  Future<Map<String, Color>> _loadCalendarMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('day_colors_v2');

      if (jsonString == null) return {};

      final colorsJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final dayColors = <String, Color>{};

      colorsJson.forEach((date, colorValue) {
        final colorInt = int.tryParse(colorValue.toString());
        if (colorInt != null) {
          dayColors[date] = Color(colorInt);
        }
      });

      Logger.info('カレンダーマーク読み込み完了');
      return dayColors;
    } catch (e) {
      Logger.error('カレンダーマーク読み込みエラー', e);
      return {};
    }
  }

  /// 統計を保存
  Future<void> _saveStatistics(Map<String, double> adherenceRates) async {
    try {
      await AppPreferences.saveString(
        'adherence_rates_v2',
        jsonEncode(adherenceRates),
      );
      
      Logger.info('統計保存完了');
    } catch (e) {
      Logger.error('統計保存エラー', e);
    }
  }

  /// 統計を読み込み
  Future<Map<String, double>> _loadStatistics() async {
    try {
      final jsonString = await AppPreferences.getString('adherence_rates_v2');
      
      if (jsonString == null) return {};

      final ratesJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final adherenceRates = <String, double>{};

      ratesJson.forEach((date, rate) {
        if (rate is num) {
          adherenceRates[date] = rate.toDouble();
        }
      });

      Logger.info('統計読み込み完了');
      return adherenceRates;
    } catch (e) {
      Logger.error('統計読み込みエラー', e);
      return {};
    }
  }
}
