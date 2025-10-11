import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// ログレベル管理
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  critical(4);
  
  const LogLevel(this.level);
  final int level;
}

// ログ管理の改善（最適化版）
class Logger {
  static DateTime? _lastLogTime;
  static const Duration _logInterval = Duration(seconds: 30);
  static LogLevel _currentLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;
  static final Map<String, DateTime> _lastLogTimes = {};
  static final Map<String, int> _logCounts = {};
  static const int _maxLogsPerKey = 10;
  static const Duration _logCooldown = Duration(minutes: 5);
  
  // ログレベルの設定
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }
  
  // ログレベルの取得
  static LogLevel get currentLevel => _currentLevel;
  
  // デバッグログ
  static void debug(String message) {
    _log(LogLevel.debug, message);
  }
  
  // 情報ログ
  static void info(String message) {
    _log(LogLevel.info, message);
  }
  
  // 警告ログ
  static void warning(String message) {
    _log(LogLevel.warning, message);
  }
  
  // エラーログ
  static void error(String message, [dynamic error]) {
    _log(LogLevel.error, message, error);
  }
  
  // クリティカルログ
  static void critical(String message, [dynamic error]) {
    _log(LogLevel.critical, message, error);
  }
  
  // パフォーマンスログ
  static void performance(String message) {
    if (_shouldLogForLevel(LogLevel.info)) {
      debugPrint('[PERFORMANCE] ${DateTime.now()}: $message');
    }
  }
  
  // 内部ログ処理
  static void _log(LogLevel level, String message, [dynamic error]) {
    if (!_shouldLogForLevel(level)) return;
    
    // ログの頻度制御
    if (!_shouldLogForFrequency(message)) return;
    
    final timestamp = DateTime.now();
    final levelName = level.name.toUpperCase();
    
    if (kDebugMode) {
      debugPrint('[$levelName] $timestamp: $message${error != null ? ': $error' : ''}');
    }
    
    // エラーレベル以上はCrashlyticsに送信
    if (level.level >= LogLevel.error.level) {
      try {
        FirebaseCrashlytics.instance.log('$levelName: $message');
        if (error != null) {
          FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
        }
      } catch (e) {
        // Crashlytics自体のエラーは無視
      }
    }
  }
  
  // ログレベルのチェック
  static bool _shouldLogForLevel(LogLevel level) {
    return level.level >= _currentLevel.level;
  }
  
  // ログの頻度制御
  static bool _shouldLogForFrequency(String message) {
    final now = DateTime.now();
    final messageHash = message.hashCode.toString();
    
    // 同じメッセージの頻度制御
    if (_lastLogTimes.containsKey(messageHash)) {
      final lastTime = _lastLogTimes[messageHash]!;
      final count = _logCounts[messageHash] ?? 0;
      
      if (now.difference(lastTime).compareTo(_logCooldown) < 0) {
        if (count >= _maxLogsPerKey) {
          return false; // 頻繁すぎるログはスキップ
        }
        _logCounts[messageHash] = count + 1;
      } else {
        _logCounts[messageHash] = 1;
      }
    } else {
      _logCounts[messageHash] = 1;
    }
    
    _lastLogTimes[messageHash] = now;
    
    // 全体的な頻度制御
    if (_lastLogTime == null || now.difference(_lastLogTime!).compareTo(_logInterval) >= 0) {
      _lastLogTime = now;
      return true;
    }
    
    return false;
  }
  
  // ログ統計の取得
  static Map<String, int> getLogStatistics() {
    return Map.unmodifiable(_logCounts);
  }
  
  // ログ統計のリセット
  static void resetLogStatistics() {
    _lastLogTimes.clear();
    _logCounts.clear();
    _lastLogTime = null;
  }
  
  // ログのフィルタリング
  static void setLogFilter(List<String> allowedCategories) {
    // 実装は必要に応じて追加
  }
  
  // ログの出力先設定
  static void setLogOutput({
    bool console = true,
    bool crashlytics = true,
    bool file = false,
  }) {
    // 実装は必要に応じて追加
  }
  
  // ログのクリーンアップ
  static void cleanup() {
    resetLogStatistics();
  }
}
