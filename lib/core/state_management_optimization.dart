import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// 状態管理最適化 - setStateの過剰呼び出しを防止
class StateManagementOptimization {
  static final Map<String, ValueNotifier> _notifiers = {};
  static final Map<String, List<VoidCallback>> _listeners = {};
  
  /// ValueNotifierの取得または作成
  static ValueNotifier<T> getNotifier<T>(String key, T initialValue) {
    if (_notifiers.containsKey(key)) {
      return _notifiers[key] as ValueNotifier<T>;
    }
    
    final notifier = ValueNotifier<T>(initialValue);
    _notifiers[key] = notifier;
    Logger.debug('ValueNotifier作成: $key');
    return notifier;
  }
  
  /// 値の更新
  static void updateValue<T>(String key, T value) {
    final notifier = _notifiers[key] as ValueNotifier<T>?;
    if (notifier != null) {
      notifier.value = value;
      Logger.debug('値更新: $key = $value');
    } else {
      Logger.warning('ValueNotifierが見つかりません: $key');
    }
  }
  
  /// リスナーの追加
  static void addListener(String key, VoidCallback listener) {
    _listeners.putIfAbsent(key, () => []).add(listener);
    Logger.debug('リスナー追加: $key');
  }
  
  /// リスナーの削除
  static void removeListener(String key, VoidCallback listener) {
    _listeners[key]?.remove(listener);
    Logger.debug('リスナー削除: $key');
  }
  
  /// 全リスナーの削除
  static void removeAllListeners(String key) {
    _listeners.remove(key);
    Logger.debug('全リスナー削除: $key');
  }
  
  /// リソースの解放
  static void dispose() {
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
    _notifiers.clear();
    _listeners.clear();
    Logger.info('StateManagementOptimization解放完了');
  }
}

/// 最適化された状態管理ウィジェット
class OptimizedStateWidget extends StatefulWidget {
  final Widget Function(BuildContext, Map<String, dynamic>) builder;
  final Map<String, dynamic> initialValues;
  
  const OptimizedStateWidget({
    super.key,
    required this.builder,
    this.initialValues = const {},
  });
  
  @override
  State<OptimizedStateWidget> createState() => _OptimizedStateWidgetState();
}

class _OptimizedStateWidgetState extends State<OptimizedStateWidget> {
  final Map<String, ValueNotifier> _notifiers = {};
  final Map<String, dynamic> _values = {};
  
  @override
  void initState() {
    super.initState();
    _initializeNotifiers();
  }
  
  void _initializeNotifiers() {
    for (final entry in widget.initialValues.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is bool) {
        _notifiers[key] = ValueNotifier<bool>(value);
      } else if (value is int) {
        _notifiers[key] = ValueNotifier<int>(value);
      } else if (value is double) {
        _notifiers[key] = ValueNotifier<double>(value);
      } else if (value is String) {
        _notifiers[key] = ValueNotifier<String>(value);
      } else if (value is DateTime) {
        _notifiers[key] = ValueNotifier<DateTime>(value);
      } else {
        _notifiers[key] = ValueNotifier<dynamic>(value);
      }
      
      _values[key] = value;
    }
  }
  
  @override
  void dispose() {
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }
  
  /// 値の更新
  void updateValue<T>(String key, T value) {
    final notifier = _notifiers[key] as ValueNotifier<T>?;
    if (notifier != null) {
      notifier.value = value;
      _values[key] = value;
    } else {
      Logger.warning('ValueNotifierが見つかりません: $key');
    }
  }
  
  /// 値の取得
  T? getValue<T>(String key) {
    return _values[key] as T?;
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _values);
  }
}

/// 最適化された日付選択管理
class OptimizedDateSelection {
  static final ValueNotifier<DateTime?> _selectedDay = ValueNotifier<DateTime?>(null);
  static final ValueNotifier<DateTime> _focusedDay = ValueNotifier<DateTime>(DateTime.now());
  static final ValueNotifier<Set<DateTime>> _selectedDates = ValueNotifier<Set<DateTime>>({});
  
  static ValueNotifier<DateTime?> get selectedDay => _selectedDay;
  static ValueNotifier<DateTime> get focusedDay => _focusedDay;
  static ValueNotifier<Set<DateTime>> get selectedDates => _selectedDates;
  
  /// 日付の選択
  static void selectDay(DateTime day, DateTime focused) {
    _selectedDay.value = day;
    _focusedDay.value = focused;
    Logger.debug('日付選択: $day');
  }
  
  /// 日付の追加
  static void addDate(DateTime date) {
    final currentDates = Set<DateTime>.from(_selectedDates.value);
    currentDates.add(date);
    _selectedDates.value = currentDates;
    Logger.debug('日付追加: $date');
  }
  
  /// 日付の削除
  static void removeDate(DateTime date) {
    final currentDates = Set<DateTime>.from(_selectedDates.value);
    currentDates.remove(date);
    _selectedDates.value = currentDates;
    Logger.debug('日付削除: $date');
  }
  
  /// 全日付のクリア
  static void clearDates() {
    _selectedDates.value = {};
    Logger.debug('全日付クリア');
  }
  
  /// リソースの解放
  static void dispose() {
    _selectedDay.dispose();
    _focusedDay.dispose();
    _selectedDates.dispose();
    Logger.info('OptimizedDateSelection解放完了');
  }
}

/// 最適化されたメモ選択管理
class OptimizedMemoSelection {
  static final ValueNotifier<dynamic?> _selectedMemo = ValueNotifier<dynamic?>(null);
  static final ValueNotifier<bool> _isMemoSelected = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> _selectedMemoId = ValueNotifier<String?>(null);
  
  static ValueNotifier<dynamic?> get selectedMemo => _selectedMemo;
  static ValueNotifier<bool> get isMemoSelected => _isMemoSelected;
  static ValueNotifier<String?> get selectedMemoId => _selectedMemoId;
  
  /// メモの選択
  static void selectMemo(dynamic memo) {
    _selectedMemo.value = memo;
    _isMemoSelected.value = true;
    _selectedMemoId.value = memo?.id;
    Logger.debug('メモ選択: ${memo?.id}');
  }
  
  /// メモの選択解除
  static void deselectMemo() {
    _selectedMemo.value = null;
    _isMemoSelected.value = false;
    _selectedMemoId.value = null;
    Logger.debug('メモ選択解除');
  }
  
  /// リソースの解放
  static void dispose() {
    _selectedMemo.dispose();
    _isMemoSelected.dispose();
    _selectedMemoId.dispose();
    Logger.info('OptimizedMemoSelection解放完了');
  }
}

/// 最適化されたアラーム状態管理
class OptimizedAlarmState {
  static final ValueNotifier<bool> _isAlarmPlaying = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> _notificationError = ValueNotifier<String?>(null);
  static final ValueNotifier<List<Map<String, dynamic>>> _alarmList = ValueNotifier<List<Map<String, dynamic>>>([]);
  
  static ValueNotifier<bool> get isAlarmPlaying => _isAlarmPlaying;
  static ValueNotifier<String?> get notificationError => _notificationError;
  static ValueNotifier<List<Map<String, dynamic>>> get alarmList => _alarmList;
  
  /// アラームの再生状態更新
  static void updateAlarmPlaying(bool isPlaying) {
    _isAlarmPlaying.value = isPlaying;
    Logger.debug('アラーム再生状態更新: $isPlaying');
  }
  
  /// 通知エラーの更新
  static void updateNotificationError(String? error) {
    _notificationError.value = error;
    Logger.debug('通知エラー更新: $error');
  }
  
  /// アラームリストの更新
  static void updateAlarmList(List<Map<String, dynamic>> alarms) {
    _alarmList.value = alarms;
    Logger.debug('アラームリスト更新: ${alarms.length}個');
  }
  
  /// リソースの解放
  static void dispose() {
    _isAlarmPlaying.dispose();
    _notificationError.dispose();
    _alarmList.dispose();
    Logger.info('OptimizedAlarmState解放完了');
  }
}

/// 最適化されたUI状態管理
class OptimizedUIState {
  static final ValueNotifier<bool> _isNameFocused = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> _isDosageFocused = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> _isNotesFocused = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  
  static ValueNotifier<bool> get isNameFocused => _isNameFocused;
  static ValueNotifier<bool> get isDosageFocused => _isDosageFocused;
  static ValueNotifier<bool> get isNotesFocused => _isNotesFocused;
  static ValueNotifier<bool> get isLoading => _isLoading;
  
  /// フォーカス状態の更新
  static void updateFocusState({
    bool? nameFocused,
    bool? dosageFocused,
    bool? notesFocused,
  }) {
    if (nameFocused != null) {
      _isNameFocused.value = nameFocused;
    }
    if (dosageFocused != null) {
      _isDosageFocused.value = dosageFocused;
    }
    if (notesFocused != null) {
      _isNotesFocused.value = notesFocused;
    }
    Logger.debug('フォーカス状態更新: name=$nameFocused, dosage=$dosageFocused, notes=$notesFocused');
  }
  
  /// ローディング状態の更新
  static void updateLoadingState(bool loading) {
    _isLoading.value = loading;
    Logger.debug('ローディング状態更新: $loading');
  }
  
  /// 全フォーカスの解除
  static void clearAllFocus() {
    _isNameFocused.value = false;
    _isDosageFocused.value = false;
    _isNotesFocused.value = false;
    Logger.debug('全フォーカス解除');
  }
  
  /// リソースの解放
  static void dispose() {
    _isNameFocused.dispose();
    _isDosageFocused.dispose();
    _isNotesFocused.dispose();
    _isLoading.dispose();
    Logger.info('OptimizedUIState解放完了');
  }
}

/// 全状態管理の統合解放
class StateManagementDisposal {
  /// 全状態管理リソースの解放
  static void disposeAll() {
    StateManagementOptimization.dispose();
    OptimizedDateSelection.dispose();
    OptimizedMemoSelection.dispose();
    OptimizedAlarmState.dispose();
    OptimizedUIState.dispose();
    Logger.info('全状態管理リソース解放完了');
  }
  
  /// 状態管理統計の取得
  static Map<String, dynamic> getStateStats() {
    return {
      'notifiers': StateManagementOptimization._notifiers.length,
      'listeners': StateManagementOptimization._listeners.length,
      'dateSelection': {
        'selectedDay': OptimizedDateSelection._selectedDay.value,
        'focusedDay': OptimizedDateSelection._focusedDay.value,
        'selectedDates': OptimizedDateSelection._selectedDates.value.length,
      },
      'memoSelection': {
        'selectedMemo': OptimizedMemoSelection._selectedMemo.value?.id,
        'isMemoSelected': OptimizedMemoSelection._isMemoSelected.value,
      },
      'alarmState': {
        'isAlarmPlaying': OptimizedAlarmState._isAlarmPlaying.value,
        'notificationError': OptimizedAlarmState._notificationError.value,
        'alarmCount': OptimizedAlarmState._alarmList.value.length,
      },
      'uiState': {
        'isNameFocused': OptimizedUIState._isNameFocused.value,
        'isDosageFocused': OptimizedUIState._isDosageFocused.value,
        'isNotesFocused': OptimizedUIState._isNotesFocused.value,
        'isLoading': OptimizedUIState._isLoading.value,
      },
    };
  }
}
