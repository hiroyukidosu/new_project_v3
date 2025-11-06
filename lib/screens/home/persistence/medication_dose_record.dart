// レビュー指摘の修正：データ永続化の複雑さを改善するための専用モデルクラス

/// 服用回数記録モデル（レビュー指摘の修正）
/// 3層ネストのMapの代わりに、専用のモデルクラスを使用
class MedicationDoseRecord {
  final String date;
  final String memoId;
  final Map<int, bool> doses; // doseIndex -> isChecked
  
  MedicationDoseRecord({
    required this.date,
    required this.memoId,
    required this.doses,
  });
  
  /// Map形式に変換（後方互換性のため）
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'memoId': memoId,
      'doses': doses.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
  
  factory MedicationDoseRecord.fromMap(Map<String, dynamic> map) {
    return MedicationDoseRecord(
      date: map['date'] as String,
      memoId: map['memoId'] as String,
      doses: (map['doses'] as Map).map((k, v) => MapEntry(int.parse(k.toString()), v == true)),
    );
  }
  
  /// ネストされたMap形式に変換（既存コードとの互換性のため）
  Map<String, Map<String, Map<int, bool>>> toNestedMap() {
    return {
      date: {
        memoId: doses,
      },
    };
  }
  
  /// ネストされたMap形式から作成
  static List<MedicationDoseRecord> fromNestedMap(
    Map<String, Map<String, Map<int, bool>>> nestedMap,
  ) {
    final records = <MedicationDoseRecord>[];
    nestedMap.forEach((date, memoMap) {
      memoMap.forEach((memoId, doses) {
        records.add(MedicationDoseRecord(
          date: date,
          memoId: memoId,
          doses: doses,
        ));
      });
    });
    return records;
  }
  
  /// ネストされたMap形式に変換（複数のレコードから）
  static Map<String, Map<String, Map<int, bool>>> toNestedMapFromList(
    List<MedicationDoseRecord> records,
  ) {
    final nestedMap = <String, Map<String, Map<int, bool>>>{};
    for (final record in records) {
      nestedMap.putIfAbsent(record.date, () => {});
      nestedMap[record.date]![record.memoId] = record.doses;
    }
    return nestedMap;
  }
}

