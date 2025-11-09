// lib/utils/preferences_cache.dart
// SharedPreferencesのキャッシュ管理（Lazy Loading対応）

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferencesのキャッシュクラス（Lazy Loading対応）
class PreferencesCache {
  static SharedPreferences? _instance;
  static bool _isInitializing = false;
  static Future<SharedPreferences>? _initFuture;
  
  // 値のキャッシュ（起動時に全て読み込まず、必要時に読む）
  static final Map<String, dynamic> _valueCache = {};

  /// SharedPreferencesインスタンスを取得（キャッシュ付き）
  static Future<SharedPreferences> get instance async {
    if (_instance != null) {
      return _instance!;
    }

    if (_isInitializing && _initFuture != null) {
      return await _initFuture!;
    }

    _isInitializing = true;
    _initFuture = SharedPreferences.getInstance().then((prefs) {
      _instance = prefs;
      _isInitializing = false;
      return prefs;
    });

    return await _initFuture!;
  }

  /// 値を取得（キャッシュ付き、Lazy Loading）
  static Future<T?> get<T>(String key) async {
    // キャッシュに存在する場合は返す
    if (_valueCache.containsKey(key)) {
      final cachedValue = _valueCache[key];
      if (cachedValue is T) {
        return cachedValue as T;
      }
    }
    
    // キャッシュにない場合は読み込む
    final prefs = await instance;
    dynamic value;
    
    if (T == String) {
      value = prefs.getString(key);
    } else if (T == int) {
      value = prefs.getInt(key);
    } else if (T == bool) {
      value = prefs.getBool(key);
    } else if (T == double) {
      value = prefs.getDouble(key);
    } else if (T == List<String>) {
      value = prefs.getStringList(key);
    } else {
      // 型が不明な場合はnullを返す
      return null;
    }
    
    // キャッシュに保存
    if (value != null) {
      _valueCache[key] = value;
      return value as T;
    }
    
    return null;
  }

  /// 値を保存（キャッシュも更新）
  static Future<bool> set<T>(String key, T value) async {
    final prefs = await instance;
    bool result = false;
    
    if (value is String) {
      result = await prefs.setString(key, value);
    } else if (value is int) {
      result = await prefs.setInt(key, value);
    } else if (value is bool) {
      result = await prefs.setBool(key, value);
    } else if (value is double) {
      result = await prefs.setDouble(key, value);
    } else if (value is List<String>) {
      result = await prefs.setStringList(key, value);
    }
    
    // キャッシュを更新
    if (result) {
      _valueCache[key] = value;
    }
    
    return result;
  }

  /// キャッシュをクリア（テスト用）
  static void clearCache() {
    _instance = null;
    _initFuture = null;
    _isInitializing = false;
    _valueCache.clear();
  }

  /// 値のキャッシュをクリア（キー指定）
  static void clearValueCache(String key) {
    _valueCache.remove(key);
  }

  /// インスタンスが初期化済みかどうか
  static bool get isInitialized => _instance != null;

  /// キャッシュされた値を取得（同期的アクセス用）
  static dynamic getCachedValue(String key) {
    return _valueCache[key];
  }
}

