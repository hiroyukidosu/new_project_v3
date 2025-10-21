import 'package:flutter/foundation.dart';

/// アプリケーションログ管理
/// 
/// 本番環境でのログ出力を制御し、パフォーマンスを向上
class AppLogger {
  // ログレベル
  static const bool _enableDebugLogs = kDebugMode;
  static const bool _enableInfoLogs = true;
  static const bool _enableErrorLogs = true;
  static const bool _enableWarningLogs = true;
  
  // ログカウンター（本番環境でのログ数を制限）
  static int _logCount = 0;
  static const int _maxLogsPerSession = 100; // セッションあたりの最大ログ数
  
  /// デバッグログ（開発環境のみ）
  static void debug(String message) {
    if (_enableDebugLogs && _shouldLog()) {
      debugPrint('[DEBUG] $message');
    }
  }
  
  /// 情報ログ
  static void info(String message) {
    if (_enableInfoLogs && _shouldLog()) {
      debugPrint('[INFO] $message');
    }
  }
  
  /// 警告ログ
  static void warning(String message) {
    if (_enableWarningLogs && _shouldLog()) {
      debugPrint('[WARNING] $message');
    }
  }
  
  /// エラーログ
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_enableErrorLogs) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('[ERROR] 詳細: $error');
      }
      if (stackTrace != null) {
        debugPrint('[ERROR] スタックトレース: $stackTrace');
      }
    }
  }
  
  /// パフォーマンスログ
  static void performance(String operation, Duration duration) {
    if (_enableDebugLogs && _shouldLog()) {
      debugPrint('[PERF] $operation: ${duration.inMilliseconds}ms');
    }
  }
  
  /// ログ出力すべきかチェック
  static bool _shouldLog() {
    if (kDebugMode) {
      return true; // 開発環境では常に出力
    }
    
    // 本番環境ではログ数を制限
    _logCount++;
    return _logCount <= _maxLogsPerSession;
  }
  
  /// ログカウンターをリセット
  static void resetLogCount() {
    _logCount = 0;
  }
  
  /// 重要なログ（本番環境でも出力）
  static void critical(String message) {
    debugPrint('[CRITICAL] $message');
  }
  
  /// ユーザーアクションログ
  static void userAction(String action) {
    if (_enableInfoLogs && _shouldLog()) {
      debugPrint('[USER] $action');
    }
  }
  
  /// データ操作ログ
  static void dataOperation(String operation, {String? details}) {
    if (_enableDebugLogs && _shouldLog()) {
      final message = details != null ? '$operation: $details' : operation;
      debugPrint('[DATA] $message');
    }
  }
}
