// lib/screens/home/business/pagination_manager.dart

import 'package:flutter/material.dart';
import '../../../models/medication_memo.dart';

/// ページネーション管理クラス
class PaginationManager {
  static const int defaultPageSize = 20;
  
  final int pageSize;
  int _currentPage = 0;
  List<MedicationMemo> _allMemos = [];
  List<MedicationMemo> _displayedMemos = [];
  bool _isLoadingMore = false;
  
  // 状態変更を通知するValueNotifier
  final ValueNotifier<int> _pageNotifier = ValueNotifier<int>(0);
  ValueNotifier<int> get pageNotifier => _pageNotifier;

  PaginationManager({this.pageSize = defaultPageSize});

  /// 現在のページ
  int get currentPage => _currentPage;

  /// 表示中のメモ
  List<MedicationMemo> get displayedMemos => _displayedMemos;

  /// さらに読み込み中か
  bool get isLoadingMore => _isLoadingMore;

  /// すべてのメモを設定
  void setAllMemos(List<MedicationMemo> memos) {
    _allMemos = List.from(memos);
    _currentPage = 0;
    _displayedMemos.clear();
    // 最初のページを読み込む
    if (_allMemos.isNotEmpty) {
      final startIndex = 0;
      final endIndex = pageSize.clamp(0, _allMemos.length);
      final newMemos = _allMemos.sublist(startIndex, endIndex);
      _displayedMemos.addAll(newMemos);
      _currentPage = 1; // 1ページ目を表示中
    }
    _pageNotifier.value = _currentPage;
  }

  /// 次のページを読み込み
  bool loadMore() {
    if (_isLoadingMore) return false;
    // 現在表示中のページ数から次のページの開始インデックスを計算
    // _currentPageは1ベース（1ページ目、2ページ目...）
    final nextPage = _currentPage + 1;
    final startIndex = (nextPage - 1) * pageSize;
    
    if (startIndex >= _allMemos.length) return false;

    _isLoadingMore = true;

    final endIndex = (startIndex + pageSize).clamp(0, _allMemos.length);
    
    final newMemos = _allMemos.sublist(startIndex, endIndex);
    _displayedMemos.addAll(newMemos);
    
    _currentPage = nextPage;
    _isLoadingMore = false;
    _pageNotifier.value = _currentPage;

    return true;
  }

  /// 指定ページに移動（1ベース: 1ページ目、2ページ目...）
  void goToPage(int page) {
    if (page < 1) return;
    final maxPage = (_allMemos.length / pageSize).ceil();
    if (page > maxPage) return;
    
    _currentPage = page;
    _displayedMemos.clear();
    
    // ページは1ベースなので、インデックスは (page - 1) * pageSize
    final startIndex = (_currentPage - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _allMemos.length);
    
    final newMemos = _allMemos.sublist(startIndex, endIndex);
    _displayedMemos.addAll(newMemos);
    _pageNotifier.value = _currentPage;
  }

  /// リセット
  void reset() {
    _currentPage = 0;
    _displayedMemos.clear();
    _isLoadingMore = false;
    _pageNotifier.value = _currentPage;
    // リセット後、最初のページを読み込む
    if (_allMemos.isNotEmpty) {
      setAllMemos(_allMemos);
    }
  }

  /// すべて読み込み済みか
  /// _currentPageは1ベースなので、表示済みのアイテム数は (_currentPage - 1) * pageSize + displayedMemos.length
  /// または、次のページの開始インデックスが総数以上かどうかで判定
  bool get hasMore {
    if (_currentPage == 0) return _allMemos.isNotEmpty;
    final nextPageStartIndex = _currentPage * pageSize;
    return nextPageStartIndex < _allMemos.length;
  }
  
  /// 総ページ数
  int get totalPages => (_allMemos.length / pageSize).ceil();

  /// 次のページを読み込む（loadMoreのエイリアス）
  void loadNextPage() {
    loadMore();
  }
  
  /// リソースを解放
  void dispose() {
    _pageNotifier.dispose();
  }
}

