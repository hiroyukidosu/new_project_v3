import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// カレンダー機能のテスト
/// 
/// 既存機能が壊れていないことを保証するテスト
void main() {
  group('Calendar Functionality Tests', () {
    testWidgets('カレンダーが正しく表示される', (WidgetTester tester) async {
      // カレンダーウィジェットの基本表示テスト
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TableCalendar<dynamic>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: DateTime.now(),
            ),
          ),
        ),
      );

      // カレンダーが表示されていることを確認
      expect(find.byType(TableCalendar), findsOneWidget);
    });

    testWidgets('日付選択が正しく動作する', (WidgetTester tester) async {
      DateTime? selectedDay;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TableCalendar<dynamic>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: DateTime.now(),
              selectedDayPredicate: (day) => selectedDay != null && isSameDay(selectedDay!, day),
              onDaySelected: (day, focusedDay) {
                selectedDay = day;
              },
            ),
          ),
        ),
      );

      // 日付をタップ
      final today = DateTime.now();
      final dayWidget = find.text('${today.day}');
      await tester.tap(dayWidget);
      await tester.pump();

      // 選択された日付が正しいことを確認
      expect(selectedDay, isNotNull);
      expect(isSameDay(selectedDay!, today), isTrue);
    });

    test('日付の比較が正しく動作する', () {
      final date1 = DateTime(2024, 1, 15);
      final date2 = DateTime(2024, 1, 15);
      final date3 = DateTime(2024, 1, 16);

      expect(isSameDay(date1, date2), isTrue);
      expect(isSameDay(date1, date3), isFalse);
    });
  });

  group('Calendar Utility Tests', () {
    test('カレンダースタイルの生成', () {
      // カレンダースタイルが正しく生成されることを確認
      final style = CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: const TextStyle(color: Colors.red),
        defaultTextStyle: const TextStyle(fontSize: 16),
      );

      expect(style.outsideDaysVisible, isFalse);
      expect(style.weekendTextStyle?.color, Colors.red);
      expect(style.defaultTextStyle?.fontSize, 16);
    });
  });
}
