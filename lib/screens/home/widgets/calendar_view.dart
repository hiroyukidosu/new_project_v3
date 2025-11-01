// lib/screens/home/widgets/calendar_view.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';

/// カレンダー表示専用のウィジェット
class CalendarView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Set<DateTime> selectedDates;
  final Map<String, Color> dayColors;
  final List<MedicationMemo> medicationMemos;
  final Map<String, Map<String, MedicationInfo>> medicationData;
  final ScrollController? scrollController;
  final Function(DateTime, DateTime?) onDaySelected;
  final Function(DateTime) onFocusedDayChanged;
  final Function(String, Color) onChangeDayColor;
  final List Function(DateTime)? eventLoader;
  final Widget Function(DateTime, {bool isSelected, bool isToday}) buildCalendarDay;
  final CalendarStyle buildCalendarStyle;
  final DateTime Function(DateTime, DateTime)? normalizeDate;

  const CalendarView({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    this.selectedDates = const {},
    this.dayColors = const {},
    this.medicationMemos = const [],
    this.medicationData = const {},
    this.scrollController,
    required this.onDaySelected,
    required this.onFocusedDayChanged,
    required this.onChangeDayColor,
    required this.eventLoader,
    required this.buildCalendarDay,
    required this.buildCalendarStyle,
    this.normalizeDate,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2030, 12, 31),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(selectedDay, day);
      },
      eventLoader: eventLoader,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: buildCalendarStyle,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.white70),
        weekendStyle: TextStyle(color: Colors.white70),
      ),
      onDaySelected: onDaySelected,
      onPageChanged: onFocusedDayChanged,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, focusedDay) {
          final isToday = isSameDay(date, DateTime.now());
          final isSelected = isSameDay(date, selectedDay);
          return buildCalendarDay(date, isSelected: isSelected, isToday: isToday);
        },
        todayBuilder: (context, date, focusedDay) {
          final isSelected = isSameDay(date, selectedDay);
          return buildCalendarDay(date, isSelected: isSelected, isToday: true);
        },
        selectedBuilder: (context, date, focusedDay) {
          return buildCalendarDay(date, isSelected: true, isToday: false);
        },
      ),
    );
  }
}
