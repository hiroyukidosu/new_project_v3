import 'package:flutter/material.dart';

/// 薬物のデータモデル
/// 薬物の名前、用量、頻度などを管理
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
