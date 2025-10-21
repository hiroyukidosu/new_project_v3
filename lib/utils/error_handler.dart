import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// エラーハンドリングユーティリティ
/// 
/// 既存のエラーハンドリングを改善し、ユーザーフレンドリーなエラー表示を提供
class ErrorHandler {
  /// エラーメッセージをユーザーフレンドリーに変換
  static String getUserFriendlyMessage(dynamic error) {
    if (error is String) {
      return error;
    }

    // 一般的なエラーパターンをチェック
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'ネットワーク接続を確認してください';
    }
    
    if (errorString.contains('permission') || errorString.contains('権限')) {
      return '必要な権限が許可されていません';
    }
    
    if (errorString.contains('storage') || errorString.contains('保存')) {
      return 'データの保存に失敗しました';
    }
    
    if (errorString.contains('load') || errorString.contains('読み込み')) {
      return 'データの読み込みに失敗しました';
    }
    
    if (errorString.contains('timeout')) {
      return '処理がタイムアウトしました。もう一度お試しください';
    }
    
    // デフォルトメッセージ
    return '予期しないエラーが発生しました。アプリを再起動してください';
  }

  /// エラーダイアログを表示
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('再試行'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// エラースナックバーを表示
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: onRetry != null
            ? SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// 成功メッセージを表示
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 警告メッセージを表示
  static void showWarningSnackBar(
    BuildContext context, {
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// 安全な非同期処理
/// 
/// エラーを適切にハンドリングしながら非同期処理を実行
class SafeAsync {
  /// 安全な非同期処理を実行
  static Future<T?> execute<T>(
    Future<T> Function() computation, {
    String? operationName,
    bool showError = true,
    BuildContext? context,
  }) async {
    try {
      if (operationName != null && kDebugMode) {
        debugPrint('[$operationName] 開始');
      }
      
      final result = await computation();
      
      if (operationName != null && kDebugMode) {
        debugPrint('[$operationName] 完了');
      }
      
      return result;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[$operationName] エラー: $error');
      }
      
      if (showError && context != null) {
        ErrorHandler.showErrorSnackBar(
          context,
          message: ErrorHandler.getUserFriendlyMessage(error),
        );
      }
      
      return null;
    }
  }

  /// 安全な同期処理を実行
  static T? executeSync<T>(
    T Function() computation, {
    String? operationName,
    bool showError = true,
    BuildContext? context,
  }) {
    try {
      if (operationName != null && kDebugMode) {
        debugPrint('[$operationName] 開始');
      }
      
      final result = computation();
      
      if (operationName != null && kDebugMode) {
        debugPrint('[$operationName] 完了');
      }
      
      return result;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[$operationName] エラー: $error');
      }
      
      if (showError && context != null) {
        ErrorHandler.showErrorSnackBar(
          context,
          message: ErrorHandler.getUserFriendlyMessage(error),
        );
      }
      
      return null;
    }
  }
}

/// リトライ機能付きの非同期処理
class RetryableAsync {
  /// リトライ機能付きで非同期処理を実行
  static Future<T?> executeWithRetry<T>(
    Future<T> Function() computation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? operationName,
    BuildContext? context,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        if (operationName != null && kDebugMode) {
          debugPrint('[$operationName] 試行 ${attempts + 1}/$maxRetries');
        }
        
        final result = await computation();
        
        if (operationName != null && kDebugMode) {
          debugPrint('[$operationName] 成功');
        }
        
        return result;
      } catch (error) {
        attempts++;
        
        if (kDebugMode) {
          debugPrint('[$operationName] 試行 $attempts 失敗: $error');
        }
        
        if (attempts >= maxRetries) {
          if (context != null) {
            ErrorHandler.showErrorSnackBar(
              context,
              message: '${ErrorHandler.getUserFriendlyMessage(error)}\n（${maxRetries}回試行しました）',
            );
          }
          return null;
        }
        
        // リトライ前に待機
        await Future.delayed(delay);
      }
    }
    
    return null;
  }
}
