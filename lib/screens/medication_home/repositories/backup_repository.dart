// lib/screens/medication_home/repositories/backup_repository.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/result.dart';
import '../../../utils/logger.dart';
import '../../../screens/helpers/home_page_backup_helper.dart';
import '../../../services/backup_history_service.dart';

/// バックアップ関連のデータアクセスを管理するRepository
class BackupRepository {
  /// バックアップデータを読み込み
  Future<Result<Map<String, dynamic>?>> loadBackupData(String backupKey) async {
    try {
      final backupData = await HomePageBackupHelper.loadBackupDataAsync(
        backupKey,
      );
      
      if (backupData == null) {
        Logger.warning('バックアップデータが見つかりません: $backupKey');
        return Error('バックアップデータが見つかりません');
      }
      
      Logger.info('バックアップデータ読み込み成功: $backupKey');
      return Success(backupData);
    } catch (e, stackTrace) {
      Logger.error('バックアップデータ読み込みエラー', e, stackTrace);
      return Error('バックアップデータの読み込みに失敗しました: $e', e);
    }
  }

  /// バックアップデータを保存
  Future<Result<String>> saveBackupData(
    Map<String, dynamic> backupData,
    String backupName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      
      final jsonString = await HomePageBackupHelper.safeJsonEncode(backupData);
      final encryptedData = await HomePageBackupHelper.encryptDataAsync(
        jsonString,
      );
      
      await prefs.setString(backupKey, encryptedData);
      await HomePageBackupHelper.updateBackupHistory(backupName, backupKey);
      
      Logger.info('バックアップデータ保存成功: $backupKey');
      return Success(backupKey);
    } catch (e, stackTrace) {
      Logger.error('バックアップデータ保存エラー', e, stackTrace);
      return Error('バックアップデータの保存に失敗しました: $e', e);
    }
  }

  /// バックアップデータを削除
  Future<Result<void>> deleteBackupData(String backupKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(backupKey);
      await BackupHistoryService.removeFromHistory(backupKey);
      
      Logger.info('バックアップデータ削除成功: $backupKey');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('バックアップデータ削除エラー', e, stackTrace);
      return Error('バックアップデータの削除に失敗しました: $e', e);
    }
  }

  /// バックアップ履歴を取得
  Future<Result<List<Map<String, dynamic>>>> getBackupHistory() async {
    try {
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
      
      Logger.info('バックアップ履歴取得成功: ${allBackups.length}件');
      return Success(allBackups);
    } catch (e, stackTrace) {
      Logger.error('バックアップ履歴取得エラー', e, stackTrace);
      return Error('バックアップ履歴の取得に失敗しました: $e', e);
    }
  }

  /// バックアップ履歴を更新
  Future<Result<void>> updateBackupHistory(
    String backupName,
    String backupKey, {
    String type = 'manual',
  }) async {
    try {
      await HomePageBackupHelper.updateBackupHistory(
        backupName,
        backupKey,
        type: type,
      );
      
      Logger.debug('バックアップ履歴更新成功: $backupName');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('バックアップ履歴更新エラー', e, stackTrace);
      return Error('バックアップ履歴の更新に失敗しました: $e', e);
    }
  }

  /// バックアップデータを復元（データ復元処理のみ）
  Future<Result<Map<String, dynamic>>> restoreBackupData(
    Map<String, dynamic> backupData,
  ) async {
    try {
      final restored = await HomePageBackupHelper.restoreDataAsync(backupData);
      
      Logger.info('バックアップデータ復元成功');
      return Success(restored);
    } catch (e, stackTrace) {
      Logger.error('バックアップデータ復元エラー', e, stackTrace);
      return Error('バックアップデータの復元に失敗しました: $e', e);
    }
  }

  /// 最後のフルバックアップキーを取得
  Future<Result<String?>> getLastFullBackupKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('last_full_backup_key');
      
      Logger.debug('最後のフルバックアップキー取得: $key');
      return Success(key);
    } catch (e, stackTrace) {
      Logger.error('最後のフルバックアップキー取得エラー', e, stackTrace);
      return Error(
        '最後のフルバックアップキーの取得に失敗しました: $e',
        e,
      );
    }
  }
}

