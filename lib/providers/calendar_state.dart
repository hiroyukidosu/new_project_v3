import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/calendar_repository.dart';

/// カレンダー状態
class CalendarState {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Set<DateTime> selectedDates;
  final Map<String, Color> dayColors;
  final bool isLoading;
  final String? errorMessage;
  
  CalendarState({
    DateTime? focusedDay,
    this.selectedDay,
    Set<DateTime>? selectedDates,
    Map<String, Color>? dayColors,
    this.isLoading = false,
    this.errorMessage,
  }) : focusedDay = focusedDay ?? DateTime.now(),
       selectedDates = selectedDates ?? {},
       dayColors = dayColors ?? {};
  
  CalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    Set<DateTime>? selectedDates,
    Map<String, Color>? dayColors,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearSelectedDay = false,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
      selectedDates: selectedDates ?? this.selectedDates,
      dayColors: dayColors ?? this.dayColors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// カレンダー状態管理Notifier
class CalendarStateNotifier extends StateNotifier<CalendarState> {
  final CalendarRepository _repository;
  
  CalendarStateNotifier(this._repository) : super(CalendarState()) {
    loadAll();
  }
  
  /// 全データを読み込み
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dayColors = await _repository.loadDayColors();
      final selectedDates = await _repository.loadSelectedDates();
      
      state = state.copyWith(
        dayColors: dayColors,
        selectedDates: selectedDates,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'データの読み込みに失敗しました: $e',
      );
    }
  }
  
  /// フォーカス日を変更
  void setFocusedDay(DateTime day) {
    state = state.copyWith(focusedDay: day);
  }
  
  /// 選択日を変更
  void setSelectedDay(DateTime? day) {
    state = state.copyWith(selectedDay: day);
  }
  
  /// 選択日付を追加
  Future<void> addSelectedDate(DateTime date) async {
    try {
      final newDates = Set<DateTime>.from(state.selectedDates)..add(date);
      await _repository.saveSelectedDates(newDates);
      state = state.copyWith(selectedDates: newDates);
    } catch (e) {
      state = state.copyWith(errorMessage: '日付の追加に失敗しました: $e');
    }
  }
  
  /// 選択日付を削除
  Future<void> removeSelectedDate(DateTime date) async {
    try {
      final newDates = Set<DateTime>.from(state.selectedDates)..remove(date);
      await _repository.saveSelectedDates(newDates);
      state = state.copyWith(selectedDates: newDates);
    } catch (e) {
      state = state.copyWith(errorMessage: '日付の削除に失敗しました: $e');
    }
  }
  
  /// 日付色を更新
  Future<void> updateDayColor(String dateKey, Color color) async {
    try {
      final newColors = Map<String, Color>.from(state.dayColors);
      newColors[dateKey] = color;
      await _repository.saveDayColors(newColors);
      state = state.copyWith(dayColors: newColors);
    } catch (e) {
      state = state.copyWith(errorMessage: '色の更新に失敗しました: $e');
    }
  }
}

/// カレンダー状態のProvider
final calendarStateProvider = StateNotifierProvider<CalendarStateNotifier, CalendarState>(
  (ref) => CalendarStateNotifier(ref.watch(calendarRepositoryProvider)),
);

/// カレンダーリポジトリのProvider
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});

/// カレンダーリポジトリの初期化用Provider
final calendarRepositoryInitProvider = FutureProvider<void>((ref) async {
  final repository = ref.read(calendarRepositoryProvider);
  await repository.initialize();
});

