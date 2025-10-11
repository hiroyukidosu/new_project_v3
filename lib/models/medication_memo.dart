import 'package:hive/hive.dart';

part 'medication_memo.g.dart';

/// メディケーションメモのモデル
@HiveType(typeId: 0)
class MedicationMemo extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String dosage;
  
  @HiveField(3)
  final String notes;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final DateTime updatedAt;
  
  @HiveField(6)
  final bool isActive;
  
  @HiveField(7)
  final List<int> selectedDays;
  
  @HiveField(8)
  final String time;
  
  @HiveField(9)
  final String color;
  
  @HiveField(10)
  final String type;
  
  MedicationMemo({
    required this.id,
    required this.name,
    required this.dosage,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.selectedDays = const [],
    this.time = '',
    this.color = '',
    this.type = '薬品',
  });
  
  /// コピーコンストラクタ
  MedicationMemo copyWith({
    String? id,
    String? name,
    String? dosage,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<int>? selectedDays,
    String? time,
    String? color,
    String? type,
  }) {
    return MedicationMemo(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      selectedDays: selectedDays ?? this.selectedDays,
      time: time ?? this.time,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }
  
  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'selectedDays': selectedDays,
      'time': time,
      'color': color,
      'type': type,
    };
  }
  
  /// JSONから作成
  factory MedicationMemo.fromJson(Map<String, dynamic> json) {
    return MedicationMemo(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      selectedDays: (json['selectedDays'] as List<dynamic>?)?.cast<int>() ?? [],
      time: json['time'] as String? ?? '',
      color: json['color'] as String? ?? '',
      type: json['type'] as String? ?? '薬品',
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationMemo && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'MedicationMemo(id: $id, name: $name, dosage: $dosage, isActive: $isActive)';
  }
}