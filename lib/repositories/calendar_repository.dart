import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/storage_keys.dart';
import '../utils/logger.dart';

/// カレンダー関連データのリポジトリ（Hive完全移行版）
class CalendarRepository {
  Box<String>? _dataBox;
  
  /// リポジトリの初期化
  Future<void> initialize() async {
    try {
      // Hiveボックスを直接開く
      if (!Hive.isBoxOpen('calendar_data')) {
        _dataBox = await Hive.openBox<String>('calendar_data');
      } else {
        _dataBox = Hive.box<String>('calendar_data');
      }
      
      Logger.info('CalendarRepository初期化完了');
    } catch (e) {
      Logger.error('CalendarRepository初期化エラー', e);
      rethrow;
    }
  }
  
  /// 日付色の取得
  Future<Map<String, Color>> loadDayColors() async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final colorsJson = _dataBox!.get(StorageKeys.dayColorsKey);
      if (colorsJson != null) {
        final colorsMap = jsonDecode(colorsJson) as Map<String, dynamic>;
        return colorsMap.map((key, value) {
          final colorValue = value is int ? value : int.parse(value.toString());
          return MapEntry(key, Color(colorValue));
        });
      }
      return {};
    } catch (e) {
      Logger.error('日付色取得エラー', e);
      return {};
    }
  }
  
  /// 日付色の保存
  Future<void> saveDayColors(Map<String, Color> colors) async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final colorsMap = colors.map((key, value) => MapEntry(key, value.value));
      await _dataBox!.put(StorageKeys.dayColorsKey, jsonEncode(colorsMap));
      Logger.debug('日付色保存完了: ${colors.length}件');
    } catch (e) {
      Logger.error('日付色保存エラー', e);
      rethrow;
    }
  }
  
  /// 選択された日付の取得
  Future<Set<DateTime>> loadSelectedDates() async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final datesJson = _dataBox!.get(StorageKeys.selectedDatesKey);
      if (datesJson != null) {
        final datesList = jsonDecode(datesJson) as List<dynamic>;
        return datesList.map((dateStr) => DateTime.parse(dateStr as String)).toSet();
      }
      return {};
    } catch (e) {
      Logger.error('選択日付取得エラー', e);
      return {};
    }
  }
  
  /// 選択された日付の保存
  Future<void> saveSelectedDates(Set<DateTime> dates) async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final datesList = dates.map((date) => date.toIso8601String()).toList();
      await _dataBox!.put(StorageKeys.selectedDatesKey, jsonEncode(datesList));
      Logger.debug('選択日付保存完了: ${dates.length}件');
    } catch (e) {
      Logger.error('選択日付保存エラー', e);
      rethrow;
    }
  }
  
  /// カレンダーマークの取得
  Future<Map<String, dynamic>> loadCalendarMarks() async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final marksJson = _dataBox!.get(StorageKeys.calendarMarksKey);
      if (marksJson != null) {
        return jsonDecode(marksJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      Logger.error('カレンダーマーク取得エラー', e);
      return {};
    }
  }
  
  /// カレンダーマークの保存
  Future<void> saveCalendarMarks(Map<String, dynamic> marks) async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      await _dataBox!.put(StorageKeys.calendarMarksKey, jsonEncode(marks));
      Logger.debug('カレンダーマーク保存完了');
    } catch (e) {
      Logger.error('カレンダーマーク保存エラー', e);
      rethrow;
    }
  }
  
  /// リソースの解放
  Future<void> dispose() async {
    try {
      // Hiveライフサイクルサービスが管理するため、ここでは何もしない
      Logger.info('CalendarRepository解放完了');
    } catch (e) {
      Logger.error('CalendarRepository解放エラー', e);
    }
  }
}

