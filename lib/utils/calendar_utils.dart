import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// カレンダー関連のユーティリティ関数
/// 
/// 既存のmain.dartから安全に抽出した関数群
/// 既存機能に影響を与えずに再利用可能
class CalendarUtils {
  /// カレンダーの日付セルを構築
  /// 
  /// 既存の_buildCalendarDayメソッドをベースにした安全な実装
  static Widget buildCalendarDay(
    DateTime day, {
    bool isSelected = false,
    bool isToday = false,
    bool hasMark = false,
    int eventCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected 
                ? Colors.white 
                : isToday 
                  ? Colors.blue 
                  : Colors.black,
              fontWeight: isSelected || isToday 
                ? FontWeight.bold 
                : FontWeight.normal,
            ),
          ),
          if (hasMark || eventCount > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasMark)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (eventCount > 0) ...[
                  if (hasMark) const SizedBox(width: 2),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// カレンダーのスタイルを構築
  /// 
  /// 既存の_buildCalendarStyleメソッドをベースにした安全な実装
  static CalendarStyle buildCalendarStyle() {
    return CalendarStyle(
      outsideDaysVisible: false,
      weekendTextStyle: const TextStyle(color: Colors.red),
      holidayTextStyle: const TextStyle(color: Colors.red),
      defaultTextStyle: const TextStyle(fontSize: 16),
      selectedTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      todayTextStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
      selectedDecoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      todayDecoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      defaultDecoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
    );
  }

  /// カレンダービルダーを構築
  /// 
  /// 既存のCalendarBuildersをベースにした安全な実装
  static CalendarBuilders buildCalendarBuilders({
    required Function(DateTime day) hasMark,
    required Function(DateTime day) getEventCount,
  }) {
    return CalendarBuilders(
      defaultBuilder: (context, day, focusedDay) {
        return buildCalendarDay(
          day,
          hasMark: hasMark(day) as bool,
          eventCount: getEventCount(day) as int,
        );
      },
      selectedBuilder: (context, day, focusedDay) {
        return buildCalendarDay(
          day,
          isSelected: true,
          hasMark: hasMark(day) as bool,
          eventCount: getEventCount(day) as int,
        );
      },
      todayBuilder: (context, day, focusedDay) {
        return buildCalendarDay(
          day,
          isToday: true,
          hasMark: hasMark(day) as bool,
          eventCount: getEventCount(day) as int,
        );
      },
    );
  }

  /// 日付をフォーマット
  static String formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  /// 日付が同じかチェック
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
