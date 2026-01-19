import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'medication_memo.dart';

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
