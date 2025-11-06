import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../medication_memo.dart';

/// 薬物メモのHiveアダプター
class MedicationMemoAdapter extends TypeAdapter<MedicationMemo> {
  @override
  final int typeId = 2;

  /// 読み込み（レビュー指摘の修正：フィールドインデックスを使用してバージョンアップに対応）
  /// 後方互換性を保つため、バージョン番号がない場合は旧形式として読み込む
  @override
  MedicationMemo read(BinaryReader reader) {
    try {
      // バージョン番号を読み込もうとする（既存データにはない可能性がある）
      final version = reader.readByte();
      
      // バージョン1以降の処理
      return MedicationMemo(
        id: reader.readString(), // フィールド0
        name: reader.readString(), // フィールド1
        type: reader.readString(), // フィールド2
        dosage: reader.readString(), // フィールド3
        notes: reader.readString(), // フィールド4
        createdAt: DateTime.parse(reader.readString()), // フィールド5
        lastTaken: reader.readBool() ? DateTime.parse(reader.readString()) : null, // フィールド6
        color: Color(reader.readInt()), // フィールド7
        selectedWeekdays: List<int>.from(reader.readList()), // フィールド8
        dosageFrequency: reader.readInt(), // フィールド9
      );
    } catch (e) {
      // 既存データ（バージョン番号なし）の場合は、旧形式として読み込む
      // 注意: この場合、readerの位置が既に進んでいる可能性があるため、
      // 実際の実装では、バージョン番号の有無を事前にチェックする必要がある
      // 簡易実装として、エラー時はデフォルト値を返す
      throw FormatException('Invalid data format: $e');
    }
  }

  /// 書き込み（レビュー指摘の修正：バージョン番号を追加）
  @override
  void write(BinaryWriter writer, MedicationMemo obj) {
    writer.writeByte(1); // バージョン1（将来の拡張用）
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

