import '../utils/logger.dart';

/// 遅延ロード機能 - パフォーマンス最適化
class LazyDataLoader {
  static bool _isEssentialDataLoaded = false;
  static bool _isSecondaryDataLoaded = false;
  
  /// 必須データの読み込み（起動時）
  static Future<void> loadEssentialData({
    required Future<void> Function() loadTodaysMedications,
    required Future<void> Function() loadUserPreferences,
  }) async {
    if (_isEssentialDataLoaded) {
      Logger.info('必須データは既に読み込まれています');
      return;
    }
    
    try {
      final startTime = DateTime.now();
      Logger.info('必須データ読み込み開始');
      
      // 並列読み込み
      await Future.wait([
        loadTodaysMedications(),
        loadUserPreferences(),
      ]);
      
      _isEssentialDataLoaded = true;
      final duration = DateTime.now().difference(startTime);
      Logger.performance('必須データ読み込み完了: ${duration.inMilliseconds}ms');
    } catch (e) {
      Logger.error('必須データ読み込みエラー', e);
      rethrow;
    }
  }
  
  /// 二次データの読み込み（UI表示後）
  static Future<void> loadSecondaryData({
    required Future<void> Function() loadHistoricalData,
    required Future<void> Function() loadStatistics,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    if (_isSecondaryDataLoaded) {
      Logger.info('二次データは既に読み込まれています');
      return;
    }
    
    try {
      // UIが表示された後に読み込み
      await Future.delayed(delay);
      
      final startTime = DateTime.now();
      Logger.info('二次データ読み込み開始');
      
      // 並列読み込み
      await Future.wait([
        loadHistoricalData(),
        loadStatistics(),
      ]);
      
      _isSecondaryDataLoaded = true;
      final duration = DateTime.now().difference(startTime);
      Logger.performance('二次データ読み込み完了: ${duration.inMilliseconds}ms');
    } catch (e) {
      Logger.error('二次データ読み込みエラー', e);
      // 二次データの読み込みエラーはアプリの動作を妨げない
    }
  }
  
  /// 遅延読み込み状態のリセット
  static void reset() {
    _isEssentialDataLoaded = false;
    _isSecondaryDataLoaded = false;
    Logger.info('遅延読み込み状態をリセット');
  }
  
  /// 必須データが読み込まれているか
  static bool get isEssentialDataLoaded => _isEssentialDataLoaded;
  
  /// 二次データが読み込まれているか
  static bool get isSecondaryDataLoaded => _isSecondaryDataLoaded;
  
  /// 全データが読み込まれているか
  static bool get isAllDataLoaded => _isEssentialDataLoaded && _isSecondaryDataLoaded;
}

/// メモ化キャッシュ機能
class MemoizedCache<T> {
  T? _cachedValue;
  DateTime? _cacheTime;
  final Duration _cacheDuration;
  final Future<T> Function() _loader;
  
  MemoizedCache({
    required Future<T> Function() loader,
    Duration cacheDuration = const Duration(minutes: 5),
  })  : _loader = loader,
        _cacheDuration = cacheDuration;
  
  /// キャッシュされた値を取得（必要に応じて再読み込み）
  Future<T> get() async {
    if (_cachedValue != null && _cacheTime != null && !_isCacheExpired()) {
      Logger.debug('キャッシュから取得');
      return _cachedValue!;
    }
    
    Logger.debug('データを再読み込み');
    _cachedValue = await _loader();
    _cacheTime = DateTime.now();
    return _cachedValue!;
  }
  
  /// キャッシュが期限切れか確認
  bool _isCacheExpired() {
    if (_cacheTime == null) return true;
    return DateTime.now().difference(_cacheTime!).compareTo(_cacheDuration) > 0;
  }
  
  /// キャッシュを無効化
  void invalidate() {
    _cachedValue = null;
    _cacheTime = null;
    Logger.debug('キャッシュを無効化');
  }
  
  /// キャッシュが有効か確認
  bool get isValid => _cachedValue != null && _cacheTime != null && !_isCacheExpired();
}

