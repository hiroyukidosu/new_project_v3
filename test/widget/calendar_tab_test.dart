import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_alarm_app/screens/calendar_tab.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  group('CalendarTab Widget Tests', () {
    testWidgets('カレンダータブが正常に表示される', (WidgetTester tester) async {
      // テストデータの準備
      final selectedDay = DateTime.now();
      final focusedDay = DateTime.now();
      final selectedDates = {selectedDay};
      final events = <DateTime, List<dynamic>>{};
      final dayColors = <DateTime, Color>{};
      
      // ウィジェットの構築
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarTab(
              selectedDay: selectedDay,
              focusedDay: focusedDay,
              selectedDates: selectedDates,
              onDaySelected: (day, focused) {},
              onPageChanged: (day) {},
              events: events,
              dayColors: dayColors,
            ),
          ),
        ),
      );
      
      // カレンダーが表示されることを確認
      expect(find.byType(TableCalendar), findsOneWidget);
    });
    
    testWidgets('日付選択が正常に動作する', (WidgetTester tester) async {
      bool daySelectedCalled = false;
      DateTime? selectedDay;
      DateTime? focusedDay;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarTab(
              selectedDay: DateTime.now(),
              focusedDay: DateTime.now(),
              selectedDates: {},
              onDaySelected: (day, focused) {
                daySelectedCalled = true;
                selectedDay = day;
                focusedDay = focused;
              },
              onPageChanged: (day) {},
              events: {},
              dayColors: {},
            ),
          ),
        ),
      );
      
      // カレンダーの日付をタップ
      await tester.tap(find.byType(TableCalendar));
      await tester.pump();
      
      // コールバックが呼ばれることを確認
      expect(daySelectedCalled, isTrue);
    });
    
    testWidgets('イベントが正常に表示される', (WidgetTester tester) async {
      final selectedDay = DateTime.now();
      final events = {
        selectedDay: ['イベント1', 'イベント2'],
      };
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarTab(
              selectedDay: selectedDay,
              focusedDay: selectedDay,
              selectedDates: {selectedDay},
              onDaySelected: (day, focused) {},
              onPageChanged: (day) {},
              events: events,
              dayColors: {},
            ),
          ),
        ),
      );
      
      // カレンダーが表示されることを確認
      expect(find.byType(TableCalendar), findsOneWidget);
    });
  });
}
