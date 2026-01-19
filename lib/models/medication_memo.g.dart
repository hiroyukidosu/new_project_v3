// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_memo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationMemoAdapter extends TypeAdapter<MedicationMemo> {
  @override
  final int typeId = 0;

  @override
  MedicationMemo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationMemo(
      id: fields[0] as String,
      name: fields[1] as String,
      dosage: fields[2] as String,
      notes: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      isActive: fields[6] as bool,
      selectedDays: (fields[7] as List).cast<int>(),
      time: fields[8] as String,
      color: fields[9] as String,
      type: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationMemo obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dosage)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.selectedDays)
      ..writeByte(8)
      ..write(obj.time)
      ..writeByte(9)
      ..write(obj.color)
      ..writeByte(10)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationMemoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
