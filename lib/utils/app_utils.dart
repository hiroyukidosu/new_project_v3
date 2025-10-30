part of medication_alarm_app;

// 簡易デバッグログ関数
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

// 簡易デバッグログ用Loggerクラス
class Logger {
  static int _logCount = 0;
  static const int _maxLogsPerSession = 50; // セッションあたりの最大ログ数  
  
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
  
  // セッションあたりのログ数を制限
  static bool _shouldLog() {
    if (kDebugMode) return true;
    _logCount++;
    return _logCount <= _maxLogsPerSession;
  }
  
  // 強制的なログ出力（セッション制限を無視）
  static void critical(String message) {
    debugPrint('[CRITICAL] $message');
  }
}

// 簡易エラーハンドラー
class AppErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    // エラーログ出力
    Logger.error('エラー発生', error);
    
    // Firebase Crashlyticsにエラーを記録
    try {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
    } catch (e) {
      // Crashlyticsがエラーになった場合は無視
    }
    
    // デバッグモードでの詳細ログ出力
    if (kDebugMode) {
      debugPrint('エラー内容: $error');
      if (stackTrace != null) {
        debugPrint('スタックトレース: $stackTrace');
      }
    }
  }
  
  static String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'ネットワーク接続を確認してください';
    }
    
    if (errorString.contains('permission') || errorString.contains('許可')) {
      return '必要な許可が設定されていません';
    }
    
    if (errorString.contains('storage') || errorString.contains('保存')) {
      return 'データの保存に失敗しました';
    }
    
    if (errorString.contains('load') || errorString.contains('読み込み')) {
      return 'データの読み込みに失敗しました';
    }
    
    return '不明なエラーが発生しました。もう一度お試しください';
  }
}

