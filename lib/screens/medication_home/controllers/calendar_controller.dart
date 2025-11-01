// lib/screens/medication_home/controllers/calendar_controller.dart

import 'package:flutter/material.dart';
import '../../../core/result.dart';
import '../../../utils/logger.dart';
import '../repositories/calendar_repository.dart';

/// カレンダー専用Controller
class CalendarController extends ChangeNotifier {
  final CalendarRepository _repository;

  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = <DateTime>{};
  Map<String, Color> _dayColors = {};

  CalendarController({
    required CalendarRepository repository,
  }) : _repository = repository;

  // ゲッター
  DateTime? get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;
  Set<DateTime> get selectedDates => _selectedDates;
  Map<String, Color> get dayColors => _dayColors;

  /// 初期化
  Future<void> initialize() async {
    try {
      final result = await _repository.loadDayColors();
      
      if (result.isSuccess) {
        _dayColors = (result as Success<Map<String, Color>>).data;
        notifyListeners();
      } else {
        Logger.error('カレンダー日付色読み込み失敗', null);
      }
    } catch (e, stackTrace) {
      Logger.error('カレンダー初期化エラー', e, stackTrace);
    }
  }

  /// 日付選択
  void selectDay(DateTime day) {
    _selectedDay = day;
    if (!_selectedDates.contains(day)) {
      _selectedDates.add(day);
    }
    notifyListeners();
  }

  /// フォーカス日付を変更
  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  /// 選択をクリア
  void clearSelection() {
    _selectedDay = null;
    _selectedDates.clear();
    notifyListeners();
  }

  /// 日付色を更新
  Future<void> updateDayColor(String dateKey, Color color) async {
    _dayColors[dateKey] = color;
    notifyListeners();

    final result = await _repository.updateDayColor(dateKey, color);
    
    if (result.isError) {
      final error = result as Error<void>;
      Logger.error('カレンダー日付色更新失敗: ${error.message}', error.error);
      // ロールバック
      _dayColors.remove(dateKey);
      notifyListeners();
    }
  }

  /// 日付色を削除
  Future<void> removeDayColor(String dateKey) async {
    final originalColor = _dayColors[dateKey];
    _dayColors.remove(dateKey);
    notifyListeners();

    final result = await _repository.removeDayColor(dateKey);
    
    if (result.isError) {
      final error = result as Error<void>;
      Logger.error('カレンダー日付色削除失敗: ${error.message}', error.error);
      // ロールバック
      if (originalColor != null) {
        _dayColors[dateKey] = originalColor;
        notifyListeners();
      }
    }
  }

  /// 全色を保存
  Future<void> saveDayColors() async {
    final result = await _repository.saveDayColors(_dayColors);
    
    if (result.isError) {
      final error = result as Error<void>;
      Logger.error('カレンダー日付色保存失敗: ${error.message}', error.error);
    }
  }

  @override
  void dispose() {
    Logger.debug('CalendarController dispose');
    super.dispose();
  }
}

