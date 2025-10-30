import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';
import '../constants/app_constants.dart';
import '../models/medication_memo.dart';

/// データリポジトリ
/// アプリ全体で使用するデータの保存・読み込みを行う
class DataRepository {
  static SharedPreferences? _prefs;
  static Box? _hiveBox;
  
  // 初期化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _hiveBox = await Hive.openBox('medication_data');
    Logger.info('DataRepository初期化完了');
  }
  
  // データを保存するメソッド
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
  
  // データを読み込むメソッド
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
  
  // データを削除するメソッド
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
  
  // リソースのクリーンアップ
  static Future<void> dispose() async {
    try {
      await _hiveBox?.close();
      Logger.info('DataRepositoryクリーンアップ完了');
    } catch (e) {
      Logger.error('DataRepositoryクリーンアップエラー', e);
    }
  }
}
