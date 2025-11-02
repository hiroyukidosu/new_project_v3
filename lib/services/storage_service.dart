// lib/services/storage_service.dart
// データ永続化サービス

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

/// ストレージサービス
class StorageService {
  static SharedPreferences? _prefs;

  /// 初期化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 設定を読み込み
  static Future<Map<String, dynamic>> loadSettings() async {
    if (_prefs == null) {
      await initialize();
    }

    final isAlarmEnabled = _prefs!.getBool('alarm_enabled') ?? true;
    final selectedNotificationType = _prefs!.getString('notification_type') ?? 'sound';
    final selectedAlarmSound = _prefs!.getString('alarm_sound') ?? 'default';
    
    // 型安全な読み込み（古いStringデータにも対応）
    int notificationVolume = 80;
    try {
      final volumeInt = _prefs!.getInt('notification_volume');
      if (volumeInt != null) {
        notificationVolume = volumeInt;
      } else {
        final volumeStr = _prefs!.getString('notification_volume');
        if (volumeStr != null && volumeStr.isNotEmpty) {
          notificationVolume = int.tryParse(volumeStr) ?? 80;
          await _prefs!.setInt('notification_volume', notificationVolume);
        } else {
          notificationVolume = 80;
        }
      }
    } catch (e) {
      notificationVolume = 80;
      await _prefs!.setInt('notification_volume', notificationVolume);
    }
    
    return {
      'isAlarmEnabled': isAlarmEnabled,
      'selectedNotificationType': selectedNotificationType,
      'selectedAlarmSound': selectedAlarmSound,
      'notificationVolume': notificationVolume,
    };
  }

  /// 設定を保存
  static Future<void> saveSettings({
    required bool isAlarmEnabled,
    required String selectedNotificationType,
    required String selectedAlarmSound,
    required int notificationVolume,
  }) async {
    if (_prefs == null) {
      await initialize();
    }

    await _prefs!.setBool('alarm_enabled', isAlarmEnabled);
    await _prefs!.setString('notification_type', selectedNotificationType);
    await _prefs!.setString('alarm_sound', selectedAlarmSound);
    await _prefs!.setInt('notification_volume', notificationVolume);
  }

  /// アラームを保存
  static Future<void> saveAlarms(List<Alarm> alarms) async {
    if (_prefs == null) {
      await initialize();
    }

    try {
      await _prefs!.setInt('alarm_count', alarms.length);
      
      for (int i = 0; i < alarms.length; i++) {
        try {
          final alarm = alarms[i];
          
          await _prefs!.setString('alarm_${i}_name', alarm.name);
          await _prefs!.setString('alarm_${i}_time', alarm.time);
          await _prefs!.setString('alarm_${i}_repeat', alarm.repeat);
          await _prefs!.setString('alarm_${i}_alarmType', alarm.alarmType);
          await _prefs!.setBool('alarm_${i}_enabled', alarm.enabled);
          await _prefs!.setBool('alarm_${i}_isRepeatEnabled', alarm.isRepeatEnabled);
          await _prefs!.setInt('alarm_${i}_volume', alarm.volume);
          
          for (int j = 0; j < 7; j++) {
            await _prefs!.setBool('alarm_${i}_day_$j', j < alarm.selectedDays.length ? alarm.selectedDays[j] : false);
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e, stackTrace) {
      // エラーは無視
    }
  }

  /// アラームを読み込み
  static Future<List<Alarm>> loadAlarms() async {
    if (_prefs == null) {
      await initialize();
    }
    
    try {
      final alarmCount = _prefs!.getInt('alarm_count') ?? 0;
      
      if (alarmCount == 0) {
        return [];
      }
      
      final alarmsList = <Alarm>[];
      
      for (int i = 0; i < alarmCount; i++) {
        try {
          final name = _prefs!.getString('alarm_${i}_name') ?? 'アラーム';
          final time = _prefs!.getString('alarm_${i}_time') ?? '00:00';
          final repeat = _prefs!.getString('alarm_${i}_repeat') ?? '一度だけ';
          final enabled = _prefs!.getBool('alarm_${i}_enabled') ?? true;
          final alarmType = _prefs!.getString('alarm_${i}_alarmType') ?? 'sound';
          final isRepeatEnabled = _prefs!.getBool('alarm_${i}_isRepeatEnabled') ?? false;
          
          int volume = 80;
          final volumeInt = _prefs!.getInt('alarm_${i}_volume');
          if (volumeInt != null) {
            volume = volumeInt;
          } else {
            final volumeStr = _prefs!.getString('alarm_${i}_volume');
            if (volumeStr != null && volumeStr.isNotEmpty) {
              volume = int.tryParse(volumeStr) ?? 80;
            }
          }
          
          final selectedDays = <bool>[];
          for (int j = 0; j < 7; j++) {
            selectedDays.add(_prefs!.getBool('alarm_${i}_day_$j') ?? false);
          }
          
          final alarm = Alarm(
            name: name,
            time: time,
            repeat: repeat,
            enabled: enabled,
            alarmType: alarmType,
            volume: volume,
            isRepeatEnabled: isRepeatEnabled,
            selectedDays: selectedDays,
          );
          
          alarmsList.add(alarm);
        } catch (e) {
          continue;
        }
      }
      
      return alarmsList;
    } catch (e, stackTrace) {
      return [];
    }
  }

  /// データ整合性チェック
  static Future<void> validateAlarmData() async {
    if (_prefs == null) {
      await initialize();
    }

    try {
      final alarmCount = _prefs!.getInt('alarm_count') ?? 0;
      
      // notification_volumeの型チェック
      try {
        final notificationVolume = _prefs!.getInt('notification_volume');
        if (notificationVolume == null) {
          final volumeStr = _prefs!.getString('notification_volume');
          if (volumeStr != null) {
            final volumeInt = int.tryParse(volumeStr) ?? 80;
            await _prefs!.setInt('notification_volume', volumeInt);
          } else {
            await _prefs!.setInt('notification_volume', 80);
          }
        }
      } catch (e) {
        await _prefs!.setInt('notification_volume', 80);
      }
      
      for (int i = 0; i < alarmCount; i++) {
        final volume = _prefs!.getInt('alarm_${i}_volume');
        if (volume == null) {
          final volumeStr = _prefs!.getString('alarm_${i}_volume');
          if (volumeStr != null) {
            final volumeInt = int.tryParse(volumeStr) ?? 80;
            await _prefs!.setInt('alarm_${i}_volume', volumeInt);
          }
        }
      }
    } catch (e) {
      // エラーは無視
    }
  }

  /// SharedPreferencesインスタンスを取得
  static Future<SharedPreferences> getSharedPreferences() async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }
}

