import 'dart:async';
import '../repositories/medication_repository.dart';
import '../utils/logger.dart';

/// 統一データマネージャー - 重複削除とデバウンス保存
class UnifiedDataManager {
  static final Map<String, bool> _dirtyFlags = {};
  static Timer? _debounceTimer;
  static bool _isSaving = false;
  static const Duration _debounceDelay = Duration(milliseconds: 2000);
  
  // シングルトンインスタンス
  static final UnifiedDataManager _instance = UnifiedDataManager._internal();
  factory UnifiedDataManager() => _instance;
  UnifiedDataManager._internal();
  
  late MedicationRepository _repository;
  
  /// 初期化
  Future<void> initialize(MedicationRepository repository) async {
    _repository = repository;
    Logger.info('UnifiedDataManager初期化完了');
  }
  
  /// データ変更をマーク（即座に保存しない）
  static void markDirty(String key) {
    _dirtyFlags[key] = true;
    Logger.debug('データ変更マーク: $key');
    _scheduleSave();
  }
  
  /// デバウンス保存のスケジュール
  static void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, _saveAllDirty);
  }
  
  /// 全ダーティデータの保存
  static Future<void> _saveAllDirty() async {
    if (_dirtyFlags.isEmpty || _isSaving) {
      Logger.debug('保存対象なしまたは保存中です。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      Logger.performance('統一データ保存開始: ${_dirtyFlags.length}件');
      final startTime = DateTime.now();
      
      final tasks = <Future<void>>[];
      
      // 変更されたデータのみ保存
      if (_dirtyFlags['memos'] == true) {
        tasks.add(_instance._saveMemos());
      }
      if (_dirtyFlags['memoStatus'] == true) {
        tasks.add(_instance._saveMemoStatus());
      }
      if (_dirtyFlags['weekdayStatus'] == true) {
        tasks.add(_instance._saveWeekdayStatus());
      }
      if (_dirtyFlags['addedMedications'] == true) {
        tasks.add(_instance._saveAddedMedications());
      }
      if (_dirtyFlags['alarmData'] == true) {
        tasks.add(_instance._saveAlarmData());
      }
      if (_dirtyFlags['calendarMarks'] == true) {
        tasks.add(_instance._saveCalendarMarks());
      }
      if (_dirtyFlags['userPreferences'] == true) {
        tasks.add(_instance._saveUserPreferences());
      }
      if (_dirtyFlags['medicationData'] == true) {
        tasks.add(_instance._saveMedicationData());
      }
      if (_dirtyFlags['dayColors'] == true) {
        tasks.add(_instance._saveDayColors());
      }
      if (_dirtyFlags['statistics'] == true) {
        tasks.add(_instance._saveStatistics());
      }
      if (_dirtyFlags['appSettings'] == true) {
        tasks.add(_instance._saveAppSettings());
      }
      if (_dirtyFlags['doseStatus'] == true) {
        tasks.add(_instance._saveDoseStatus());
      }
      
      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
        final duration = DateTime.now().difference(startTime);
        Logger.performance('統一データ保存完了: ${duration.inMilliseconds}ms');
      }
      
      _dirtyFlags.clear();
    } catch (e) {
      Logger.error('統一データ保存エラー', e);
      rethrow;
    } finally {
      _isSaving = false;
    }
  }
  
  /// 強制保存（アプリ終了時など）
  static Future<void> forceSave() async {
    if (_isSaving) {
      Logger.warning('保存中です。完了を待機します。');
      while (_isSaving) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    _debounceTimer?.cancel();
    await _saveAllDirty();
    Logger.info('強制保存完了');
  }
  
  /// メモの保存
  Future<void> _saveMemos() async {
    try {
      // 実際のメモ保存処理はViewModelで管理
      Logger.debug('メモ保存処理');
    } catch (e) {
      Logger.error('メモ保存エラー', e);
      rethrow;
    }
  }
  
  /// メモステータスの保存
  Future<void> _saveMemoStatus() async {
    try {
      // 実際のメモステータス保存処理はViewModelで管理
      Logger.debug('メモステータス保存処理');
    } catch (e) {
      Logger.error('メモステータス保存エラー', e);
      rethrow;
    }
  }
  
  /// 曜日ステータスの保存
  Future<void> _saveWeekdayStatus() async {
    try {
      // 実際の曜日ステータス保存処理はViewModelで管理
      Logger.debug('曜日ステータス保存処理');
    } catch (e) {
      Logger.error('曜日ステータス保存エラー', e);
      rethrow;
    }
  }
  
  /// 追加メディケーションの保存
  Future<void> _saveAddedMedications() async {
    try {
      // 実際の追加メディケーション保存処理はViewModelで管理
      Logger.debug('追加メディケーション保存処理');
    } catch (e) {
      Logger.error('追加メディケーション保存エラー', e);
      rethrow;
    }
  }
  
  /// アラームデータの保存
  Future<void> _saveAlarmData() async {
    try {
      // 実際のアラームデータ保存処理はViewModelで管理
      Logger.debug('アラームデータ保存処理');
    } catch (e) {
      Logger.error('アラームデータ保存エラー', e);
      rethrow;
    }
  }
  
  /// カレンダーマークの保存
  Future<void> _saveCalendarMarks() async {
    try {
      // 実際のカレンダーマーク保存処理はViewModelで管理
      Logger.debug('カレンダーマーク保存処理');
    } catch (e) {
      Logger.error('カレンダーマーク保存エラー', e);
      rethrow;
    }
  }
  
  /// ユーザー設定の保存
  Future<void> _saveUserPreferences() async {
    try {
      // 実際のユーザー設定保存処理はViewModelで管理
      Logger.debug('ユーザー設定保存処理');
    } catch (e) {
      Logger.error('ユーザー設定保存エラー', e);
      rethrow;
    }
  }
  
  /// メディケーションデータの保存
  Future<void> _saveMedicationData() async {
    try {
      // 実際のメディケーションデータ保存処理はViewModelで管理
      Logger.debug('メディケーションデータ保存処理');
    } catch (e) {
      Logger.error('メディケーションデータ保存エラー', e);
      rethrow;
    }
  }
  
  /// 日付色の保存
  Future<void> _saveDayColors() async {
    try {
      // 実際の日付色保存処理はViewModelで管理
      Logger.debug('日付色保存処理');
    } catch (e) {
      Logger.error('日付色保存エラー', e);
      rethrow;
    }
  }
  
  /// 統計データの保存
  Future<void> _saveStatistics() async {
    try {
      // 実際の統計データ保存処理はViewModelで管理
      Logger.debug('統計データ保存処理');
    } catch (e) {
      Logger.error('統計データ保存エラー', e);
      rethrow;
    }
  }
  
  /// アプリ設定の保存
  Future<void> _saveAppSettings() async {
    try {
      // 実際のアプリ設定保存処理はViewModelで管理
      Logger.debug('アプリ設定保存処理');
    } catch (e) {
      Logger.error('アプリ設定保存エラー', e);
      rethrow;
    }
  }
  
  /// 服用ステータスの保存
  Future<void> _saveDoseStatus() async {
    try {
      // 実際の服用ステータス保存処理はViewModelで管理
      Logger.debug('服用ステータス保存処理');
    } catch (e) {
      Logger.error('服用ステータス保存エラー', e);
      rethrow;
    }
  }
  
  /// ダーティフラグの取得
  static Map<String, bool> get dirtyFlags => Map.unmodifiable(_dirtyFlags);
  
  /// 保存状態の確認
  static bool get isSaving => _isSaving;
  
  /// リソースの解放
  static void dispose() {
    _debounceTimer?.cancel();
    _dirtyFlags.clear();
    _isSaving = false;
    Logger.info('UnifiedDataManager解放完了');
  }
}

/// デバウンス機能
class Debouncer {
  final Duration delay;
  Timer? _timer;
  
  Debouncer({required this.delay});
  
  void run(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }
  
  void cancel() {
    _timer?.cancel();
  }
  
  void dispose() {
    _timer?.cancel();
  }
}

/// データ保存の最適化
class DataSaveOptimizer {
  static final Map<String, DateTime> _lastSaveTimes = {};
  static const Duration _minSaveInterval = Duration(seconds: 1);
  
  /// 保存の最適化チェック
  static bool shouldSave(String key) {
    final lastSave = _lastSaveTimes[key];
    if (lastSave == null) return true;
    
    final now = DateTime.now();
    return now.difference(lastSave) >= _minSaveInterval;
  }
  
  /// 保存時間の記録
  static void recordSave(String key) {
    _lastSaveTimes[key] = DateTime.now();
  }
  
  /// 統計の取得
  static Map<String, dynamic> getStats() {
    return {
      'lastSaveTimes': Map.from(_lastSaveTimes),
      'totalSaves': _lastSaveTimes.length,
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _lastSaveTimes.clear();
  }
}
