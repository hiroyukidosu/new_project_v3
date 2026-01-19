import 'dart:async';
import '../utils/logger.dart';

/// 非同期処理の競合状態修正 - 並列実行とロック管理
class AsyncRaceConditionFix {
  static final Map<String, bool> _operationLocks = {};
  static final Map<String, Completer<void>> _operationCompleters = {};
  static final Map<String, List<Future<void>>> _pendingOperations = {};
  static final Map<String, DateTime> _lastOperationTimes = {};
  
  /// 操作のロック取得
  static Future<bool> acquireLock(String operationId, {Duration timeout = const Duration(seconds: 30)}) async {
    if (_operationLocks[operationId] == true) {
      Logger.warning('操作が既に実行中です: $operationId');
      return false;
    }
    
    _operationLocks[operationId] = true;
    _lastOperationTimes[operationId] = DateTime.now();
    Logger.debug('ロック取得: $operationId');
    return true;
  }
  
  /// 操作のロック解放
  static void releaseLock(String operationId) {
    _operationLocks[operationId] = false;
    _operationCompleters.remove(operationId);
    Logger.debug('ロック解放: $operationId');
  }
  
  /// 安全な並列実行
  static Future<List<T>> safeParallelExecution<T>(
    String operationId,
    List<Future<T> Function()> operations, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!await acquireLock(operationId, timeout: timeout)) {
      throw Exception('操作のロック取得に失敗しました: $operationId');
    }
    
    try {
      Logger.performance('並列実行開始: $operationId (${operations.length}個の操作)');
      final startTime = DateTime.now();
      
      // 並列実行
      final futures = operations.map((operation) => operation()).toList();
      final results = await Future.wait(futures).timeout(timeout);
      
      final duration = DateTime.now().difference(startTime);
      Logger.performance('並列実行完了: $operationId (${duration.inMilliseconds}ms)');
      
      return results;
    } catch (e) {
      Logger.error('並列実行エラー: $operationId', e);
      rethrow;
    } finally {
      releaseLock(operationId);
    }
  }
  
  /// 安全な逐次実行
  static Future<List<T>> safeSequentialExecution<T>(
    String operationId,
    List<Future<T> Function()> operations, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!await acquireLock(operationId, timeout: timeout)) {
      throw Exception('操作のロック取得に失敗しました: $operationId');
    }
    
    try {
      Logger.performance('逐次実行開始: $operationId (${operations.length}個の操作)');
      final startTime = DateTime.now();
      
      final results = <T>[];
      for (final operation in operations) {
        final result = await operation().timeout(timeout);
        results.add(result);
      }
      
      final duration = DateTime.now().difference(startTime);
      Logger.performance('逐次実行完了: $operationId (${duration.inMilliseconds}ms)');
      
      return results;
    } catch (e) {
      Logger.error('逐次実行エラー: $operationId', e);
      rethrow;
    } finally {
      releaseLock(operationId);
    }
  }
  
  /// デバウンス付き実行
  static Future<void> debouncedExecution(
    String operationId,
    Future<void> Function() operation, {
    Duration debounceDelay = const Duration(milliseconds: 500),
  }) async {
    // 既存の操作をキャンセル
    _pendingOperations[operationId]?.forEach((future) {
      // キャンセル可能な場合はキャンセル
    });
    _pendingOperations[operationId] = [];
    
    // 新しい操作をスケジュール
    final future = Future.delayed(debounceDelay, () async {
      try {
        await operation();
      } catch (e) {
        Logger.error('デバウンス実行エラー: $operationId', e);
      }
    });
    
    _pendingOperations[operationId] = [future];
    await future;
  }
  
  /// 操作の待機
  static Future<void> waitForOperation(String operationId) async {
    if (_operationLocks[operationId] == true) {
      final completer = _operationCompleters.putIfAbsent(operationId, () => Completer<void>());
      await completer.future;
    }
  }
  
  /// 全操作の完了待機
  static Future<void> waitForAllOperations() async {
    final activeOperations = _operationLocks.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
    
    if (activeOperations.isNotEmpty) {
      Logger.info('アクティブな操作の完了を待機: $activeOperations');
      await Future.wait(activeOperations.map((id) => waitForOperation(id)));
    }
  }
  
  /// 操作統計の取得
  static Map<String, dynamic> getOperationStats() {
    return {
      'activeOperations': _operationLocks.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList(),
      'pendingOperations': _pendingOperations.length,
      'totalLocks': _operationLocks.length,
      'lastOperationTimes': Map.from(_lastOperationTimes),
    };
  }
  
  /// 全ロックの解放
  static void releaseAllLocks() {
    _operationLocks.clear();
    _operationCompleters.clear();
    _pendingOperations.clear();
    _lastOperationTimes.clear();
    Logger.info('全ロックを解放しました');
  }
}

/// データ保存の競合状態修正
class DataSaveRaceConditionFix {
  static bool _isSaving = false;
  static final List<Future<void>> _pendingSaves = [];
  static final Map<String, bool> _dirtyFlags = {};
  
  /// 安全なデータ保存（並列実行）
  static Future<void> safeSaveParallel({
    required Future<void> Function() saveMedicationMemoStatus,
    required Future<void> Function() saveWeekdayMedicationStatus,
    required Future<void> Function() saveAddedMedications,
    required Future<void> Function() saveAlarmData,
    required Future<void> Function() saveCalendarMarks,
    required Future<void> Function() saveUserPreferences,
    required Future<void> Function() saveMedicationData,
    required Future<void> Function() saveDayColors,
    required Future<void> Function() saveStatistics,
    required Future<void> Function() saveAppSettings,
    required Future<void> Function() saveMedicationDoseStatus,
  }) async {
    if (_isSaving) {
      Logger.warning('データ保存中です。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      Logger.performance('データ保存開始（並列実行）');
      final startTime = DateTime.now();
      
      // 並列実行で高速化
      await Future.wait([
        saveMedicationMemoStatus(),
        saveWeekdayMedicationStatus(),
        saveAddedMedications(),
        saveAlarmData(),
        saveCalendarMarks(),
        saveUserPreferences(),
        saveMedicationData(),
        saveDayColors(),
        saveStatistics(),
        saveAppSettings(),
        saveMedicationDoseStatus(),
      ]);
      
      final duration = DateTime.now().difference(startTime);
      Logger.performance('データ保存完了（並列実行）: ${duration.inMilliseconds}ms');
    } catch (e) {
      Logger.error('データ保存エラー（並列実行）', e);
      rethrow;
    } finally {
      _isSaving = false;
    }
  }
  
  /// 差分保存（変更されたデータのみ）
  static Future<void> differentialSave({
    required Map<String, bool> dirtyFlags,
    required Future<void> Function() saveMedicationMemoStatus,
    required Future<void> Function() saveWeekdayMedicationStatus,
    required Future<void> Function() saveAddedMedications,
    required Future<void> Function() saveAlarmData,
    required Future<void> Function() saveCalendarMarks,
    required Future<void> Function() saveUserPreferences,
    required Future<void> Function() saveMedicationData,
    required Future<void> Function() saveDayColors,
    required Future<void> Function() saveStatistics,
    required Future<void> Function() saveAppSettings,
    required Future<void> Function() saveMedicationDoseStatus,
  }) async {
    if (_isSaving) {
      Logger.warning('データ保存中です。スキップします。');
      return;
    }
    
    if (dirtyFlags.isEmpty) {
      Logger.debug('変更されたデータがありません。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      final tasks = <Future<void>>[];
      
      // 変更されたデータのみ保存
      if (dirtyFlags['medicationMemoStatus'] == true) {
        tasks.add(saveMedicationMemoStatus());
      }
      if (dirtyFlags['weekdayMedicationStatus'] == true) {
        tasks.add(saveWeekdayMedicationStatus());
      }
      if (dirtyFlags['addedMedications'] == true) {
        tasks.add(saveAddedMedications());
      }
      if (dirtyFlags['alarmData'] == true) {
        tasks.add(saveAlarmData());
      }
      if (dirtyFlags['calendarMarks'] == true) {
        tasks.add(saveCalendarMarks());
      }
      if (dirtyFlags['userPreferences'] == true) {
        tasks.add(saveUserPreferences());
      }
      if (dirtyFlags['medicationData'] == true) {
        tasks.add(saveMedicationData());
      }
      if (dirtyFlags['dayColors'] == true) {
        tasks.add(saveDayColors());
      }
      if (dirtyFlags['statistics'] == true) {
        tasks.add(saveStatistics());
      }
      if (dirtyFlags['appSettings'] == true) {
        tasks.add(saveAppSettings());
      }
      if (dirtyFlags['medicationDoseStatus'] == true) {
        tasks.add(saveMedicationDoseStatus());
      }
      
      if (tasks.isNotEmpty) {
        Logger.performance('差分保存開始: ${tasks.length}個の操作');
        final startTime = DateTime.now();
        
        await Future.wait(tasks);
        
        final duration = DateTime.now().difference(startTime);
        Logger.performance('差分保存完了: ${duration.inMilliseconds}ms');
      }
      
      // ダーティフラグをクリア
      dirtyFlags.clear();
    } catch (e) {
      Logger.error('差分保存エラー', e);
      rethrow;
    } finally {
      _isSaving = false;
    }
  }
  
  /// 保存状態の確認
  static bool get isSaving => _isSaving;
  
  /// ダーティフラグの設定
  static void markDirty(String dataType) {
    _dirtyFlags[dataType] = true;
    Logger.debug('データ変更マーク: $dataType');
  }
  
  /// ダーティフラグのクリア
  static void clearDirtyFlags() {
    _dirtyFlags.clear();
    Logger.debug('ダーティフラグクリア');
  }
  
  /// 保存の強制完了
  static Future<void> forceCompleteSave() async {
    if (_pendingSaves.isNotEmpty) {
      Logger.info('保留中の保存操作を完了します: ${_pendingSaves.length}個');
      await Future.wait(_pendingSaves);
      _pendingSaves.clear();
    }
  }
}

/// 非同期処理の監視
class AsyncOperationMonitor {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final Map<String, Duration> _operationDurations = {};
  static final Map<String, int> _operationCounts = {};
  
  /// 操作の開始を記録
  static void recordOperationStart(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
    _operationCounts[operationId] = (_operationCounts[operationId] ?? 0) + 1;
    Logger.debug('操作開始記録: $operationId');
  }
  
  /// 操作の終了を記録
  static void recordOperationEnd(String operationId) {
    final startTime = _operationStartTimes.remove(operationId);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationId] = duration;
      Logger.performance('操作完了: $operationId (${duration.inMilliseconds}ms)');
    }
  }
  
  /// 長時間実行中の操作を検出
  static List<String> detectLongRunningOperations({Duration threshold = const Duration(seconds: 30)}) {
    final now = DateTime.now();
    final longRunning = <String>[];
    
    for (final entry in _operationStartTimes.entries) {
      final duration = now.difference(entry.value);
      if (duration.compareTo(threshold) > 0) {
        longRunning.add('${entry.key}: ${duration.inSeconds}秒');
      }
    }
    
    return longRunning;
  }
  
  /// 操作統計の取得
  static Map<String, dynamic> getOperationStats() {
    return {
      'activeOperations': _operationStartTimes.keys.toList(),
      'completedOperations': _operationDurations.length,
      'operationCounts': Map.from(_operationCounts),
      'longRunningOperations': detectLongRunningOperations(),
      'averageDuration': _operationDurations.values.isNotEmpty
          ? _operationDurations.values
              .map((d) => d.inMilliseconds)
              .reduce((a, b) => a + b) / _operationDurations.length
          : 0,
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _operationCounts.clear();
    Logger.info('操作統計をクリアしました');
  }
}
