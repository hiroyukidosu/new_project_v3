import 'package:flutter/material.dart';

/// エラーダイアログウィジェット
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onConfirm;
  
  const ErrorDialog({
    super.key,
    this.title = 'エラー',
    required this.message,
    this.onConfirm,
  });
  
  static Future<void> show(
    BuildContext context, {
    String title = 'エラー',
    required String message,
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

