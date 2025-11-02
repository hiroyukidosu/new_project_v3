// lib/alarm/alarm_settings_manager.dart
// アラーム設定管理機能を分離

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アラーム設定管理クラス
class AlarmSettingsManager {
  final SharedPreferences prefs;

  AlarmSettingsManager(this.prefs);

  /// 設定を読み込み
  Future<Map<String, dynamic>> loadSettings() async {
    final isAlarmEnabled = prefs.getBool('alarm_enabled') ?? true;
    final selectedNotificationType = prefs.getString('notification_type') ?? 'sound';
    final selectedAlarmSound = prefs.getString('alarm_sound') ?? 'default';
    
    // 型安全な読み込み（古いStringデータにも対応）
    int notificationVolume = 80;
    try {
      final volumeInt = prefs.getInt('notification_volume');
      if (volumeInt != null) {
        notificationVolume = volumeInt;
        debugPrint('✅ notification_volume読み込み成功: $notificationVolume (int型)');
      } else {
        final volumeStr = prefs.getString('notification_volume');
        if (volumeStr != null && volumeStr.isNotEmpty) {
          notificationVolume = int.tryParse(volumeStr) ?? 80;
          debugPrint('⚠️ volumeを文字列から整数に変換: $volumeStr -> $notificationVolume');
          await prefs.setInt('notification_volume', notificationVolume);
        } else {
          notificationVolume = 80;
          debugPrint('⚠️ notification_volumeのデータが見つかりません。デフォルト値80を使用');
        }
      }
    } catch (e) {
      debugPrint('❌ notification_volume読み込みエラー: $e');
      notificationVolume = 80;
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
    debugPrint('✅ 設定保存完了');
  }

  /// データ整合性チェック
  Future<void> validateAlarmData() async {
    try {
      final alarmCount = prefs.getInt('alarm_count') ?? 0;
      debugPrint('🔍 データ整合性チェック開始: $alarmCount件のアラーム');
      
      // notification_volumeの型チェック
      try {
        final notificationVolume = prefs.getInt('notification_volume');
        if (notificationVolume != null) {
          debugPrint('✅ notification_volume: $notificationVolume (int型)');
        } else {
          debugPrint('⚠️ notification_volumeがint型で読み込めません');
          final volumeStr = prefs.getString('notification_volume');
          if (volumeStr != null) {
            debugPrint('⚠️ notification_volumeが文字列として保存されています: $volumeStr');
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
        await prefs.setInt('notification_volume', 80);
      }
      
      for (int i = 0; i < alarmCount; i++) {
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
          // 型エラーを修正
          final volumeStr = prefs.getString('alarm_${i}_volume');
          if (volumeStr != null) {
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
}

