// lib/screens/home/widgets/dialogs/backup_preview_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../helpers/home_page_backup_helper.dart';

/// バックアッププレビューダイアログ
class BackupPreviewDialog extends StatelessWidget {
  final String backupKey;
  final Function(String) onRestore;

  const BackupPreviewDialog({
    super.key,
    required this.backupKey,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: HomePageBackupHelper.loadBackupDataAsync(backupKey),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AlertDialog(
            title: Text('バックアッププレビュー'),
            content: Center(child: CircularProgressIndicator()),
          );
        }

        final backupData = snapshot.data;

        if (backupData == null) {
          return AlertDialog(
            title: const Text('バックアッププレビュー'),
            content: const Text('バックアップデータが見つかりません'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('バックアッププレビュー'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('名前: ${backupData['name']}'),
                Text(
                  '作成日時: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(backupData['createdAt']))}',
                ),
                const SizedBox(height: 8),
                const Text('📊 バックアップ内容:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('・服用メモ数: ${(backupData['medicationMemos'] as List).length}件'),
                Text('・追加薬品数: ${(backupData['addedMedications'] as List).length}件'),
                Text('・薬品データ数: ${(backupData['medicines'] as List).length}件'),
                Text('・アラーム数: ${(backupData['alarmList'] as List).length}件'),
                const SizedBox(height: 16),
                const Text('このバックアップを復元しますか？'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onRestore(backupKey);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('復元する'),
            ),
          ],
        );
      },
    );
  }
}

