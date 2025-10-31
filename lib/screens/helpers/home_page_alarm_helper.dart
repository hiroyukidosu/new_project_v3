// アラーム関連ヘルパー
import 'package:shared_preferences/shared_preferences.dart';

class HomePageAlarmHelper {
  static Future<List<Map<String, dynamic>>> loadAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmCount = prefs.getInt('alarm_count') ?? 0;
      final alarmsList = <Map<String, dynamic>>[];
      for (int i = 0; i < alarmCount; i++) {
        final name = prefs.getString('alarm_${i}_name');
        final time = prefs.getString('alarm_${i}_time');
        final repeat = prefs.getString('alarm_${i}_repeat');
        final enabled = prefs.getBool('alarm_${i}_enabled');
        final alarmType = prefs.getString('alarm_${i}_alarmType');
        final volume = prefs.getInt('alarm_${i}_volume');
        final message = prefs.getString('alarm_${i}_message');
        if (name != null && time != null) {
          alarmsList.add({
            'name': name,
            'time': time,
            'repeat': repeat ?? '一度だけ',
            'enabled': enabled ?? true,
            'alarmType': alarmType ?? 'sound',
            'volume': volume ?? 80,
            'message': message ?? '薬を服用する時間です',
          });
        }
      }
      return alarmsList;
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveAlarmData(List<Map<String, dynamic>> alarmList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('alarm_count', alarmList.length);
      for (int i = 0; i < alarmList.length; i++) {
        final alarm = alarmList[i];
        await prefs.setString('alarm_${i}_name', alarm['name'] ?? '');
        await prefs.setString('alarm_${i}_time', alarm['time'] ?? '09:00');
        await prefs.setString('alarm_${i}_repeat', alarm['repeat'] ?? '一度だけ');
        await prefs.setBool('alarm_${i}_enabled', alarm['enabled'] ?? true);
        await prefs.setString('alarm_${i}_alarmType', alarm['alarmType'] ?? 'sound');
        await prefs.setInt('alarm_${i}_volume', alarm['volume'] ?? 80);
        await prefs.setString('alarm_${i}_message', alarm['message'] ?? '薬を服用する時間です');
      }
      await prefs.setString('alarm_backup_count', alarmList.length.toString());
      await prefs.setString('alarm_last_save', DateTime.now().toIso8601String());
    } catch (e) {
      // エラー処理
    }
  }

  static Future<void> checkAlarmDataIntegrity(List<Map<String, dynamic>> alarmList) async {
    for (int i = 0; i < alarmList.length; i++) {
      final alarm = alarmList[i];
      alarm['title'] ??= '服用アラーム';
      alarm['time'] ??= '09:00';
      alarm['enabled'] ??= true;
      alarm['message'] ??= '薬を服用する時間です';
    }
  }
}

