import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/storage_keys.dart';
import '../utils/logger.dart';

/// アラーム関連データのリポジトリ
class AlarmRepository {
  late SharedPreferences _prefs;
  late Box<String> _dataBox;
  
  /// リポジトリの初期化
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _dataBox = await Hive.openBox<String>('alarm_data');
      Logger.info('AlarmRepository初期化完了');
    } catch (e) {
      Logger.error('AlarmRepository初期化エラー', e);
      rethrow;
    }
  }
  
  /// アラームリストの取得
  Future<List<Map<String, dynamic>>> loadAlarmList() async {
    try {
      final alarmListJson = _prefs.getString(StorageKeys.alarmListKey);
      if (alarmListJson != null) {
        final alarmList = jsonDecode(alarmListJson) as List<dynamic>;
        return alarmList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      Logger.error('アラームリスト取得エラー', e);
      return [];
    }
  }
  
  /// アラームリストの保存
  Future<void> saveAlarmList(List<Map<String, dynamic>> alarmList) async {
    try {
      await _prefs.setString(StorageKeys.alarmListKey, jsonEncode(alarmList));
      await _dataBox.put(StorageKeys.alarmListKey, jsonEncode(alarmList));
      Logger.debug('アラームリスト保存完了: ${alarmList.length}件');
    } catch (e) {
      Logger.error('アラームリスト保存エラー', e);
      rethrow;
    }
  }
  
  /// アラーム設定の取得
  Future<Map<String, dynamic>> loadAlarmSettings() async {
    try {
      final settingsJson = _prefs.getString(StorageKeys.alarmSettingsKey);
      if (settingsJson != null) {
        return jsonDecode(settingsJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      Logger.error('アラーム設定取得エラー', e);
      return {};
    }
  }
  
  /// アラーム設定の保存
  Future<void> saveAlarmSettings(Map<String, dynamic> settings) async {
    try {
      await _prefs.setString(StorageKeys.alarmSettingsKey, jsonEncode(settings));
      await _dataBox.put(StorageKeys.alarmSettingsKey, jsonEncode(settings));
      Logger.debug('アラーム設定保存完了');
    } catch (e) {
      Logger.error('アラーム設定保存エラー', e);
      rethrow;
    }
  }
  
  /// リソースの解放
  Future<void> dispose() async {
    try {
      await _dataBox.close();
      Logger.info('AlarmRepository解放完了');
    } catch (e) {
      Logger.error('AlarmRepository解放エラー', e);
    }
  }
}

