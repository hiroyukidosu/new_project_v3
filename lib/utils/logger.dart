// Flutter core imports
import 'package:flutter/foundation.dart';

// 高速化：シンプルなデバッグログ
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

// 高速化：シンプルなLogger（本番環境でのログ削減）
class Logger {
  static int _logCount = 0;
  static const int _maxLogsPerSession = 50; // 本番環境でのログ数制限
  
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
  
  // 本番環境でのログ数を制限
  static bool _shouldLog() {
    if (kDebugMode) return true;
    _logCount++;
    return _logCount <= _maxLogsPerSession;
  }
  
  // 重要なログ（本番環境でも出力）
  static void critical(String message) {
    debugPrint('[CRITICAL] $message');
  }
}