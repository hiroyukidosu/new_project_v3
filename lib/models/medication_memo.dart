// Flutter core imports
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] ?? '薬品',
        dosage: json['dosage'] ?? '',
        notes: json['notes'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        lastTaken: json['lastTaken'] != null ? DateTime.parse(json['lastTaken']) : null,
        color: Color(json['color'] ?? Colors.blue.value),
        selectedWeekdays: List<int>.from(json['selectedWeekdays'] ?? []),
        dosageFrequency: json['dosageFrequency'] ?? 1,
      );
}

class MedicationMemoAdapter extends TypeAdapter<MedicationMemo> {
  @override
  final int typeId = 2;

  @override
  MedicationMemo read(BinaryReader reader) {
    return MedicationMemo(
      id: reader.readString(),
      name: reader.readString(),
      type: reader.readString(),
      dosage: reader.readString(),
      notes: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
      lastTaken: reader.readBool() ? DateTime.parse(reader.readString()) : null,
      color: Color(reader.readInt()),
      selectedWeekdays: List<int>.from(reader.readList()),
      dosageFrequency: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MedicationMemo obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.type);
    writer.writeString(obj.dosage);
    writer.writeString(obj.notes);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeBool(obj.lastTaken != null);
    if (obj.lastTaken != null) {
      writer.writeString(obj.lastTaken!.toIso8601String());
    }
    writer.writeInt(obj.color.value);
    writer.writeList(obj.selectedWeekdays);
    writer.writeInt(obj.dosageFrequency);
  }
}