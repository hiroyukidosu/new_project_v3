import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        selectedDays: [1, 2, 3],
        createdAt: DateTime.now(),
      );
      
      expect(memo.id, equals('test_id'));
      expect(memo.name, equals('テスト薬'));
      expect(memo.dosage, equals('1錠'));
      expect(memo.type, equals('薬'));
      expect(memo.selectedDays, equals([1, 2, 3]));
    });
    
    test('MedicationMemoのJSON変換が正常に動作する', () {
      final memo = MedicationMemo(
        id: 'test_id',
        name: 'テスト薬',
        dosage: '1錠',
        type: '薬',
        selectedDays: [1, 2, 3],
        createdAt: DateTime.now(),
      );
      
      final json = memo.toJson();
      final restoredMemo = MedicationMemo.fromJson(json);
      
      expect(restoredMemo.id, equals(memo.id));
      expect(restoredMemo.name, equals(memo.name));
      expect(restoredMemo.dosage, equals(memo.dosage));
      expect(restoredMemo.type, equals(memo.type));
      expect(restoredMemo.selectedDays, equals(memo.selectedDays));
    });
    
    test('MedicationMemoのcopyWithが正常に動作する', () {
      final originalMemo = MedicationMemo(
        id: 'test_id',
        name: 'テスト薬',
        dosage: '1錠',
        type: '薬',
        selectedDays: [1, 2, 3],
        createdAt: DateTime.now(),
      );
      
      final updatedMemo = originalMemo.copyWith(
        name: '更新された薬',
        dosage: '2錠',
      );
      
      expect(updatedMemo.id, equals(originalMemo.id));
      expect(updatedMemo.name, equals('更新された薬'));
      expect(updatedMemo.dosage, equals('2錠'));
      expect(updatedMemo.type, equals(originalMemo.type));
      expect(updatedMemo.selectedDays, equals(originalMemo.selectedDays));
    });
  });
}
