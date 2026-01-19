import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// パフォーマンス最適化 - setState削減と効率的なリストビルド
class PerformanceOptimizer {
  
  /// 最適化されたsetState（複数更新を1回にまとめる）
  static void optimizedSetState(State state, VoidCallback updates) {
    state.setState(() {
      updates();
    });
    Logger.debug('最適化されたsetState実行');
  }
  
  /// バッチ更新（複数の変更を1回のsetStateで実行）
  static void batchUpdate(State state, List<VoidCallback> updates) {
    state.setState(() {
      for (final update in updates) {
        update();
      }
    });
    Logger.debug('バッチ更新実行: ${updates.length}件');
  }
  
  /// 最適化されたListViewの構築
  static Widget buildOptimizedListView({
    required List<dynamic> items,
    required Widget Function(BuildContext, dynamic, int) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool enableCaching = true,
    bool enableRepaintBoundary = true,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: items.length,
      cacheExtent: enableCaching ? 500 : 0,
      addRepaintBoundaries: enableRepaintBoundary,
      addAutomaticKeepAlives: enableCaching,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        final item = items[index];
        return enableRepaintBoundary
            ? RepaintBoundary(
                child: itemBuilder(context, item, index),
              )
            : itemBuilder(context, item, index);
      },
    );
  }
  
  /// 最適化されたGridViewの構築
  static Widget buildOptimizedGridView({
    required List<dynamic> items,
    required Widget Function(BuildContext, dynamic, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool enableCaching = true,
    bool enableRepaintBoundary = true,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      cacheExtent: enableCaching ? 500 : 0,
      addRepaintBoundaries: enableRepaintBoundary,
      addAutomaticKeepAlives: enableCaching,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        final item = items[index];
        return enableRepaintBoundary
            ? RepaintBoundary(
                child: itemBuilder(context, item, index),
              )
            : itemBuilder(context, item, index);
      },
    );
  }
  
  /// 最適化されたカレンダーの構築
  static Widget buildOptimizedCalendar({
    required DateTime focusedDay,
    required DateTime selectedDay,
    required Function(DateTime, DateTime) onDaySelected,
    required Function(DateTime) onPageChanged,
    required Map<DateTime, List<dynamic>> events,
    ScrollController? controller,
    bool enableCaching = true,
  }) {
    return _OptimizedCalendar(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      events: events,
      controller: controller,
      enableCaching: enableCaching,
    );
  }
}

/// 最適化されたカレンダー
class _OptimizedCalendar extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Map<DateTime, List<dynamic>> events;
  final ScrollController? controller;
  final bool enableCaching;
  
  const _OptimizedCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.events,
    this.controller,
    this.enableCaching = true,
  });
  
  @override
  State<_OptimizedCalendar> createState() => _OptimizedCalendarState();
}

class _OptimizedCalendarState extends State<_OptimizedCalendar> {
  late ScrollController _scrollController;
  final Map<DateTime, List<dynamic>> _cachedEvents = {};
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _preloadEvents();
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  void _onScroll() {
    if (widget.enableCaching) {
      _preloadEvents();
    }
  }
  
  void _preloadEvents() {
    // 現在の表示範囲の前後1ヶ月分のイベントをプリロード
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final endDate = now.add(const Duration(days: 30));
    
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      final date = startDate.add(Duration(days: i));
      if (!_cachedEvents.containsKey(date)) {
        _cachedEvents[date] = widget.events[date] ?? [];
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      cacheExtent: widget.enableCaching ? 1000 : 0,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: widget.enableCaching,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        // カレンダーの月表示を遅延読み込み
        final monthDate = DateTime(widget.focusedDay.year, widget.focusedDay.month + index);
        return _buildMonthView(context, monthDate);
      },
    );
  }
  
  Widget _buildMonthView(BuildContext context, DateTime monthDate) {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            '${monthDate.year}年${monthDate.month}月',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: _getDaysInMonth(monthDate),
              itemBuilder: (context, dayIndex) {
                final day = dayIndex + 1;
                final date = DateTime(monthDate.year, monthDate.month, day);
                final hasEvents = _cachedEvents[date]?.isNotEmpty ?? false;
                
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
}

/// パフォーマンス監視
class PerformanceMonitor {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final Map<String, Duration> _operationDurations = {};
  static final Map<String, int> _operationCounts = {};
  
  /// 操作の開始を記録
  static void recordOperationStart(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
    _operationCounts[operationId] = (_operationCounts[operationId] ?? 0) + 1;
    Logger.debug('操作開始記録: $operationId');
  }
  
  /// 操作の終了を記録
  static void recordOperationEnd(String operationId) {
    final startTime = _operationStartTimes.remove(operationId);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationId] = duration;
      Logger.performance('操作完了: $operationId (${duration.inMilliseconds}ms)');
    }
  }
  
  /// 長時間実行中の操作を検出
  static List<String> detectLongRunningOperations({Duration threshold = const Duration(seconds: 30)}) {
    final now = DateTime.now();
    final longRunning = <String>[];
    
    for (final entry in _operationStartTimes.entries) {
      final duration = now.difference(entry.value);
      if (duration.compareTo(threshold) > 0) {
        longRunning.add('${entry.key}: ${duration.inSeconds}秒');
      }
    }
    
    return longRunning;
  }
  
  /// 操作統計の取得
  static Map<String, dynamic> getOperationStats() {
    return {
      'activeOperations': _operationStartTimes.keys.toList(),
      'completedOperations': _operationDurations.length,
      'operationCounts': Map.from(_operationCounts),
      'longRunningOperations': detectLongRunningOperations(),
      'averageDuration': _operationDurations.values.isNotEmpty
          ? _operationDurations.values
              .map((d) => d.inMilliseconds)
              .reduce((a, b) => a + b) / _operationDurations.length
          : 0,
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _operationCounts.clear();
    Logger.info('操作統計をクリアしました');
  }
}

/// メモリ使用量の監視
class MemoryMonitor {
  static final Map<String, int> _memoryUsage = {};
  static final Map<String, DateTime> _lastMemoryCheck = {};
  
  /// メモリ使用量の記録
  static void recordMemoryUsage(String key, int bytes) {
    _memoryUsage[key] = bytes;
    _lastMemoryCheck[key] = DateTime.now();
    Logger.debug('メモリ使用量記録: $key (${bytes / 1024}KB)');
  }
  
  /// メモリ使用量の取得
  static int getMemoryUsage(String key) {
    return _memoryUsage[key] ?? 0;
  }
  
  /// メモリ使用量の統計
  static Map<String, dynamic> getMemoryStats() {
    final totalMemory = _memoryUsage.values.fold(0, (sum, usage) => sum + usage);
    return {
      'totalMemory': totalMemory,
      'totalMemoryKB': totalMemory / 1024,
      'totalMemoryMB': totalMemory / (1024 * 1024),
      'memoryUsage': Map.from(_memoryUsage),
      'lastMemoryCheck': Map.from(_lastMemoryCheck),
    };
  }
  
  /// メモリ使用量のクリア
  static void clearMemoryStats() {
    _memoryUsage.clear();
    _lastMemoryCheck.clear();
    Logger.info('メモリ使用量統計をクリアしました');
  }
}
