// lib/screens/home/persistence/alarm_data_persistence.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/logger.dart';

/// アラームデータの永続化を管理するクラス
class AlarmDataPersistence {
  static const String _alarmListKey = 'alarm_list_v2';
  static const String _alarmListBackupKey = 'alarm_list_backup';

  /// アラームデータを保存
  Future<void> saveAlarmData(List<Map<String, dynamic>> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = alarms.map((alarm) => alarm).toList();
      final jsonString = jsonEncode(alarmsJson);
      
      // メインキーとバックアップキーに保存
      await prefs.setString(_alarmListKey, jsonString);
      await prefs.setString(_alarmListBackupKey, jsonString);
      
      Logger.debug('アラームデータ保存完了: ${alarms.length}件');
    } catch (e) {
      Logger.error('アラームデータ保存エラー', e);
      rethrow;
    }
  }

  /// アラームデータを読み込み
  Future<List<Map<String, dynamic>>> loadAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // まずメインキーから読み込み
      final jsonString = prefs.getString(_alarmListKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> alarmsList = jsonDecode(jsonString);
        final alarms = alarmsList.cast<Map<String, dynamic>>().toList();
        Logger.info('アラームデータ読み込み成功: ${alarms.length}件');
        return alarms;
      }
      
      // バックアップキーから読み込み
      final backupJsonString = prefs.getString(_alarmListBackupKey);
      if (backupJsonString != null && backupJsonString.isNotEmpty) {
        final List<dynamic> alarmsList = jsonDecode(backupJsonString);
        final alarms = alarmsList.cast<Map<String, dynamic>>().toList();
        Logger.info('アラームデータ復元成功: ${alarms.length}件');
        return alarms;
      }
      
      return [];
    } catch (e) {
      Logger.error('アラームデータ読み込みエラー', e);
      return [];
    }
  }

  /// アラームを追加
  Future<void> addAlarm(Map<String, dynamic> alarm) async {
    try {
      final alarms = await loadAlarmData();
      alarms.add(alarm);
      await saveAlarmData(alarms);
      Logger.info('アラーム追加成功');
    } catch (e) {
      Logger.error('アラーム追加エラー', e);
      rethrow;
    }
  }

  /// アラームを削除
  Future<void> deleteAlarm(int index) async {
    try {
      final alarms = await loadAlarmData();
      if (index >= 0 && index < alarms.length) {
        alarms.removeAt(index);
        await saveAlarmData(alarms);
        Logger.info('アラーム削除成功: index=$index');
      }
    } catch (e) {
      Logger.error('アラーム削除エラー', e);
      rethrow;
    }
  }

  /// アラームを更新
  Future<void> updateAlarm(int index, Map<String, dynamic> updatedAlarm) async {
    try {
      final alarms = await loadAlarmData();
      if (index >= 0 && index < alarms.length) {
        alarms[index] = updatedAlarm;
        await saveAlarmData(alarms);
        Logger.info('アラーム更新成功: index=$index');
      }
    } catch (e) {
      Logger.error('アラーム更新エラー', e);
      rethrow;
    }
  }
}

