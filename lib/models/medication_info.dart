/// 薬物情報のデータモデル
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
        checked: json['checked'] ?? false,
        medicine: json['medicine'] ?? '',
        actualTime: json['actualTime'] != null ? DateTime.parse(json['actualTime']) : null,
        notes: json['notes'] ?? '',
        sideEffects: json['sideEffects'] ?? '',
      );
}
