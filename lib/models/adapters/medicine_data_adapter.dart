import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import '../medicine_data.dart';

/// 薬物データのHiveアダプター
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

