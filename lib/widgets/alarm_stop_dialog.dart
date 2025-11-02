// lib/widgets/alarm_stop_dialog.dart
// アラーム停止ダイアログ

import 'package:flutter/material.dart';

/// アラーム停止ダイアログ
class AlarmStopDialog extends StatefulWidget {
  final VoidCallback onStop;

  const AlarmStopDialog({
    super.key,
    required this.onStop,
  });

  @override
  State<AlarmStopDialog> createState() => _AlarmStopDialogState();
}

class _AlarmStopDialogState extends State<AlarmStopDialog> {
  @override
  void initState() {
    super.initState();
    // 5秒後に自動的にダイアログを閉じる
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.alarm,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'お薬を飲む時間になりました',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'この通知は5秒後に自動的に消えます',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

