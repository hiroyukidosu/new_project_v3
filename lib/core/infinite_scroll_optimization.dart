import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// 無限スクロール最適化 - ページネーションとLazyLoading
class InfiniteScrollOptimization {
  static const int _defaultPageSize = 20;
  static const int _preloadThreshold = 5;
  static const Duration _loadMoreDelay = Duration(milliseconds: 300);
  
  /// 最適化されたListViewの構築
  static Widget buildOptimizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    required Future<List<T>> Function(int page, int pageSize) loadMore,
    int pageSize = _defaultPageSize,
    bool hasMore = true,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool enableLazyLoading = true,
    bool enablePreloading = true,
  }) {
    return _OptimizedListView<T>(
      items: items,
      itemBuilder: itemBuilder,
      loadMore: loadMore,
      pageSize: pageSize,
      hasMore: hasMore,
      controller: controller,
      padding: padding,
      enableLazyLoading: enableLazyLoading,
      enablePreloading: enablePreloading,
    );
  }
  
  /// 最適化されたGridViewの構築
  static Widget buildOptimizedGridView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    required Future<List<T>> Function(int page, int pageSize) loadMore,
    required SliverGridDelegate gridDelegate,
    int pageSize = _defaultPageSize,
    bool hasMore = true,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool enableLazyLoading = true,
  }) {
    return _OptimizedGridView<T>(
      items: items,
      itemBuilder: itemBuilder,
      loadMore: loadMore,
      gridDelegate: gridDelegate,
      pageSize: pageSize,
      hasMore: hasMore,
      controller: controller,
      padding: padding,
      enableLazyLoading: enableLazyLoading,
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
    bool enableLazyLoading = true,
  }) {
    return _OptimizedCalendar(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      events: events,
      controller: controller,
      enableLazyLoading: enableLazyLoading,
    );
  }
}

/// 最適化されたListView
class _OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Future<List<T>> Function(int page, int pageSize) loadMore;
  final int pageSize;
  final bool hasMore;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool enableLazyLoading;
  final bool enablePreloading;
  
  const _OptimizedListView({
    required this.items,
    required this.itemBuilder,
    required this.loadMore,
    required this.pageSize,
    this.hasMore = true,
    this.controller,
    this.padding,
    this.enableLazyLoading = true,
    this.enablePreloading = true,
  });
  
  @override
  State<_OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<_OptimizedListView<T>> {
  late ScrollController _scrollController;
  bool _isLoading = false;
  int _currentPage = 0;
  List<T> _allItems = [];
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _allItems = List<T>.from(widget.items);
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  void _onScroll() {
    if (!widget.enableLazyLoading) return;
    
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }
  
  Future<void> _loadMoreData() async {
    if (_isLoading || !widget.hasMore) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newItems = await widget.loadMore(_currentPage + 1, widget.pageSize);
      
      if (mounted) {
        setState(() {
          _currentPage++;
          _allItems.addAll(newItems);
          _isLoading = false;
        });
        
        Logger.debug('データ読み込み完了: ${newItems.length}件');
      }
    } catch (e) {
      Logger.error('データ読み込みエラー', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: _allItems.length + (_isLoading ? 1 : 0),
      cacheExtent: 1000,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        if (index >= _allItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return RepaintBoundary(
          child: widget.itemBuilder(context, _allItems[index], index),
        );
      },
    );
  }
}

/// 最適化されたGridView
class _OptimizedGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Future<List<T>> Function(int page, int pageSize) loadMore;
  final SliverGridDelegate gridDelegate;
  final int pageSize;
  final bool hasMore;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool enableLazyLoading;
  
  const _OptimizedGridView({
    required this.items,
    required this.itemBuilder,
    required this.loadMore,
    required this.gridDelegate,
    required this.pageSize,
    this.hasMore = true,
    this.controller,
    this.padding,
    this.enableLazyLoading = true,
  });
  
  @override
  State<_OptimizedGridView<T>> createState() => _OptimizedGridViewState<T>();
}

class _OptimizedGridViewState<T> extends State<_OptimizedGridView<T>> {
  late ScrollController _scrollController;
  bool _isLoading = false;
  int _currentPage = 0;
  List<T> _allItems = [];
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _allItems = List<T>.from(widget.items);
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  void _onScroll() {
    if (!widget.enableLazyLoading) return;
    
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }
  
  Future<void> _loadMoreData() async {
    if (_isLoading || !widget.hasMore) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newItems = await widget.loadMore(_currentPage + 1, widget.pageSize);
      
      if (mounted) {
        setState(() {
          _currentPage++;
          _allItems.addAll(newItems);
          _isLoading = false;
        });
        
        Logger.debug('データ読み込み完了: ${newItems.length}件');
      }
    } catch (e) {
      Logger.error('データ読み込みエラー', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      gridDelegate: widget.gridDelegate,
      itemCount: _allItems.length + (_isLoading ? 1 : 0),
      cacheExtent: 500,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        if (index >= _allItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return RepaintBoundary(
          child: widget.itemBuilder(context, _allItems[index], index),
        );
      },
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
  final bool enableLazyLoading;
  
  const _OptimizedCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.events,
    this.controller,
    this.enableLazyLoading = true,
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
    if (!widget.enableLazyLoading) return;
    
    // スクロール位置に基づいてイベントをプリロード
    _preloadEvents();
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
      cacheExtent: 1000,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
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

/// ページネーション管理
class PaginationManager {
  static const int _defaultPageSize = 20;
  static const int _maxCacheSize = 100;
  
  final Map<String, List<dynamic>> _cache = {};
  final Map<String, int> _currentPages = {};
  final Map<String, bool> _hasMore = {};
  
  /// ページネーション付きデータの取得
  Future<List<dynamic>> getPaginatedData(
    String key,
    Future<List<dynamic>> Function(int page, int pageSize) loadFunction, {
    int pageSize = _defaultPageSize,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _cache.remove(key);
      _currentPages.remove(key);
      _hasMore.remove(key);
    }
    
    final currentPage = _currentPages[key] ?? 0;
    final cachedData = _cache[key] ?? [];
    
    if (cachedData.isEmpty || _hasMore[key] == true) {
      try {
        final newData = await loadFunction(currentPage + 1, pageSize);
        
        if (newData.length < pageSize) {
          _hasMore[key] = false;
        } else {
          _hasMore[key] = true;
        }
        
        _currentPages[key] = currentPage + 1;
        _cache[key] = [...cachedData, ...newData];
        
        // キャッシュサイズの制限
        if (_cache[key]!.length > _maxCacheSize) {
          _cache[key] = _cache[key]!.sublist(_cache[key]!.length - _maxCacheSize);
        }
        
        Logger.debug('ページネーションデータ取得完了: $key (${newData.length}件)');
      } catch (e) {
        Logger.error('ページネーションデータ取得エラー: $key', e);
      }
    }
    
    return _cache[key] ?? [];
  }
  
  /// キャッシュのクリア
  void clearCache(String key) {
    _cache.remove(key);
    _currentPages.remove(key);
    _hasMore.remove(key);
    Logger.debug('ページネーションキャッシュクリア: $key');
  }
  
  /// 全キャッシュのクリア
  void clearAllCache() {
    _cache.clear();
    _currentPages.clear();
    _hasMore.clear();
    Logger.info('全ページネーションキャッシュクリア');
  }
  
  /// 統計情報の取得
  Map<String, dynamic> getStats() {
    return {
      'cacheKeys': _cache.keys.toList(),
      'cacheSizes': _cache.map((key, value) => MapEntry(key, value.length)),
      'currentPages': Map.from(_currentPages),
      'hasMore': Map.from(_hasMore),
    };
  }
}
