import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/alarm_repository.dart';

/// アラーム状態
class AlarmState {
  final List<Map<String, dynamic>> alarmList;
  final Map<String, dynamic> alarmSettings;
  final bool isLoading;
  final String? errorMessage;
  
  AlarmState({
    this.alarmList = const [],
    this.alarmSettings = const {},
    this.isLoading = false,
    this.errorMessage,
  });
  
  AlarmState copyWith({
    List<Map<String, dynamic>>? alarmList,
    Map<String, dynamic>? alarmSettings,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AlarmState(
      alarmList: alarmList ?? this.alarmList,
      alarmSettings: alarmSettings ?? this.alarmSettings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// アラーム状態管理Notifier
class AlarmStateNotifier extends StateNotifier<AlarmState> {
  final AlarmRepository _repository;
  
  AlarmStateNotifier(this._repository) : super(AlarmState()) {
    loadAll();
  }
  
  /// 全データを読み込み
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final alarmList = await _repository.loadAlarmList();
      final alarmSettings = await _repository.loadAlarmSettings();
      
      state = state.copyWith(
        alarmList: alarmList,
        alarmSettings: alarmSettings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'データの読み込みに失敗しました: $e',
      );
    }
  }
  
  /// アラームを追加
  Future<void> addAlarm(Map<String, dynamic> alarm) async {
    try {
      final newAlarmList = List<Map<String, dynamic>>.from(state.alarmList)..add(alarm);
      await _repository.saveAlarmList(newAlarmList);
      state = state.copyWith(alarmList: newAlarmList);
    } catch (e) {
      state = state.copyWith(errorMessage: 'アラームの追加に失敗しました: $e');
    }
  }
  
  /// アラームを更新
  Future<void> updateAlarm(int index, Map<String, dynamic> alarm) async {
    try {
      final newAlarmList = List<Map<String, dynamic>>.from(state.alarmList);
      if (index >= 0 && index < newAlarmList.length) {
        newAlarmList[index] = alarm;
        await _repository.saveAlarmList(newAlarmList);
        state = state.copyWith(alarmList: newAlarmList);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'アラームの更新に失敗しました: $e');
    }
  }
  
  /// アラームを削除
  Future<void> deleteAlarm(int index) async {
    try {
      final newAlarmList = List<Map<String, dynamic>>.from(state.alarmList);
      if (index >= 0 && index < newAlarmList.length) {
        newAlarmList.removeAt(index);
        await _repository.saveAlarmList(newAlarmList);
        state = state.copyWith(alarmList: newAlarmList);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'アラームの削除に失敗しました: $e');
    }
  }
  
  /// アラーム設定を更新
  Future<void> updateAlarmSettings(Map<String, dynamic> settings) async {
    try {
      await _repository.saveAlarmSettings(settings);
      state = state.copyWith(alarmSettings: settings);
    } catch (e) {
      state = state.copyWith(errorMessage: 'アラーム設定の更新に失敗しました: $e');
    }
  }
}

/// アラーム状態のProvider
final alarmStateProvider = StateNotifierProvider<AlarmStateNotifier, AlarmState>(
  (ref) => AlarmStateNotifier(ref.watch(alarmRepositoryProvider)),
);

/// アラームリポジトリのProvider
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepository();
});

/// アラームリポジトリの初期化用Provider
final alarmRepositoryInitProvider = FutureProvider<void>((ref) async {
  final repository = ref.read(alarmRepositoryProvider);
  await repository.initialize();
});

