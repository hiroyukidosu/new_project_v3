import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// カレンダータブの状態管理
/// 
/// 責務:
/// - 日付選択の管理
/// - 服用記録の表示
/// - カレンダーマークの更新
class CalendarController extends ChangeNotifier {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> _events = {};
  Map<DateTime, bool> _calendarMarks = {};

  // Getters
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  CalendarFormat get calendarFormat => _calendarFormat;
  Map<DateTime, List<dynamic>> get events => _events;
  Map<DateTime, bool> get calendarMarks => _calendarMarks;

  /// 日付を選択
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      notifyListeners();
    }
  }

  /// フォーカスされた日付を変更
  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
  }

  /// カレンダーフォーマットを変更
  void onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      _calendarFormat = format;
      notifyListeners();
    }
  }

  /// カレンダーマークを更新
  void updateCalendarMarks(Map<DateTime, bool> marks) {
    _calendarMarks = marks;
    notifyListeners();
  }

  /// イベントを更新
  void updateEvents(Map<DateTime, List<dynamic>> newEvents) {
    _events = newEvents;
    notifyListeners();
  }

  /// カレンダーマークを保存
  Future<void> saveCalendarMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final marksJson = <String, bool>{};
      
      for (final entry in _calendarMarks.entries) {
        marksJson[entry.key.toIso8601String()] = entry.value;
      }
      
      await prefs.setString('calendar_marks', jsonEncode(marksJson));
    } catch (e) {
      debugPrint('カレンダーマーク保存エラー: $e');
    }
  }

  /// カレンダーマークを読み込み
  Future<void> loadCalendarMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final marksString = prefs.getString('calendar_marks');
      
      if (marksString != null) {
        final marksJson = jsonDecode(marksString) as Map<String, dynamic>;
        _calendarMarks = marksJson.map(
          (key, value) => MapEntry(DateTime.parse(key), value as bool),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('カレンダーマーク読み込みエラー: $e');
    }
  }

  /// 指定された日付にマークがあるかチェック
  bool hasMark(DateTime date) {
    return _calendarMarks[date] ?? false;
  }

  /// 指定された日付にイベントがあるかチェック
  bool hasEvent(DateTime date) {
    return _events[date]?.isNotEmpty ?? false;
  }

  /// 指定された日付のイベント数を取得
  int getEventCount(DateTime date) {
    return _events[date]?.length ?? 0;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
