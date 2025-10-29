// Flutter core imports
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// 薬のデータモデル
/// 薬の名前、用量、頻度、メモを管理
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
        name: json['name'] ?? '',
        dosage: json['dosage'] ?? '',
        frequency: json['frequency'] ?? '',
        notes: json['notes'] ?? '',
        category: json['category'] ?? '処方薬',
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        color: Color(json['color'] ?? Colors.blue.value),
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