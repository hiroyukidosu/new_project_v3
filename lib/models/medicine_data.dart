// 薬データのモデルクラス
class MedicineData {
  final String id;
  final String name;
  final String dosage;
  final String type;
  final List<int> selectedDays;
  final Map<String, bool> status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MedicineData({
    required this.id,
    required this.name,
    required this.dosage,
    required this.type,
    required this.selectedDays,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'type': type,
      'selectedDays': selectedDays,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory MedicineData.fromJson(Map<String, dynamic> json) {
    return MedicineData(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      type: json['type'] as String,
      selectedDays: List<int>.from(json['selectedDays'] as List),
      status: Map<String, bool>.from(json['status'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  MedicineData copyWith({
    String? id,
    String? name,
    String? dosage,
    String? type,
    List<int>? selectedDays,
    Map<String, bool>? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineData(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      selectedDays: selectedDays ?? this.selectedDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicineData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MedicineData(id: $id, name: $name, dosage: $dosage, type: $type)';
  }
}
