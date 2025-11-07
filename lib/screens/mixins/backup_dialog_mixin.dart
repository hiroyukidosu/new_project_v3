// lib/screens/mixins/backup_dialog_mixin.dart
// バックアップ関連のダイアログ表示機能を分離

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_core_mixin.dart';

/// バックアップダイアログ表示機能のMixin
/// このmixinを使用するクラスは、BackupCoreMixinを実装する必要があります
mixin BackupDialogMixin<T extends StatefulWidget> on State<T>, BackupCoreMixin<T> {
  // 操作後5分以内の手動復元機能
  Future<void> showManualRestoreDialog() async {
    if (!mounted) return;
    
    final now = DateTime.now();
    final canRestore = lastOperationTime != null && 
        now.difference(lastOperationTime!).inMinutes <= 5;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.blue),
            SizedBox(width: 8),
            Text('手動復元'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canRestore ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  canRestore 
                    ? '✅ 操作後5分以内です\n最後の操作から${now.difference(lastOperationTime!).inMinutes}分経過'
                    : '⚠️ 操作後5分を過ぎています\n最後の操作から${lastOperationTime != null ? now.difference(lastOperationTime!).inMinutes : 0}分経過',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              if (canRestore)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await performManualRestore();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('1つ前の状態に戻す'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  // バックアップダイアログ表示
  Future<void> showBackupDialog() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.orange),
            SizedBox(width: 8),
            Text('バックアップ'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⏱ バックアップ間隔\n\n'
                  '・毎日深夜2:00（自動）- フルバックアップ\n'
                  '・手動保存（任意）- 任意タイミングで保存',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await createManualBackup();
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
                onPressed: () async {
                  Navigator.of(context).pop();
                  await showBackupHistory();
                },
                icon: const Icon(Icons.history),
                label: const Text('保存履歴を見る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<bool>(
                future: hasUndoAvailable(),
                builder: (context, snapshot) {
                  final available = snapshot.data ?? false;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: available
                          ? () async {
                              Navigator.of(context).pop();
                              await undoLastChange();
                            }
                          : null,
                      icon: const Icon(Icons.undo),
                      label: const Text('1つ前の状態に復元'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: available ? Colors.teal : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final prefs = await SharedPreferences.getInstance();
                    // 最新フルバックアップを参照
                    final key = prefs.getString('last_full_backup_key');
                    if (key != null) {
                      await restoreBackup(key);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('フルバックアップが見つかりません'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.restore_page),
                  label: const Text('フルバックアップを復元'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

