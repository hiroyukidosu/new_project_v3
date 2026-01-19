/// 型安全なモデルクラス
/// 
/// 既存のMap<String, dynamic>を型安全なクラスに置き換え

/// アラーム情報の型安全なモデル
class AlarmModel {
  final String id;
  final String name;
  final String time;
  final int volume;
  final bool isEnabled;
  final List<int> weekdays;
  final String soundType;
  final bool isVibrationEnabled;
  
  const AlarmModel({
    required this.id,
    required this.name,
    required this.time,
    required this.volume,
    required this.isEnabled,
    required this.weekdays,
    required this.soundType,
    required this.isVibrationEnabled,
  });
  
  /// MapからAlarmModelを作成
  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    return AlarmModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'アラーム',
      time: map['time']?.toString() ?? '09:00',
      volume: (map['volume'] as int?) ?? 80,
      isEnabled: (map['isEnabled'] as bool?) ?? true,
      weekdays: (map['weekdays'] as List<dynamic>?)?.cast<int>() ?? [1, 2, 3, 4, 5],
      soundType: map['soundType']?.toString() ?? 'default',
      isVibrationEnabled: (map['isVibrationEnabled'] as bool?) ?? true,
    );
  }
  
  /// AlarmModelをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'volume': volume,
      'isEnabled': isEnabled,
      'weekdays': weekdays,
      'soundType': soundType,
      'isVibrationEnabled': isVibrationEnabled,
    };
  }
  
  /// コピーを作成（一部のプロパティを変更）
  AlarmModel copyWith({
    String? id,
    String? name,
    String? time,
    int? volume,
    bool? isEnabled,
    List<int>? weekdays,
    String? soundType,
    bool? isVibrationEnabled,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      volume: volume ?? this.volume,
      isEnabled: isEnabled ?? this.isEnabled,
      weekdays: weekdays ?? this.weekdays,
      soundType: soundType ?? this.soundType,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlarmModel &&
        other.id == id &&
        other.name == name &&
        other.time == time &&
        other.volume == volume &&
        other.isEnabled == isEnabled &&
        other.weekdays == weekdays &&
        other.soundType == soundType &&
        other.isVibrationEnabled == isVibrationEnabled;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      time,
      volume,
      isEnabled,
      weekdays,
      soundType,
      isVibrationEnabled,
    );
  }
  
  @override
  String toString() {
    return 'AlarmModel(id: $id, name: $name, time: $time, volume: $volume, isEnabled: $isEnabled, weekdays: $weekdays, soundType: $soundType, isVibrationEnabled: $isVibrationEnabled)';
  }
}

/// 服用記録の型安全なモデル
class MedicationRecordModel {
  final String id;
  final String medicationName;
  final String date;
  final String timeSlot;
  final bool isTaken;
  final String? memo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const MedicationRecordModel({
    required this.id,
    required this.medicationName,
    required this.date,
    required this.timeSlot,
    required this.isTaken,
    this.memo,
    required this.createdAt,
    this.updatedAt,
  });
  
  /// MapからMedicationRecordModelを作成
  factory MedicationRecordModel.fromMap(Map<String, dynamic> map) {
    return MedicationRecordModel(
      id: map['id']?.toString() ?? '',
      medicationName: map['medicationName']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      timeSlot: map['timeSlot']?.toString() ?? '',
      isTaken: (map['isTaken'] as bool?) ?? false,
      memo: map['memo']?.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
  
  /// MedicationRecordModelをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationName': medicationName,
      'date': date,
      'timeSlot': timeSlot,
      'isTaken': isTaken,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  /// コピーを作成
  MedicationRecordModel copyWith({
    String? id,
    String? medicationName,
    String? date,
    String? timeSlot,
    bool? isTaken,
    String? memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationRecordModel(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      isTaken: isTaken ?? this.isTaken,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationRecordModel &&
        other.id == id &&
        other.medicationName == medicationName &&
        other.date == date &&
        other.timeSlot == timeSlot &&
        other.isTaken == isTaken &&
        other.memo == memo &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      id,
      medicationName,
      date,
      timeSlot,
      isTaken,
      memo,
      createdAt,
      updatedAt,
    );
  }
  
  @override
  String toString() {
    return 'MedicationRecordModel(id: $id, medicationName: $medicationName, date: $date, timeSlot: $timeSlot, isTaken: $isTaken, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// アプリ設定の型安全なモデル
class AppSettingsModel {
  final bool isDarkMode;
  final String language;
  final bool isNotificationEnabled;
  final bool isVibrationEnabled;
  final int defaultVolume;
  final String defaultSoundType;
  final bool isAutoBackupEnabled;
  final int backupIntervalHours;
  
  const AppSettingsModel({
    required this.isDarkMode,
    required this.language,
    required this.isNotificationEnabled,
    required this.isVibrationEnabled,
    required this.defaultVolume,
    required this.defaultSoundType,
    required this.isAutoBackupEnabled,
    required this.backupIntervalHours,
  });
  
  /// MapからAppSettingsModelを作成
  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      isDarkMode: (map['isDarkMode'] as bool?) ?? false,
      language: map['language']?.toString() ?? 'ja',
      isNotificationEnabled: (map['isNotificationEnabled'] as bool?) ?? true,
      isVibrationEnabled: (map['isVibrationEnabled'] as bool?) ?? true,
      defaultVolume: (map['defaultVolume'] as int?) ?? 80,
      defaultSoundType: map['defaultSoundType']?.toString() ?? 'default',
      isAutoBackupEnabled: (map['isAutoBackupEnabled'] as bool?) ?? true,
      backupIntervalHours: (map['backupIntervalHours'] as int?) ?? 24,
    );
  }
  
  /// AppSettingsModelをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'language': language,
      'isNotificationEnabled': isNotificationEnabled,
      'isVibrationEnabled': isVibrationEnabled,
      'defaultVolume': defaultVolume,
      'defaultSoundType': defaultSoundType,
      'isAutoBackupEnabled': isAutoBackupEnabled,
      'backupIntervalHours': backupIntervalHours,
    };
  }
  
  /// コピーを作成
  AppSettingsModel copyWith({
    bool? isDarkMode,
    String? language,
    bool? isNotificationEnabled,
    bool? isVibrationEnabled,
    int? defaultVolume,
    String? defaultSoundType,
    bool? isAutoBackupEnabled,
    int? backupIntervalHours,
  }) {
    return AppSettingsModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      defaultVolume: defaultVolume ?? this.defaultVolume,
      defaultSoundType: defaultSoundType ?? this.defaultSoundType,
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      backupIntervalHours: backupIntervalHours ?? this.backupIntervalHours,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettingsModel &&
        other.isDarkMode == isDarkMode &&
        other.language == language &&
        other.isNotificationEnabled == isNotificationEnabled &&
        other.isVibrationEnabled == isVibrationEnabled &&
        other.defaultVolume == defaultVolume &&
        other.defaultSoundType == defaultSoundType &&
        other.isAutoBackupEnabled == isAutoBackupEnabled &&
        other.backupIntervalHours == backupIntervalHours;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      isDarkMode,
      language,
      isNotificationEnabled,
      isVibrationEnabled,
      defaultVolume,
      defaultSoundType,
      isAutoBackupEnabled,
      backupIntervalHours,
    );
  }
  
  @override
  String toString() {
    return 'AppSettingsModel(isDarkMode: $isDarkMode, language: $language, isNotificationEnabled: $isNotificationEnabled, isVibrationEnabled: $isVibrationEnabled, defaultVolume: $defaultVolume, defaultSoundType: $defaultSoundType, isAutoBackupEnabled: $isAutoBackupEnabled, backupIntervalHours: $backupIntervalHours)';
  }
}
