// lib/screens/home/widgets/dialogs/backup_dialog.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// バックアップメインダイアログ
class BackupDialog extends StatelessWidget {
  final Future<bool> Function() hasUndoAvailable;
  final VoidCallback onCreate;
  final VoidCallback onShowHistory;
  final VoidCallback onUndo;
  final Future<void> Function() onRestoreLatest;

  const BackupDialog({
    super.key,
    required this.hasUndoAvailable,
    required this.onCreate,
    required this.onShowHistory,
    required this.onUndo,
    required this.onRestoreLatest,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.backup, color: Colors.purple),
          SizedBox(width: 8),
          Text('バックアップ'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('・毎日深夜2:00（自動）- フルバックアップ\n・手動保存（任意）- 任意タイミングで保存'),
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
                backgroundColor: Colors.purple,
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
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 1つ前の状態に復元機能は削除されました
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final key = prefs.getString('last_full_backup_key');
                Navigator.of(context).pop(key != null ? 'restore:$key' : null);
                if (key != null) {
                  await onRestoreLatest();
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text('最新フルバックアップを復元'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
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

