// lib/core/widgets/error_dialog.dart
// エラー表示用のダイアログウィジェット

import 'package:flutter/material.dart';
import '../errors/app_error.dart';

/// エラーダイアログを表示
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  /// エラーダイアログを表示するヘルパーメソッド
  static Future<void> show({
    required BuildContext context,
    required AppError error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            _getErrorIcon(),
            color: _getErrorColor(),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getErrorTitle(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error.userMessage,
            style: const TextStyle(fontSize: 16),
          ),
          if (error is RetryableError && onRetry != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'このエラーは再試行できます',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('閉じる'),
          ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getErrorColor(),
              foregroundColor: Colors.white,
            ),
            child: const Text('再試行'),
          ),
      ],
    );
  }

  IconData _getErrorIcon() {
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

  Color _getErrorColor() {
    if (error is NetworkError) {
      return Colors.orange;
    } else if (error is StorageError) {
      return Colors.red;
    } else if (error is ValidationError) {
      return Colors.amber;
    } else if (error is PermissionError) {
      return Colors.purple;
    } else if (error is TimeoutError) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  String _getErrorTitle() {
    if (error is NetworkError) {
      return 'ネットワークエラー';
    } else if (error is StorageError) {
      return 'データエラー';
    } else if (error is ValidationError) {
      return '入力エラー';
    } else if (error is PermissionError) {
      return '権限エラー';
    } else if (error is TimeoutError) {
      return 'タイムアウト';
    } else {
      return 'エラー';
    }
  }
}

