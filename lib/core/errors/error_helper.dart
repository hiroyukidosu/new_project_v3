// lib/core/errors/error_helper.dart
// エラーハンドリングのヘルパークラス

import 'package:flutter/material.dart';
import 'app_error.dart';
import 'error_handler.dart';
import '../widgets/error_dialog.dart';
import '../widgets/error_snackbar.dart';

/// エラーハンドリングのヘルパークラス
class ErrorHelper {
  /// エラーをユーザーに表示（ダイアログ）
  static Future<void> showErrorDialog({
    required BuildContext context,
    required AppError error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    if (!context.mounted) return;
    await ErrorDialog.show(
      context: context,
      error: error,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  /// エラーをユーザーに表示（スナックバー）
  static void showErrorSnackBar({
    required BuildContext context,
    required AppError error,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    ErrorSnackBar.show(
      context: context,
      error: error,
      onRetry: onRetry,
      duration: duration,
    );
  }

  /// エラー結果を処理してユーザーに表示
  static Future<void> handleErrorResult<T>({
    required BuildContext? context,
    required ErrorResult<T> result,
    VoidCallback? onRetry,
    bool showDialog = false,
  }) async {
    switch (result) {
      case Success():
        // 成功時は何もしない
        break;
      case Failure(:final error):
        await ErrorHandler.logError(error);
        
        if (context == null || !context.mounted) return;
        
        if (showDialog) {
          await showErrorDialog(
            context: context,
            error: error,
            onRetry: onRetry,
          );
        } else {
          showErrorSnackBar(
            context: context,
            error: error,
            onRetry: onRetry,
          );
        }
    }
  }

  /// エラーを処理して結果を返す（リトライ付き）
  static Future<ErrorResult<T>> executeWithRetry<T>({
    required Future<T> Function() action,
    int maxRetries = 2,
    Duration? retryDelay,
    AppError Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    return await ErrorHandler.handle(
      action: action,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      onError: onError,
    );
  }
}

