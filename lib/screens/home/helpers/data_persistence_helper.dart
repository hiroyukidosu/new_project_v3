// lib/screens/home/helpers/data_persistence_helper.dart
// データ保存・読み込み関連のヘルパーメソッド

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../models/medication_info.dart';
import '../../../services/app_preferences.dart';
import '../../../services/medication_service.dart';
import '../state/home_page_state_manager.dart';
import '../../helpers/home_page_alarm_helper.dart';
import '../../helpers/home_page_data_helper.dart';
import '../persistence/medication_data_persistence.dart';

/// データ永続化ヘルパー
/// StateManager経由でデータを保存・読み込みする
class DataPersistenceHelper {
  final HomePageStateManager stateManager;
  final MedicationDataPersistence medicationDataPersistence;

  DataPersistenceHelper({
    required this.stateManager,
    required this.medicationDataPersistence,
  });

  /// 服用データを保存
  Future<void> saveMedicationData() async {
    try {
      final selectedDay = stateManager.selectedDay;
      if (selectedDay == null) return;
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
      final medicationData = <String, MedicationInfo>{};
      
      // addedMedicationsからMedicationInfoを作成
      final addedMeds = stateManager.addedMedications;
      for (final med in addedMeds) {
        final name = med['name']?.toString() ?? '';
        final taken = med['taken'] is bool ? med['taken'] as bool : false;
        final takenTime = med['takenTime'] is DateTime ? med['takenTime'] as DateTime? : null;
        final notes = med['notes']?.toString() ?? '';
        
        medicationData[name] = MedicationInfo(
          checked: taken,
          medicine: name,
          actualTime: takenTime,
          notes: notes,
        );
      }
      
      // 保存処理
      await MedicationService.saveMedicationData({dateStr: medicationData});
      await saveToSharedPreferences(dateStr, medicationData);
      await saveMemoStatus();
      await saveAdditionalBackup(dateStr, medicationData);
      await saveMedicationList();
      await saveAlarmData();
      
      debugPrint('全データ保存完了: $dateStr');
    } catch (e) {
      debugPrint('データ保存エラー: $e');
    }
  }

  /// SharedPreferencesに保存
  Future<void> saveToSharedPreferences(String dateStr, Map<String, MedicationInfo> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = <String, dynamic>{};
      
      for (final entry in data.entries) {
        dataJson[entry.key] = entry.value.toJson();
      }
      
      await prefs.setString('medication_backup_$dateStr', jsonEncode(dataJson));
      await prefs.setString('last_save_date', dateStr);
      debugPrint('SharedPreferencesバックアップ保存完了: $dateStr');
    } catch (e) {
      debugPrint('SharedPreferences保存エラー: $e');
    }
  }

  /// 追加のバックアップ保存
  Future<void> saveAdditionalBackup(String dateStr, Map<String, MedicationInfo> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = <String, dynamic>{};
      
      for (final entry in data.entries) {
        dataJson[entry.key] = entry.value.toJson();
      }
      
      await prefs.setString('medication_backup_$dateStr', jsonEncode(dataJson));
      await prefs.setString('medication_backup_latest', jsonEncode(dataJson));
      await prefs.setString('last_save_date', dateStr);
      await prefs.setString('last_save_timestamp', DateTime.now().toIso8601String());
      await prefs.commit();
      
      debugPrint('追加バックアップ保存完了: $dateStr');
    } catch (e) {
      debugPrint('追加バックアップ保存エラー: $e');
    }
  }

  /// 服用薬リストを保存
  Future<void> saveMedicationList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medicationListJson = <String, dynamic>{};
      
      final addedMeds = stateManager.addedMedications;
      for (int i = 0; i < addedMeds.length; i++) {
        final med = addedMeds[i];
        medicationListJson['medication_$i'] = {
          'id': med['id'],
          'name': med['name'],
          'type': med['type'],
          'dosage': med['dosage'],
          'color': med['color'],
          'taken': med['taken'],
          'takenTime': med['takenTime']?.toIso8601String(),
          'notes': med['notes'],
        };
      }
      
      await prefs.setString('medicationList', jsonEncode(medicationListJson));
      await prefs.setString('medicationList_backup', jsonEncode(medicationListJson));
      await prefs.setInt('medicationList_count', addedMeds.length);
      
      debugPrint('服用薬データ保存完了: ${addedMeds.length}件');
    } catch (e) {
      debugPrint('服用薬データ保存エラー: $e');
    }
  }

  /// アラームデータを保存
  Future<void> saveAlarmData() async {
    await HomePageAlarmHelper.saveAlarmData(stateManager.alarmList);
  }

  /// メモの状態を保存
  Future<void> saveMemoStatus() async {
    try {
      final memoStatusJson = <String, dynamic>{};
      
      final memoStatus = stateManager.medicationMemoStatus;
      for (final entry in memoStatus.entries) {
        memoStatusJson[entry.key] = entry.value;
      }
      
      await AppPreferences.saveString('medicationMemoStatus', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('medication_memo_status', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('memo_status_backup', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('last_memo_save', DateTime.now().toIso8601String());
      
      debugPrint('メモ状態保存完了: ${memoStatusJson.length}件');
    } catch (e) {
      debugPrint('メモ状態保存エラー: $e');
    }
  }

  /// メモの状態を読み込み
  Future<void> loadMemoStatus() async {
    try {
      String? memoStatusStr;
      
      // 複数のキーから読み込みを試行
      memoStatusStr = await AppPreferences.getString('medicationMemoStatus');
      if (memoStatusStr == null || memoStatusStr.isEmpty) {
        memoStatusStr = await AppPreferences.getString('medication_memo_status');
      }
      if (memoStatusStr == null || memoStatusStr.isEmpty) {
        memoStatusStr = await AppPreferences.getString('memo_status_backup');
      }
      
      if (memoStatusStr != null && memoStatusStr.isNotEmpty) {
        final memoStatusJson = jsonDecode(memoStatusStr) as Map<String, dynamic>;
        stateManager.medicationMemoStatus.clear();
        memoStatusJson.forEach((key, value) {
          if (value is bool) {
            stateManager.medicationMemoStatus[key] = value;
          }
        });
        debugPrint('メモ状態読み込み完了: ${stateManager.medicationMemoStatus.length}件');
      }
    } catch (e) {
      debugPrint('メモ状態読み込みエラー: $e');
    }
  }

  /// 服用回数別状態を保存
  Future<void> saveMedicationDoseStatus() async {
    try {
      await medicationDataPersistence.saveMedicationDoseStatus(stateManager.weekdayMedicationDoseStatus);
    } catch (e) {
      debugPrint('❌ 服用回数別ステータス保存エラー: $e');
    }
  }

  /// 日付色を保存
  Future<void> saveDayColors() async {
    await HomePageDataHelper.saveDayColors(stateManager.dayColors);
  }
}

