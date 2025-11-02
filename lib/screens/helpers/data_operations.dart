// lib/screens/helpers/data_operations.dart
// データ操作関連の機能を集約

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';
import '../../services/app_preferences.dart';
import '../../services/medication_service.dart';
import '../home/state/home_page_state_manager.dart';
import '../home/helpers/data_persistence_helper.dart';
import '../home/persistence/medication_data_persistence.dart';
import 'home_page_data_helper.dart';

/// データ操作を管理するクラス
/// home_page.dartからデータ操作関連メソッドを移動
class DataOperations {
  final HomePageStateManager? stateManager;
  final DataPersistenceHelper? dataPersistenceHelper;
  final MedicationDataPersistence medicationDataPersistence;
  final Timer? Function() getSaveDebounceTimer;
  final void Function(Timer?) setSaveDebounceTimer;
  final DateTime? Function() getLastOperationTime;
  final void Function(DateTime) setLastOperationTime;

  DataOperations({
    required this.stateManager,
    required this.dataPersistenceHelper,
    required this.medicationDataPersistence,
    required this.getSaveDebounceTimer,
    required this.setSaveDebounceTimer,
    required this.getLastOperationTime,
    required this.setLastOperationTime,
  });

  /// 全データ保存
  Future<void> saveAllData() async {
    if (stateManager != null && stateManager!.isInitialized) {
      await stateManager!.saveAllData();
      // 操作時間を記録（手動復元用）
      setLastOperationTime(DateTime.now());
    } else {
      debugPrint('⚠️ StateManagerが初期化されていません。データ保存をスキップします。');
    }
  }

  /// 遅延保存（デバウンス）
  void saveCurrentDataDebounced() {
    final saveTimer = stateManager?.saveDebounceTimer ?? getSaveDebounceTimer();
    saveTimer?.cancel();
    final newTimer = Timer(const Duration(seconds: 2), () {
      saveAllData();
    });
    if (stateManager != null) {
      stateManager!.saveDebounceTimer = newTimer;
    } else {
      setSaveDebounceTimer(newTimer);
    }
  }

  /// データ保存
  Future<void> saveCurrentData() async {
    if (stateManager != null && stateManager!.isInitialized) {
      await saveAllData();
    } else {
      debugPrint('⚠️ StateManagerが初期化されていません。データ保存をスキップします。');
    }
  }

  /// 動的薬リストの保存
  Future<void> saveAddedMedications() async {
    try {
      final selectedDay = stateManager?.selectedDay;
      if (selectedDay == null) return;
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
      final medicationData = stateManager?.medicationData ?? {};
      final addedMeds = stateManager?.addedMedications ?? [];
      medicationData.putIfAbsent(dateStr, () => {});
      
      // 動的薬リストの保存（個別に保存）
      for (final medication in addedMeds) {
        final key = 'added_medication_${medication.hashCode}';
        medicationData[dateStr]![key] = MedicationInfo(
          checked: medication['isChecked'] as bool,
          medicine: medication['name'] as String,
          actualTime: medication['isChecked'] as bool ? DateTime.now() : null,
        );
      }
      
      if (stateManager != null) {
        stateManager!.medicationData = medicationData;
      }
      await MedicationService.saveMedicationData(medicationData);
    } catch (e) {
      debugPrint('❌ 動的薬リスト保存エラー: $e');
    }
  }

  /// 服用メモの状態保存
  Future<void> saveMedicationMemoStatus() async {
    try {
      await medicationDataPersistence.saveMedicationMemoStatus(stateManager?.medicationMemoStatus ?? {});
    } catch (e) {
      debugPrint('❌ メモステータス保存エラー: $e');
    }
  }

  /// 曜日設定薬の状態保存
  Future<void> saveWeekdayMedicationStatus() async {
    try {
      await medicationDataPersistence.saveWeekdayMedicationStatus(stateManager?.weekdayMedicationStatus ?? {});
    } catch (e) {
      debugPrint('❌ 曜日別ステータス保存エラー: $e');
    }
  }

  /// 服用回数ステータス保存
  Future<void> saveMedicationDoseStatus() async {
    await dataPersistenceHelper?.saveMedicationDoseStatus();
  }

  /// 薬データ保存
  Future<void> saveMedicationData() async {
    await dataPersistenceHelper?.saveMedicationData();
  }

  /// カレンダーマーク保存
  Future<void> saveCalendarMarks() async {
    // StateManager.saveAllData()で実行済み
  }

  /// カレンダーマーク読み込み
  Future<void> loadCalendarMarks() async {
    // StateManager.init()で実行済み
  }

  /// ユーザー設定保存
  Future<void> saveUserPreferences() async {
    // StateManager.saveAllData()で実行済み
  }

  /// ユーザー設定読み込み
  Future<void> loadUserPreferences() async {
    // StateManager.init()で実行済み
  }

  /// 日付色保存
  Future<void> saveDayColors() async {
    if (stateManager != null && stateManager!.isInitialized) {
      await HomePageDataHelper.saveDayColors(stateManager?.dayColors ?? {});
    }
  }

  /// 日付色読み込み
  Future<void> loadDayColors() async {
    // StateManager.init()で実行済み
  }

  /// 統計保存
  Future<void> saveStatistics() async {
    // StateManager.saveAllData()で実行済み
  }

  /// 統計読み込み
  Future<void> loadStatistics() async {
    // StateManager.init()で実行済み
  }

  /// アプリ設定保存
  Future<void> saveAppSettings() async {
    // StateManager.saveAllData()で実行済み
  }

  /// データ読み込み（簡素化）
  Future<void> loadCurrentData() async {
    if (stateManager != null && stateManager!.isInitialized) {
      final selectedDay = stateManager?.selectedDay;
      if (selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
        final memo = await SharedPreferences.getInstance().then((prefs) => prefs.getString('memo_$dateStr'));
        if (memo != null) {
          stateManager?.memoController.text = memo ?? '';
        }
      }
    }
  }

  /// 服用メモステータス読み込み
  Future<void> loadMedicationMemoStatus() async {
    // StateManager.init()で実行済み
  }

  /// 曜日別ステータス読み込み
  Future<void> loadWeekdayMedicationStatus() async {
    // StateManager.init()で実行済み
  }

  /// メモ読み込み
  Future<void> loadMemo() async {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay != null && stateManager != null && stateManager!.isInitialized) {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
      final prefs = await SharedPreferences.getInstance();
      final memo = prefs.getString('memo_$dateStr');
      if (memo != null && stateManager != null) {
        stateManager?.memoController.text = memo;
      }
    }
  }

  /// 選択日付のメモ読み込み
  Future<void> loadMemoForSelectedDate() async {
    try {
      final selectedDay = stateManager?.selectedDay;
      if (selectedDay != null && stateManager != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
        final prefs = await SharedPreferences.getInstance();
        final savedMemo = prefs.getString('memo_$dateStr');
        if (stateManager != null) {
          if (savedMemo != null) {
            stateManager?.memoController.text = savedMemo;
            stateManager?.notifiers.memoTextNotifier.value = savedMemo;
          } else {
            stateManager?.memoController.clear();
            stateManager?.notifiers.memoTextNotifier.value = '';
          }
        }
      }
    } catch (e) {
      debugPrint('❌ メモ読み込みエラー: $e');
    }
  }

  /// 選択日付の薬入力を更新
  Future<void> updateMedicineInputsForSelectedDate() async {
    if (stateManager == null || !stateManager!.isInitialized) return;
    final selectedDay = stateManager!.selectedDay;
    if (selectedDay != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
      final dayData = stateManager!.medicationData[dateStr];
      stateManager!.addedMedications = [];
      if (dayData != null) {
        for (final entry in dayData.entries) {
          if (entry.key.startsWith('added_medication_')) {
            stateManager!.addedMedications.add({
              'name': entry.value.medicine,
              'type': '薬',
              'color': Colors.blue,
              'dosage': '',
              'notes': '',
              'isChecked': entry.value.checked,
            });
          }
        }
      }
      await loadMemoForSelectedDate();
    } else {
      stateManager!.addedMedications = [];
      stateManager!.memoController.clear();
    }
  }

  /// SharedPreferencesからの服用メモ読み込み
  Future<List<MedicationMemo>> loadMemosFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKeys = [
        'medication_memos_backup', 
        'medication_memos_backup2', 
        'medication_memos_backup3',
        'medication_memos_v2',
        'medication_memos'
      ];
      
      for (final key in backupKeys) {
        try {
          final backupJson = prefs.getString(key);
          if (backupJson != null && backupJson.isNotEmpty) {
            final decoded = jsonDecode(backupJson);
            final memosList = decoded is List ? decoded : <dynamic>[];
            final memos = memosList
                .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
                .toList();
            debugPrint('✅ SharedPreferencesから復元: ${memos.length}件 ($key)');
            return memos;
          }
        } catch (e) {
          debugPrint('⚠️ キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      debugPrint('⚠️ 全てのバックアップが見つかりません');
      return [];
    } catch (e) {
      debugPrint('❌ SharedPreferences読み込みエラー: $e');
      return [];
    }
  }

  /// SharedPreferencesへのバックアップ保存
  Future<void> backupMemosToSharedPreferences() async {
    try {
      final memos = stateManager?.medicationMemos ?? [];
      if (memos.isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      final memosJson = memos.map((memo) => memo.toJson()).toList();
      final jsonString = jsonEncode(memosJson);
      
      // 複数キーに保存（3重バックアップ）
      await Future.wait([
        prefs.setString('medication_memos_backup', jsonString),
        prefs.setString('medication_memos_backup2', jsonString),
        prefs.setString('medication_memos_backup3', jsonString),
        prefs.setString('medication_memos_v2', jsonString),
      ]);
      
      debugPrint('✅ 服用メモバックアップ保存完了: ${memos.length}件');
    } catch (e) {
      debugPrint('❌ 服用メモバックアップ保存エラー: $e');
    }
  }

  /// メモの状態を読み込み（完全版）
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
        if (stateManager != null) {
          stateManager!.medicationMemoStatus = memoStatusJson.map((key, value) => MapEntry(key, value as bool));
          debugPrint('メモ状態読み込み完了: ${stateManager!.medicationMemoStatus.length}件');
        }
      } else {
        debugPrint('メモ状態データが見つかりません（初期値を使用）');
        stateManager?.medicationMemoStatus = {};
      }
    } catch (e) {
      debugPrint('メモ状態読み込みエラー: $e');
      stateManager?.medicationMemoStatus = {};
    }
  }

  /// 服用メモのチェック状態を取得
  bool getMedicationMemoStatus(String memoId) {
    return stateManager?.medicationMemoStatus[memoId] ?? false;
  }

  /// 選択された日付の服用メモのチェック状態を取得
  bool getMedicationMemoStatusForSelectedDay(String memoId) {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final memoStatus = stateManager?.medicationMemoStatus ?? {};
    return memoStatus[memoId] ?? false;
  }

  /// 日付メモ保存
  Future<void> saveMemo() async {
    try {
      final selectedDay = stateManager?.selectedDay;
      final memoController = stateManager?.memoController;
      if (selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('memo_$dateStr', memoController?.text ?? '');
      }
    } catch (e) {
      debugPrint('❌ メモ保存エラー: $e');
    }
  }
}

