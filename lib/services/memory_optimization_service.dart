import 'dart:async';
import '../utils/logger.dart';

// メモリ最適化サービス
class MemoryOptimizationService {
  static const int _maxCachedDays = 30; // 直近30日のみキャッシュ
  static const Duration _cacheExpiry = Duration(hours: 24);
  
  // キャッシュ管理
  static final Map<String, CachedData> _cache = {};
  static final Map<String, DateTime> _lastAccess = {};
  
  // メモリ使用量の監視
  static int _currentMemoryUsage = 0;
  static const int _maxMemoryUsage = 100 * 1024 * 1024; // 100MB制限
  
  // データの取得（メモリ効率化版）
  static Future<T?> getData<T>(String key, Future<T> Function() loader) async {
    // キャッシュから取得を試行
    if (_cache.containsKey(key)) {
      final cachedData = _cache[key]!;
      if (!_isExpired(cachedData.timestamp)) {
        _lastAccess[key] = DateTime.now();
        Logger.debug('キャッシュから取得: $key');
        return cachedData.data as T?;
      } else {
        _cache.remove(key);
        _lastAccess.remove(key);
        Logger.debug('キャッシュ期限切れ: $key');
      }
    }
    
    // メモリ使用量チェック
    if (_currentMemoryUsage > _maxMemoryUsage) {
      _evictOldCache();
    }
    
    // データベースから読み込み
    try {
      final data = await loader();
      _cache[key] = CachedData(data, DateTime.now());
      _lastAccess[key] = DateTime.now();
      _currentMemoryUsage += _estimateSize(data);
      
      Logger.debug('データベースから読み込み: $key');
      return data;
    } catch (e) {
      Logger.error('データ読み込みエラー: $key', e);
      return null;
    }
  }
  
  // データの保存（メモリ効率化版）
  static Future<void> saveData<T>(String key, T data, Future<void> Function(T) saver) async {
    try {
      await saver(data);
      
      // キャッシュを更新
      _cache[key] = CachedData(data, DateTime.now());
      _lastAccess[key] = DateTime.now();
      _currentMemoryUsage += _estimateSize(data);
      
      Logger.debug('データ保存完了: $key');
    } catch (e) {
      Logger.error('データ保存エラー: $key', e);
      rethrow;
    }
  }
  
  // 古いキャッシュの削除
  static void _evictOldCache() {
    if (_cache.length <= _maxCachedDays) return;
    
    // アクセス時間でソート
    final sortedKeys = _lastAccess.entries
        .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
    
    // 古いキャッシュを削除
    final keysToRemove = sortedKeys
        .take(_cache.length - _maxCachedDays)
        .map((e) => e.key)
        .toList();
    
    for (final key in keysToRemove) {
      final cachedData = _cache.remove(key);
      _lastAccess.remove(key);
      if (cachedData != null) {
        _currentMemoryUsage -= _estimateSize(cachedData.data);
      }
    }
    
    Logger.info('古いキャッシュを削除: ${keysToRemove.length}件');
  }
  
  // 期限切れチェック
  static bool _isExpired(DateTime timestamp) {
    return DateTime.now().difference(timestamp).compareTo(_cacheExpiry) > 0;
  }
  
  // データサイズの推定
  static int _estimateSize(dynamic data) {
    if (data == null) return 0;
    
    if (data is String) {
      return data.length * 2; // UTF-16文字
    } else if (data is Map) {
      return data.length * 100; // 推定値
    } else if (data is List) {
      return data.length * 50; // 推定値
    } else {
      return 100; // デフォルトサイズ
    }
  }
  
  // 特定の日付のデータを取得（メモリ効率化版）
  static Future<Map<String, dynamic>?> getDayData(DateTime date) async {
    final key = _dateKey(date);
    return await getData<Map<String, dynamic>>(key, () => _loadDayDataFromDb(date));
  }
  
  // 日付キーの生成
  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // データベースから日付データを読み込み
  static Future<Map<String, dynamic>?> _loadDayDataFromDb(DateTime date) async {
    // 実装は既存のロジックを移植
    Logger.debug('データベースから日付データを読み込み: ${_dateKey(date)}');
    return {};
  }
  
  // メモリ使用量の取得
  static int getCurrentMemoryUsage() => _currentMemoryUsage;
  
  // キャッシュサイズの取得
  static int getCacheSize() => _cache.length;
  
  // 全キャッシュのクリア
  static void clearAllCache() {
    _cache.clear();
    _lastAccess.clear();
    _currentMemoryUsage = 0;
    Logger.info('全キャッシュをクリア');
  }
  
  // 特定のキーのキャッシュをクリア
  static void clearCache(String key) {
    final cachedData = _cache.remove(key);
    _lastAccess.remove(key);
    if (cachedData != null) {
      _currentMemoryUsage -= _estimateSize(cachedData.data);
    }
    Logger.debug('キャッシュクリア: $key');
  }
  
  // メモリ使用量の監視
  static void monitorMemoryUsage() {
    Logger.info('メモリ使用量: ${(_currentMemoryUsage / 1024 / 1024).toStringAsFixed(2)}MB');
    Logger.info('キャッシュサイズ: ${_cache.length}件');
    
    if (_currentMemoryUsage > _maxMemoryUsage * 0.8) {
      Logger.warning('メモリ使用量が高いです: ${(_currentMemoryUsage / 1024 / 1024).toStringAsFixed(2)}MB');
      _evictOldCache();
    }
  }
  
  // リソースの解放
  static void dispose() {
    clearAllCache();
    Logger.info('MemoryOptimizationServiceリソース解放完了');
  }
}

// キャッシュデータクラス
class CachedData {
  final dynamic data;
  final DateTime timestamp;
  
  CachedData(this.data, this.timestamp);
}

// 日付別データ管理
class MedicationDayData {
  final DateTime date;
  final Map<String, dynamic> medicationData;
  final Map<String, bool> memoStatus;
  final Map<String, Map<int, bool>> doseStatus;
  
  const MedicationDayData({
    required this.date,
    required this.medicationData,
    required this.memoStatus,
    required this.doseStatus,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'medicationData': medicationData,
      'memoStatus': memoStatus,
      'doseStatus': doseStatus,
    };
  }
  
  factory MedicationDayData.fromJson(Map<String, dynamic> json) {
    return MedicationDayData(
      date: DateTime.parse(json['date']),
      medicationData: Map<String, dynamic>.from(json['medicationData']),
      memoStatus: Map<String, bool>.from(json['memoStatus']),
      doseStatus: (json['doseStatus'] as Map).map(
        (key, value) => MapEntry(key, Map<int, bool>.from(value)),
      ),
    );
  }
}
