// lib/screens/home/controllers/calendar_controller.dart
// カレンダー関連のビジネスロジックを管理

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/home_page_state_manager.dart';
import '../persistence/snapshot_persistence.dart';

/// カレンダーコントローラー
/// 日付選択、日付色変更などの操作を管理
class CalendarController {
  final HomePageStateManager stateManager;
  final SnapshotPersistence snapshotPersistence;
  final VoidCallback onStateChanged;

  CalendarController({
    required this.stateManager,
    required this.snapshotPersistence,
    required this.onStateChanged,
  });

  /// 日付正規化
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 日付選択
  Future<void> selectDay(DateTime day, DateTime focusedDay) async {
    if (!stateManager.isInitialized) return;

    await snapshotPersistence.saveSnapshotBeforeChange(
      '日付選択_${DateFormat('yyyy-MM-dd').format(day)}',
      () async => _createBackupData('日付選択前'),
    );

    stateManager.selectedDay = day;
    stateManager.focusedDay = focusedDay;
    stateManager.notifiers.selectedDayNotifier.value = day;
    stateManager.notifiers.focusedDayNotifier.value = focusedDay;

    // カレンダーマークに追加
    final normalizedDay = _normalizeDate(day);
    if (!stateManager.selectedDates.contains(normalizedDay)) {
      stateManager.selectedDates.add(normalizedDay);
    }

    await stateManager.saveAllData();
    onStateChanged();
  }

  /// 日付色変更
  Future<void> changeDayColor(String dateKey, Color color) async {
    if (!stateManager.isInitialized) return;

    await snapshotPersistence.saveSnapshotBeforeChange(
      '色変更_$dateKey',
      () async => _createBackupData('色変更前_$dateKey'),
    );

    stateManager.dayColors[dateKey] = color;
    stateManager.notifiers.dayColorsNotifier.value = Map<String, Color>.from(stateManager.dayColors);

    await stateManager.saveAllData();
    onStateChanged();
  }

  /// バックアップデータ作成
  Future<Map<String, dynamic>> _createBackupData(String label) async {
    return {
      'selectedDay': stateManager.selectedDay?.toIso8601String(),
      'focusedDay': stateManager.focusedDay.toIso8601String(),
      'selectedDates': stateManager.selectedDates.map((d) => d.toIso8601String()).toList(),
      'dayColors': stateManager.dayColors.map((k, v) => MapEntry(k, v.value)),
      'label': label,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

