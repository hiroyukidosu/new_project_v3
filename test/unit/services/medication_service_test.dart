import 'package:flutter_test/flutter_test.dart';
import 'package:medication_alarm_app/models/medication_memo.dart';

void main() {
  group('MedicationMemo Model Tests', () {
    test('MedicationMemoの作成が正常に動作する', () {
      // テストデータの作成
      final memo = MedicationMemo(
        id: 'test_id',
        name: 'テスト薬',
        dosage: '1錠',
        type: '薬',
        selectedWeekdays: [1, 2, 3],
        createdAt: DateTime.now(),
      );
      
      expect(memo.id, equals('test_id'));
      expect(memo.name, equals('テスト薬'));
      expect(memo.dosage, equals('1錠'));
      expect(memo.type, equals('薬'));
      expect(memo.selectedWeekdays, equals([1, 2, 3]));
    });
    
    test('MedicationMemoのJSON変換が正常に動作する', () {
      final memo = MedicationMemo(
        id: 'test_id',
        name: 'テスト薬',
        dosage: '1錠',
        type: '薬',
        selectedWeekdays: [1, 2, 3],
        createdAt: DateTime.now(),
      );
      
      final json = memo.toJson();
      final restoredMemo = MedicationMemo.fromJson(json);
      
      expect(restoredMemo.id, equals(memo.id));
      expect(restoredMemo.name, equals(memo.name));
      expect(restoredMemo.dosage, equals(memo.dosage));
      expect(restoredMemo.type, equals(memo.type));
      expect(restoredMemo.selectedWeekdays, equals(memo.selectedWeekdays));
    });
    
    test('MedicationMemoの比較が正常に動作する', () {
      final memo1 = MedicationMemo(
        id: 'test_id',
        name: 'テスト薬',
        dosage: '1錠',
        type: '薬',
        selectedWeekdays: [1, 2, 3],
        createdAt: DateTime.now(),
      );
      
      final memo2 = MedicationMemo(
        id: 'test_id',
        name: 'テスト薬',
        dosage: '1錠',
        type: '薬',
        selectedWeekdays: [1, 2, 3],
        createdAt: DateTime.now(),
      );
      
      expect(memo1.id, equals(memo2.id));
      expect(memo1.name, equals(memo2.name));
      expect(memo1.dosage, equals(memo2.dosage));
      expect(memo1.type, equals(memo2.type));
      expect(memo1.selectedWeekdays, equals(memo2.selectedWeekdays));
    });
  });
}
