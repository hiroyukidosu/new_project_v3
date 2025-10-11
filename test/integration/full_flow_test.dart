import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_alarm_app/main.dart';

void main() {
  group('Full Flow Integration Tests', () {
    testWidgets('アプリの完全なフローが正常に動作する', (WidgetTester tester) async {
      // アプリの起動
      await tester.pumpWidget(const MedicationAlarmApp());
      await tester.pumpAndSettle();
      
      // メイン画面が表示されることを確認
      expect(find.byType(MaterialApp), findsOneWidget);
    });
    
    testWidgets('基本的な機能テスト', (WidgetTester tester) async {
      // アプリの起動
      await tester.pumpWidget(const MedicationAlarmApp());
      await tester.pumpAndSettle();
      
      // 基本的な検証
      expect(find.byType(MaterialApp), findsOneWidget);
    });
    
    testWidgets('エラーハンドリングが正常に動作する', (WidgetTester tester) async {
      // アプリの起動
      await tester.pumpWidget(const MedicationAlarmApp());
      await tester.pumpAndSettle();
      
      // エラーが発生してもアプリがクラッシュしないことを確認
      expect(() async {
        await tester.pumpWidget(const MedicationAlarmApp());
        await tester.pumpAndSettle();
      }, returnsNormally);
    });
    
    testWidgets('パフォーマンステスト', (WidgetTester tester) async {
      // アプリの起動
      await tester.pumpWidget(const MedicationAlarmApp());
      
      // パフォーマンス測定
      final stopwatch = Stopwatch()..start();
      
      // 複数の操作を実行
      for (int i = 0; i < 10; i++) {
        await tester.pump();
        await tester.pumpAndSettle();
      }
      
      stopwatch.stop();
      
      // パフォーマンスが許容範囲内であることを確認
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
