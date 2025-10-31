// SharedPreferences管理サービス
// アプリケーションのユーザー設定や状態をSharedPreferencesで永続化します

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences管理クラス
/// アプリケーション全体で使用する設定値を管理します
class AppPreferences {
  static SharedPreferences? _preferences;
  
  /// アプリ起動時に一度だけ呼ぶ
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    if (kDebugMode) {
      debugPrint('[INFO] AppPreferences初期化完了');
    }
  }
  
  /// 文字列を保存
  static Future<bool> saveString(String key, String value) async {
    if (_preferences == null) await init();
    return await _preferences!.setString(key, value);
  }
  
  /// 文字列を読み込み
  static String? getString(String key) {
    return _preferences?.getString(key);
  }
  
  /// キーを削除
  static Future<bool> remove(String key) async {
    if (_preferences == null) await init();
    return await _preferences!.remove(key);
  }
  
  /// 整数を保存
  static Future<bool> saveInt(String key, int value) async {
    if (_preferences == null) await init();
    return await _preferences!.setInt(key, value);
  }
  
  /// 整数を読み込み
  static int? getInt(String key) {
    return _preferences?.getInt(key);
  }
  
  /// ブール値を保存
  static Future<bool> saveBool(String key, bool value) async {
    if (_preferences == null) await init();
    return await _preferences!.setBool(key, value);
  }
  
  /// ブール値を読み込み
  static bool? getBool(String key) {
    return _preferences?.getBool(key);
  }
  
  /// 倍精度浮動小数点を保存
  static Future<bool> saveDouble(String key, double value) async {
    if (_preferences == null) await init();
    return await _preferences!.setDouble(key, value);
  }
  
  /// 倍精度浮動小数点を読み込み
  static double? getDouble(String key) {
    return _preferences?.getDouble(key);
  }
}

