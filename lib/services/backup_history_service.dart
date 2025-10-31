// バックアップ履歴管理サービス
// バックアップ履歴の保存・取得・更新を担当

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// バックアップ履歴管理サービス
class BackupHistoryService {
  static const String _historyKey = 'backup_history';
  static const int _maxHistoryCount = 5;

  /// バックアップ履歴を更新（最大5件まで保持）
  static Future<void> updateBackupHistory(
    String backupName,
    String backupKey, {
    String type = 'manual',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson) as List);
    
    history.add({
      'name': backupName,
      'key': backupKey,
      'createdAt': DateTime.now().toIso8601String(),
      'type': type,
    });
    
    // 古い順に自動削除（最大5件まで保持）
    if (history.length > _maxHistoryCount) {
      // 古いバックアップデータを削除
      final oldBackup = history.removeAt(0);
      await prefs.remove(oldBackup['key'] as String);
    }
    
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  /// バックアップ履歴を取得
  static Future<List<Map<String, dynamic>>> getBackupHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(historyJson) as List);
  }

  /// バックアップ履歴から削除
  static Future<void> removeFromHistory(String backupKey) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson) as List);
    
    history.removeWhere((item) => item['key'] == backupKey);
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  /// 最新の自動バックアップキーを取得
  static Future<String?> getLastAutoBackupKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_auto_backup_key');
  }

  /// 最新の自動バックアップキーを設定
  static Future<void> setLastAutoBackupKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_auto_backup_key', key);
  }
}

