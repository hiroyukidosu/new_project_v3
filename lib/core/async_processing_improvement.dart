import 'dart:async';
import '../utils/logger.dart';

/// 非同期処理の改善 - 優先度付きロード
class AsyncProcessingImprovement {
  
  /// 優先度付きアプリ初期化
  static Future<void> initializeApp({
    required Future<void> Function() loadCriticalData,
    required Future<void> Function() loadSecondaryData,
    required VoidCallback onReady,
  }) async {
    Logger.info('優先度付きアプリ初期化開始');
    
    try {
      // 1. 即座に表示が必要なデータ
      Logger.info('重要データ読み込み開始');
      await loadCriticalData();
      
      // UIを即座に表示
      onReady();
      Logger.info('重要データ読み込み完了、UI表示開始');
      
      // 2. バックグラウンドで読み込み
      unawaited(_loadSecondaryDataInBackground(loadSecondaryData));
      
    } catch (e) {
      Logger.error('アプリ初期化エラー', e);
      rethrow;
    }
  }
  
  /// バックグラウンドでの二次データ読み込み
  static Future<void> _loadSecondaryDataInBackground(
    Future<void> Function() loadSecondaryData,
  ) async {
    try {
      // 少し遅延させてUIのレンダリングを優先
      await Future.delayed(const Duration(milliseconds: 500));
      
      Logger.info('二次データ読み込み開始');
      await loadSecondaryData();
      Logger.info('二次データ読み込み完了');
    } catch (e) {
      Logger.error('二次データ読み込みエラー', e);
    }
  }
  
  /// 優先度付きデータ読み込み
  static Future<void> loadDataWithPriority({
    required List<Future<void> Function()> criticalTasks,
    required List<Future<void> Function()> secondaryTasks,
    required List<Future<void> Function()> backgroundTasks,
  }) async {
    Logger.info('優先度付きデータ読み込み開始');
    
    try {
      // 1. 重要タスク（並列実行）
      if (criticalTasks.isNotEmpty) {
        Logger.info('重要タスク実行: ${criticalTasks.length}件');
        await Future.wait(criticalTasks.map((task) => task()));
        Logger.info('重要タスク完了');
      }
      
      // 2. 二次タスク（並列実行）
      if (secondaryTasks.isNotEmpty) {
        Logger.info('二次タスク実行: ${secondaryTasks.length}件');
        await Future.wait(secondaryTasks.map((task) => task()));
        Logger.info('二次タスク完了');
      }
      
      // 3. バックグラウンドタスク（非同期実行）
      if (backgroundTasks.isNotEmpty) {
        Logger.info('バックグラウンドタスク実行: ${backgroundTasks.length}件');
        unawaited(Future.wait(backgroundTasks.map((task) => task())));
        Logger.info('バックグラウンドタスク開始');
      }
      
    } catch (e) {
      Logger.error('優先度付きデータ読み込みエラー', e);
      rethrow;
    }
  }
  
  /// デバウンス付き実行
  static Future<void> debouncedExecution(
    String key,
    Future<void> Function() operation, {
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    _DebounceManager.debounce(key, operation, delay);
  }
  
  /// スロットル付き実行
  static Future<void> throttledExecution(
    String key,
    Future<void> Function() operation, {
    Duration interval = const Duration(seconds: 1),
  }) async {
    _ThrottleManager.throttle(key, operation, interval);
  }
  
  /// リトライ付き実行
  static Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    T? fallback,
  }) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        Logger.warning('リトライ ${retryCount}/$maxRetries: $e');
        
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        } else {
          Logger.error('最大リトライ回数に達しました', e);
          return fallback;
        }
      }
    }
    
    return fallback;
  }
  
  /// 並列実行の最適化
  static Future<List<T>> executeInParallel<T>(
    List<Future<T> Function()> operations, {
    int maxConcurrency = 5,
  }) async {
    final results = <T>[];
    final futures = <Future<T>>[];
    
    for (int i = 0; i < operations.length; i += maxConcurrency) {
      final batch = operations.skip(i).take(maxConcurrency);
      final batchFutures = batch.map((operation) => operation()).toList();
      
      final batchResults = await Future.wait(batchFutures);
      results.addAll(batchResults);
      
      Logger.debug('バッチ実行完了: ${i + 1}-${i + batch.length}');
    }
    
    return results;
  }
}

/// デバウンス管理
class _DebounceManager {
  static final Map<String, Timer> _timers = {};
  
  static void debounce(
    String key,
    Future<void> Function() operation,
    Duration delay,
  ) {
    _timers[key]?.cancel();
    _timers[key] = Timer(delay, () async {
      try {
        await operation();
        Logger.debug('デバウンス実行完了: $key');
      } catch (e) {
        Logger.error('デバウンス実行エラー: $key', e);
      }
    });
  }
  
  static void cancel(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }
  
  static void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}

/// スロットル管理
class _ThrottleManager {
  static final Map<String, DateTime> _lastExecutions = {};
  
  static void throttle(
    String key,
    Future<void> Function() operation,
    Duration interval,
  ) {
    final now = DateTime.now();
    final lastExecution = _lastExecutions[key];
    
    if (lastExecution == null || now.difference(lastExecution) >= interval) {
      _lastExecutions[key] = now;
      unawaited(_executeOperation(key, operation));
    } else {
      Logger.debug('スロットル制限: $key');
    }
  }
  
  static Future<void> _executeOperation(
    String key,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
      Logger.debug('スロットル実行完了: $key');
    } catch (e) {
      Logger.error('スロットル実行エラー: $key', e);
    }
  }
  
  static void clear(String key) {
    _lastExecutions.remove(key);
  }
  
  static void clearAll() {
    _lastExecutions.clear();
  }
}

/// 非同期処理の監視
class AsyncProcessingMonitor {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final Map<String, Duration> _operationDurations = {};
  static final Map<String, int> _operationCounts = {};
  static final Map<String, List<String>> _operationErrors = {};
  
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
  
  /// 操作エラーの記録
  static void recordOperationError(String operationId, String error) {
    _operationErrors.putIfAbsent(operationId, () => []).add(error);
    Logger.error('操作エラー: $operationId - $error');
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
      'operationErrors': Map.from(_operationErrors),
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
    _operationErrors.clear();
    Logger.info('非同期処理統計をクリアしました');
  }
}

/// 最適化されたアプリ初期化の実装例
class OptimizedAppInitializer {
  static Future<void> initializeOptimizedApp({
    required Future<void> Function() loadCriticalData,
    required Future<void> Function() loadSecondaryData,
    required VoidCallback onReady,
  }) async {
    await AsyncProcessingImprovement.initializeApp(
      loadCriticalData: loadCriticalData,
      loadSecondaryData: loadSecondaryData,
      onReady: onReady,
    );
  }
  
  /// 重要データの読み込み
  static Future<void> loadCriticalData() async {
    Logger.info('重要データ読み込み開始');
    
    // 即座に表示が必要なデータ
    await Future.wait([
      _loadUserPreferences(),
      _loadTodayMedications(),
      _loadCurrentSettings(),
    ]);
    
    Logger.info('重要データ読み込み完了');
  }
  
  /// 二次データの読み込み
  static Future<void> loadSecondaryData() async {
    Logger.info('二次データ読み込み開始');
    
    // 後から読み込むデータ
    await Future.wait([
      _loadHistoricalData(),
      _loadStatistics(),
      _loadAlarmData(),
      _loadCalendarMarks(),
    ]);
    
    Logger.info('二次データ読み込み完了');
  }
  
  /// バックグラウンドデータの読み込み
  static Future<void> loadBackgroundData() async {
    Logger.info('バックグラウンドデータ読み込み開始');
    
    // バックグラウンドで読み込むデータ
    unawaited(_loadAnalyticsData());
    unawaited(_loadCacheData());
    unawaited(_loadOfflineData());
    
    Logger.info('バックグラウンドデータ読み込み開始');
  }
  
  // プレースホルダーメソッド
  static Future<void> _loadUserPreferences() async {
    await Future.delayed(const Duration(milliseconds: 100));
    Logger.debug('ユーザー設定読み込み完了');
  }
  
  static Future<void> _loadTodayMedications() async {
    await Future.delayed(const Duration(milliseconds: 150));
    Logger.debug('今日のメディケーション読み込み完了');
  }
  
  static Future<void> _loadCurrentSettings() async {
    await Future.delayed(const Duration(milliseconds: 80));
    Logger.debug('現在の設定読み込み完了');
  }
  
  static Future<void> _loadHistoricalData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    Logger.debug('履歴データ読み込み完了');
  }
  
  static Future<void> _loadStatistics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    Logger.debug('統計データ読み込み完了');
  }
  
  static Future<void> _loadAlarmData() async {
    await Future.delayed(const Duration(milliseconds: 200));
    Logger.debug('アラームデータ読み込み完了');
  }
  
  static Future<void> _loadCalendarMarks() async {
    await Future.delayed(const Duration(milliseconds: 250));
    Logger.debug('カレンダーマーク読み込み完了');
  }
  
  static Future<void> _loadAnalyticsData() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    Logger.debug('アナリティクスデータ読み込み完了');
  }
  
  static Future<void> _loadCacheData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    Logger.debug('キャッシュデータ読み込み完了');
  }
  
  static Future<void> _loadOfflineData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    Logger.debug('オフラインデータ読み込み完了');
  }
}
