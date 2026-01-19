import 'package:flutter/material.dart';

/// 薬物・サプリメントのデータモデル
/// Hive最適化版のMedicationMemo（大量データ対応）
class MedicationMemo {
  final String id;
  final String name;
  final String type; // '薬物' or 'サプリメント'
  final String dosage;
  final String notes;
  final DateTime createdAt;
  final DateTime? lastTaken;
  final Color color;
  final List<int> selectedWeekdays; // 0=月曜日, 1=火曜日, ..., 6=日曜日
  final int dosageFrequency; // 薬物服用回数（1日何回）
  
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
  
  // JSON変換メソッド（保存・復元用）
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
        type: json['type'] ?? '薬物',
        dosage: json['dosage'] ?? '',
        notes: json['notes'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        lastTaken: json['lastTaken'] != null ? DateTime.parse(json['lastTaken']) : null,
        color: Color(json['color'] ?? Colors.blue.value),
        selectedWeekdays: List<int>.from(json['selectedWeekdays'] ?? []),
        dosageFrequency: json['dosageFrequency'] ?? 1,
      );
}
