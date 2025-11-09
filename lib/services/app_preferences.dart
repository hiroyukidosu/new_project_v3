// SharedPreferences管理サービス
// アプリケーションのユーザー設定や状態をSharedPreferencesで永続化します

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/performance_monitor.dart';
import '../utils/preferences_cache.dart';

/// SharedPreferences管理クラス
/// アプリケーション全体で使用する設定値を管理します
class AppPreferences {
  static bool _isInitialized = false;
  
  // 頻繁にアクセスする値のキャッシュ
  static String? _cachedLocale;
  static bool? _cachedFirstLaunch;
  
  /// アプリ起動時に一度だけ呼ぶ（軽量版）
  static Future<void> init() async {
    if (_isInitialized) return;
    
    PerformanceMonitor.start('app_preferences_init');
    // PreferencesCacheを使用（Lazy Loading）
    await PreferencesCache.instance;
    PerformanceMonitor.end('app_preferences_init');
    
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('[INFO] AppPreferences初期化完了');
    }
  }
  
  /// 同期的にアクセス可能（初期化後）
  static Future<SharedPreferences> get instance async {
    return await PreferencesCache.instance;
  }
  
  /// 文字列を保存（PreferencesCache使用）
  static Future<bool> saveString(String key, String value) async {
    if (!_isInitialized) await init();
    return await PreferencesCache.set<String>(key, value);
  }
  
  /// 文字列を読み込み（PreferencesCache使用、Lazy Loading、非同期版）
  static Future<String?> getStringAsync(String key) async {
    if (!_isInitialized) await init();
    return await PreferencesCache.get<String>(key);
  }
  
  /// 文字列を読み込み（後方互換性のため、同期的なアクセスも提供）
  static String? getString(String key) {
    // キャッシュから取得を試みる（非同期版を使用することを推奨）
    if (!_isInitialized) {
      // 初期化されていない場合はnullを返す（非同期版を使用することを推奨）
      return null;
    }
    // PreferencesCacheのキャッシュから取得
    final cached = PreferencesCache.getCachedValue(key);
    if (cached is String) {
      return cached;
    }
    return null;
  }
  
  /// ロケールを取得（キャッシュ付き、非同期版）
  static Future<String> getLocaleAsync() async {
    _cachedLocale ??= await getStringAsync('locale') ?? 'ja';
    return _cachedLocale!;
  }
  
  /// ロケールを取得（後方互換性のため、同期的なアクセスも提供）
  static String get locale {
    _cachedLocale ??= getString('locale') ?? 'ja';
    return _cachedLocale!;
  }
  
  /// ロケールを保存
  static Future<bool> saveLocale(String locale) async {
    _cachedLocale = locale;
    return await saveString('locale', locale);
  }
  
  /// 初回起動フラグを取得（キャッシュ付き、非同期版）
  static Future<bool> getIsFirstLaunchAsync() async {
    _cachedFirstLaunch ??= await getBoolAsync('is_first_launch') ?? true;
    return _cachedFirstLaunch!;
  }
  
  /// 初回起動フラグを取得（後方互換性のため、同期的なアクセスも提供）
  static bool get isFirstLaunch {
    _cachedFirstLaunch ??= getBool('is_first_launch') ?? true;
    return _cachedFirstLaunch!;
  }
  
  /// 初回起動フラグを保存
  static Future<bool> saveFirstLaunch(bool value) async {
    _cachedFirstLaunch = value;
    return await saveBool('is_first_launch', value);
  }
  
  /// キャッシュをクリア
  static void clearCache() {
    _cachedLocale = null;
    _cachedFirstLaunch = null;
  }
  
  /// キーを削除
  static Future<bool> remove(String key) async {
    if (!_isInitialized) await init();
    final prefs = await instance;
    PreferencesCache.clearValueCache(key); // キャッシュもクリア
    return await prefs.remove(key);
  }
  
  /// 整数を保存（PreferencesCache使用）
  static Future<bool> saveInt(String key, int value) async {
    if (!_isInitialized) await init();
    return await PreferencesCache.set<int>(key, value);
  }
  
  /// 整数を読み込み（PreferencesCache使用、Lazy Loading、非同期版）
  static Future<int?> getIntAsync(String key) async {
    if (!_isInitialized) await init();
    return await PreferencesCache.get<int>(key);
  }
  
  /// 整数を読み込み（後方互換性のため、同期的なアクセスも提供）
  static int? getInt(String key) {
    if (!_isInitialized) return null;
    final cached = PreferencesCache.getCachedValue(key);
    if (cached is int) {
      return cached;
    }
    return null;
  }
  
  /// ブール値を保存（PreferencesCache使用）
  static Future<bool> saveBool(String key, bool value) async {
    if (!_isInitialized) await init();
    return await PreferencesCache.set<bool>(key, value);
  }
  
  /// ブール値を読み込み（PreferencesCache使用、Lazy Loading、非同期版）
  static Future<bool?> getBoolAsync(String key) async {
    if (!_isInitialized) await init();
    return await PreferencesCache.get<bool>(key);
  }
  
  /// ブール値を読み込み（後方互換性のため、同期的なアクセスも提供）
  static bool? getBool(String key) {
    if (!_isInitialized) return null;
    final cached = PreferencesCache.getCachedValue(key);
    if (cached is bool) {
      return cached;
    }
    return null;
  }
  
  /// 倍精度浮動小数点を保存（PreferencesCache使用）
  static Future<bool> saveDouble(String key, double value) async {
    if (!_isInitialized) await init();
    return await PreferencesCache.set<double>(key, value);
  }
  
  /// 倍精度浮動小数点を読み込み（PreferencesCache使用、Lazy Loading）
  static Future<double?> getDouble(String key) async {
    if (!_isInitialized) await init();
    return await PreferencesCache.get<double>(key);
  }
}

