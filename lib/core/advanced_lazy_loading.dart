import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// 高度なLazyLoading機能 - 大量データの効率的な読み込み
class AdvancedLazyLoading {
  static const int _defaultPageSize = 20;
  static const int _preloadThreshold = 5;
  
  /// ページネーション付きListView
  static Widget buildPaginatedListView<T>({
    required List<T> allItems,
    required Widget Function(BuildContext, T, int) itemBuilder,
    required Future<List<T>> Function(int page, int pageSize) loadMore,
    int pageSize = _defaultPageSize,
    bool hasMore = true,
    VoidCallback? onLoadMore,
  }) {
    return _PaginatedListView<T>(
      allItems: allItems,
      itemBuilder: itemBuilder,
      loadMore: loadMore,
      pageSize: pageSize,
      hasMore: hasMore,
      onLoadMore: onLoadMore,
    );
  }
  
  /// 仮想化されたListView（大量データ用）
  static Widget buildVirtualizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    double? height,
    int cacheExtent = 500,
  }) {
    return SizedBox(
      height: height ?? 400,
      child: ListView.builder(
        itemCount: items.length,
        cacheExtent: cacheExtent.toDouble(),
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: true,
        addSemanticIndexes: true,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: itemBuilder(context, items[index], index),
          );
        },
      ),
    );
  }
  
  /// 遅延読み込み付きGridView
  static Widget buildLazyGridView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    int crossAxisCount = 2,
    double childAspectRatio = 1.0,
    double? height,
    int cacheExtent = 200,
  }) {
    return SizedBox(
      height: height ?? 300,
      child: GridView.builder(
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        cacheExtent: cacheExtent.toDouble(),
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: true,
        addSemanticIndexes: true,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: itemBuilder(context, items[index], index),
          );
        },
      ),
    );
  }
  
  /// 遅延読み込み付きカレンダー
  static Widget buildLazyCalendar({
    required DateTime focusedDay,
    required DateTime selectedDay,
    required Function(DateTime, DateTime) onDaySelected,
    required Function(DateTime) onPageChanged,
    required Map<DateTime, List<dynamic>> events,
    int cacheExtent = 1000,
  }) {
    return _LazyCalendar(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      events: events,
      cacheExtent: cacheExtent,
    );
  }
}

/// ページネーション付きListView
class _PaginatedListView<T> extends StatefulWidget {
  final List<T> allItems;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Future<List<T>> Function(int page, int pageSize) loadMore;
  final int pageSize;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  
  const _PaginatedListView({
    required this.allItems,
    required this.itemBuilder,
    required this.loadMore,
    required this.pageSize,
    this.hasMore = true,
    this.onLoadMore,
  });
  
  @override
  State<_PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<_PaginatedListView<T>> {
  late ScrollController _scrollController;
  bool _isLoading = false;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
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
          _isLoading = false;
        });
        
        widget.onLoadMore?.call();
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
      itemCount: widget.allItems.length + (_isLoading ? 1 : 0),
      cacheExtent: 500,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        if (index >= widget.allItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return RepaintBoundary(
          child: widget.itemBuilder(context, widget.allItems[index], index),
        );
      },
    );
  }
}

/// 遅延読み込み付きカレンダー
class _LazyCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Map<DateTime, List<dynamic>> events;
  final int cacheExtent;
  
  const _LazyCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.events,
    required this.cacheExtent,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: cacheExtent.toDouble(),
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        // カレンダーの月表示を遅延読み込み
        final monthDate = DateTime(focusedDay.year, focusedDay.month + index);
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
                final hasEvents = events[date]?.isNotEmpty ?? false;
                
                return GestureDetector(
                  onTap: () => onDaySelected(date, date),
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

/// 遅延読み込み状態管理
class LazyLoadingState {
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;
  
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  
  void setLoading(bool loading) {
    _isLoading = loading;
  }
  
  void setCurrentPage(int page) {
    _currentPage = page;
  }
  
  void setHasMore(bool hasMore) {
    _hasMore = hasMore;
  }
  
  void reset() {
    _isLoading = false;
    _currentPage = 0;
    _hasMore = true;
  }
}
