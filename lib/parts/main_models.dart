part of '../main.dart';

class MedicineData {
  final String name;
  final String dosage;
  final String frequency;
  final String notes;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;
  final Color color;
  MedicineData({
    required this.name,
    this.dosage = '',
    this.frequency = '',
    this.notes = '',
    this.category = '処方薬',
    this.startDate,
    this.endDate,
    Color? color,
  }) : color = color ?? Colors.blue;
  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'notes': notes,
        'category': category,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'color': color.value,
      };
  factory MedicineData.fromJson(Map<String, dynamic> json) => MedicineData(
        name: json['name'] as String? ?? '',
        dosage: json['dosage'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        category: json['category'] as String? ?? '処方薬',
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
        color: Color(json['color'] as int? ?? Colors.blue.value),
      );
}

/// 服用メモのデータモデル
/// 薬やサプリメントの情報を管理
// Hive最適化版のMedicationMemo（大量データ対応）
class MedicationMemo {
  final String id;
  final String name;
  final String type; // '薬品' or 'サプリメント'
  final String dosage;
  final String notes;
  final DateTime createdAt;
  final DateTime? lastTaken;
  final Color color;
  final List<int> selectedWeekdays; // 0=日曜日, 1=月曜日, ..., 6=土曜日
  final int dosageFrequency; // 服用回数（1〜6回）
  
  MedicationMemo({
    required this.id,
    required this.name,
    required this.type,
    this.dosage = '',
    this.notes = '',
    required this.createdAt,
    this.lastTaken,
    Color? color,
    this.selectedWeekdays = const [],
    this.dosageFrequency = 1,
  }) : color = color ?? Colors.blue;
  
  // JSON変換（後方互換性）
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'dosage': dosage,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'lastTaken': lastTaken?.toIso8601String(),
        'color': color.value,
        'selectedWeekdays': selectedWeekdays,
        'dosageFrequency': dosageFrequency,
      };
      
  factory MedicationMemo.fromJson(Map<String, dynamic> json) => MedicationMemo(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '薬品',
        dosage: json['dosage'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastTaken: json['lastTaken'] != null ? DateTime.parse(json['lastTaken'] as String) : null,
        color: Color(json['color'] as int? ?? Colors.blue.value),
        selectedWeekdays: List<int>.from(json['selectedWeekdays'] as List? ?? []),
        dosageFrequency: json['dosageFrequency'] as int? ?? 1,
      );
}

class MedicineDataAdapter extends TypeAdapter<MedicineData> {
  @override
  final int typeId = 1;
  @override
  MedicineData read(BinaryReader reader) {
    return MedicineData(
      name: reader.readString(),
      dosage: reader.readString(),
      frequency: reader.readString(),
      notes: reader.readString(),
      category: reader.readString(),
      startDate: reader.read() as DateTime?,
      endDate: reader.read() as DateTime?,
      color: Color(reader.readInt()),
    );
  }
  @override
  void write(BinaryWriter writer, MedicineData obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.dosage);
    writer.writeString(obj.frequency);
    writer.writeString(obj.notes);
    writer.writeString(obj.category);
    writer.write(obj.startDate);
    writer.write(obj.endDate);
    writer.writeInt(obj.color.value);
  }
}

class MedicationInfo {
  final bool checked;
  final String medicine;
  final DateTime? actualTime;
  final String notes;
  final String sideEffects;
  MedicationInfo({
    required this.checked,
    required this.medicine,
    this.actualTime,
    this.notes = '',
    this.sideEffects = '',
  });
  Map<String, dynamic> toJson() => {
        'checked': checked,
        'medicine': medicine,
        'actualTime': actualTime?.toIso8601String(),
        'notes': notes,
        'sideEffects': sideEffects,
      };
  factory MedicationInfo.fromJson(Map<String, dynamic> json) => MedicationInfo(
        checked: json['checked'] as bool? ?? false,
        medicine: json['medicine'] as String? ?? '',
        actualTime: json['actualTime'] != null ? DateTime.parse(json['actualTime'] as String) : null,
        notes: json['notes'] as String? ?? '',
        sideEffects: json['sideEffects'] as String? ?? '',
      );
}

class MedicationInfoAdapter extends TypeAdapter<MedicationInfo> {
  @override
  final int typeId = 0;
  @override
  MedicationInfo read(BinaryReader reader) {
    return MedicationInfo(
      checked: reader.readBool(),
      medicine: reader.readString(),
      actualTime: reader.read() as DateTime?,
      notes: reader.readString(),
      sideEffects: reader.readString(),
    );
  }
  @override
  void write(BinaryWriter writer, MedicationInfo obj) {
    writer.writeBool(obj.checked);
    writer.writeString(obj.medicine);
    writer.write(obj.actualTime);
    writer.writeString(obj.notes);
    writer.writeString(obj.sideEffects);
  }
}
