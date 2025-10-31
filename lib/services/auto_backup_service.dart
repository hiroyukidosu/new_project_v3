// 自動バックアップサービス
// 自動バックアップのスケジュールと実行を担当

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_utils.dart';
import 'backup_history_service.dart';

/// 自動バックアップサービスのコールバック型定義
typedef BackupDataCreator = Future<Map<String, dynamic>> Function(String backupName);
typedef BackupCompleteCallback = Future<void> Function(String backupKey);

/// 自動バックアップサービス
class AutoBackupService {
  static Timer? _timer;
  static bool _enabled = true;

  /// 自動バックアップ機能を初期化
  static void initialize(BackupDataCreator createBackupData, BackupCompleteCallback onComplete) {
    _scheduleAutoBackup(createBackupData, onComplete);
    debugPrint('🔄 自動バックアップ機能を初期化しました');
  }

  /// 深夜2:00の自動バックアップをスケジュール
  static void _scheduleAutoBackup(
    BackupDataCreator createBackupData,
    BackupCompleteCallback onComplete,
  ) {
    _timer?.cancel();
    
    final now = DateTime.now();
    // 次の実行時刻を当日20:12（過ぎていれば翌日20:12）に設定
    final todayTarget = DateTime(now.year, now.month, now.day, 20, 12);
    final nextRun = now.isBefore(todayTarget)
        ? todayTarget
        : DateTime(now.year, now.month, now.day + 1, 20, 12);
    final duration = nextRun.difference(now);
    
    _timer = Timer(duration, () async {
      if (_enabled) {
        await _performAutoBackup(createBackupData, onComplete);
        // 次の日の深夜2:00をスケジュール
        _scheduleAutoBackup(createBackupData, onComplete);
      }
    });
    
    debugPrint('🔄 自動バックアップをスケジュールしました: ${nextRun.toString()}');
  }

  /// 自動バックアップを実行
  static Future<void> _performAutoBackup(
    BackupDataCreator createBackupData,
    BackupCompleteCallback onComplete,
  ) async {
    try {
      final backupName = '自動バックアップ_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
      debugPrint('🔄 自動バックアップを実行: $backupName');
      
      // バックアップデータを作成
      final backupData = await createBackupData(backupName);
      final jsonString = await BackupUtils.safeJsonEncode(backupData);
      final encryptedData = await BackupUtils.encryptData(jsonString);
      
      // バックアップを保存
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'auto_backup_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(backupKey, encryptedData);
      
      // 履歴を更新（フルとして扱う）
      await BackupHistoryService.updateBackupHistory(backupName, backupKey, type: 'full');
      
      // 最新バックアップ参照キーを保存
      await BackupHistoryService.setLastAutoBackupKey(backupKey);
      await prefs.setString('last_full_backup_key', backupKey);
      
      debugPrint('✅ 自動バックアップ完了: $backupName');
      
      // コールバック実行
      await onComplete(backupKey);
    } catch (e) {
      debugPrint('❌ 自動バックアップエラー: $e');
    }
  }

  /// 自動バックアップを停止
  static void stop() {
    _timer?.cancel();
    _timer = null;
    _enabled = false;
  }

  /// 自動バックアップを再開
  static void resume(BackupDataCreator createBackupData, BackupCompleteCallback onComplete) {
    _enabled = true;
    initialize(createBackupData, onComplete);
  }
}

