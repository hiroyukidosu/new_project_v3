// lib/screens/home/widgets/dialogs/backup_history_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/backup_history_service.dart';

/// バックアップ履歴ダイアログ
class BackupHistoryDialog extends StatelessWidget {
  final Function(String) onRestore;
  final Function(String, int) onDelete;
  final Function(String) onPreview;

  const BackupHistoryDialog({
    super.key,
    required this.onRestore,
    required this.onDelete,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadAllBackups(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AlertDialog(
            title: Text('バックアップ一覧'),
            content: Center(child: CircularProgressIndicator()),
          );
        }

        final allBackups = snapshot.data!;

        if (allBackups.isEmpty) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 8),
                Text('バックアップ一覧'),
              ],
            ),
            content: const Text('バックアップがありません'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.history, color: Colors.blue),
              SizedBox(width: 8),
              Text('バックアップ一覧'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: ListView.builder(
              itemCount: allBackups.length,
              itemBuilder: (context, index) {
                final backup = allBackups[allBackups.length - 1 - index]; // 新しい順に表示
                final createdAt = DateTime.parse(backup['createdAt'] as String);
                final isAuto = backup['type'] == 'auto';

                // 各項目に異なる色を設定
                final cardColor = isAuto 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1);
                final borderColor = isAuto 
                    ? Colors.green
                    : Colors.orange;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: borderColor, width: 1),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isAuto ? Icons.schedule : Icons.backup,
                      color: isAuto ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      backup['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAuto ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('yyyy-MM-dd HH:mm').format(createdAt)),
                        Text(
                          '${backup['source']}バックアップ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAuto ? Colors.green.shade600 : Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'restore':
                            await onRestore(backup['key'] as String);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            break;
                          case 'delete':
                            if (!isAuto) {
                              await onDelete(backup['key'] as String, index);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                            break;
                          case 'preview':
                            await onPreview(backup['key'] as String);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(Icons.restore, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('復元'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, color: Colors.green),
                              SizedBox(width: 8),
                              Text('プレビュー'),
                            ],
                          ),
                        ),
                        if (!isAuto)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('削除'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadAllBackups() async {
    final history = await BackupHistoryService.getBackupHistory();
    final allBackups = <Map<String, dynamic>>[];

    // 手動バックアップ履歴を追加
    for (final backup in history) {
      allBackups.add({
        ...backup,
        'type': 'manual',
        'source': '履歴',
      });
    }

    // 自動バックアップを追加
    final autoBackupKey = await BackupHistoryService.getLastAutoBackupKey();
    if (autoBackupKey != null) {
      allBackups.add({
        'name': '自動バックアップ（最新）',
        'key': autoBackupKey,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'auto',
        'source': '自動',
      });
    }

    return allBackups;
  }
}

