import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// データ永続化用のMixin - 重複コード削減
mixin DataPersistenceMixin {
  /// JSON保存
  Future<bool> saveJson(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      
      // メインとバックアップを並列保存
      final results = await Future.wait([
        prefs.setString(key, jsonString),
        prefs.setString('${key}_backup', jsonString),
      ]);
      
      return results.every((r) => r);
    } catch (e) {
      Logger.error('JSON保存エラー: $key', e);
      return false;
    }
  }
  
  /// JSON読み込み
  Future<Map<String, dynamic>?> loadJson(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // メインから読み込み、失敗したらバックアップ
      for (final currentKey in [key, '${key}_backup']) {
        try {
          final jsonString = prefs.getString(currentKey);
          if (jsonString != null && jsonString.isNotEmpty) {
            return jsonDecode(jsonString) as Map<String, dynamic>;
          }
        } catch (e) {
          Logger.warning('JSON読み込みエラー: $currentKey - $e');
          continue;
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('JSON読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// 文字列保存
  Future<bool> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final results = await Future.wait([
        prefs.setString(key, value),
        prefs.setString('${key}_backup', value),
      ]);
      
      return results.every((r) => r);
    } catch (e) {
      Logger.error('文字列保存エラー: $key', e);
      return false;
    }
  }
  
  /// 文字列読み込み
  Future<String?> loadString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final currentKey in [key, '${key}_backup']) {
        final value = prefs.getString(currentKey);
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('文字列読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// 整数保存
  Future<bool> saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(key, value);
    } catch (e) {
      Logger.error('整数保存エラー: $key', e);
      return false;
    }
  }
  
  /// 整数読み込み
  Future<int?> loadInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      Logger.error('整数読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// ブール値保存
  Future<bool> saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(key, value);
    } catch (e) {
      Logger.error('ブール値保存エラー: $key', e);
      return false;
    }
  }
  
  /// ブール値読み込み
  Future<bool?> loadBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e) {
      Logger.error('ブール値読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// データ削除
  Future<bool> deleteData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.remove(key),
        prefs.remove('${key}_backup'),
      ]);
      
      return true;
    } catch (e) {
      Logger.error('データ削除エラー: $key', e);
      return false;
    }
  }
}

