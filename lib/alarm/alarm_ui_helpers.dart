// lib/alarm/alarm_ui_helpers.dart
// アラームUI構築ヘルパーを分離

import 'package:flutter/material.dart';

/// アラームUI構築ヘルパークラス
class AlarmUIHelpers {
  /// アラームタイプのチップを構築
  static Widget buildAlarmTypeChip(String type) {
    final typeInfo = getAlarmTypeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (typeInfo['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (typeInfo['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(typeInfo['icon'] as String, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            typeInfo['name'] as String,
            style: TextStyle(
              fontSize: 10,
              color: typeInfo['color'] as Color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 音量のチップを構築
  static Widget buildVolumeChip(int volume) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.volume_up, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '$volume%',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// アラームタイプ情報を取得
  static Map<String, dynamic> getAlarmTypeInfo(String type) {
    switch (type) {
      case 'sound':
        return {'name': '音', 'icon': '🔊', 'color': Colors.blue};
      case 'sound_vibration':
        return {'name': '音＋バイブ', 'icon': '🔊📳', 'color': Colors.green};
      case 'vibration':
        return {'name': 'バイブ', 'icon': '📳', 'color': Colors.orange};
      case 'silent':
        return {'name': 'サイレント', 'icon': '🔇', 'color': Colors.grey};
      default:
        return {'name': 'デフォルト', 'icon': '🔔', 'color': Colors.blue};
    }
  }

  /// 通知タイプ名を取得
  static String getNotificationTypeName(String type) {
    switch (type) {
      case 'sound':
        return '音';
      case 'sound_vibration':
        return '音＋バイブ';
      case 'vibration':
        return 'バイブ';
      case 'silent':
        return 'サイレント';
      default:
        return 'デフォルト';
    }
  }

  /// 繰り返し表示テキストを取得
  static String getRepeatDisplayText(Map<String, dynamic> alarm) {
    final repeat = alarm['repeat'] ?? '一度だけ';
    final isRepeatEnabled = alarm['isRepeatEnabled'] ?? false;
    final selectedDays = alarm['selectedDays'] as List<bool>?;
    
    if (!(isRepeatEnabled as bool) || repeat == '一度だけ') {
      return '一度だけ';
    }
    
    if (repeat == '曜日' && selectedDays != null) {
      const days = ['月', '火', '水', '木', '金', '土', '日'];
      final selectedDayNames = <String>[];
      for (int i = 0; i < 7; i++) {
        if (selectedDays[i]) {
          selectedDayNames.add(days[i]);
        }
      }
      return selectedDayNames.isEmpty ? '曜日未選択' : selectedDayNames.join(',');
    }
    
    return repeat as String;
  }
}

