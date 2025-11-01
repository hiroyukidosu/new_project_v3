// lib/screens/home/handlers/calendar_event_handler.dart

import 'package:flutter/material.dart';
import '../../../utils/logger.dart';
import '../../home/persistence/medication_data_persistence.dart';

/// カレンダー関連のイベントを処理するクラス
class CalendarEventHandler {
  final MedicationDataPersistence _persistence;
  final Function(DateTime) onStateUpdate;
  final Function(String, Color) onDayColorUpdate;

  CalendarEventHandler({
    required MedicationDataPersistence persistence,
    required this.onStateUpdate,
    required this.onDayColorUpdate,
  }) : _persistence = persistence;

  /// 日付が選択されたときの処理
  void onDaySelected(DateTime day, DateTime? selectedDay) {
    try {
      Logger.debug('日付選択: ${day.toString()}');
      
      // 状態を更新
      if (selectedDay == null || selectedDay != day) {
        onStateUpdate(day);
      }
    } catch (e) {
      Logger.error('日付選択処理エラー', e);
    }
  }

  /// 日付の色を変更
  Future<void> onChangeDayColor(String dateKey, Color color) async {
    try {
      Logger.debug('日付色変更: $dateKey');
      
      // 状態を更新
      onDayColorUpdate(dateKey, color);
    } catch (e) {
      Logger.error('日付色変更エラー', e);
    }
  }

  /// フォーカスされた日付を変更
  void onFocusedDayChanged(DateTime focusedDay, Function(DateTime) onUpdate) {
    try {
      Logger.debug('フォーカス日付変更: ${focusedDay.toString()}');
      onUpdate(focusedDay);
    } catch (e) {
      Logger.error('フォーカス日付変更エラー', e);
    }
  }

  /// カレンダーマークを更新
  Future<void> updateCalendarMarks(DateTime day) async {
    try {
      // カレンダーマークの更新処理
      Logger.debug('カレンダーマーク更新: ${day.toString()}');
    } catch (e) {
      Logger.error('カレンダーマーク更新エラー', e);
    }
  }
}

