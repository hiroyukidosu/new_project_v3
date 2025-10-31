// メディケーション管理機能のMixin
// home_page.dartからメディケーション管理関連の機能を分離

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../services/medication_service.dart';

/// メディケーション管理機能のMixin
/// このmixinを使用するクラスは、必要な状態変数とメソッドを提供する必要があります
mixin HomePageMedicationMixin<T extends StatefulWidget> on State<T> {
  // 抽象ゲッター/セッター（実装クラスで提供する必要がある）
  DateTime? get selectedDay;
  Set<DateTime> get selectedDates;
  List<Map<String, dynamic>> get addedMedications;
  List<MedicationMemo> get medicationMemos;
  Map<String, bool> get medicationMemoStatus;
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus;
  
  void addToAddedMedications(Map<String, dynamic> medication);
  void removeFromAddedMedications(String memoId);
  void clearAddedMedications();
  void setMedicationMemoStatusValue(String id, bool value);
  void addSelectedDate(DateTime date);
  void removeSelectedDate(String dateStr);
  
  // 抽象メソッド（実装クラスで提供する必要がある）
  Future<void> saveAllData();
  Future<void> saveToSharedPreferences(String dateStr, Map<String, dynamic> data);
  Future<void> saveMemoStatus();
  Future<void> saveAdditionalBackup(String dateStr, Map<String, dynamic> data);
  Future<void> saveMedicationList();
  Future<void> saveAlarmData();
  int getMedicationMemoDoseStatusForSelectedDay(String memoId, int doseIndex);
  int getMedicationMemoCheckedCountForSelectedDay(String memoId);
  
  // 服用済みに追加（簡素化版）
  void addToTakenMedications(MedicationMemo memo) {
    if (selectedDay == null) return;
    
    // 重複チェック
    final existingIndex = addedMedications.indexWhere((med) => med['id'] == memo.id);
    
    if (existingIndex == -1) {
      // 新規追加
      addToAddedMedications({
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
      addedMedications[existingIndex]['taken'] = true;
      addedMedications[existingIndex]['takenTime'] = DateTime.now();
    }
    
    // メモの状態を更新
    setMedicationMemoStatusValue(memo.id, true);
    
    // カレンダーマークを追加（服用状況に反映）
    if (selectedDay != null) {
      final normalizedDay = DateTime.utc(
        selectedDay!.year,
        selectedDay!.month,
        selectedDay!.day,
      );
      if (!selectedDates.contains(normalizedDay)) {
        addSelectedDate(normalizedDay);
      }
    }
    
    // データ保存のみ
    saveAllData();
  }
  
  // 服用済みから削除（簡素化版）
  void removeFromTakenMedications(String memoId) {
    removeFromAddedMedications(memoId);
    
    // その日の服用メモがすべてチェックされていない場合、カレンダーマークを削除
    if (selectedDay != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
      final hasCheckedMemos = medicationMemoStatus.values.any((status) => status);
      if (!hasCheckedMemos && addedMedications.isEmpty) {
        removeSelectedDate(dateStr);
      }
    }
    
    // データ保存のみ
    saveAllData();
  }
  
  // 服用メモの状態を更新
  void updateMedicationMemoStatus(String memoId, bool isChecked) {
    setState(() {
      setMedicationMemoStatusValue(memoId, isChecked);
    });
    // データ保存
    saveAllData();
  }
  
  // 選択された日付の服用メモを取得
  List<MedicationMemo> getMedicationsForSelectedDay() {
    if (selectedDay == null) return [];
    
    final weekday = selectedDay!.weekday % 7;
    return medicationMemos.where((memo) {
      // 曜日が設定されているか、または常時服用の場合
      return memo.selectedWeekdays.isEmpty || memo.selectedWeekdays.contains(weekday);
    }).toList();
  }
  
  // 服用データを保存（確実なデータ保持）
  Future<void> saveMedicationData() async {
    try {
      if (selectedDay == null) return;
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
      final medicationData = <String, dynamic>{};
      
      // _addedMedicationsからMedicationInfoを作成
      for (final med in addedMedications) {
        final name = med['name']?.toString() ?? '';
        final taken = med['taken'] is bool ? med['taken'] as bool : false;
        final takenTime = med['takenTime'] is DateTime ? med['takenTime'] as DateTime? : null;
        final notes = med['notes']?.toString() ?? '';
        
        medicationData[name] = {
          'checked': taken,
          'medicine': name,
          'actualTime': takenTime?.toIso8601String(),
          'notes': notes,
        };
      }
      
      // awaitを確実に付けて保存
      await MedicationService.saveMedicationData({dateStr: medicationData});
      await saveToSharedPreferences(dateStr, medicationData);
      await saveMemoStatus();
      await saveAdditionalBackup(dateStr, medicationData);
      
      // 服用薬データも保存
      await saveMedicationList();
      
      // アラームデータも保存
      await saveAlarmData();
      
      debugPrint('全データ保存完了: $dateStr');
    } catch (e) {
      debugPrint('服用データ保存エラー: $e');
    }
  }
  
  // 服用回数別のチェック状況を更新
  Future<void> updateMedicationDoseStatus(
    String memoId,
    int doseIndex,
    bool isChecked,
  ) async {
    if (selectedDay == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
    
    // データ構造を準備
    if (!weekdayMedicationDoseStatus.containsKey(dateStr)) {
      weekdayMedicationDoseStatus[dateStr] = {};
    }
    if (!weekdayMedicationDoseStatus[dateStr]!.containsKey(memoId)) {
      weekdayMedicationDoseStatus[dateStr]![memoId] = {};
    }
    
    // 状態を更新
    weekdayMedicationDoseStatus[dateStr]![memoId]![doseIndex] = isChecked;
    
    // すべての回数がチェックされたか確認
    final memo = medicationMemos.firstWhere((m) => m.id == memoId);
    final totalCount = memo.dosageFrequency;
    final checkedCount = weekdayMedicationDoseStatus[dateStr]![memoId]!.values
        .where((checked) => checked)
        .length;
    
    // すべてチェックされた場合は、メモの状態も更新
    if (checkedCount == totalCount) {
      setMedicationMemoStatusValue(memoId, true);
    } else {
      setMedicationMemoStatusValue(memoId, false);
    }
    
    // データ保存
    await saveAllData();
  }
  
  // 指定日のメモの服用回数別チェック状況を取得
  bool getMedicationMemoDoseStatus(String memoId, int doseIndex) {
    if (selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
    return weekdayMedicationDoseStatus[dateStr]?[memoId]?[doseIndex] ?? false;
  }
  
  // 指定日のメモの服用済み回数を取得
  int getMedicationMemoCheckedCount(String memoId) {
    if (selectedDay == null) return 0;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
    final doseStatus = weekdayMedicationDoseStatus[dateStr]?[memoId];
    if (doseStatus == null) return 0;
    return doseStatus.values.where((isChecked) => isChecked).length;
  }
}

