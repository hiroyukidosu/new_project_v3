// Dart core imports
import 'dart:convert';

// Third-party package imports
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Local imports
import '../utils/logger.dart';

// 統一されたデータリポジトリ
class DataRepository {
  static SharedPreferences? _prefs;
  static Box? _hiveBox;
  
  // 初期化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _hiveBox = await Hive.openBox('medication_data');
    Logger.info('DataRepository初期化完了');
  }
  
  // 統一された保存メソッド
  static Future<void> save<T>(String key, T data) async {
    try {
      final json = jsonEncode(data);
      await Future.wait([
        _prefs!.setString(key, json),
        _prefs!.setString('${key}_backup', json),
      ]);
      Logger.info('データ保存完了: $key');
    } catch (e) {
      Logger.error('データ保存エラー: $key', e);
    }
  }
  
  // 統一された読み込みメソッド
  static Future<T?> load<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      for (final suffix in ['', '_backup']) {
        final json = _prefs!.getString('$key$suffix');
        if (json != null && json.isNotEmpty) {
          final data = fromJson(jsonDecode(json));
          Logger.info('データ読み込み成功: $key$suffix');
          return data;
        }
      }
      Logger.warning('データが見つかりません: $key');
      return null;
    } catch (e) {
      Logger.error('データ読み込みエラー: $key', e);
      return null;
    }
  }
  
  // 統一された削除メソッド
  static Future<void> delete(String key) async {
    try {
      await Future.wait([
        _prefs!.remove(key),
        _prefs!.remove('${key}_backup'),
      ]);
      Logger.info('データ削除完了: $key');
    } catch (e) {
      Logger.error('データ削除エラー: $key', e);
    }
  }
  
  // メモリリーク防止のためのクリーンアップ
  static Future<void> dispose() async {
    try {
      await _hiveBox?.close();
      Logger.info('DataRepositoryクリーンアップ完了');
    } catch (e) {
      Logger.error('DataRepositoryクリーンアップエラー', e);
    }
  }
}
