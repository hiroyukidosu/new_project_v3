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
    debugPrint('✅ StorageService初期化完了');
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
        debugPrint('✅ notification_volume読み込み成功: $notificationVolume (int型)');
      } else {
        final volumeStr = _prefs!.getString('notification_volume');
        if (volumeStr != null && volumeStr.isNotEmpty) {
          notificationVolume = int.tryParse(volumeStr) ?? 80;
          debugPrint('⚠️ volumeを文字列から整数に変換: $volumeStr -> $notificationVolume');
          await _prefs!.setInt('notification_volume', notificationVolume);
          debugPrint('✅ notification_volumeを正しい型で再保存: $notificationVolume');
        } else {
          notificationVolume = 80;
          debugPrint('⚠️ notification_volumeのデータが見つかりません。デフォルト値80を使用');
        }
      }
    } catch (e) {
      debugPrint('❌ notification_volume読み込みエラー: $e');
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
    debugPrint('✅ 設定保存完了');
  }

  /// アラームを保存
  static Future<void> saveAlarms(List<Alarm> alarms) async {
    if (_prefs == null) {
      await initialize();
    }

    try {
      await _prefs!.setInt('alarm_count', alarms.length);
      debugPrint('✅ アラーム数保存完了: ${alarms.length}件');
      
      for (int i = 0; i < alarms.length; i++) {
        try {
          final alarm = alarms[i];
          debugPrint('💾 アラーム $i 保存: ${alarm.name}');
          
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
          
          debugPrint('✅ アラーム $i 保存完了');
        } catch (e) {
          debugPrint('❌ アラーム $i 保存エラー: $e');
          continue;
        }
      }
      
      final savedCount = _prefs!.getInt('alarm_count') ?? 0;
      debugPrint('✅ 保存確認: $savedCount件のアラームが保存されました');
    } catch (e, stackTrace) {
      debugPrint('❌ アラームデータ保存エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }

  /// アラームを読み込み
  static Future<List<Alarm>> loadAlarms() async {
    if (_prefs == null) {
      await initialize();
    }

    debugPrint('📂 アラーム読み込み開始');
    
    try {
      final alarmCount = _prefs!.getInt('alarm_count') ?? 0;
      debugPrint('📂 保存されているアラーム数: $alarmCount件');
      
      if (alarmCount == 0) {
        debugPrint('ℹ️ アラームデータなし');
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
              debugPrint('⚠️ アラーム $i: volumeを文字列から整数に変換: $volumeStr -> $volume');
            }
          }
          
          final selectedDays = <bool>[];
          for (int j = 0; j < 7; j++) {
            selectedDays.add(_prefs!.getBool('alarm_${i}_day_$j') ?? false);
          }
          
          debugPrint('📂 アラーム $i 読み込み: name=$name, time=$time, volume=$volume');
          
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
          debugPrint('✅ アラーム $i 追加完了');
        } catch (e) {
          debugPrint('❌ アラーム $i 読み込みエラー: $e');
          continue;
        }
      }
      
      debugPrint('📂 読み込み完了: ${alarmsList.length}件のアラーム');
      return alarmsList;
    } catch (e, stackTrace) {
      debugPrint('❌ アラームデータ読み込みエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
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
      debugPrint('🔍 データ整合性チェック開始: $alarmCount件のアラーム');
      
      // notification_volumeの型チェック
      try {
        final notificationVolume = _prefs!.getInt('notification_volume');
        if (notificationVolume != null) {
          debugPrint('✅ notification_volume: $notificationVolume (int型)');
        } else {
          debugPrint('⚠️ notification_volumeがint型で読み込めません');
          final volumeStr = _prefs!.getString('notification_volume');
          if (volumeStr != null) {
            debugPrint('⚠️ notification_volumeが文字列として保存されています: $volumeStr');
            final volumeInt = int.tryParse(volumeStr) ?? 80;
            await _prefs!.setInt('notification_volume', volumeInt);
            debugPrint('✅ notification_volumeを正しい型で再保存: $volumeInt');
          } else {
            debugPrint('⚠️ notification_volumeのデータが見つかりません。デフォルト値80で保存');
            await _prefs!.setInt('notification_volume', 80);
          }
        }
      } catch (e) {
        debugPrint('❌ notification_volume型チェックエラー: $e');
        await _prefs!.setInt('notification_volume', 80);
      }
      
      for (int i = 0; i < alarmCount; i++) {
        final name = _prefs!.getString('alarm_${i}_name');
        final time = _prefs!.getString('alarm_${i}_time');
        final volume = _prefs!.getInt('alarm_${i}_volume');
        
        if (name == null || name.isEmpty) {
          debugPrint('⚠️ アラーム $i: nameが無効');
        }
        if (time == null || time.isEmpty) {
          debugPrint('⚠️ アラーム $i: timeが無効');
        }
        if (volume == null) {
          debugPrint('⚠️ アラーム $i: volumeが無効（型エラーの可能性）');
          final volumeStr = _prefs!.getString('alarm_${i}_volume');
          if (volumeStr != null) {
            debugPrint('⚠️ アラーム $i: volumeが文字列として保存されています: $volumeStr');
            final volumeInt = int.tryParse(volumeStr) ?? 80;
            await _prefs!.setInt('alarm_${i}_volume', volumeInt);
            debugPrint('✅ アラーム $i: volumeを正しい型で再保存: $volumeInt');
          }
        }
      }
      
      debugPrint('✅ データ整合性チェック完了');
    } catch (e) {
      debugPrint('❌ データ整合性チェックエラー: $e');
    }
  }
}

