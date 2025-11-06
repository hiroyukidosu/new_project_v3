// lib/screens/helpers/medication_operations.dart
// メモ操作関連の機能を集約

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../home/state/home_page_state_manager.dart';
import '../home/persistence/medication_data_persistence.dart';
import '../home/controllers/medication_controller.dart';

/// メモ操作を管理するクラス
/// home_page.dartからメモ操作関連メソッドを移動
class MedicationOperations {
  final HomePageStateManager? stateManager;
  final MedicationController? medicationController;
  final MedicationDataPersistence medicationDataPersistence;
  final Future<void> Function() onSaveAllData;
  final void Function() onStateChanged;
  final void Function() onUpdateCalendarMarks;

  MedicationOperations({
    required this.stateManager,
    required this.medicationController,
    required this.medicationDataPersistence,
    required this.onSaveAllData,
    required this.onStateChanged,
    required this.onUpdateCalendarMarks,
  });

  /// メモ追加
  void addMemo() {
    medicationController?.addMemo();
  }

  /// メモ編集
  void editMemo(MedicationMemo memo) {
    medicationController?.editMemo(memo);
  }

  /// 服用済みにマーク
  Future<void> markAsTaken(MedicationMemo memo) async {
    await medicationController?.markAsTaken(memo);
  }

  /// メモ削除
  Future<void> deleteMemo(String id) async {
    await medicationController?.deleteMemo(id);
  }

  /// 服用メモの状態を更新
  void updateMedicationMemoStatus(String memoId, bool isChecked) {
    if (stateManager != null) {
      stateManager!.medicationMemoStatus[memoId] = isChecked;
    }
    onSaveAllData();
  }

  /// 服用済みに追加
  void addToTakenMedications(MedicationMemo memo) {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null) return;
    
    // 重複チェック
    final addedMeds = stateManager?.addedMedications ?? [];
    final existingIndex = addedMeds.indexWhere((med) => med['id'] == memo.id);
    
    if (existingIndex == -1) {
      // 新規追加
      addedMeds.add({
        'id': memo.id,
        'name': memo.name,
        'type': memo.type,
        'dosage': memo.dosage,
        'color': memo.color,
        'taken': true,
        'takenTime': DateTime.now(),
        'notes': memo.notes,
      });
    } else {
      // 既存のものを更新
      addedMeds[existingIndex]['taken'] = true;
      addedMeds[existingIndex]['takenTime'] = DateTime.now();
      stateManager?.addedMedications = List.from(addedMeds);
    }
    
    // メモの状態を更新
    if (stateManager != null) {
      stateManager!.medicationMemoStatus[memo.id] = true;
    }
    
    // カレンダーマークを追加
    if (selectedDay != null && stateManager != null) {
      final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      if (!stateManager!.selectedDates.contains(normalizedDay)) {
        stateManager!.selectedDates.add(normalizedDay);
      }
    }
    
    onSaveAllData();
  }

  /// 服用済みから削除
  void removeFromTakenMedications(String memoId) {
    final addedMeds = stateManager?.addedMedications ?? [];
    addedMeds.removeWhere((med) => med['id'] == memoId);
    stateManager?.addedMedications = List.from(addedMeds);
    
    // その日の服用メモがすべてチェックされていない場合、カレンダーマークを削除
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
      final memoStatus = stateManager?.medicationMemoStatus ?? {};
      final addedMeds = stateManager?.addedMedications ?? [];
      final hasCheckedMemos = memoStatus.values.any((status) => status);
      if (!hasCheckedMemos && addedMeds.isEmpty && stateManager != null) {
        final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
        stateManager!.selectedDates.removeWhere((d) => DateFormat('yyyy-MM-dd').format(d) == selectedDateStr);
      }
    }
    
    onSaveAllData();
  }

  /// 服用メモ保存（バックアップ付き）
  Future<void> saveMedicationMemoWithBackup(MedicationMemo memo) async {
    if (stateManager != null && stateManager!.isInitialized) {
      await stateManager!.medicationDataPersistence.saveMedicationMemo(memo);
    }
  }

  /// 服用メモ削除（バックアップ付き）
  Future<void> deleteMedicationMemoWithBackup(String memoId) async {
    if (stateManager != null && stateManager!.isInitialized) {
      await stateManager!.medicationDataPersistence.deleteMedicationMemo(memoId);
    }
  }

  /// 服用メモ読み込み（リトライ付き）
  Future<void> loadMedicationMemosWithRetry({int maxRetries = 3}) async {
    // StateManager.init()で実行済み
    if (stateManager != null && stateManager!.isInitialized) {
      // StateManager経由で管理（同期不要）
    }
  }

  /// バックアップから服用メモ復元
  Future<void> restoreMedicationMemosFromBackup() async {
    debugPrint('⚠️ バックアップ復元はStateManagerで実行済み');
  }

  /// 選択された日付の曜日に基づいて服用メモを取得
  List<MedicationMemo> getMedicationsForSelectedDay() {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null || stateManager == null) return [];
    
    final weekday = selectedDay.weekday % 7; // 0=日曜日, 1=月曜日, ..., 6=土曜日
    final memos = stateManager?.medicationMemos ?? [];
    return memos.where((memo) => memo.selectedWeekdays.contains(weekday)).toList();
  }

  /// 曜日設定された薬の服用状況を取得
  bool getWeekdayMedicationStatus(String memoId) {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final status = stateManager?.weekdayMedicationStatus ?? {};
    return status[dateStr]?[memoId] ?? false;
  }

  /// 曜日設定された薬の服用状況を更新
  void updateWeekdayMedicationStatus(String memoId, bool isTaken) {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    if (stateManager != null) {
      stateManager!.weekdayMedicationStatus.putIfAbsent(dateStr, () => <String, bool>{});
      stateManager!.weekdayMedicationStatus[dateStr]![memoId] = isTaken;
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

  /// 指定日のメモの服用回数別チェック状況を取得
  bool getMedicationMemoDoseStatusForSelectedDay(String memoId, int doseIndex) {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final doseStatus = stateManager?.weekdayMedicationDoseStatus ?? {};
    return doseStatus[dateStr]?[memoId]?[doseIndex] ?? false;
  }

  /// 指定日のメモの服用済み回数を取得
  int getMedicationMemoCheckedCountForSelectedDay(String memoId, [int? index]) {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null) return 0;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final doseStatus = (stateManager?.weekdayMedicationDoseStatus ?? {})[dateStr]?[memoId];
    if (doseStatus == null) return 0;
    if (index != null) {
      return doseStatus[index] == true ? 1 : 0;
    }
    return doseStatus.values.where((isChecked) => isChecked).length;
  }

  /// 薬をタイムスロットに追加
  void addMedicationToTimeSlot(
    String medicationName,
    String Function(List<String>) generateDefaultTitle,
    void Function(String) showLimitDialog,
    void Function(String) showSnackBar,
    void Function() saveCurrentDataDebounced,
  ) {
    // メモ制限チェック
    if (!canAddMemo(stateManager)) {
      showLimitDialog('メモ');
      return;
    }
    
    // 服用メモから薬の詳細情報を取得
    final memos = stateManager?.medicationMemos ?? [];
    final memo = memos.firstWhere(
      (memo) => memo.name == medicationName,
      orElse: () {
        // 空タイトルへの対応: 自動連番を割り当て
        final titles = memos.map((m) => m.name).toList();
        final autoTitle = generateDefaultTitle(titles);
        return MedicationMemo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: medicationName.trim().isEmpty ? autoTitle : medicationName,
          type: '薬',
          color: Colors.blue,
          dosage: '',
          notes: '',
          createdAt: DateTime.now(),
        );
      },
    );
    
    // 新しい薬をリストに追加
    final addedMeds = stateManager?.addedMedications ?? [];
    addedMeds.add({
      'name': memo.name,
      'type': memo.type,
      'color': memo.color,
      'dosage': memo.dosage,
      'notes': memo.notes,
      'isChecked': false,
    });
    stateManager?.addedMedications = List.from(addedMeds);
    
    saveCurrentDataDebounced();
    showSnackBar('$medicationName を服用記録に追加しました');
  }

  /// メモ追加可能かチェック（ヘルパー）
  bool canAddMemo(HomePageStateManager? stateManager) {
    const maxMemos = 500;
    final memos = stateManager?.medicationMemos ?? [];
    return memos.length < maxMemos;
  }
}

