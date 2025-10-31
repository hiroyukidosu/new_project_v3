// CalendarTab
// カレンダータブ

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';

/// カレンダータブ
/// カレンダーと服用記録を表示
class CalendarTab extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Set<DateTime> selectedDates;
  final ScrollController scrollController;
  final Map<String, Color> dayColors;
  final List<MedicationMemo> medicationMemos;
  final Map<String, Map<String, MedicationInfo>> medicationData;
  final Function(DateTime, DateTime) onDaySelected;
  final Function() onChangeDayColor;
  final List<Widget> Function(DateTime) getEventsForDay;
  final Function(DateTime) normalizeDate;
  final Map<String, int> Function(DateTime) calculateDayMedicationStats;
  final Function(DateTime, {bool isSelected, bool isToday}) buildCalendarDay;
  final CalendarStyle Function() buildCalendarStyle;
  final Widget Function() buildMemoField;
  final Widget Function() buildMedicationStats;
  final Widget Function() buildMedicationRecords;
  final Function(DateTime) onFocusedDayChanged;
  final VoidCallback onStateUpdate;

  const CalendarTab({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.selectedDates,
    required this.scrollController,
    required this.dayColors,
    required this.medicationMemos,
    required this.medicationData,
    required this.onDaySelected,
    required this.onChangeDayColor,
    required this.getEventsForDay,
    required this.normalizeDate,
    required this.calculateDayMedicationStats,
    required this.buildCalendarDay,
    required this.buildCalendarStyle,
    required this.buildMemoField,
    required this.buildMedicationStats,
    required this.buildMedicationRecords,
    required this.onFocusedDayChanged,
    required this.onStateUpdate,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay;
  }

  @override
  void didUpdateWidget(CalendarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedDay != oldWidget.focusedDay) {
      _focusedDay = widget.focusedDay;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 600;
        final isNarrowScreen = screenWidth < 360;
        
        return Column(
          children: [
            // スワイプ可能なカレンダーエリア
            Expanded(
              flex: 1,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  return true;
                },
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isNarrowScreen ? 8 : screenWidth * 0.05,
                          vertical: isSmallScreen ? 4 : 8,
                        ),
                        child: Column(
                          children: [
                            // メモフィールド
                            if (widget.selectedDay != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: EdgeInsets.fromLTRB(
                                  isSmallScreen ? 8 : (isNarrowScreen ? 12 : 16),
                                  0,
                                  isSmallScreen ? 8 : (isNarrowScreen ? 12 : 16),
                                  isSmallScreen ? 8 : (isNarrowScreen ? 12 : 16),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '今日のメモ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    widget.buildMemoField(),
                                  ],
                                ),
                              ),
                            
                            // カレンダー本体（スワイプ検出を改善）
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragStart: (_) {
                                debugPrint('カレンダー: ドラッグ開始');
                              },
                              onVerticalDragUpdate: (details) {
                                final delta = details.delta.dy;
                                
                                if (delta < -3) {
                                  if (widget.scrollController.hasClients) {
                                    final maxScroll = widget.scrollController.position.maxScrollExtent;
                                    final currentScroll = widget.scrollController.offset;
                                    final targetScroll = (currentScroll + 30).clamp(0.0, maxScroll);
                                    
                                    widget.scrollController.animateTo(
                                      targetScroll,
                                      duration: const Duration(milliseconds: 100),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                } else if (delta > 3) {
                                  if (widget.scrollController.hasClients) {
                                    final currentScroll = widget.scrollController.offset;
                                    final targetScroll = (currentScroll - 30).clamp(0.0, double.infinity);
                                    
                                    widget.scrollController.animateTo(
                                      targetScroll,
                                      duration: const Duration(milliseconds: 100),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                }
                              },
                              onVerticalDragEnd: (details) {
                                final velocity = details.primaryVelocity ?? 0;
                                
                                if (!widget.scrollController.hasClients) return;
                                
                                if (velocity < -300) {
                                  widget.scrollController.animateTo(
                                    widget.scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                } else if (velocity > 300) {
                                  widget.scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              child: SizedBox(
                                height: 400,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF667eea).withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // カレンダー本体
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: TableCalendar<dynamic>(
                                          firstDay: DateTime.utc(2020, 1, 1),
                                          lastDay: DateTime.utc(2030, 12, 31),
                                          focusedDay: _focusedDay,
                                          calendarFormat: CalendarFormat.month,
                                          eventLoader: widget.getEventsForDay,
                                          startingDayOfWeek: StartingDayOfWeek.monday,
                                          locale: 'ja_JP',
                                          availableGestures: AvailableGestures.none,
                                          calendarBuilders: CalendarBuilders(
                                            defaultBuilder: (context, day, focusedDay) {
                                              return widget.buildCalendarDay(day);
                                            },
                                            selectedBuilder: (context, day, focusedDay) {
                                              return widget.buildCalendarDay(day, isSelected: true);
                                            },
                                            todayBuilder: (context, day, focusedDay) {
                                              return widget.buildCalendarDay(day, isToday: true);
                                            },
                                          ),
                                          headerStyle: HeaderStyle(
                                            formatButtonVisible: false,
                                            titleCentered: true,
                                            titleTextStyle: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                                            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0xFF667eea),
                                                  Color(0xFF764ba2),
                                                ],
                                              ),
                                            ),
                                          ),
                                          daysOfWeekStyle: const DaysOfWeekStyle(
                                            weekdayStyle: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                            weekendStyle: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          calendarStyle: widget.buildCalendarStyle(),
                                          onDaySelected: widget.onDaySelected,
                                          selectedDayPredicate: (day) {
                                            return widget.selectedDates.contains(widget.normalizeDate(day));
                                          },
                                          onPageChanged: (focusedDay) {
                                            setState(() {
                                              _focusedDay = focusedDay;
                                            });
                                            widget.onFocusedDayChanged(focusedDay);
                                          },
                                        ),
                                      ),
                                      
                                      // 左上：左移動ボタン
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                                              });
                                              widget.onFocusedDayChanged(_focusedDay);
                                              widget.onStateUpdate();
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.9),
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.arrow_back,
                                                color: Colors.blue,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // 右上：右移動ボタン
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                                              });
                                              widget.onFocusedDayChanged(_focusedDay);
                                              widget.onStateUpdate();
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.9),
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward,
                                                color: Colors.blue,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // 左矢印アイコンの右側：色変更アイコン
                                      Positioned(
                                        top: 12,
                                        left: 60,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: widget.onChangeDayColor,
                                            borderRadius: BorderRadius.circular(15),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.9),
                                                borderRadius: BorderRadius.circular(15),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.palette,
                                                color: Colors.purple,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // 今日の服用状況表示
                            if (widget.selectedDay != null)
                              widget.buildMedicationStats(),
                            
                            const SizedBox(height: 8),
                            
                            // 服用記録セクション
                            if (widget.selectedDay != null)
                              widget.buildMedicationRecords(),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

