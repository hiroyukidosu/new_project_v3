import '../utils/logger.dart';

/// アラーム最適化 - ログの無限出力を防ぐ
class AlarmOptimization {
  static DateTime? _lastAlarmCheckTime;
  static DateTime? _lastAlarmLogTime;
  static const Duration _alarmCheckInterval = Duration(minutes: 1);
  static const Duration _alarmLogInterval = Duration(minutes: 5); // ✅ 修正：5分に1回に変更
  
  /// 最適化されたアラームチェック
  static bool shouldCheckAlarms() {
    final now = DateTime.now();
    
    // ✅ 修正：チェック間隔を制限する
    if (_lastAlarmCheckTime != null && 
        now.difference(_lastAlarmCheckTime!).compareTo(_alarmCheckInterval) < 0) {
      return false; // 1分以内の重複チェックをスキップ
    }
    
    _lastAlarmCheckTime = now;
    return true;
  }
  
  /// ログの頻度制限
  static bool shouldLogAlarmCheck() {
    final now = DateTime.now();
    if (_lastAlarmLogTime == null || 
        now.difference(_lastAlarmLogTime!).compareTo(_alarmLogInterval) >= 0) {
      _lastAlarmLogTime = now;
      return true;
    }
    return false;
  }
  
  /// アラーム時間のパース
  static DateTime? parseAlarmTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      Logger.warning('アラーム時間パースエラー: $timeString');
    }
    return null;
  }
  
  /// 過去のアラームかどうかをチェック
  static bool isPastAlarm(String timeString) {
    final alarmTime = parseAlarmTime(timeString);
    if (alarmTime == null) return true;
    
    final now = DateTime.now();
    return alarmTime.isBefore(now.subtract(const Duration(minutes: 1)));
  }
  
  /// アラームチェックの統計
  static Map<String, dynamic> getAlarmStats() {
    return {
      'lastCheckTime': _lastAlarmCheckTime?.toIso8601String(),
      'lastLogTime': _lastAlarmLogTime?.toIso8601String(),
      'checkInterval': _alarmCheckInterval.inMinutes,
      'logInterval': _alarmLogInterval.inSeconds,
    };
  }
  
  /// 統計のリセット
  static void resetStats() {
    _lastAlarmCheckTime = null;
    _lastAlarmLogTime = null;
    Logger.info('アラーム最適化統計をリセットしました');
  }
}

/// 最適化されたアラームチェッカー
class OptimizedAlarmChecker {
  final List<Map<String, dynamic>> _alarms;
  final Map<String, dynamic> _alarmSettings;
  final Function(Map<String, dynamic>) _triggerAlarm;
  
  OptimizedAlarmChecker({
    required List<Map<String, dynamic>> alarms,
    required Map<String, dynamic> alarmSettings,
    required Function(Map<String, dynamic>) triggerAlarm,
  }) : _alarms = alarms,
       _alarmSettings = alarmSettings,
       _triggerAlarm = triggerAlarm;
  
  /// 最適化されたアラームチェック
  void checkAlarms() {
    // ✅ 修正：チェック間隔を制限する
    if (!AlarmOptimization.shouldCheckAlarms()) {
      return;
    }
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // ✅ 修正：ログの頻度制限
    if (AlarmOptimization.shouldLogAlarmCheck()) {
      Logger.info('服用時間のアラームチェック: $currentTime, アラーム数: ${_alarms.length}, 有効: ${_alarmSettings['isAlarmEnabled']}');
    }
    
    if (!_alarmSettings['isAlarmEnabled']) return;
    
    for (final alarm in _alarms) {
      if (alarm['enabled'] == true && alarm['time'] == currentTime) {
        // ✅ 修正：過去のアラームはスキップする
        if (AlarmOptimization.isPastAlarm(alarm['time'])) {
          continue; // 1分以上前のアラームはスキップ
        }
        
        if (AlarmOptimization.shouldLogAlarmCheck()) {
          Logger.info('服用時間のアラーム: ${alarm['name']}, 時間: ${alarm['time']}, 有効: ${alarm['enabled']}');
        }
        _triggerAlarm(alarm);
      }
    }
  }
  
  /// アラームの統計情報を取得
  Map<String, dynamic> getStats() {
    return {
      'alarmCount': _alarms.length,
      'enabledAlarms': _alarms.where((alarm) => alarm['enabled'] == true).length,
      'disabledAlarms': _alarms.where((alarm) => alarm['enabled'] == false).length,
      'isAlarmEnabled': _alarmSettings['isAlarmEnabled'],
      'optimizationStats': AlarmOptimization.getAlarmStats(),
    };
  }
}

/// アラーム最適化の監視
class AlarmOptimizationMonitor {
  static final Map<String, int> _checkCounts = {};
  static final Map<String, DateTime> _lastCheckTimes = {};
  static final List<String> _optimizationLogs = [];
  
  /// アラームチェックの記録
  static void recordAlarmCheck(String alarmId, bool wasTriggered) {
    _checkCounts[alarmId] = (_checkCounts[alarmId] ?? 0) + 1;
    _lastCheckTimes[alarmId] = DateTime.now();
    
    if (wasTriggered) {
      _optimizationLogs.add('アラーム発火: $alarmId at ${DateTime.now()}');
    }
  }
  
  /// 最適化ログの記録
  static void recordOptimizationLog(String message) {
    _optimizationLogs.add('${DateTime.now()}: $message');
    
    // ログが多すぎる場合は古いログを削除
    if (_optimizationLogs.length > 100) {
      _optimizationLogs.removeRange(0, 50);
    }
  }
  
  /// 統計の取得
  static Map<String, dynamic> getOptimizationStats() {
    return {
      'checkCounts': Map.from(_checkCounts),
      'lastCheckTimes': Map.from(_lastCheckTimes),
      'optimizationLogs': List.from(_optimizationLogs),
      'totalChecks': _checkCounts.values.fold(0, (sum, count) => sum + count),
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _checkCounts.clear();
    _lastCheckTimes.clear();
    _optimizationLogs.clear();
    Logger.info('アラーム最適化統計をクリアしました');
  }
}
