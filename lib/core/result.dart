/// 結果型（Result型）
/// エラーハンドリングと成功/失敗の状態を表現します
sealed class Result<T> {
  const Result();
}

/// 成功結果
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// エラー結果
final class Error<T> extends Result<T> {
  final String message;
  final Object? error;
  const Error(this.message, [this.error]);
}

/// Result型の拡張メソッド
extension ResultExtension<T> on Result<T> {
  /// 成功したかどうか
  bool get isSuccess => this is Success<T>;
  
  /// エラーかどうか
  bool get isError => this is Error<T>;
  
  /// データを取得（成功時）
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  
  /// エラーメッセージを取得（エラー時）
  String? get errorMessageOrNull => this is Error<T> ? (this as Error<T>).message : null;
  
  /// 成功時のコールバック
  Result<T> onSuccess(void Function(T data) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).data);
    }
    return this;
  }
  
  /// エラー時のコールバック
  Result<T> onError(void Function(String message, Object? error) callback) {
    if (this is Error<T>) {
      final error = this as Error<T>;
      callback(error.message, error.error);
    }
    return this;
  }
}

