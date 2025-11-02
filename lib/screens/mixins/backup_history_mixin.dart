// lib/screens/mixins/backup_history_mixin.dart
// バックアップ履歴表示機能を分離

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/backup_history_service.dart';
import 'backup_core_mixin.dart';

/// バックアップ履歴表示機能のMixin
/// このmixinを使用するクラスは、BackupCoreMixinを実装する必要があります
mixin BackupHistoryMixin<T extends StatefulWidget> on State<T>, BackupCoreMixin<T> {
  @override
  Future<void> showBackupHistory() async {
    if (!mounted) return;
    
    final history = await BackupHistoryService.getBackupHistory();
    
    // 自動バックアップも含めて全てのバックアップを取得
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
    
    if (allBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('バックアップがありません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isAuto ? Icons.schedule : Icons.backup,
                    color: isAuto ? Colors.green : Colors.orange,
                  ),
                  title: Text(backup['name'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('yyyy-MM-dd HH:mm').format(createdAt)),
                      Text(
                        '${backup['source']}バックアップ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAuto ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'restore':
                          await restoreBackup(backup['key'] as String);
                          break;
                        case 'delete':
                          if (!isAuto) {
                            await deleteBackup(backup['key'] as String, index);
                          }
                          break;
                        case 'preview':
                          await previewBackup(backup['key'] as String);
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
                      if (!isAuto) const PopupMenuItem(
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
      ),
    );
  }

  @override
  Future<void> previewBackup(String backupKey) async {
    try {
      final backupData = await loadBackupDataAsync(backupKey);
      
      if (backupData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('バックアップデータが見つかりません'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('バックアッププレビュー'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('名前: ${backupData['name'] as String}'),
                  Text('作成日時: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(backupData['createdAt']))}'),
                  const SizedBox(height: 8),
                  const Text('📊 バックアップ内容:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('・服用メモ数: ${(backupData['medicationMemos'] as List).length}件'),
                  Text('・追加薬品数: ${(backupData['addedMedications'] as List).length}件'),
                  Text('・薬品データ数: ${(backupData['medicines'] as List).length}件'),
                  Text('・アラーム数: ${(backupData['alarmList'] as List).length}件'),
                  Text('・カレンダー色設定: ${(backupData['dayColors'] as Map).length}日分'),
                  Text('・チェック状態: ${(backupData['weekdayMedicationStatus'] as Map).length}日分'),
                  Text('・服用率データ: ${(backupData['adherenceRates'] as Map).length}件'),
                  const SizedBox(height: 16),
                  const Text('このバックアップを復元しますか？'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  restoreBackup(backupKey);
                },
                child: const Text('復元する'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プレビューエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

