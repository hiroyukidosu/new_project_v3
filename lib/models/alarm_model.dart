// lib/models/alarm_model.dart
// アラームデータモデル

import 'dart:convert';

/// アラームデータモデル
class Alarm {
  final String name;
  final String time;
  final String repeat;
  final bool enabled;
  final String alarmType;
  final int volume;
  final bool isRepeatEnabled;
  final List<bool> selectedDays;
  DateTime? lastTriggered;
  bool temporarilyDisabled;

  Alarm({
    required this.name,
    required this.time,
    this.repeat = '一度だけ',
    this.enabled = true,
    this.alarmType = 'sound',
    this.volume = 80,
    this.isRepeatEnabled = false,
    this.selectedDays = const [false, false, false, false, false, false, false],
    this.lastTriggered,
    this.temporarilyDisabled = false,
  });

  /// MapからAlarmを作成
  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      name: map['name']?.toString() ?? 'アラーム',
      time: map['time']?.toString() ?? '00:00',
      repeat: map['repeat']?.toString() ?? '一度だけ',
      enabled: map['enabled'] is bool ? map['enabled'] as bool : true,
      alarmType: map['alarmType']?.toString() ?? 'sound',
      volume: _parseVolume(map['volume']),
      isRepeatEnabled: map['isRepeatEnabled'] is bool ? map['isRepeatEnabled'] as bool : false,
      selectedDays: _parseSelectedDays(map['selectedDays']),
      lastTriggered: map['lastTriggered'] is DateTime ? map['lastTriggered'] as DateTime : null,
      temporarilyDisabled: map['temporarilyDisabled'] is bool ? map['temporarilyDisabled'] as bool : false,
    );
  }

  /// Mapに変換
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'time': time,
      'repeat': repeat,
      'enabled': enabled,
      'alarmType': alarmType,
      'volume': volume,
      'isRepeatEnabled': isRepeatEnabled,
      'selectedDays': selectedDays,
      'lastTriggered': lastTriggered,
      'temporarilyDisabled': temporarilyDisabled,
    };
  }

  /// JSON文字列からAlarmを作成
  factory Alarm.fromJson(String json) {
    return Alarm.fromMap(jsonDecode(json));
  }

  /// JSON文字列に変換
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Alarmのコピーを作成
  Alarm copyWith({
    String? name,
    String? time,
    String? repeat,
    bool? enabled,
    String? alarmType,
    int? volume,
    bool? isRepeatEnabled,
    List<bool>? selectedDays,
    DateTime? lastTriggered,
    bool? temporarilyDisabled,
  }) {
    return Alarm(
      name: name ?? this.name,
      time: time ?? this.time,
      repeat: repeat ?? this.repeat,
      enabled: enabled ?? this.enabled,
      alarmType: alarmType ?? this.alarmType,
      volume: volume ?? this.volume,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      temporarilyDisabled: temporarilyDisabled ?? this.temporarilyDisabled,
    );
  }

  /// バリデーション
  bool isValid() {
    if (name.isEmpty || name.trim().isEmpty) return false;
    if (time.isEmpty || !_isValidTimeFormat(time)) return false;
    if (volume < 0 || volume > 100) return false;
    if (selectedDays.length != 7) return false;
    return true;
  }

  /// 時間フォーマットの検証
  static bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  /// volumeの型安全なパース
  static int _parseVolume(dynamic volume) {
    if (volume is int) {
      return volume.clamp(0, 100);
    } else if (volume is String) {
      final parsed = int.tryParse(volume);
      return parsed != null ? parsed.clamp(0, 100) : 80;
    } else if (volume is double) {
      return volume.round().clamp(0, 100);
    }
    return 80;
  }

  /// selectedDaysの型安全なパース
  static List<bool> _parseSelectedDays(dynamic selectedDays) {
    if (selectedDays is List) {
      try {
        final days = selectedDays.cast<bool>();
        if (days.length == 7) {
          return days;
        }
      } catch (e) {
        // キャスト失敗時はデフォルト値を返す
      }
    }
    return [false, false, false, false, false, false, false];
  }

  @override
  String toString() {
    return 'Alarm(name: $name, time: $time, enabled: $enabled, repeat: $repeat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alarm &&
        other.name == name &&
        other.time == time &&
        other.repeat == repeat &&
        other.enabled == enabled &&
        other.alarmType == alarmType &&
        other.volume == volume;
  }

  @override
  int get hashCode {
    return Object.hash(name, time, repeat, enabled, alarmType, volume);
  }
}

