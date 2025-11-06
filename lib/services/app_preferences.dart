// SharedPreferences管理サービス
// アプリケーションのユーザー設定や状態をSharedPreferencesで永続化します

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences管理クラス
/// アプリケーション全体で使用する設定値を管理します
class AppPreferences {
  static SharedPreferences? _preferences;
  static bool _isInitialized = false;
  
  /// アプリ起動時に一度だけ呼ぶ
  static Future<void> init() async {
    if (_isInitialized && _preferences != null) {
      return; // 既に初期化済み
    }
    
    _preferences = await SharedPreferences.getInstance();
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('[INFO] AppPreferences初期化完了');
    }
  }
  
  /// 初期化状態を確認
  static bool get isInitialized => _isInitialized && _preferences != null;
  
  /// 文字列を保存
  static Future<bool> saveString(String key, String value) async {
    if (!isInitialized) await init();
    return await _preferences!.setString(key, value);
  }
  
  /// 文字列を読み込み（レビュー指摘の修正）
  static String getString(String key, {String defaultValue = ''}) {
    if (!isInitialized) {
      throw StateError('AppPreferences not initialized. Call init() first.');
    }
    return _preferences!.getString(key) ?? defaultValue;
  }
  
  /// 文字列を読み込み（nullable版 - 後方互換性のため）
  static String? getStringOrNull(String key) {
    if (!isInitialized) return null;
    return _preferences?.getString(key);
  }
  
  /// キーを削除
  static Future<bool> remove(String key) async {
    if (!isInitialized) await init();
    return await _preferences!.remove(key);
  }
  
  /// 整数を保存
  static Future<bool> saveInt(String key, int value) async {
    if (!isInitialized) await init();
    return await _preferences!.setInt(key, value);
  }
  
  /// 整数を読み込み
  static int? getInt(String key) {
    return _preferences?.getInt(key);
  }
  
  /// ブール値を保存
  static Future<bool> saveBool(String key, bool value) async {
    if (!isInitialized) await init();
    return await _preferences!.setBool(key, value);
  }
  
  /// ブール値を読み込み（レビュー指摘の修正）
  /// nullを返すより例外を投げる方が、未初期化状態を早期に検出できる
  static bool getBool(String key, {bool defaultValue = false}) {
    if (!isInitialized) {
      throw StateError('AppPreferences not initialized. Call init() first.');
    }
    return _preferences!.getBool(key) ?? defaultValue;
  }
  
  /// ブール値を読み込み（nullable版 - 後方互換性のため）
  static bool? getBoolOrNull(String key) {
    if (!isInitialized) return null;
    return _preferences?.getBool(key);
  }
  
  /// 倍精度浮動小数点を保存
  static Future<bool> saveDouble(String key, double value) async {
    if (!isInitialized) await init();
    return await _preferences!.setDouble(key, value);
  }
  
  /// 倍精度浮動小数点を読み込み
  static double? getDouble(String key) {
    return _preferences?.getDouble(key);
  }
}

