import 'package:hive/hive.dart';
import '../medication_info.dart';

/// 薬物情報のHiveアダプター
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

