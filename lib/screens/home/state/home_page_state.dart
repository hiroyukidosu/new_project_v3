// lib/screens/home/state/home_page_state.dart

import 'package:flutter/material.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';

/// ホームページの状態を管理するクラス
class HomePageState {
  // カレンダー関連
  DateTime focusedDay;
  DateTime? selectedDay;
  Set<DateTime> selectedDates;
  Map<String, Color> dayColors;
  
  // メディケーション関連
  List<MedicationMemo> medicationMemos;
  Map<String, bool> medicationMemoStatus;
  Map<String, Map<String, bool>> weekdayMedicationStatus;
  Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus;
  List<Map<String, dynamic>> addedMedications;
  Map<String, Map<String, MedicationInfo>> medicationData;
  
  // アラーム関連
  List<Map<String, dynamic>> alarmList;
  
  // UI状態
  bool isMemoSelected;
  MedicationMemo? selectedMemo;
  String memoText;
  
  // 統計関連
  Map<String, double> adherenceRates;
  double? customAdherenceResult;
  int? customDaysResult;
  
  // タブ関連
  int currentTabIndex;

  HomePageState({
    required this.focusedDay,
    this.selectedDay,
    this.selectedDates = const {},
    this.dayColors = const {},
    this.medicationMemos = const [],
    this.medicationMemoStatus = const {},
    this.weekdayMedicationStatus = const {},
    this.weekdayMedicationDoseStatus = const {},
    this.addedMedications = const [],
    this.medicationData = const {},
    this.alarmList = const [],
    this.isMemoSelected = false,
    this.selectedMemo,
    this.memoText = '',
    this.adherenceRates = const {},
    this.customAdherenceResult,
    this.customDaysResult,
    this.currentTabIndex = 0,
  });

  /// 状態のコピーを作成
  HomePageState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    Set<DateTime> selectedDates,
    Map<String, Color>? dayColors,
    List<MedicationMemo>? medicationMemos,
    Map<String, bool>? medicationMemoStatus,
    Map<String, Map<String, bool>>? weekdayMedicationStatus,
    Map<String, Map<String, Map<int, bool>>>? weekdayMedicationDoseStatus,
    List<Map<String, dynamic>>? addedMedications,
    Map<String, Map<String, MedicationInfo>>? medicationData,
    List<Map<String, dynamic>>? alarmList,
    bool? isMemoSelected,
    MedicationMemo? selectedMemo,
    String? memoText,
    Map<String, double>? adherenceRates,
    double? customAdherenceResult,
    int? customDaysResult,
    int? currentTabIndex,
  }) {
    return HomePageState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedDates: selectedDates ?? this.selectedDates,
      dayColors: dayColors ?? this.dayColors,
      medicationMemos: medicationMemos ?? this.medicationMemos,
      medicationMemoStatus: medicationMemoStatus ?? this.medicationMemoStatus,
      weekdayMedicationStatus: weekdayMedicationStatus ?? this.weekdayMedicationStatus,
      weekdayMedicationDoseStatus: weekdayMedicationDoseStatus ?? this.weekdayMedicationDoseStatus,
      addedMedications: addedMedications ?? this.addedMedications,
      medicationData: medicationData ?? this.medicationData,
      alarmList: alarmList ?? this.alarmList,
      isMemoSelected: isMemoSelected ?? this.isMemoSelected,
      selectedMemo: selectedMemo ?? this.selectedMemo,
      memoText: memoText ?? this.memoText,
      adherenceRates: adherenceRates ?? this.adherenceRates,
      customAdherenceResult: customAdherenceResult ?? this.customAdherenceResult,
      customDaysResult: customDaysResult ?? this.customDaysResult,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
    );
  }
}

