import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../utils/logger.dart';

/// 具体的なエラーハンドリング - エラー分類と詳細な処理
class SpecificErrorHandling {
  
  /// 具体的なエラー分類
  static Future<T?> executeWithSpecificHandling<T>({
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
    } on DatabaseException catch (e) {
      Logger.error('$context: データベースエラー', e);
      if (reportToCrashlytics) {
        await _reportToCrashlytics(e, context);
      }
      return fallback;
    } on AuthenticationException catch (e) {
      Logger.error('$context: 認証エラー', e);
      if (reportToCrashlytics) {
        await _reportToCrashlytics(e, context);
      }
      return fallback;
    } on FileSystemException catch (e) {
      Logger.error('$context: ファイルシステムエラー', e);
      if (reportToCrashlytics) {
        await _reportToCrashlytics(e, context);
      }
      return fallback;
    } on TimeoutException catch (e) {
      Logger.error('$context: タイムアウトエラー', e);
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
  static void showSpecificError(
    BuildContext context,
    AppException exception, {
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;
    
    String message;
    String title;
    Color backgroundColor;
    
    switch (exception.type) {
      case ErrorType.network:
        title = 'ネットワークエラー';
        message = 'インターネット接続を確認してください。';
        backgroundColor = Colors.orange;
        break;
      case ErrorType.storage:
        title = 'ストレージエラー';
        message = 'ストレージの容量が不足しています。';
        backgroundColor = Colors.red;
        break;
      case ErrorType.permission:
        title = '権限エラー';
        message = '必要な権限が不足しています。設定を確認してください。';
        backgroundColor = Colors.purple;
        break;
      case ErrorType.validation:
        title = '入力エラー';
        message = '入力データに問題があります。内容を確認してください。';
        backgroundColor = Colors.amber;
        break;
      case ErrorType.database:
        title = 'データベースエラー';
        message = 'データの読み書きに問題が発生しました。';
        backgroundColor = Colors.red;
        break;
      case ErrorType.authentication:
        title = '認証エラー';
        message = '認証に失敗しました。再度ログインしてください。';
        backgroundColor = Colors.red;
        break;
      case ErrorType.fileSystem:
        title = 'ファイルエラー';
        message = 'ファイルの操作に問題が発生しました。';
        backgroundColor = Colors.red;
        break;
      case ErrorType.timeout:
        title = 'タイムアウトエラー';
        message = '処理に時間がかかりすぎています。再度お試しください。';
        backgroundColor = Colors.orange;
        break;
      case ErrorType.unknown:
        title = 'エラー';
        message = '予期しないエラーが発生しました。';
        backgroundColor = Colors.red;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
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
    AppException exception, {
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;
    
    String title;
    String message;
    IconData icon;
    Color iconColor;
    
    switch (exception.type) {
      case ErrorType.network:
        title = 'ネットワークエラー';
        message = 'インターネット接続を確認してください。';
        icon = Icons.wifi_off;
        iconColor = Colors.orange;
        break;
      case ErrorType.storage:
        title = 'ストレージエラー';
        message = 'ストレージの容量が不足しています。';
        icon = Icons.storage;
        iconColor = Colors.red;
        break;
      case ErrorType.permission:
        title = '権限エラー';
        message = '必要な権限が不足しています。設定を確認してください。';
        icon = Icons.lock;
        iconColor = Colors.purple;
        break;
      case ErrorType.validation:
        title = '入力エラー';
        message = '入力データに問題があります。内容を確認してください。';
        icon = Icons.error_outline;
        iconColor = Colors.amber;
        break;
      case ErrorType.database:
        title = 'データベースエラー';
        message = 'データの読み書きに問題が発生しました。';
        icon = Icons.database;
        iconColor = Colors.red;
        break;
      case ErrorType.authentication:
        title = '認証エラー';
        message = '認証に失敗しました。再度ログインしてください。';
        icon = Icons.person_off;
        iconColor = Colors.red;
        break;
      case ErrorType.fileSystem:
        title = 'ファイルエラー';
        message = 'ファイルの操作に問題が発生しました。';
        icon = Icons.folder_off;
        iconColor = Colors.red;
        break;
      case ErrorType.timeout:
        title = 'タイムアウトエラー';
        message = '処理に時間がかかりすぎています。再度お試しください。';
        icon = Icons.timer_off;
        iconColor = Colors.orange;
        break;
      case ErrorType.unknown:
        title = 'エラー';
        message = '予期しないエラーが発生しました。';
        icon = Icons.error;
        iconColor = Colors.red;
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
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
  
  /// Crashlyticsへのレポート
  static Future<void> _reportToCrashlytics(
    dynamic error,
    String context, [
    StackTrace? stackTrace,
  ]) async {
    try {
      await FirebaseCrashlytics.instance.log('$context: $error');
      if (stackTrace != null) {
        await FirebaseCrashlytics.instance.recordError(error, stackTrace);
      } else {
        await FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
      }
      Logger.debug('Crashlyticsレポート送信: $context');
    } catch (e) {
      Logger.warning('Crashlyticsレポートエラー: $e');
    }
  }
}

/// アプリ例外クラス
class AppException implements Exception {
  final String message;
  final ErrorType type;
  final String? details;
  final DateTime timestamp;
  
  AppException(this.message, this.type, {this.details})
      : timestamp = DateTime.now();
  
  @override
  String toString() => 'AppException($type): $message';
}

/// エラータイプの列挙
enum ErrorType {
  network,
  storage,
  permission,
  validation,
  database,
  authentication,
  fileSystem,
  timeout,
  unknown,
}

/// 具体的な例外クラス
class NetworkException extends AppException {
  final int? statusCode;
  final String? endpoint;
  
  NetworkException(String message, {this.statusCode, this.endpoint})
      : super(message, ErrorType.network, details: 'Status: $statusCode, Endpoint: $endpoint');
}

class StorageException extends AppException {
  final String? path;
  final int? availableSpace;
  
  StorageException(String message, {this.path, this.availableSpace})
      : super(message, ErrorType.storage, details: 'Path: $path, Available: $availableSpace');
}

class PermissionException extends AppException {
  final String? permission;
  final bool? isGranted;
  
  PermissionException(String message, {this.permission, this.isGranted})
      : super(message, ErrorType.permission, details: 'Permission: $permission, Granted: $isGranted');
}

class ValidationException extends AppException {
  final String? field;
  final String? expectedFormat;
  
  ValidationException(String message, {this.field, this.expectedFormat})
      : super(message, ErrorType.validation, details: 'Field: $field, Expected: $expectedFormat');
}

class DatabaseException extends AppException {
  final String? table;
  final String? operation;
  
  DatabaseException(String message, {this.table, this.operation})
      : super(message, ErrorType.database, details: 'Table: $table, Operation: $operation');
}

class AuthenticationException extends AppException {
  final String? userId;
  final String? authMethod;
  
  AuthenticationException(String message, {this.userId, this.authMethod})
      : super(message, ErrorType.authentication, details: 'User: $userId, Method: $authMethod');
}

class FileSystemException extends AppException {
  final String? filePath;
  final String? operation;
  
  FileSystemException(String message, {this.filePath, this.operation})
      : super(message, ErrorType.fileSystem, details: 'Path: $filePath, Operation: $operation');
}

class TimeoutException extends AppException {
  final Duration? timeout;
  final String? operation;
  
  TimeoutException(String message, {this.timeout, this.operation})
      : super(message, ErrorType.timeout, details: 'Timeout: $timeout, Operation: $operation');
}

/// エラーハンドリングミックスイン
mixin SpecificErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  
  /// 具体的なエラー処理付き操作実行
  Future<R?> safeExecuteWithSpecificHandling<R>(
    Future<R> Function() operation, {
    required String context,
    R? fallback,
    bool showUserMessage = true,
    bool reportToCrashlytics = true,
  }) async {
    return await SpecificErrorHandling.executeWithSpecificHandling(
      operation: operation,
      context: context,
      fallback: fallback,
      showUserMessage: showUserMessage,
      reportToCrashlytics: reportToCrashlytics,
    );
  }
  
  /// 具体的なエラー表示
  void showSpecificError(AppException exception, {VoidCallback? onRetry}) {
    SpecificErrorHandling.showSpecificError(
      context,
      exception,
      onRetry: onRetry,
    );
  }
  
  /// エラーダイアログの表示
  void showErrorDialog(AppException exception, {VoidCallback? onRetry, VoidCallback? onCancel}) {
    SpecificErrorHandling.showErrorDialog(
      context,
      exception,
      onRetry: onRetry,
      onCancel: onCancel,
    );
  }
}

/// エラーハンドリングのテスト
class SpecificErrorHandlingTest {
  static Future<void> testSpecificErrorHandling() async {
    Logger.info('具体的なエラーハンドリングテスト開始');
    
    // ネットワークエラーのテスト
    await SpecificErrorHandling.executeWithSpecificHandling(
      operation: () async {
        throw NetworkException('テストネットワークエラー', statusCode: 500, endpoint: '/api/test');
      },
      context: 'ネットワークテスト',
      fallback: 'フォールバック値',
    );
    
    // ストレージエラーのテスト
    await SpecificErrorHandling.executeWithSpecificHandling(
      operation: () async {
        throw StorageException('テストストレージエラー', path: '/test/path', availableSpace: 1024);
      },
      context: 'ストレージテスト',
      fallback: 'フォールバック値',
    );
    
    // 権限エラーのテスト
    await SpecificErrorHandling.executeWithSpecificHandling(
      operation: () async {
        throw PermissionException('テスト権限エラー', permission: 'storage', isGranted: false);
      },
      context: '権限テスト',
      fallback: 'フォールバック値',
    );
    
    // バリデーションエラーのテスト
    await SpecificErrorHandling.executeWithSpecificHandling(
      operation: () async {
        throw ValidationException('テストバリデーションエラー', field: 'email', expectedFormat: 'email@example.com');
      },
      context: 'バリデーションテスト',
      fallback: 'フォールバック値',
    );
    
    Logger.info('具体的なエラーハンドリングテスト完了');
  }
}
