// lib/alarm/alarm_data_manager.dart
// アラームデータ管理機能を分離

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アラームデータ管理クラス
class AlarmDataManager {
  final SharedPreferences prefs;

  AlarmDataManager(this.prefs);

  /// 設定を読み込み
  Future<Map<String, dynamic>> loadSettings() async {
    final isAlarmEnabled = prefs.getBool('alarm_enabled') ?? true;
    final selectedNotificationType = prefs.getString('notification_type') ?? 'sound';
    final selectedAlarmSound = prefs.getString('alarm_sound') ?? 'default';
    
    // 型安全な読み込み（古いStringデータにも対応）
    int notificationVolume = 80;
    try {
      // まずint型で読み込みを試行
      final volumeInt = prefs.getInt('notification_volume');
      if (volumeInt != null) {
        notificationVolume = volumeInt;
        debugPrint('✅ notification_volume読み込み成功: $notificationVolume (int型)');
      } else {
        // int型で読み込めない場合、古いStringデータの可能性をチェック
        debugPrint('⚠️ notification_volumeがint型で読み込めません。古いデータ形式の可能性があります。');
        final volumeStr = prefs.getString('notification_volume');
        if (volumeStr != null && volumeStr.isNotEmpty) {
          notificationVolume = int.tryParse(volumeStr) ?? 80;
          debugPrint('⚠️ volumeを文字列から整数に変換: $volumeStr -> $notificationVolume');
          // 次回は正しい型で保存されるように即座に保存
          await prefs.setInt('notification_volume', notificationVolume);
          debugPrint('✅ notification_volumeを正しい型で再保存: $notificationVolume');
        } else {
          notificationVolume = 80;
          debugPrint('⚠️ notification_volumeのデータが見つかりません。デフォルト値80を使用');
        }
      }
    } catch (e) {
      debugPrint('❌ notification_volume読み込みエラー: $e');
      notificationVolume = 80;
      debugPrint('⚠️ デフォルト値80を使用し、正しい型で保存します');
      // エラーが出たので正しい型で保存
      await prefs.setInt('notification_volume', notificationVolume);
    }
    
    return {
      'isAlarmEnabled': isAlarmEnabled,
      'selectedNotificationType': selectedNotificationType,
      'selectedAlarmSound': selectedAlarmSound,
      'notificationVolume': notificationVolume,
    };
  }

  /// 設定を保存
  Future<void> saveSettings({
    required bool isAlarmEnabled,
    required String selectedNotificationType,
    required String selectedAlarmSound,
    required int notificationVolume,
  }) async {
    await prefs.setBool('alarm_enabled', isAlarmEnabled);
    await prefs.setString('notification_type', selectedNotificationType);
    await prefs.setString('alarm_sound', selectedAlarmSound);
    await prefs.setInt('notification_volume', notificationVolume);
  }

  /// 曜日データを読み込む
  List<bool> loadSelectedDays(int index) {
    final selectedDays = <bool>[];
    for (int j = 0; j < 7; j++) {
      final day = prefs.getBool('alarm_${index}_day_$j') ?? false;
      selectedDays.add(day);
    }
    return selectedDays;
  }

  /// データ整合性チェック
  Future<void> validateAlarmData() async {
    try {
      final alarmCount = prefs.getInt('alarm_count') ?? 0;
      debugPrint('🔍 データ整合性チェック開始: $alarmCount件のアラーム');
      
      // 通知設定の型チェック（強化版）
      debugPrint('🔍 notification_volumeの型チェック開始');
      try {
        final notificationVolume = prefs.getInt('notification_volume');
        if (notificationVolume != null) {
          debugPrint('✅ notification_volume: $notificationVolume (int型)');
        } else {
          debugPrint('⚠️ notification_volumeがint型で読み込めません');
          // 古いStringデータをチェック
          final volumeStr = prefs.getString('notification_volume');
          if (volumeStr != null) {
            debugPrint('⚠️ notification_volumeが文字列として保存されています: $volumeStr');
            // 正しい型で再保存
            final volumeInt = int.tryParse(volumeStr) ?? 80;
            await prefs.setInt('notification_volume', volumeInt);
            debugPrint('✅ notification_volumeを正しい型で再保存: $volumeInt');
          } else {
            debugPrint('⚠️ notification_volumeのデータが見つかりません。デフォルト値80で保存');
            await prefs.setInt('notification_volume', 80);
          }
        }
      } catch (e) {
        debugPrint('❌ notification_volume型チェックエラー: $e');
        // エラーが発生した場合、デフォルト値で保存
        await prefs.setInt('notification_volume', 80);
        debugPrint('✅ notification_volumeをデフォルト値80で保存');
      }
      
      for (int i = 0; i < alarmCount; i++) {
        // 各フィールドの型をチェック
        final name = prefs.getString('alarm_${i}_name');
        final time = prefs.getString('alarm_${i}_time');
        final volume = prefs.getInt('alarm_${i}_volume');
        
        if (name == null || name.isEmpty) {
          debugPrint('⚠️ アラーム $i: nameが無効');
        }
        if (time == null || time.isEmpty) {
          debugPrint('⚠️ アラーム $i: timeが無効');
        }
        if (volume == null) {
          debugPrint('⚠️ アラーム $i: volumeが無効（型エラーの可能性）');
          // 古いStringデータをチェック
          final volumeStr = prefs.getString('alarm_${i}_volume');
          if (volumeStr != null) {
            debugPrint('⚠️ アラーム $i: volumeが文字列として保存されています: $volumeStr');
            // 正しい型で再保存
            final volumeInt = int.tryParse(volumeStr) ?? 80;
            await prefs.setInt('alarm_${i}_volume', volumeInt);
            debugPrint('✅ アラーム $i: volumeを正しい型で再保存: $volumeInt');
          }
        }
      }
      
      debugPrint('✅ データ整合性チェック完了');
    } catch (e) {
      debugPrint('❌ データ整合性チェックエラー: $e');
    }
  }

  /// アラームを保存
  Future<void> saveAlarms(List<Map<String, dynamic>> alarms) async {
    try {
      // アラーム数を保存
      await prefs.setInt('alarm_count', alarms.length);
      debugPrint('✅ アラーム数保存完了: ${alarms.length}件');
      
      // 各アラームのデータを個別に保存（完全な型安全性）
      for (int i = 0; i < alarms.length; i++) {
        try {
          final alarm = alarms[i];
          debugPrint('💾 アラーム $i 保存: ${alarm['name']}');
          
          // 文字列フィールド
          await prefs.setString('alarm_${i}_name', alarm['name']?.toString() ?? 'アラーム');
          await prefs.setString('alarm_${i}_time', alarm['time']?.toString() ?? '00:00');
          await prefs.setString('alarm_${i}_repeat', alarm['repeat']?.toString() ?? '一度だけ');
          await prefs.setString('alarm_${i}_alarmType', alarm['alarmType']?.toString() ?? 'sound');
          
          // ブール値
          final enabled = alarm['enabled'] is bool ? alarm['enabled'] as bool : true;
          await prefs.setBool('alarm_${i}_enabled', enabled);
          
          final isRepeatEnabled = alarm['isRepeatEnabled'] is bool ? alarm['isRepeatEnabled'] as bool : false;
          await prefs.setBool('alarm_${i}_isRepeatEnabled', isRepeatEnabled);
          
          // 整数値（volumeの型安全性を完全保証）
          int volume = 80;
          if (alarm['volume'] is int) {
            volume = alarm['volume'] as int;
          } else if (alarm['volume'] is String) {
            volume = int.tryParse(alarm['volume'] as String) ?? 80;
            debugPrint('⚠️ アラーム $i: volumeを文字列から整数に変換: ${alarm['volume']} -> $volume');
          } else if (alarm['volume'] is double) {
            volume = (alarm['volume'] as double).round();
          }
          await prefs.setInt('alarm_${i}_volume', volume);
          debugPrint('✅ アラーム $i volume保存: $volume');
          
          // 曜日データ
          final selectedDays = alarm['selectedDays'] is List ? 
                              (alarm['selectedDays'] as List).cast<bool>() : 
                              [false, false, false, false, false, false, false];
          for (int j = 0; j < 7; j++) {
            await prefs.setBool('alarm_${i}_day_$j', j < selectedDays.length ? selectedDays[j] : false);
          }
          
          debugPrint('✅ アラーム $i 保存完了');
        } catch (e) {
          debugPrint('❌ アラーム $i 保存エラー: $e');
          continue;
        }
      }
      
      // 保存完了を確認
      final savedCount = prefs.getInt('alarm_count') ?? 0;
      debugPrint('✅ 保存確認: $savedCount件のアラームが保存されました');
      
    } catch (e, stackTrace) {
      debugPrint('❌ アラームデータ保存エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }

  /// アラームを読み込み
  Future<List<Map<String, dynamic>>> loadAlarms() async {
    debugPrint('📂 アラーム読み込み開始');
    
    try {
      final alarmCount = prefs.getInt('alarm_count') ?? 0;
      debugPrint('📂 保存されているアラーム数: $alarmCount件');
      
      if (alarmCount == 0) {
        debugPrint('ℹ️ アラームデータなし');
        return [];
      }
      
      final alarmsList = <Map<String, dynamic>>[];
      
      for (int i = 0; i < alarmCount; i++) {
        try {
          // 各フィールドを型安全に取得
          final name = prefs.getString('alarm_${i}_name') ?? 'アラーム';
          final time = prefs.getString('alarm_${i}_time') ?? '00:00';
          final repeat = prefs.getString('alarm_${i}_repeat') ?? '一度だけ';
          final enabled = prefs.getBool('alarm_${i}_enabled') ?? true;
          final alarmType = prefs.getString('alarm_${i}_alarmType') ?? 'sound';
          final isRepeatEnabled = prefs.getBool('alarm_${i}_isRepeatEnabled') ?? false;
          
          // volumeの完全な型安全性
          int volume = 80;
          final volumeInt = prefs.getInt('alarm_${i}_volume');
          if (volumeInt != null) {
            volume = volumeInt;
          } else {
            final volumeStr = prefs.getString('alarm_${i}_volume');
            if (volumeStr != null && volumeStr.isNotEmpty) {
              volume = int.tryParse(volumeStr) ?? 80;
              debugPrint('⚠️ アラーム $i: volumeを文字列から整数に変換: $volumeStr -> $volume');
            }
          }
          
          // 曜日データを読み込み
          final selectedDays = <bool>[];
          for (int j = 0; j < 7; j++) {
            selectedDays.add(prefs.getBool('alarm_${i}_day_$j') ?? false);
          }
          
          debugPrint('📂 アラーム $i 読み込み: name=$name, time=$time, volume=$volume');
          
          // アラームをリストに追加
          alarmsList.add({
            'name': name,
            'time': time,
            'repeat': repeat,
            'enabled': enabled,
            'alarmType': alarmType,
            'volume': volume,
            'isRepeatEnabled': isRepeatEnabled,
            'selectedDays': selectedDays,
          });
          
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
}

