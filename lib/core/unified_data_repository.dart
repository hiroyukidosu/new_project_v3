import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// 統一データリポジトリ - すべてのデータ永続化を一元管理
class UnifiedDataRepository {
  static const _keys = {
    'memos': 'medication_memos_v3',
    'alarms': 'alarms_v3',
    'calendar': 'calendar_marks_v3',
    'settings': 'user_settings_v3',
    'statistics': 'statistics_v3',
    'weekday_status': 'weekday_medication_status_v3',
    'dose_status': 'medication_dose_status_v3',
    'added_medications': 'added_medications_v3',
  };
  
  static SharedPreferences? _prefs;
  
  /// 初期化
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    Logger.info('UnifiedDataRepository初期化完了');
  }
  
  /// 汎用保存メソッド
  static Future<bool> save<T>(String key, T data) async {
    await initialize();
    
    try {
      final jsonString = jsonEncode(data);
      final mainKey = _keys[key] ?? key;
      final backupKey = '${mainKey}_backup';
      
      // メインとバックアップを並列保存
      final results = await Future.wait([
        _prefs!.setString(mainKey, jsonString),
        _prefs!.setString(backupKey, jsonString),
      ]);
      
      final success = results.every((r) => r);
      if (success) {
        Logger.info('データ保存成功: $key');
      } else {
        Logger.error('データ保存失敗: $key');
      }
      
      return success;
    } catch (e) {
      Logger.error('データ保存エラー: $key', e);
      return false;
    }
  }
  
  /// 汎用読み込みメソッド
  static Future<T?> load<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    await initialize();
    
    try {
      final mainKey = _keys[key] ?? key;
      final backupKey = '${mainKey}_backup';
      
      // メインから読み込み、失敗したらバックアップ
      for (final currentKey in [mainKey, backupKey]) {
        try {
          final jsonString = _prefs!.getString(currentKey);
          if (jsonString != null && jsonString.isNotEmpty) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            Logger.info('データ読み込み成功: $key (from $currentKey)');
            return fromJson(json);
          }
        } catch (e) {
          Logger.warning('キー $currentKey の読み込みエラー: $e');
          continue;
        }
      }
      
      Logger.warning('データが見つかりません: $key');
      return null;
    } catch (e) {
      Logger.error('データ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// リスト保存
  static Future<bool> saveList<T>(String key, List<T> data) async {
    await initialize();
    
    try {
      final jsonString = jsonEncode({'items': data});
      final mainKey = _keys[key] ?? key;
      final backupKey = '${mainKey}_backup';
      
      final results = await Future.wait([
        _prefs!.setString(mainKey, jsonString),
        _prefs!.setString(backupKey, jsonString),
      ]);
      
      return results.every((r) => r);
    } catch (e) {
      Logger.error('リスト保存エラー: $key', e);
      return false;
    }
  }
  
  /// リスト読み込み
  static Future<List<T>> loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    await initialize();
    
    try {
      final mainKey = _keys[key] ?? key;
      final backupKey = '${mainKey}_backup';
      
      for (final currentKey in [mainKey, backupKey]) {
        try {
          final jsonString = _prefs!.getString(currentKey);
          if (jsonString != null && jsonString.isNotEmpty) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final items = json['items'] as List;
            return items.map((item) => fromJson(item as Map<String, dynamic>)).toList();
          }
        } catch (e) {
          Logger.warning('リスト読み込みエラー: $currentKey - $e');
          continue;
        }
      }
      
      return [];
    } catch (e) {
      Logger.error('リスト読み込みエラー: $key', e);
      return [];
    }
  }
  
  /// データ削除
  static Future<bool> delete(String key) async {
    await initialize();
    
    try {
      final mainKey = _keys[key] ?? key;
      final backupKey = '${mainKey}_backup';
      
      await Future.wait([
        _prefs!.remove(mainKey),
        _prefs!.remove(backupKey),
      ]);
      
      Logger.info('データ削除完了: $key');
      return true;
    } catch (e) {
      Logger.error('データ削除エラー: $key', e);
      return false;
    }
  }
  
  /// 全データクリア
  static Future<bool> clearAll() async {
    await initialize();
    
    try {
      await _prefs!.clear();
      Logger.info('全データクリア完了');
      return true;
    } catch (e) {
      Logger.error('全データクリアエラー', e);
      return false;
    }
  }
}

