// lib/screens/medication_home/widgets/tabs/calendar_tab_widget.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../controllers/medication_home_controller.dart';
import '../../../controllers/calendar_controller.dart';
import '../../home/widgets/calendar_view.dart';

/// カレンダータブウィジェット
class CalendarTabWidget extends StatelessWidget {
  final MedicationHomeController mainController;
  final CalendarController calendarController;

  const CalendarTabWidget({
    super.key,
    required this.mainController,
    required this.calendarController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: calendarController,
      builder: (context, _) {
        return CalendarView(
          focusedDay: calendarController.focusedDay,
          selectedDay: calendarController.selectedDay,
          selectedDates: calendarController.selectedDates,
          dayColors: calendarController.dayColors,
          medicationMemos: mainController.memos,
          medicationData: mainController.medicationData,
          onDaySelected: (day, focusedDay) {
            calendarController.selectDay(day);
            if (focusedDay != null) {
              calendarController.setFocusedDay(focusedDay);
            }
          },
          onChangeDayColor: (dateKey, color) {
            calendarController.updateDayColor(dateKey, color);
          },
          eventLoader: (day) {
            // イベントリストを返す（カレンダーのマーカー表示用）
            // 空リストを返す（必要に応じて実装）
            return <dynamic>[];
          },
          buildCalendarDay: (date, {required bool isSelected, required bool isToday}) {
            // TODO: カレンダー日のビルダーを実装
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : isToday ? Colors.blue.withOpacity(0.3) : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : isToday ? Colors.blue : Colors.black87,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
          buildCalendarStyle: CalendarStyle(
            defaultDecoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

