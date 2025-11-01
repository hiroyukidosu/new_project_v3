// lib/screens/home/business/calendar_marker_manager.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';
import '../../helpers/calculations/medication_stats_calculator.dart';

/// カレンダーマーカーの管理を行うクラス
class CalendarMarkerManager {
  final Map<String, Map<String, MedicationInfo>> medicationData;
  final List<MedicationMemo> medicationMemos;
  final Map<String, bool> medicationMemoStatus;
  final int Function(String, String) getMedicationMemoCheckedCountForDate;

  CalendarMarkerManager({
    required this.medicationData,
    required this.medicationMemos,
    required this.medicationMemoStatus,
    required this.getMedicationMemoCheckedCountForDate,
  });

  /// 指定日のイベントリストを取得
  List<Widget> getEventsForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final events = <Widget>[];
    
    // 動的に追加された薬のイベント
    if (medicationData.containsKey(dateStr)) {
      final dayData = medicationData[dateStr]!;
      for (final info in dayData.values) {
        if (info.checked) {
          events.add(
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          );
        }
      }
    }
    
    // 服用メモのイベント
    final weekday = day.weekday % 7;
    for (final memo in medicationMemos) {
      if (memo.selectedWeekdays.contains(weekday)) {
        final checkedCount = getMedicationMemoCheckedCountForDate(memo.id, dateStr);
        final totalCount = memo.dosageFrequency;
        
        if (checkedCount == totalCount) {
          events.add(
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          );
        } else if (checkedCount > 0) {
          events.add(
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          );
        }
      }
    }
    
    return events;
  }

  /// カレンダーマークを更新
  void updateCalendarMarks(DateTime day, Function(DateTime) onUpdate) {
    try {
      // マークの更新処理
      onUpdate(day);
    } catch (e) {
      // エラー処理
    }
  }

  /// 指定日の統計を計算
  Map<String, int> calculateDayStats(DateTime day) {
    return MedicationStatsCalculator.calculateDayMedicationStats(
      day: day,
      medicationData: medicationData,
      medicationMemos: medicationMemos,
      getMedicationMemoCheckedCountForDate: getMedicationMemoCheckedCountForDate,
    );
  }
}

