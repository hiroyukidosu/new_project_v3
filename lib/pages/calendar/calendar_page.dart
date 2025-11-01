import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/calendar_state.dart';
import '../../providers/medication_state.dart';
import '../../widgets/calendar/calendar_day_cell.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_dialog.dart';

/// カレンダーページ
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});
  
  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  final ScrollController _calendarScrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _initializeScrollListener();
  }
  
  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }
  
  /// スクロールリスナーの初期化
  void _initializeScrollListener() {
    _calendarScrollController.addListener(() {
      // オーバースクロール検出などの処理は必要に応じて追加
    });
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarStateProvider);
    final medicationState = ref.watch(medicationStateProvider);
    
    return LoadingOverlay(
      isLoading: calendarState.isLoading || medicationState.isLoading,
      message: '読み込み中...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('カレンダー'),
        ),
        body: Column(
          children: [
            // カレンダーヘッダー
            _buildCalendarHeader(context, calendarState, ref),
            
            // カレンダーグリッド（スクロール可能）
            Expanded(
              child: SingleChildScrollView(
                controller: _calendarScrollController,
                child: _buildCalendarGrid(context, calendarState, ref),
              ),
            ),
            
            // 服用記録リスト
            _buildMedicationRecordsList(context, medicationState),
            
            // メモフィールド
            _buildMemoField(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalendarHeader(
    BuildContext context,
    CalendarState state,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final newFocusedDay = state.focusedDay.subtract(const Duration(days: 30));
              ref.read(calendarStateProvider.notifier).setFocusedDay(newFocusedDay);
            },
          ),
          Text(
            '${state.focusedDay.year}年${state.focusedDay.month}月',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final newFocusedDay = state.focusedDay.add(const Duration(days: 30));
              ref.read(calendarStateProvider.notifier).setFocusedDay(newFocusedDay);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalendarGrid(
    BuildContext context,
    CalendarState state,
    WidgetRef ref,
  ) {
    final daysInMonth = DateTime(state.focusedDay.year, state.focusedDay.month + 1, 0).day;
    final firstDay = DateTime(state.focusedDay.year, state.focusedDay.month, 1);
    final firstWeekday = firstDay.weekday % 7;
    
    // 週数と曜日のヘッダー
    final weekCount = ((daysInMonth + firstWeekday + 6) / 7).ceil();
    
    return Column(
      children: [
        // 曜日ヘッダー
        _buildWeekdayHeader(context),
        // カレンダーグリッド
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: daysInMonth + firstWeekday,
          itemBuilder: (context, index) {
            if (index < firstWeekday) {
              return const SizedBox.shrink();
            }
            
            final day = index - firstWeekday + 1;
            final date = DateTime(state.focusedDay.year, state.focusedDay.month, day);
            final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            
            final isSelected = state.selectedDay != null &&
                state.selectedDay!.year == date.year &&
                state.selectedDay!.month == date.month &&
                state.selectedDay!.day == date.day;
            
            final dayColor = state.dayColors[dateKey];
            
            return CalendarDayCell(
              day: date,
              isSelected: isSelected,
              hasScheduledMemo: dayColor != null,
              backgroundColor: dayColor,
              onTap: () {
                ref.read(calendarStateProvider.notifier).setSelectedDay(date);
                // スクロール位置を調整（必要に応じて）
                _scrollToDayIfNeeded(date);
              },
            );
          },
        ),
      ],
    );
  }
  
  /// 曜日ヘッダーを構築
  Widget _buildWeekdayHeader(BuildContext context) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  /// 選択した日にスクロール（必要に応じて）
  void _scrollToDayIfNeeded(DateTime selectedDay) {
    if (!_calendarScrollController.hasClients) return;
    
    // 選択された日が画面外にある場合、スクロール位置を調整
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_calendarScrollController.hasClients) {
        // スクロール位置の調整ロジックは必要に応じて実装
        // 現時点では基本機能のみ実装
      }
    });
  }
  
  /// カレンダーを一番下にスクロール
  void _scrollToBottom() {
    if (_calendarScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_calendarScrollController.hasClients) {
          _calendarScrollController.animateTo(
            _calendarScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
  
  /// カレンダーを一番上にスクロール
  void _scrollToTop() {
    if (_calendarScrollController.hasClients) {
      _calendarScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }
  
  Widget _buildMedicationRecordsList(
    BuildContext context,
    MedicationState state,
  ) {
    if (state.medicationMemos.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 150,
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.medicationMemos.length,
        itemBuilder: (context, index) {
          final memo = state.medicationMemos[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: memo.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    memo.name,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMemoField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'メモを入力...',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
    );
  }
}

