// lib/screens/home/widgets/dialogs/backup_dialog.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// バックアップメインダイアログ
class BackupDialog extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onShowHistory;

  const BackupDialog({
    super.key,
    required this.onCreate,
    required this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.backup, color: Colors.orange),
          SizedBox(width: 8),
          Text('バックアップ'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '手動保存 - 任意タイミングで保存',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop('create');
                onCreate();
              },
              icon: const Icon(Icons.save),
              label: const Text('手動バックアップを作成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop('history');
                onShowHistory();
              },
              icon: const Icon(Icons.history),
              label: const Text('保存履歴を見る'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

