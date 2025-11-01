import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart' show CalendarStyle;
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';

/// カレンダーUIビルダーミックスイン
/// カレンダー関連のUI構築メソッドを提供
mixin CalendarUIBuilderMixin {
  // これらの変数は_MedicationHomePageStateで定義されている前提
  List<MedicationMemo> get medicationMemos;
  Map<String, Map<String, MedicationInfo>> get medicationData;
  Map<String, Color> get dayColors;
  Map<String, int> Function(DateTime) get calculateDayMedicationStats;
  int Function(String, String) get getMedicationMemoCheckedCountForDate;
  
  /// カレンダーの日付セルを構築
  Widget buildCalendarDay(DateTime day, {bool isSelected = false, bool isToday = false}) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    // 服用メモで設定された曜日かチェック
    final hasScheduledMemo = medicationMemos.any((memo) => 
      memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)
    );
    
    // 服用記録が100%かチェック
    final stats = calculateDayMedicationStats(day);
    final total = stats['total'] ?? 0;
    final taken = stats['taken'] ?? 0;
    final isComplete = total > 0 && taken == total;
    
    // カスタム色取得
    final customColor = dayColors[dateStr];
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: customColor ?? 
          (isSelected 
            ? const Color(0xFFff6b6b)
            : isToday 
              ? const Color(0xFF4ecdc4)
              : Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
        border: hasScheduledMemo 
          ? Border.all(color: Colors.amber, width: 2)
          : null,
        boxShadow: isSelected || isToday
          ? [
              BoxShadow(
                color: (customColor ?? (isSelected ? const Color(0xFFff6b6b) : const Color(0xFF4ecdc4))).withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
      ),
      child: Stack(
        children: [
          // 日付
          Center(
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          
          // 曜日マーク（左上）
          if (hasScheduledMemo)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          
          // 完了チェックマーク（右下）
          if (isComplete)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// カレンダースタイルを構築
  /// 注意: CalendarStyleはtable_calendarパッケージから提供されます
  CalendarStyle buildCalendarStyle() {
    return CalendarStyle(
      todayDecoration: BoxDecoration(
        color: const Color(0xFF4ecdc4),
        shape: BoxShape.circle,
      ),
      selectedDecoration: BoxDecoration(
        color: const Color(0xFFff6b6b),
        shape: BoxShape.circle,
      ),
      defaultTextStyle: const TextStyle(color: Colors.white),
      weekendTextStyle: const TextStyle(color: Colors.white),
      holidayTextStyle: const TextStyle(color: Colors.white),
    );
  }
}

