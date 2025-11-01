// lib/screens/home/widgets/dialogs/warning_dialog.dart

import 'package:flutter/material.dart';

/// 警告ダイアログ
class WarningDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const WarningDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Flexible(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: const Text('キャンセル'),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText ?? '了解'),
        ),
      ],
    );
  }

  /// 制限ダイアログを表示
  static void showLimitDialog(BuildContext context, String type, int maxCount) {
    showDialog(
      context: context,
      builder: (context) => WarningDialog(
        title: '${type}上限',
        message: '$typeは最大$maxCount件まで設定できます。\n不要な$typeを削除してください。',
      ),
    );
  }

  /// 一般的な警告ダイアログを表示
  static void show(BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) => WarningDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }
}

