// lib/screens/medication_home/repositories/calendar_repository.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/result.dart';
import '../../../utils/logger.dart';

/// カレンダー関連のデータアクセスを管理するRepository
class CalendarRepository {
  static const String _dayColorsKey = 'calendar_day_colors';

  /// カレンダーの日付色を読み込み
  Future<Result<Map<String, Color>>> loadDayColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_dayColorsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return Success({});
      }

      final Map<String, dynamic> colorsMap = jsonDecode(jsonString);
      final dayColors = colorsMap.map(
        (date, colorValue) => MapEntry(
          date,
          Color(int.parse(colorValue.toString())),
        ),
      );

      Logger.debug('カレンダー日付色読み込み成功: ${dayColors.length}件');
      return Success(dayColors);
    } catch (e, stackTrace) {
      Logger.error('カレンダー日付色読み込みエラー', e, stackTrace);
      return Error('カレンダー日付色の読み込みに失敗しました: $e', e);
    }
  }

  /// カレンダーの日付色を保存
  Future<Result<void>> saveDayColors(Map<String, Color> dayColors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> colorsJson = dayColors.map(
        (date, color) => MapEntry(date, color.value.toString()),
      );
      
      await prefs.setString(_dayColorsKey, jsonEncode(colorsJson));
      Logger.debug('カレンダー日付色保存成功: ${colorsJson.length}件');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('カレンダー日付色保存エラー', e, stackTrace);
      return Error('カレンダー日付色の保存に失敗しました: $e', e);
    }
  }

  /// 特定の日付の色を更新
  Future<Result<void>> updateDayColor(String dateKey, Color color) async {
    try {
      final result = await loadDayColors();
      
      return result.onSuccess((dayColors) async {
        final updatedColors = Map<String, Color>.from(dayColors);
        updatedColors[dateKey] = color;
        return await saveDayColors(updatedColors);
      }).onError((message, error) => Error(message, error));
    } catch (e, stackTrace) {
      Logger.error('カレンダー日付色更新エラー', e, stackTrace);
      return Error('カレンダー日付色の更新に失敗しました: $e', e);
    }
  }

  /// 特定の日付の色を削除
  Future<Result<void>> removeDayColor(String dateKey) async {
    try {
      final result = await loadDayColors();
      
      return result.onSuccess((dayColors) async {
        final updatedColors = Map<String, Color>.from(dayColors);
        updatedColors.remove(dateKey);
        return await saveDayColors(updatedColors);
      }).onError((message, error) => Error(message, error));
    } catch (e, stackTrace) {
      Logger.error('カレンダー日付色削除エラー', e, stackTrace);
      return Error('カレンダー日付色の削除に失敗しました: $e', e);
    }
  }
}

