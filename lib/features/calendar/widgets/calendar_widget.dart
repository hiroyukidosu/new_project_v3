import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/calendar_controller.dart';

/// カレンダー表示ウィジェット
/// 
/// 責務:
/// - カレンダーの表示
/// - 日付選択の処理
/// - マークの表示
class CalendarWidget extends StatelessWidget {
  final CalendarController controller;
  final Widget Function(DateTime day)? dayBuilder;
  final CalendarStyle? calendarStyle;
  final CalendarBuilders? calendarBuilders;

  const CalendarWidget({
    super.key,
    required this.controller,
    this.dayBuilder,
    this.calendarStyle,
    this.calendarBuilders,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return TableCalendar<dynamic>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: controller.focusedDay,
          selectedDayPredicate: (day) => isSameDay(controller.selectedDay, day),
          calendarFormat: controller.calendarFormat,
          onDaySelected: controller.onDaySelected,
          onPageChanged: controller.onPageChanged,
          onFormatChanged: controller.onFormatChanged,
          calendarStyle: calendarStyle ?? _buildDefaultCalendarStyle(),
          calendarBuilders: calendarBuilders ?? _buildDefaultCalendarBuilders(),
          eventLoader: (day) => controller.events[day] ?? [],
        );
      },
    );
  }

  /// デフォルトのカレンダースタイル
  CalendarStyle _buildDefaultCalendarStyle() {
    return CalendarStyle(
      outsideDaysVisible: false,
      weekendTextStyle: const TextStyle(color: Colors.red),
      holidayTextStyle: const TextStyle(color: Colors.red),
      defaultTextStyle: const TextStyle(fontSize: 16),
      selectedTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      todayTextStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
      selectedDecoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      todayDecoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      defaultDecoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
    );
  }

  /// デフォルトのカレンダービルダー
  CalendarBuilders _buildDefaultCalendarBuilders() {
    return CalendarBuilders(
      defaultBuilder: (context, day, focusedDay) {
        return _buildCalendarDay(day);
      },
      selectedBuilder: (context, day, focusedDay) {
        return _buildCalendarDay(day, isSelected: true);
      },
      todayBuilder: (context, day, focusedDay) {
        return _buildCalendarDay(day, isToday: true);
      },
    );
  }

  /// カレンダーの日付セルを構築
  Widget _buildCalendarDay(DateTime day, {bool isSelected = false, bool isToday = false}) {
    final hasMark = controller.hasMark(day);
    final eventCount = controller.getEventCount(day);
    
    return Container(
      margin: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected 
                ? Colors.white 
                : isToday 
                  ? Colors.blue 
                  : Colors.black,
              fontWeight: isSelected || isToday 
                ? FontWeight.bold 
                : FontWeight.normal,
            ),
          ),
          if (hasMark || eventCount > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasMark)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (eventCount > 0) ...[
                  if (hasMark) const SizedBox(width: 2),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
