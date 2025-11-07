// lib/screens/helpers/calendar_operations.dart
// カレンダー・統計関連の機能を集約

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../services/medication_service.dart';
import '../home/state/home_page_state_manager.dart';
import 'calculations/adherence_calculator.dart';

/// カレンダー・統計操作を管理するクラス
/// home_page.dartからカレンダー・統計関連メソッドを移動
class CalendarOperations {
  final HomePageStateManager? stateManager;
  final bool Function() onMountedCheck;
  final void Function() onStateChanged;

  CalendarOperations({
    required this.stateManager,
    required this.onMountedCheck,
    required this.onStateChanged,
  });

  /// カレンダーマーク更新
  void updateCalendarMarks() {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null || stateManager == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    
    // 服用メモのチェック状態を確認
    final memoStatus = stateManager!.medicationMemoStatus;
    final hasCheckedMemos = memoStatus.values.any((status) => status);
    
    // 追加された薬のチェック状態を確認
    final addedMeds = stateManager!.addedMedications;
    final hasCheckedMeds = addedMeds.any((med) => med['taken'] == true);
    
    // 服用済みのメモまたは薬がある場合、カレンダーマークを追加
    if (hasCheckedMemos || hasCheckedMeds) {
      if (!stateManager!.selectedDates.contains(normalizedDay)) {
        stateManager!.selectedDates.add(normalizedDay);
      }
    } else {
      // 服用済みがない場合、その日のマークを削除
      final dateStrFormatted = DateFormat('yyyy-MM-dd').format(selectedDay);
      stateManager!.selectedDates.removeWhere((d) {
        final dStr = DateFormat('yyyy-MM-dd').format(d);
        return dStr == dateStrFormatted;
      });
    }
    
    // UI更新
    if (onMountedCheck()) {
      onStateChanged();
    }
  }

  /// 遵守率統計を計算（StateManagerも更新）
  Future<void> calculateAdherenceStats() async {
    try {
      final stats = <String, double>{};
      final medicationData = stateManager?.medicationData ?? {};
      final medicationMemos = stateManager?.medicationMemos ?? [];
      final weekdayStatus = stateManager?.weekdayMedicationStatus ?? {};
      final memoStatus = stateManager?.medicationMemoStatus ?? {};
      
      for (final period in [7, 30, 90]) {
        final rate = AdherenceCalculator.calculateCustomAdherence(
          days: period,
          medicationData: medicationData,
          medicationMemos: medicationMemos,
          weekdayMedicationStatus: weekdayStatus,
          medicationMemoStatus: memoStatus,
          getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
            final doseStatus = (stateManager?.weekdayMedicationDoseStatus ?? {})[dateStr]?[memoId];
            if (doseStatus == null) return 0;
            return doseStatus.values.where((isChecked) => isChecked).length;
          },
        );
        stats['$period日間'] = rate;
      }
      
      if (stateManager != null) {
        stateManager!.adherenceRates = Map.from(stats);
        stateManager!.notifiers.adherenceRatesNotifier.value = Map.from(stats);
      }
      
      await MedicationService.saveAdherenceStats(stats);
      
      if (onMountedCheck()) {
        onStateChanged();
      }
    } catch (e) {
      debugPrint('❌ 遵守率統計計算エラー: $e');
    }
  }

  /// 軽量化された統計計算メソッド
  Map<String, int> calculateMedicationStats() {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null) return {'total': 0, 'taken': 0};
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    final addedMeds = stateManager?.addedMedications ?? [];
    totalMedications += addedMeds.length;
    takenMedications += addedMeds.where((med) => med['isChecked'] == true).length;
    
    // 服用メモの統計（軽量化）
    final weekday = selectedDay.weekday % 7;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final memos = stateManager?.medicationMemos ?? [];
    final status = stateManager?.medicationMemoStatus ?? {};
    
    for (final memo in memos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications++;
        if (status[memo.id] == true) {
          takenMedications++;
        }
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  /// 日付正規化
  DateTime normalizeDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  /// カレンダーイベント取得
  List<Widget> getEventsForDay(DateTime day) {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final weekday = day.weekday % 7;
      
      bool hasMedications = false;
      bool allTaken = true;
      int takenCount = 0;
      int totalCount = 0;
      
      // 動的薬リストのチェック
      final addedMeds = stateManager?.addedMedications ?? [];
      if (addedMeds.isNotEmpty) {
        hasMedications = true;
        totalCount += addedMeds.length;
        for (final medication in addedMeds) {
          if (medication['isChecked'] == true) {
            takenCount++;
          } else {
            allTaken = false;
          }
        }
      }
      
      // 服用メモのチェック
      final memos = stateManager?.medicationMemos ?? [];
      final memoStatus = stateManager?.medicationMemoStatus ?? {};
      for (final memo in memos) {
        if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
          hasMedications = true;
          totalCount++;
          if (memoStatus[memo.id] == true) {
            takenCount++;
          } else {
            allTaken = false;
          }
        }
      }
      
      // イベントウィジェット生成（簡略化版）
      if (!hasMedications) {
        return [];
      }
      
      return [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: allTaken ? Colors.green : Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
      ];
    } catch (e) {
      debugPrint('❌ カレンダーイベント取得エラー: $e');
      return [];
    }
  }
}

