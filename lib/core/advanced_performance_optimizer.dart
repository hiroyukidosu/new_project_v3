import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

/// 高度なパフォーマンス最適化 - Riverpod/Provider状態管理
class AdvancedPerformanceOptimizer {
  
  /// 最適化された状態管理（Riverpod）
  static Widget buildOptimizedStateManagement({
    required Widget child,
    // required List<Provider> providers,
  }) {
    return child;
    // return ProviderScope(
    //   child: MultiProvider(
    //     providers: providers,
    //     child: child,
    //   ),
    // );
  }
  
  /// メモ化されたウィジェットの構築
  static Widget buildMemoizedWidget({
    required Widget Function() builder,
    required String key,
  }) {
    return _MemoizedWidget(
      key: ValueKey(key),
      builder: builder,
    );
  }
  
  /// 最適化されたカレンダータブ
  static Widget buildOptimizedCalendarTab({
    required DateTime focusedDay,
    required DateTime selectedDay,
    required Function(DateTime, DateTime) onDaySelected,
    required Function(DateTime) onPageChanged,
    required Map<DateTime, List<dynamic>> events,
    required Widget Function() medicationRecordsBuilder,
  }) {
    return _OptimizedCalendarTab(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      events: events,
      medicationRecordsBuilder: medicationRecordsBuilder,
    );
  }
  
  /// 最適化されたメディケーションカード
  static Widget buildOptimizedMedicationCard({
    required dynamic memo,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return _OptimizedMedicationCard(
      memo: memo,
      onTap: onTap,
      isSelected: isSelected,
    );
  }
}

/// メモ化されたウィジェット
class _MemoizedWidget extends StatefulWidget {
  final Widget Function() builder;
  
  const _MemoizedWidget({
    super.key,
    required this.builder,
  });
  
  @override
  State<_MemoizedWidget> createState() => _MemoizedWidgetState();
}

class _MemoizedWidgetState extends State<_MemoizedWidget> {
  late Widget _cachedWidget;
  
  @override
  void initState() {
    super.initState();
    _cachedWidget = widget.builder();
  }
  
  @override
  Widget build(BuildContext context) {
    return _cachedWidget;
  }
}

/// 最適化されたカレンダータブ
class _OptimizedCalendarTab extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Map<DateTime, List<dynamic>> events;
  final Widget Function() medicationRecordsBuilder;
  
  const _OptimizedCalendarTab({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.events,
    required this.medicationRecordsBuilder,
  });
  
  @override
  State<_OptimizedCalendarTab> createState() => _OptimizedCalendarTabState();
}

class _OptimizedCalendarTabState extends State<_OptimizedCalendarTab> {
  late Widget _calendarWidget;
  late Widget _medicationRecordsWidget;
  
  @override
  void initState() {
    super.initState();
    _initializeWidgets();
  }
  
  void _initializeWidgets() {
    // カレンダーウィジェットを1回だけ構築
    _calendarWidget = _buildCalendarWidget();
    
    // メディケーションレコードウィジェットを1回だけ構築
    _medicationRecordsWidget = widget.medicationRecordsBuilder();
  }
  
  Widget _buildCalendarWidget() {
    return Container(
      height: 400,
      child: Column(
        children: [
          // カレンダーヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${widget.focusedDay.year}年${widget.focusedDay.month}月',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // カレンダーグリッド
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: _getDaysInMonth(widget.focusedDay),
              itemBuilder: (context, dayIndex) {
                final day = dayIndex + 1;
                final date = DateTime(widget.focusedDay.year, widget.focusedDay.month, day);
                final hasEvents = widget.events[date]?.isNotEmpty ?? false;
                
                return GestureDetector(
                  onTap: () => widget.onDaySelected(date, date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: hasEvents ? Colors.blue.withOpacity(0.3) : null,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: hasEvents ? Colors.blue : Colors.black,
                          fontWeight: hasEvents ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _calendarWidget, // 再利用
          _medicationRecordsWidget, // 再利用
        ],
      ),
    );
  }
}

/// 最適化されたメディケーションカード
class _OptimizedMedicationCard extends StatelessWidget {
  final dynamic memo;
  final VoidCallback onTap;
  final bool isSelected;
  
  const _OptimizedMedicationCard({
    required this.memo,
    required this.onTap,
    required this.isSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo['name'] ?? '無題',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                memo['dosage'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              if (memo['notes'] != null && memo['notes'].isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  memo['notes'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// パフォーマンス監視
class PerformanceMonitor {
  static final Map<String, DateTime> _renderStartTimes = {};
  static final Map<String, Duration> _renderDurations = {};
  static final Map<String, int> _renderCounts = {};
  
  /// レンダリング開始の記録
  static void recordRenderStart(String widgetName) {
    _renderStartTimes[widgetName] = DateTime.now();
    _renderCounts[widgetName] = (_renderCounts[widgetName] ?? 0) + 1;
    Logger.debug('レンダリング開始: $widgetName');
  }
  
  /// レンダリング終了の記録
  static void recordRenderEnd(String widgetName) {
    final startTime = _renderStartTimes.remove(widgetName);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _renderDurations[widgetName] = duration;
      Logger.performance('レンダリング完了: $widgetName (${duration.inMilliseconds}ms)');
    }
  }
  
  /// レンダリング統計の取得
  static Map<String, dynamic> getRenderStats() {
    return {
      'activeRenders': _renderStartTimes.keys.toList(),
      'completedRenders': _renderDurations.length,
      'renderCounts': Map.from(_renderCounts),
      'averageRenderTime': _renderDurations.values.isNotEmpty
          ? _renderDurations.values
              .map((d) => d.inMilliseconds)
              .reduce((a, b) => a + b) / _renderDurations.length
          : 0,
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _renderStartTimes.clear();
    _renderDurations.clear();
    _renderCounts.clear();
    Logger.info('レンダリング統計をクリアしました');
  }
}

/// 最適化された状態管理
class OptimizedMedicationState extends ChangeNotifier {
  List<dynamic> _memos = [];
  bool _isLoading = false;
  String? _error;
  
  List<dynamic> get memos => _memos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// メモの追加
  void addMemo(dynamic memo) {
    _memos.add(memo);
    notifyListeners(); // 必要な箇所のみ更新
    Logger.debug('メモ追加: ${memo['name']}');
  }
  
  /// メモの更新
  void updateMemo(int index, dynamic memo) {
    if (index >= 0 && index < _memos.length) {
      _memos[index] = memo;
      notifyListeners();
      Logger.debug('メモ更新: ${memo['name']}');
    }
  }
  
  /// メモの削除
  void removeMemo(int index) {
    if (index >= 0 && index < _memos.length) {
      final removed = _memos.removeAt(index);
      notifyListeners();
      Logger.debug('メモ削除: ${removed['name']}');
    }
  }
  
  /// ローディング状態の設定
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// エラーの設定
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// エラーのクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
