// lib/core/errors/app_error.dart
// アプリケーション全体で使用するエラータイプの定義

/// アプリケーションエラーの基底クラス
sealed class AppError {
  final String userMessage;
  final Object? originalError;
  final StackTrace? stackTrace;
  final String? errorCode;

  const AppError({
    required this.userMessage,
    this.originalError,
    this.stackTrace,
    this.errorCode,
  });

  /// エラーの詳細情報を取得
  String get details {
    if (originalError != null) {
      return originalError.toString();
    }
    return userMessage;
  }

  /// デバッグ用の詳細情報
  String get debugInfo {
    final buffer = StringBuffer();
    buffer.writeln('Error Type: ${runtimeType}');
    buffer.writeln('User Message: $userMessage');
    if (errorCode != null) {
      buffer.writeln('Error Code: $errorCode');
    }
    if (originalError != null) {
      buffer.writeln('Original Error: $originalError');
    }
    if (stackTrace != null) {
      buffer.writeln('Stack Trace: $stackTrace');
    }
    return buffer.toString();
  }
}

/// ネットワークエラー（リトライ可能）
class NetworkError extends RetryableError {
  const NetworkError({
    super.userMessage = 'ネットワーク接続に問題があります。インターネット接続を確認してください。',
    super.originalError,
    super.stackTrace,
    super.errorCode = 'NETWORK_ERROR',
  });
}

/// ストレージエラー（データ保存/読み込みエラー、リトライ可能）
class StorageError extends RetryableError {
  const StorageError({
    super.userMessage = 'データの保存または読み込み中にエラーが発生しました。',
    super.originalError,
    super.stackTrace,
    super.errorCode = 'STORAGE_ERROR',
  });
}

/// バリデーションエラー（入力値の検証エラー、リトライ不可能）
class ValidationError extends NonRetryableError {
  const ValidationError({
    required super.userMessage,
    super.originalError,
    super.stackTrace,
    super.errorCode = 'VALIDATION_ERROR',
  });
}

/// 権限エラー（アクセス権限がない、リトライ不可能）
class PermissionError extends NonRetryableError {
  const PermissionError({
    super.userMessage = '必要な権限がありません。設定から権限を有効にしてください。',
    super.originalError,
    super.stackTrace,
    super.errorCode = 'PERMISSION_ERROR',
  });
}

/// タイムアウトエラー（リトライ可能）
class TimeoutError extends RetryableError {
  const TimeoutError({
    super.userMessage = '処理がタイムアウトしました。しばらく待ってから再度お試しください。',
    super.originalError,
    super.stackTrace,
    super.errorCode = 'TIMEOUT_ERROR',
  });
}

/// 不明なエラー（リトライ不可能）
class UnknownError extends NonRetryableError {
  const UnknownError({
    super.userMessage = '予期しないエラーが発生しました。',
    super.originalError,
    super.stackTrace,
    super.errorCode = 'UNKNOWN_ERROR',
  });
}

/// リトライ可能なエラー
abstract class RetryableError extends AppError {
  const RetryableError({
    required super.userMessage,
    super.originalError,
    super.stackTrace,
    super.errorCode,
  });

  /// リトライ可能かどうか
  bool get canRetry => true;
}

/// リトライ不可能なエラー
abstract class NonRetryableError extends AppError {
  const NonRetryableError({
    required super.userMessage,
    super.originalError,
    super.stackTrace,
    super.errorCode,
  });
}
