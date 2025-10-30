import 'package:flutter/foundation.dart';

/// デバッグ用ロガー
class Logger {
  static int _logCount = 0;
  static const int _maxLogsPerSession = 50; // セッションごとのログ上限
  
  static void info(String message) {
    if (_shouldLog()) debugPrint('[INFO] $message');
  }
  
  static void error(String message, [dynamic error]) {
    if (_shouldLog()) debugPrint('[ERROR] $message: $error');
  }
  
  static void warning(String message) {
    if (_shouldLog()) debugPrint('[WARNING] $message');
  }
  
  static void debug(String message) {
    if (kDebugMode && _shouldLog()) debugPrint('[DEBUG] $message');
  }
  
  // セッションごとのログ上限チェック
  static bool _shouldLog() {
    if (kDebugMode) return true;
    _logCount++;
    return _logCount <= _maxLogsPerSession;
  }
  
  // 常にログ出力する（エラーなど）
  static void critical(String message) {
    debugPrint('[CRITICAL] $message');
  }
}
