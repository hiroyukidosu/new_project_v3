import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../utils/logger.dart';

/// エラーハンドリングの改善 - 包括的なエラー管理
class ErrorHandler {
  static final Map<String, int> _errorCounts = {};
  static final Map<String, DateTime> _lastErrorTimes = {};
  static const int _maxErrorsPerMinute = 5;
  static const Duration _errorCooldown = Duration(minutes: 1);
  
  /// 安全な操作実行
  static Future<T?> execute<T>({
    required Future<T> Function() operation,
    required String context,
    T? fallback,
    bool showUserMessage = true,
    bool reportToCrashlytics = true,
  }) async {
    try {
      return await operation();
    } on NetworkException catch (e) {
      Logger.error('$context: ネットワークエラー', e);
      if (reportToCrashlytics) {
        await _reportToCrashlytics(e, context);
      }
      return fallback;
    } on StorageException catch (e) {
      Logger.error('$context: ストレージエラー', e);
      if (reportToCrashlytics) {
        await _reportToCrashlytics(e, context);
      }
      return fallback;
    } on ValidationException catch (e) {
      Logger.error('$context: バリデーションエラー', e);
      if (reportToCrashlytics) {
        await _reportToCrashlytics(e, context);
      }
      return fallback;
    } on PermissionException catch (e) {
      Logger.error('$context: 権限エラー', e);
      if (reportToCrashlytics) {
        await _reportToCrashlytics(e, context);
      }
      return fallback;
    } catch (e, stackTrace) {
      Logger.critical('$context: 予期しないエラー', e);
      if (reportToCrashlytics) {
        await _reportToCrashlytics(e, context, stackTrace);
      }
      return fallback;
    }
  }
  
  /// ユーザーフレンドリーなエラー表示
  static void showUserFriendlyError(
    BuildContext context,
    String errorContext,
    dynamic error, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    if (!context.mounted) return;
    
    String message;
    if (customMessage != null) {
      message = customMessage;
    } else if (error.toString().contains('permission')) {
      message = '権限が不足しています。設定を確認してください。';
    } else if (error.toString().contains('network')) {
      message = 'ネットワーク接続を確認してください。';
    } else if (error.toString().contains('storage')) {
      message = 'ストレージの容量が不足しています。';
    } else if (error.toString().contains('validation')) {
      message = '入力データに問題があります。';
    } else {
      message = '問題が発生しました。もう一度お試しください。';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
  
  /// エラーダイアログの表示
  static void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onCancel();
              },
              child: const Text('キャンセル'),
            ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('再試行'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// エラーの頻度制御
  static bool shouldReportError(String context) {
    final now = DateTime.now();
    final lastErrorTime = _lastErrorTimes[context];
    final errorCount = _errorCounts[context] ?? 0;
    
    if (lastErrorTime != null) {
      final timeDiff = now.difference(lastErrorTime);
      if (timeDiff < _errorCooldown) {
        if (errorCount >= _maxErrorsPerMinute) {
          Logger.warning('エラー頻度制限: $context (${errorCount}回/分)');
          return false;
        }
      } else {
        _errorCounts[context] = 0;
      }
    }
    
    _errorCounts[context] = errorCount + 1;
    _lastErrorTimes[context] = now;
    return true;
  }
  
  /// Crashlyticsへのレポート
  static Future<void> _reportToCrashlytics(
    dynamic error,
    String context, [
    StackTrace? stackTrace,
  ]) async {
    try {
      if (shouldReportError(context)) {
        await FirebaseCrashlytics.instance.log('$context: $error');
        if (stackTrace != null) {
          await FirebaseCrashlytics.instance.recordError(error, stackTrace);
        } else {
          await FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
        }
        Logger.debug('Crashlyticsレポート送信: $context');
      }
    } catch (e) {
      Logger.warning('Crashlyticsレポートエラー: $e');
    }
  }
  
  /// エラー統計の取得
  static Map<String, dynamic> getErrorStats() {
    return {
      'errorCounts': Map.from(_errorCounts),
      'lastErrorTimes': Map.from(_lastErrorTimes),
      'totalErrors': _errorCounts.values.fold(0, (sum, count) => sum + count),
    };
  }
  
  /// エラー統計のクリア
  static void clearErrorStats() {
    _errorCounts.clear();
    _lastErrorTimes.clear();
    Logger.info('エラー統計をクリアしました');
  }
}

/// カスタム例外クラス
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  
  NetworkException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'NetworkException: $message';
}

class StorageException implements Exception {
  final String message;
  final String? path;
  
  StorageException(this.message, [this.path]);
  
  @override
  String toString() => 'StorageException: $message';
}

class ValidationException implements Exception {
  final String message;
  final String? field;
  
  ValidationException(this.message, [this.field]);
  
  @override
  String toString() => 'ValidationException: $message';
}

class PermissionException implements Exception {
  final String message;
  final String? permission;
  
  PermissionException(this.message, [this.permission]);
  
  @override
  String toString() => 'PermissionException: $message';
}

/// エラーハンドリングミックスイン
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  
  /// 安全な操作実行
  Future<R?> safeExecute<R>(
    Future<R> Function() operation, {
    required String context,
    R? fallback,
    bool showUserMessage = true,
    bool reportToCrashlytics = true,
  }) async {
    return await ErrorHandler.execute(
      operation: operation,
      context: context,
      fallback: fallback,
      showUserMessage: showUserMessage,
      reportToCrashlytics: reportToCrashlytics,
    );
  }
  
  /// ユーザーフレンドリーなエラー表示
  void showError(String errorContext, dynamic error, {VoidCallback? onRetry}) {
    ErrorHandler.showUserFriendlyError(
      errorContext,
      error,
      onRetry: onRetry,
    );
  }
  
  /// エラーダイアログの表示
  void showErrorDialog(
    String title,
    String message, {
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    ErrorHandler.showErrorDialog(
      context,
      title,
      message,
      onRetry: onRetry,
      onCancel: onCancel,
    );
  }
}

/// グローバルエラーハンドラー
class GlobalErrorHandler {
  static void initialize() {
    // Flutterエラーのハンドリング
    FlutterError.onError = (FlutterErrorDetails details) {
      Logger.critical('Flutterエラー', details.exception);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    
    // プラットフォームエラーのハンドリング
    PlatformDispatcher.instance.onError = (error, stack) {
      Logger.critical('プラットフォームエラー', error);
      FirebaseCrashlytics.instance.recordError(error, stack);
      return true;
    };
  }
}

/// エラー回復機能
class ErrorRecovery {
  static final Map<String, int> _retryCounts = {};
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  /// リトライ付き操作実行
  static Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    required String context,
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
    T? fallback,
  }) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        _retryCounts[context] = retryCount;
        
        if (retryCount < maxRetries) {
          Logger.warning('$context: リトライ ${retryCount}/$maxRetries');
          await Future.delayed(retryDelay);
        } else {
          Logger.error('$context: 最大リトライ回数に達しました', e);
          return fallback;
        }
      }
    }
    
    return fallback;
  }
  
  /// リトライ統計の取得
  static Map<String, int> getRetryStats() {
    return Map.from(_retryCounts);
  }
  
  /// リトライ統計のクリア
  static void clearRetryStats() {
    _retryCounts.clear();
    Logger.info('リトライ統計をクリアしました');
  }
}

/// エラーハンドリングのテスト
class ErrorHandlingTest {
  static Future<void> testErrorHandling() async {
    Logger.info('エラーハンドリングテスト開始');
    
    // ネットワークエラーのテスト
    await ErrorHandler.execute(
      operation: () async {
        throw NetworkException('テストネットワークエラー', 500);
      },
      context: 'ネットワークテスト',
      fallback: 'フォールバック値',
    );
    
    // ストレージエラーのテスト
    await ErrorHandler.execute(
      operation: () async {
        throw StorageException('テストストレージエラー', '/test/path');
      },
      context: 'ストレージテスト',
      fallback: 'フォールバック値',
    );
    
    // バリデーションエラーのテスト
    await ErrorHandler.execute(
      operation: () async {
        throw ValidationException('テストバリデーションエラー', 'testField');
      },
      context: 'バリデーションテスト',
      fallback: 'フォールバック値',
    );
    
    // 権限エラーのテスト
    await ErrorHandler.execute(
      operation: () async {
        throw PermissionException('テスト権限エラー', 'testPermission');
      },
      context: '権限テスト',
      fallback: 'フォールバック値',
    );
    
    Logger.info('エラーハンドリングテスト完了');
  }
}
