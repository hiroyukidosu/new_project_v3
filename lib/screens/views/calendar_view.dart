// CalendarView
// カレンダータブ - 完全独立化（StateManagerに直接依存）

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';
import '../home/state/home_page_state_manager.dart';
import '../helpers/calculations/medication_stats_calculator.dart';
import '../home/widgets/day_memo_field_widget.dart';
import '../home/widgets/day_medication_records_widget.dart';
import '../home/widgets/day_color_picker_dialog.dart';
import '../../services/trial_service.dart';
import '../../widgets/trial_limit_dialog.dart';
import '../home/widgets/medication_item_widgets.dart';

/// カレンダービュー
/// StateManagerに完全依存し、コールバック関数は不要
class CalendarView extends StatefulWidget {
  final HomePageStateManager stateManager;
  final void Function(MedicationMemo)? onEditMemo;
  final void Function(String)? onDeleteMemo;
  final void Function(String, String)? onShowMemoDetailDialog;
  final void Function()? onShowWarningDialog;

  const CalendarView({
    super.key,
    required this.stateManager,
    this.onEditMemo,
    this.onDeleteMemo,
    this.onShowMemoDetailDialog,
    this.onShowWarningDialog,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.stateManager.focusedDay;
  }

  /// 日付の正規化（UTC時刻に変換）
  DateTime _normalizeDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  /// 日付選択処理
  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    try {
      // トライアル制限チェック（当日以外の選択時）
      final isExpired = await TrialService.isTrialExpired();
      final today = DateTime.now();
      final isToday = selectedDay.year == today.year && 
                      selectedDay.month == today.month && 
                      selectedDay.day == today.day;
      
      if (isExpired && !isToday) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => TrialLimitDialog(featureName: 'カレンダー'),
        );
        return;
      }
      
      final normalizedDay = _normalizeDate(selectedDay);
      final wasSelected = widget.stateManager.selectedDates.contains(normalizedDay);
      
      // StateManagerを更新
      if (wasSelected) {
        widget.stateManager.selectedDates.remove(normalizedDay);
        widget.stateManager.selectedDay = null;
        widget.stateManager.addedMedications.clear();
      } else {
        widget.stateManager.selectedDates.add(normalizedDay);
        widget.stateManager.selectedDay = normalizedDay;
        widget.stateManager.addedMedications.clear();
      }
      widget.stateManager.focusedDay = focusedDay;
      widget.stateManager.notifiers.selectedDayNotifier.value = widget.stateManager.selectedDay;
      widget.stateManager.notifiers.focusedDayNotifier.value = widget.stateManager.focusedDay;
      
      setState(() {
        _focusedDay = focusedDay;
      });
      
      // データ読み込み（必要に応じて）
      if (!wasSelected && widget.stateManager.selectedDay != null) {
        await _loadDataForSelectedDay();
      }
      
      // メモスナップショット保存フラグをリセット
      widget.stateManager.memoSnapshotSaved = false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('日付の選択に失敗しました: $e')),
        );
      }
    }
  }

  /// 選択日のデータ読み込み
  Future<void> _loadDataForSelectedDay() async {
    // StateManager.init()で既に読み込まれているため、必要に応じて追加処理を実装
  }

  /// 日付の色変更
  Future<void> _changeDayColor() async {
    final selectedDay = widget.stateManager.selectedDay;
    if (selectedDay == null || !mounted) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    
    DayColorPickerDialog.show(
      context,
      dateKey: dateStr,
      onColorSelected: (key, color) async {
        await widget.stateManager.snapshotPersistence.saveSnapshotBeforeChange(
          '日付色変更_$key',
          () => widget.stateManager.backupHandler.createBackupData('変更前_日付色変更_$key'),
        );
      widget.stateManager.dayColors[key] = color;
      widget.stateManager.notifiers.dayColorsNotifier.value = Map<String, Color>.from(widget.stateManager.dayColors);
      await widget.stateManager.saveAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('色を設定しました')),
          );
        }
      },
      onColorRemoved: (key) async {
        await widget.stateManager.snapshotPersistence.saveSnapshotBeforeChange(
          '日付色リセット_$key',
          () => widget.stateManager.backupHandler.createBackupData('変更前_日付色リセット_$key'),
        );
        widget.stateManager.dayColors.remove(key);
        widget.stateManager.notifiers.dayColorsNotifier.value = Map<String, Color>.from(widget.stateManager.dayColors);
        await widget.stateManager.saveAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('色を削除しました')),
          );
        }
      },
    );
  }

  // 注意: _saveDayColors()は削除（StateManager.saveAllData()で実行済み）

  /// カレンダーの日付セルを構築
  Widget _buildCalendarDay(DateTime day, {bool isSelected = false, bool isToday = false}) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    // 服用メモで設定された曜日かチェック
    final hasScheduledMemo = widget.stateManager.medicationMemos.any((memo) => 
      memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)
    );
    
    // 服用記録が100%かチェック
    final stats = MedicationStatsCalculator.calculateDayMedicationStats(
      day: day,
      medicationData: widget.stateManager.medicationData,
      medicationMemos: widget.stateManager.medicationMemos,
      getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
        final doseStatus = widget.stateManager.weekdayMedicationDoseStatus[dateStr]?[memoId];
        if (doseStatus == null) return 0;
        return doseStatus.values.where((isChecked) => isChecked).length;
      },
    );
    final total = stats['total'] ?? 0;
    final taken = stats['taken'] ?? 0;
    final isComplete = total > 0 && taken == total;
    
    // カスタム色取得
    final customColor = widget.stateManager.dayColors[dateStr];
    
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
  CalendarStyle _buildCalendarStyle() {
    return CalendarStyle(
      outsideDaysVisible: false,
      cellMargin: const EdgeInsets.all(2),
      cellPadding: const EdgeInsets.all(4),
      cellAlignment: Alignment.center,
      defaultTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      selectedTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      todayTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      weekendTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      defaultDecoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      selectedDecoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFff6b6b),
            Color(0xFFee5a24),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff6b6b).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      todayDecoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4ecdc4),
            Color(0xFF44a08d),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ecdc4).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      markersMaxCount: 1,
      markerDecoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  /// 服用統計を構築
  Widget _buildMedicationStats() {
    final selectedDay = widget.stateManager.selectedDay;
    if (selectedDay == null) return const SizedBox.shrink();
    
    final stats = MedicationStatsCalculator.calculateDayMedicationStats(
      day: selectedDay,
      medicationData: widget.stateManager.medicationData,
      medicationMemos: widget.stateManager.medicationMemos,
      getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
        final doseStatus = widget.stateManager.weekdayMedicationDoseStatus[dateStr]?[memoId];
        if (doseStatus == null) return 0;
        return doseStatus.values.where((isChecked) => isChecked).length;
      },
    );
    final total = stats['total'] ?? 0;
    final taken = stats['taken'] ?? 0;
    
    return MedicationStatsCardSimple(
      total: total,
      taken: taken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 600;
        final isNarrowScreen = screenWidth < 360;
        
        return ValueListenableBuilder<DateTime?>(
          valueListenable: widget.stateManager.notifiers.selectedDayNotifier,
          builder: (context, selectedDay, _) {
            return SingleChildScrollView(
              controller: widget.stateManager.calendarScrollController,
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrowScreen ? 8 : screenWidth * 0.05,
                  vertical: isSmallScreen ? 4 : 8,
                ),
                child: Column(
                  children: [
                    // メモフィールド
                    if (selectedDay != null)
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
                        child: ValueListenableBuilder<String>(
                          valueListenable: widget.stateManager.notifiers.memoTextNotifier,
                          builder: (context, memoText, _) {
                            return DayMemoFieldWidget(
                              selectedDay: selectedDay,
                              initialMemoText: widget.stateManager.memoController.text,
                              memoTextNotifier: widget.stateManager.notifiers.memoTextNotifier,
                              isMemoFocused: widget.stateManager.isMemoFocused,
                              onMemoChanged: (value) {
                                // デバウンス処理はStateManager内で管理
                                widget.stateManager.notifiers.memoTextNotifier.value = value;
                                widget.stateManager.memoController.text = value;
                              },
                              onMemoUnfocused: () {},
                              onMemoSaved: () async {
                                await widget.stateManager.saveAllData();
                              },
                              onMemoCleared: () async {
                                widget.stateManager.memoController.clear();
                                widget.stateManager.notifiers.memoTextNotifier.value = '';
                                widget.stateManager.isMemoFocused = false;
                                await widget.stateManager.saveAllData();
                                if (mounted) {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                              onMemoFocused: () async {
                                final isExpired = await TrialService.isTrialExpired();
                                if (isExpired) {
                                  if (!mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (context) => TrialLimitDialog(featureName: 'メモ'),
                                  );
                                  FocusScope.of(context).unfocus();
                                  return;
                                }
                                widget.stateManager.isMemoFocused = true;
                              },
                            );
                          },
                        ),
                      ),
                    
                    // カレンダー本体
                    SizedBox(
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
                                eventLoader: (day) => [],
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
                                onDaySelected: _onDaySelected,
                                selectedDayPredicate: (day) {
                                  return widget.stateManager.selectedDates.contains(_normalizeDate(day));
                                },
                                onPageChanged: (focusedDay) {
                                  setState(() {
                                    _focusedDay = focusedDay;
                                  });
                                  widget.stateManager.focusedDay = focusedDay;
                                  widget.stateManager.notifiers.focusedDayNotifier.value = focusedDay;
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
                                    widget.stateManager.focusedDay = _focusedDay;
                                    widget.stateManager.notifiers.focusedDayNotifier.value = _focusedDay;
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
                                    widget.stateManager.focusedDay = _focusedDay;
                                    widget.stateManager.notifiers.focusedDayNotifier.value = _focusedDay;
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
                            if (selectedDay != null)
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
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 今日の服用状況表示
                    if (selectedDay != null) _buildMedicationStats(),
                    
                    const SizedBox(height: 8),
                    
                    // 服用記録セクション
                    if (selectedDay != null)
                      DayMedicationRecordsWidget(
                        selectedDay: selectedDay,
                        medicationMemos: widget.stateManager.medicationMemos
                            .where((memo) {
                              final weekday = selectedDay.weekday % 7;
                              return memo.selectedWeekdays.isNotEmpty && 
                                     memo.selectedWeekdays.contains(weekday);
                            })
                            .toList(),
                        addedMedications: widget.stateManager.addedMedications,
                        weekdayMedicationDoseStatus: widget.stateManager.weekdayMedicationDoseStatus,
                        isMemoSelected: widget.stateManager.isMemoSelected,
                        selectedMemo: widget.stateManager.selectedMemo,
                        onMemoTap: (memo) {
                          setState(() {
                            widget.stateManager.isMemoSelected = true;
                            widget.stateManager.selectedMemo = memo;
                          });
                        },
                        onBackTap: () {
                          setState(() {
                            widget.stateManager.isMemoSelected = false;
                            widget.stateManager.selectedMemo = null;
                          });
                        },
                        onDoseStatusChanged: (memoId, doseIndex, isChecked) async {
                          if (selectedDay != null) {
                            final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
                            await widget.stateManager.snapshotPersistence.saveSnapshotBeforeChange(
                              '服用回数チェック_${widget.stateManager.medicationMemos.firstWhere((m) => m.id == memoId).name}_${doseIndex + 1}回目_$dateStr',
                              () => widget.stateManager.backupHandler.createBackupData('変更前_服用回数チェック'),
                            );
                            widget.stateManager.weekdayMedicationStatus.putIfAbsent(dateStr, () => {});
                            widget.stateManager.weekdayMedicationDoseStatus.putIfAbsent(dateStr, () => {});
                            widget.stateManager.weekdayMedicationDoseStatus[dateStr]!.putIfAbsent(memoId, () => {});
                            widget.stateManager.weekdayMedicationDoseStatus[dateStr]![memoId]![doseIndex] = isChecked;
                            
                            final memo = widget.stateManager.medicationMemos.firstWhere((m) => m.id == memoId);
                            final checkedCount = widget.stateManager.weekdayMedicationDoseStatus[dateStr]?[memoId]?.values.where((checked) => checked).length ?? 0;
                            widget.stateManager.weekdayMedicationStatus[dateStr]![memoId] = checkedCount == memo.dosageFrequency;
                            widget.stateManager.medicationMemoStatus[memoId] = checkedCount == memo.dosageFrequency;
                            
                            setState(() {});
                            await widget.stateManager.saveAllData();
                          }
                        },
                        onEditMemo: widget.onEditMemo ?? (memo) {},
                        onDeleteMemo: widget.onDeleteMemo ?? (id) {},
                        onShowMemoDetailDialog: widget.onShowMemoDetailDialog ?? (name, notes) {},
                        onShowWarningDialog: widget.onShowWarningDialog ?? () {},
                        getMedicationMemoDoseStatus: (memoId, index) {
                          if (selectedDay == null) return false;
                          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
                          return widget.stateManager.weekdayMedicationDoseStatus[dateStr]?[memoId]?[index] ?? false;
                        },
                        getMedicationMemoCheckedCount: (memoId) {
                          if (selectedDay == null) return 0;
                          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
                          final doseStatus = widget.stateManager.weekdayMedicationDoseStatus[dateStr]?[memoId];
                          if (doseStatus == null) return 0;
                          return doseStatus.values.where((isChecked) => isChecked).length;
                        },
                        onAddedMedicationCheckToggle: (medication) async {
                          if (selectedDay != null) {
                            final currentChecked = (medication['isChecked'] as bool?) ?? false;
                            medication['isChecked'] = !currentChecked;
                            widget.stateManager.addedMedications = List.from(widget.stateManager.addedMedications);
                            setState(() {});
                            await widget.stateManager.saveAllData();
                          }
                        },
                        onAddedMedicationDelete: (medication) async {
                          if (selectedDay != null) {
                            widget.stateManager.addedMedications.remove(medication);
                            setState(() {});
                            await widget.stateManager.saveAllData();
                          }
                        },
                      ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

