// lib/screens/home/business/pagination_manager.dart

import '../../../models/medication_memo.dart';

/// ページネーション管理クラス
class PaginationManager {
  static const int defaultPageSize = 20;
  
  final int pageSize;
  int _currentPage = 0;
  List<MedicationMemo> _allMemos = [];
  List<MedicationMemo> _displayedMemos = [];
  bool _isLoadingMore = false;

  PaginationManager({this.pageSize = defaultPageSize});

  /// 現在のページ
  int get currentPage => _currentPage;

  /// 表示中のメモ
  List<MedicationMemo> get displayedMemos => _displayedMemos;

  /// さらに読み込み中か
  bool get isLoadingMore => _isLoadingMore;

  /// すべてのメモを設定
  void setAllMemos(List<MedicationMemo> memos) {
    _allMemos = memos;
    _currentPage = 0;
    _displayedMemos.clear();
    loadMore();
  }

  /// 次のページを読み込み
  bool loadMore() {
    if (_isLoadingMore) return false;
    if (_currentPage * pageSize >= _allMemos.length) return false;

    _isLoadingMore = true;

    final startIndex = _currentPage * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _allMemos.length);
    
    final newMemos = _allMemos.sublist(startIndex, endIndex);
    _displayedMemos.addAll(newMemos);
    
    _currentPage++;
    _isLoadingMore = false;

    return true;
  }

  /// 指定ページに移動
  void goToPage(int page) {
    if (page < 0) return;
    if (page * pageSize >= _allMemos.length) return;
    
    _currentPage = page;
    _displayedMemos.clear();
    
    final startIndex = _currentPage * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _allMemos.length);
    
    final newMemos = _allMemos.sublist(startIndex, endIndex);
    _displayedMemos.addAll(newMemos);
  }

  /// リセット
  void reset() {
    _currentPage = 0;
    _displayedMemos.clear();
    _isLoadingMore = false;
  }

  /// すべて読み込み済みか
  bool get hasMore => _currentPage * pageSize < _allMemos.length;

  /// 次のページを読み込む（loadMoreのエイリアス）
  void loadNextPage() {
    loadMore();
  }
}

