// Flutter core imports
import 'package:hive/hive.dart';

// 服用情報のデータモデル
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

// MedicationInfoのHiveアダプター
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
