import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Local imports
import '../../utils/constants.dart';
import '../../utils/logger.dart';
import '../../utils/error_handler.dart';
import '../../models/medication_memo.dart';
import '../../models/medicine_data.dart';
import '../../models/medication_info.dart';
import '../../services/medication_service.dart';
import '../../services/data_repository.dart';
import '../common_widgets.dart';

class CalendarTab extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Set<DateTime> selectedDates;
  final Map<String, String> calendarMemos;
  final List<Map<String, dynamic>> addedMedications;
  final Map<String, Map<String, MedicationInfo>> medicationData;
  final List<MedicationMemo> medicationMemos;
  final Map<String, Map<String, bool>> weekdayMedicationStatus;
  final Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus;
  final Map<String, bool> medicationMemoStatus;
  final ValueNotifier<String> memoTextNotifier;
  final ValueNotifier<Map<String, Color>> dayColorsNotifier;
  final ScrollController calendarScrollController;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onFocusedDayChanged;
  final Function(String) onMemoChanged;
  final Function() onMemoSaved;
  final Function(MedicationMemo) onMemoTapped;
  final Function(Map<String, dynamic>) onMedicationToggled;
  final Function(String, int) onDoseToggled;

  const CalendarTab({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.selectedDates,
    required this.calendarMemos,
    required this.addedMedications,
    required this.medicationData,
    required this.medicationMemos,
    required this.weekdayMedicationStatus,
    required this.weekdayMedicationDoseStatus,
    required this.medicationMemoStatus,
    required this.memoTextNotifier,
    required this.dayColorsNotifier,
    required this.calendarScrollController,
    required this.onDaySelected,
    required this.onFocusedDayChanged,
    required this.onMemoChanged,
    required this.onMemoSaved,
    required this.onMemoTapped,
    required this.onMedicationToggled,
    required this.onDoseToggled,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();
  bool _isMemoFocused = false;
  Map<String, Color> _dayColors = {};

  @override
  void initState() {
    super.initState();
    _dayColors = widget.dayColorsNotifier.value;
    widget.dayColorsNotifier.addListener(_onDayColorsChanged);
    widget.memoTextNotifier.addListener(_onMemoTextChanged);
  }

  @override
  void dispose() {
    _memoController.dispose();
    _memoFocusNode.dispose();
    widget.dayColorsNotifier.removeListener(_onDayColorsChanged);
    widget.memoTextNotifier.removeListener(_onMemoTextChanged);
    super.dispose();
  }

  void _onDayColorsChanged() {
    setState(() {
      _dayColors = widget.dayColorsNotifier.value;
    });
  }

  void _onMemoTextChanged() {
    _memoController.text = widget.memoTextNotifier.value;
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
            Expanded(
              flex: 1,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) => true,
                child: SingleChildScrollView(
                  controller: widget.calendarScrollController,
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
                              _buildMemoField(),
                            
                            // カレンダー本体
                            _buildCalendar(),
                            
                            const SizedBox(height: 12),
                            
                            // 今日の服用状況表示
                            if (widget.selectedDay != null)
                              _buildMedicationStats(),
                            
                            const SizedBox(height: 8),
                            
                            // 服用記録セクション
                            if (widget.selectedDay != null)
                              _buildMedicationRecords(),
                            
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

  Widget _buildMemoField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          const Text(
            '今日のメモ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _memoController,
            focusNode: _memoFocusNode,
            decoration: const InputDecoration(
              hintText: 'メモを入力してください...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 3,
            onChanged: (value) {
              widget.onMemoChanged(value);
            },
            onSubmitted: (value) {
              widget.onMemoSaved();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) {
        debugPrint('カレンダー: ドラッグ開始');
      },
      onVerticalDragUpdate: (details) {
        final delta = details.delta.dy;
        
        if (delta < -3) { // 上スワイプ
          if (widget.calendarScrollController.hasClients) {
            final maxScroll = widget.calendarScrollController.position.maxScrollExtent;
            final currentScroll = widget.calendarScrollController.offset;
            final targetScroll = (currentScroll + 30).clamp(0.0, maxScroll);
            
            widget.calendarScrollController.animateTo(
              targetScroll,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        } else if (delta > 3) { // 下スワイプ
          if (widget.calendarScrollController.hasClients) {
            final currentScroll = widget.calendarScrollController.offset;
            final targetScroll = (currentScroll - 30).clamp(0.0, double.infinity);
            
            widget.calendarScrollController.animateTo(
              targetScroll,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        }
      },
      child: SizedBox(
        height: 350,
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
                  focusedDay: widget.focusedDay,
                  calendarFormat: CalendarFormat.month,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  locale: 'ja_JP',
                  availableGestures: AvailableGestures.none,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildCalendarDay(day);
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildCalendarDay(day, isSelected: true);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildCalendarDay(day, isToday: true);
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
                  calendarStyle: _buildCalendarStyle(),
                  onDaySelected: (selectedDay, focusedDay) {
                    widget.onDaySelected(selectedDay, focusedDay);
                  },
                  selectedDayPredicate: (day) {
                    return widget.selectedDates.contains(_normalizeDate(day));
                  },
                  onPageChanged: widget.onFocusedDayChanged,
                ),
              ),
              
              // ナビゲーションボタン
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Stack(
      children: [
        // 左移動ボタン
        Positioned(
          top: 12,
          left: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final newFocusedDay = DateTime(widget.focusedDay.year, widget.focusedDay.month - 1);
                widget.onFocusedDayChanged(newFocusedDay);
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
        
        // 右移動ボタン
        Positioned(
          top: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final newFocusedDay = DateTime(widget.focusedDay.year, widget.focusedDay.month + 1);
                widget.onFocusedDayChanged(newFocusedDay);
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
        
        // 色変更ボタン
        Positioned(
          top: 12,
          left: 60,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _changeDayColor,
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
    );
  }

  Widget _buildCalendarDay(DateTime day, {bool isSelected = false, bool isToday = false}) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    // 服用メモで設定された曜日かチェック
    final hasScheduledMemo = widget.medicationMemos.any((memo) => 
      memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)
    );
    
    // 服用記録が100%かチェック
    final stats = _calculateDayMedicationStats(day);
    final total = stats['total'] ?? 0;
    final taken = stats['taken'] ?? 0;
    final isComplete = total > 0 && taken == total;
    
    // カスタム色取得
    final customColor = _dayColors[dateStr];
    
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

  Map<String, int> _calculateDayMedicationStats(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    if (widget.medicationData.containsKey(dateStr)) {
      final dayData = widget.medicationData[dateStr]!;
      totalMedications += dayData.length;
      takenMedications += dayData.values.where((info) => info.checked).length;
    }
    
    // 服用メモの統計
    for (final memo in widget.medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications += memo.dosageFrequency;
        final checkedCount = _getMedicationMemoCheckedCountForDate(memo.id, dateStr);
        takenMedications += checkedCount;
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  int _getMedicationMemoCheckedCountForDate(String memoId, String dateStr) {
    final doseStatus = widget.weekdayMedicationDoseStatus[dateStr]?[memoId];
    if (doseStatus == null) return 0;
    return doseStatus.values.where((isChecked) => isChecked).length;
  }

  CalendarStyle _buildCalendarStyle() {
    return CalendarStyle(
      outsideDaysVisible: false,
      weekendTextStyle: const TextStyle(color: Colors.white),
      holidayTextStyle: const TextStyle(color: Colors.white),
      defaultTextStyle: const TextStyle(color: Colors.white),
      selectedTextStyle: const TextStyle(color: Colors.white),
      todayTextStyle: const TextStyle(color: Colors.white),
      markerDecoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return [];
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _changeDayColor() {
    if (widget.selectedDay == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDay!);
    final colors = [
      {'color': const Color(0xFFff6b6b), 'name': '赤'},
      {'color': const Color(0xFF4ecdc4), 'name': '青緑'},
      {'color': const Color(0xFF45b7d1), 'name': '青'},
      {'color': const Color(0xFFf9ca24), 'name': '黄色'},
      {'color': const Color(0xFFf0932b), 'name': 'オレンジ'},
      {'color': const Color(0xFFeb4d4b), 'name': 'ピンク'},
      {'color': const Color(0xFF6c5ce7), 'name': '紫'},
      {'color': const Color(0xFFa29bfe), 'name': '薄紫'},
      {'color': const Color(0xFF00d2d3), 'name': 'ターコイズ'},
      {'color': const Color(0xFF1e3799), 'name': '濃紺'},
      {'color': const Color(0xFFe55039), 'name': 'トマト'},
      {'color': const Color(0xFF2ecc71), 'name': 'エメラルド'},
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'カレンダーの色を選択',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 13.7,
                childAspectRatio: 1,
              ),
              itemCount: colors.length + 1,
              itemBuilder: (context, index) {
                if (index == colors.length) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _dayColors.remove(dateStr);
                        widget.dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey, width: 2),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.clear, color: Colors.grey, size: 32),
                          SizedBox(height: 4),
                          Text(
                            'リセット',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final colorData = colors[index];
                final color = colorData['color'] as Color;
                final name = colorData['name'] as String;
                final isSelected = _dayColors[dateStr] == color;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _dayColors[dateStr] = color;
                      widget.dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 32,
                          )
                        else
                          const SizedBox(height: 32),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMedicationStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          const Text(
            '今日の服用状況',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '服用記録を確認してください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationRecords() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${DateFormat('yyyy年M月d日', 'ja_JP').format(widget.selectedDay!)}の服用記録',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '今日の服用状況を確認しましょう',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 服用記録リスト
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_getMedicationListLength() == 0)
                  _buildNoMedicationMessage()
                else
                  _buildMedicationList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getMedicationListLength() {
    final addedCount = widget.addedMedications.length;
    final memoCount = _getMedicationsForSelectedDay().length;
    return addedCount + memoCount;
  }

  List<MedicationMemo> _getMedicationsForSelectedDay() {
    if (widget.selectedDay == null) return [];
    
    final weekday = widget.selectedDay!.weekday % 7;
    return widget.medicationMemos.where((memo) => 
      memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)
    ).toList();
  }

  Widget _buildNoMedicationMessage() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '服用メモから服用スケジュール\n(毎日、曜日)を選択してください',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '服用メモタブで薬品やサプリメントを追加してから、\nカレンダーページで服用スケジュールを管理できます。',
            style: const TextStyle(
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList() {
    final medications = _getMedicationsForSelectedDay();
    
    return Column(
      children: medications.map((memo) => _buildMedicationMemoCheckbox(memo)).toList(),
    );
  }

  Widget _buildMedicationMemoCheckbox(MedicationMemo memo) {
    final checkedCount = _getMedicationMemoCheckedCountForDate(memo.id, DateFormat('yyyy-MM-dd').format(widget.selectedDay!));
    final totalCount = memo.dosageFrequency;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checkedCount == totalCount 
              ? Colors.green 
              : Colors.grey.withOpacity(0.3),
          width: checkedCount == totalCount ? 1.5 : 1,
        ),
        color: checkedCount == totalCount 
            ? Colors.green.withOpacity(0.05) 
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(
          value: checkedCount == totalCount,
          onChanged: (value) {
            if (value == true) {
              // すべての服用回数をチェック
              for (int i = 0; i < totalCount; i++) {
                widget.onDoseToggled(memo.id, i);
              }
            } else {
              // すべての服用回数をアンチェック
              for (int i = 0; i < totalCount; i++) {
                widget.onDoseToggled(memo.id, i);
              }
            }
          },
        ),
        title: Text(
          memo.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: checkedCount == totalCount ? Colors.green : Colors.black,
          ),
        ),
        subtitle: Text(
          '${checkedCount}/${totalCount} 回服用済み',
          style: TextStyle(
            color: checkedCount == totalCount ? Colors.green : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          checkedCount == totalCount ? Icons.check_circle : Icons.radio_button_unchecked,
          color: checkedCount == totalCount ? Colors.green : Colors.grey,
        ),
        onTap: () {
          widget.onMemoTapped(memo);
        },
      ),
    );
  }
}
