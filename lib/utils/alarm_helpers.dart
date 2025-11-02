// lib/utils/alarm_helpers.dart
// アラーム関連のヘルパー関数

import '../models/alarm_model.dart';

/// アラーム関連のヘルパー関数
class AlarmHelpers {
  /// 通知タイプ名を取得
  static String getNotificationTypeName(String type) {
    switch (type) {
      case 'sound':
        return '音';
      case 'sound_vibration':
        return '音+バイブ';
      case 'vibration':
        return 'バイブ';
      case 'silent':
        return 'サイレント';
      default:
        return 'デフォルト';
    }
  }

  /// アラームタイプ情報を取得
  static Map<String, dynamic> getAlarmTypeInfo(String type) {
    switch (type) {
      case 'sound':
        return {
          'name': '音',
          'icon': '🔊',
          'color': 'blue',
        };
      case 'sound_vibration':
        return {
          'name': '音+バイブ',
          'icon': '🔊📳',
          'color': 'orange',
        };
      case 'vibration':
        return {
          'name': 'バイブ',
          'icon': '📳',
          'color': 'purple',
        };
      case 'silent':
        return {
          'name': 'サイレント',
          'icon': '🔇',
          'color': 'grey',
        };
      default:
        return {
          'name': 'デフォルト',
          'icon': '🔔',
          'color': 'blue',
        };
    }
  }

  /// 繰り返し表示テキストを取得
  static String getRepeatDisplayText(Alarm alarm) {
    final repeat = alarm.repeat;
    final isRepeatEnabled = alarm.isRepeatEnabled;
    final selectedDays = alarm.selectedDays;
    
    if (!isRepeatEnabled || repeat == '一度だけ') {
      return '一度だけ';
    }
    
    if (repeat == '曜日') {
      const dayNames = ['月', '火', '水', '木', '金', '土', '日'];
      final selectedDayNames = <String>[];
      for (int i = 0; i < 7; i++) {
        if (selectedDays[i]) {
          selectedDayNames.add(dayNames[i]);
        }
      }
      return selectedDayNames.isEmpty ? '曜日未選択' : selectedDayNames.join(',');
    }
    
    return repeat;
  }

  /// アラームが発火すべきか判定
  static bool shouldTriggerAlarm(Alarm alarm, int currentWeekday) {
    // 一度だけの場合、常に発火
    if (!alarm.isRepeatEnabled || alarm.repeat == '一度だけ') {
      return true;
    }
    
    switch (alarm.repeat) {
      case '毎日':
        return true;
      case '平日':
        return currentWeekday >= 1 && currentWeekday <= 5; // 月〜金
      case '週末':
        return currentWeekday == 6 || currentWeekday == 7; // 土、日
      case '曜日':
        if (alarm.selectedDays.length == 7) {
          // 曜日配列のインデックス調整（月曜日=0, 日曜日=6）
          final dayIndex = currentWeekday == 7 ? 6 : currentWeekday - 1;
          return alarm.selectedDays[dayIndex];
        }
        return false;
      default:
        return true;
    }
  }

  /// 現在時刻を文字列で取得 (HH:mm形式)
  static String getCurrentTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// 時刻が一致しているか判定
  static bool isTimeMatch(String alarmTime, String currentTime) {
    return alarmTime == currentTime;
  }

  /// アラームが最近発火したか判定（1分以内）
  static bool wasRecentlyTriggered(Alarm alarm) {
    if (alarm.lastTriggered == null) return false;
    final now = DateTime.now();
    return now.difference(alarm.lastTriggered!).inMinutes < 1;
  }
}

