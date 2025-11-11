// lib/core/widgets/error_snackbar.dart
// エラー表示用のスナックバーウィジェット

import 'package:flutter/material.dart';
import '../errors/app_error.dart';

/// エラースナックバーを表示
class ErrorSnackBar {
  /// エラースナックバーを表示するヘルパーメソッド
  static void show({
    required BuildContext context,
    required AppError error,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.userMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static IconData _getErrorIcon(AppError error) {
    if (error is NetworkError) {
      return Icons.wifi_off;
    } else if (error is StorageError) {
      return Icons.storage;
    } else if (error is ValidationError) {
      return Icons.error_outline;
    } else if (error is PermissionError) {
      return Icons.lock_outline;
    } else if (error is TimeoutError) {
      return Icons.timer_off;
    } else {
      return Icons.error;
    }
  }

  static Color _getErrorColor(AppError error) {
    if (error is NetworkError) {
      return Colors.orange;
    } else if (error is StorageError) {
      return Colors.red;
    } else if (error is ValidationError) {
      return Colors.amber.shade700;
    } else if (error is PermissionError) {
      return Colors.purple;
    } else if (error is TimeoutError) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }
}

