import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/app_dimensions.dart';
import '../utils/logger.dart';

// カレンダータブの分離
class CalendarTab extends StatefulWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final Set<DateTime> selectedDates;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Map<DateTime, List<dynamic>> events;
  final Map<DateTime, Color> dayColors;

  const CalendarTab({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.selectedDates,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.events,
    required this.dayColors,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier(_getEventsForDay(widget.selectedDay));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return widget.events[day] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(widget.selectedDay, selectedDay)) {
      setState(() {
        widget.onDaySelected(selectedDay, focusedDay);
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: AppDimensions.cardMargin,
          child: TableCalendar<dynamic>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: widget.focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
              ),
              formatButtonTextStyle: const TextStyle(
                color: Colors.white,
              ),
            ),
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            rangeSelectionMode: _rangeSelectionMode,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: widget.onPageChanged,
            selectedDayPredicate: (day) {
              return widget.selectedDates.contains(day);
            },
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 1,
                  child: _buildEventsMarker(day, events),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.mediumSpacing),
        Expanded(
          child: ValueListenableBuilder<List<dynamic>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              return ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.mediumSpacing,
                      vertical: AppDimensions.smallSpacing,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(AppDimensions.smallBorderRadius),
                    ),
                    child: ListTile(
                      onTap: () => Logger.debug('イベントタップ: ${value[index]}'),
                      title: Text(value[index].toString()),
                      leading: const Icon(Icons.event),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventsMarker(DateTime day, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
