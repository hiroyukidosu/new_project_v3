// Hive完全移行サービス
// 歴史データを含む全てのSharedPreferencesデータをHiveに移行します

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_memo.dart';
import '../config/storage_keys.dart';
import '../utils/logger.dart';

/// Hive移行サービス
/// SharedPreferencesからHiveへの完全移行を管理します
class HiveMigrationService {
  static const String _migrationVersionKey = 'hive_migration_version';
  static const int _currentMigrationVersion = 2; // 完全移行版
  
  /// 移行が必要かどうかを確認
  static Future<bool> needsMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationVersion = prefs.getInt(_migrationVersionKey) ?? 0;
      return migrationVersion < _currentMigrationVersion;
    } catch (e) {
      Logger.error('移行確認エラー', e);
      return true; // エラー時は安全のため移行を実行
    }
  }
  
  /// 完全移行を実行（歴史データを含む）
  static Future<void> performFullMigration() async {
    try {
      Logger.info('🔄 Hive完全移行開始...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // 1. メディケーションメモの移行
      await _migrateMedicationMemos(prefs);
      
      // 2. メディケーションステータスの移行
      await _migrateMedicationStatus(prefs);
      
      // 3. アラームデータの移行
      await _migrateAlarmData(prefs);
      
      // 4. カレンダーデータの移行
      await _migrateCalendarData(prefs);
      
      // 5. 統計データの移行
      await _migrateStatistics(prefs);
      
      // 6. ユーザー設定の移行
      await _migrateUserPreferences(prefs);
      
      // 7. バックアップデータの移行
      await _migrateBackupData(prefs);
      
      // 8. その他のデータの移行（旧キーも含む）
      await _migrateLegacyData(prefs);
      
      // 移行完了をマーク
      await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
      
      Logger.info('✅ Hive完全移行完了');
    } catch (e, stackTrace) {
      Logger.error('Hive移行エラー', e);
      Logger.error('スタックトレース', stackTrace);
      rethrow;
    }
  }
  
  /// メディケーションメモの移行
  static Future<void> _migrateMedicationMemos(SharedPreferences prefs) async {
    try {
      // Hiveボックスを取得
      final memoBox = Hive.box<MedicationMemo>('medication_memos');
      
      // 既存のHiveデータを確認
      final existingHiveCount = memoBox.length;
      
      // SharedPreferencesから旧データを取得
      final allKeys = prefs.getKeys();
      
      // 旧キーパターンでメモを検索
      int migratedCount = 0;
      for (final key in allKeys) {
        if (key.startsWith('memo_') || key.startsWith('medication_memo_')) {
          try {
            final memoJson = prefs.getString(key);
            if (memoJson != null) {
              final memoData = jsonDecode(memoJson) as Map<String, dynamic>;
              final memo = MedicationMemo.fromJson(memoData);
              
              // Hiveに存在しない場合のみ追加
              if (!memoBox.containsKey(memo.id)) {
                await memoBox.put(memo.id, memo);
                migratedCount++;
              }
            }
          } catch (e) {
            Logger.warning('メモ移行エラー: $key - $e');
          }
        }
      }
      
      // 旧バージョンのキーからも移行
      final oldMemosKey = prefs.getString('medication_memos');
      if (oldMemosKey != null) {
        try {
          final memosList = jsonDecode(oldMemosKey) as List<dynamic>;
          for (final memoData in memosList) {
            try {
              final memo = MedicationMemo.fromJson(memoData as Map<String, dynamic>);
              if (!memoBox.containsKey(memo.id)) {
                await memoBox.put(memo.id, memo);
                migratedCount++;
              }
            } catch (e) {
              Logger.warning('メモリスト移行エラー: $e');
            }
          }
        } catch (e) {
          Logger.warning('メモリスト解析エラー: $e');
        }
      }
      
      Logger.info('メモ移行完了: 既存${existingHiveCount}件 + 新規移行${migratedCount}件');
    } catch (e) {
      Logger.error('メディケーションメモ移行エラー', e);
    }
  }
  
  /// メディケーションステータスの移行
  static Future<void> _migrateMedicationStatus(SharedPreferences prefs) async {
    try {
      final dataBox = Hive.openBox<String>('medication_data');
      
      // 各ステータスキーを移行
      final statusKeys = [
        StorageKeys.medicationMemoStatusKey,
        'medication_memo_status', // 旧キー
        StorageKeys.weekdayMedicationStatusKey,
        'weekday_medication_status', // 旧キー
        StorageKeys.medicationDoseStatusKey,
        'medication_dose_status', // 旧キー
      ];
      
      for (final key in statusKeys) {
        final statusJson = prefs.getString(key);
        if (statusJson != null) {
          final box = await dataBox;
          if (!box.containsKey(key)) {
            await box.put(key, statusJson);
          }
        }
      }
      
      Logger.info('メディケーションステータス移行完了');
    } catch (e) {
      Logger.error('メディケーションステータス移行エラー', e);
    }
  }
  
  /// アラームデータの移行
  static Future<void> _migrateAlarmData(SharedPreferences prefs) async {
    try {
      final alarmBox = Hive.openBox<String>('alarm_data');
      
      final alarmKeys = [
        StorageKeys.alarmListKey,
        'alarm_data', // 旧キー
        StorageKeys.alarmSettingsKey,
        'alarm_settings', // 旧キー
      ];
      
      for (final key in alarmKeys) {
        final alarmJson = prefs.getString(key);
        if (alarmJson != null) {
          final box = await alarmBox;
          if (!box.containsKey(key)) {
            await box.put(key, alarmJson);
          }
        }
      }
      
      Logger.info('アラームデータ移行完了');
    } catch (e) {
      Logger.error('アラームデータ移行エラー', e);
    }
  }
  
  /// カレンダーデータの移行
  static Future<void> _migrateCalendarData(SharedPreferences prefs) async {
    try {
      final calendarBox = Hive.openBox<String>('calendar_data');
      
      final calendarKeys = [
        StorageKeys.calendarMarksKey,
        'calendar_marks', // 旧キー
        StorageKeys.dayColorsKey,
        'day_colors', // 旧キー
        StorageKeys.selectedDatesKey,
        'selected_dates', // 旧キー
      ];
      
      for (final key in calendarKeys) {
        final calendarJson = prefs.getString(key);
        if (calendarJson != null) {
          final box = await calendarBox;
          if (!box.containsKey(key)) {
            await box.put(key, calendarJson);
          }
        }
      }
      
      Logger.info('カレンダーデータ移行完了');
    } catch (e) {
      Logger.error('カレンダーデータ移行エラー', e);
    }
  }
  
  /// 統計データの移行
  static Future<void> _migrateStatistics(SharedPreferences prefs) async {
    try {
      final dataBox = Hive.openBox<String>('medication_data');
      
      final statsKeys = [
        StorageKeys.statisticsKey,
        'statistics', // 旧キー
        StorageKeys.adherenceRatesKey,
        'adherence_rates', // 旧キー
      ];
      
      for (final key in statsKeys) {
        final statsJson = prefs.getString(key);
        if (statsJson != null) {
          final box = await dataBox;
          if (!box.containsKey(key)) {
            await box.put(key, statsJson);
          }
        }
      }
      
      Logger.info('統計データ移行完了');
    } catch (e) {
      Logger.error('統計データ移行エラー', e);
    }
  }
  
  /// ユーザー設定の移行
  static Future<void> _migrateUserPreferences(SharedPreferences prefs) async {
    try {
      final dataBox = Hive.openBox<String>('medication_data');
      
      final prefKeys = [
        StorageKeys.userPreferencesKey,
        'user_preferences', // 旧キー
        StorageKeys.appSettingsKey,
        'app_settings', // 旧キー
      ];
      
      for (final key in prefKeys) {
        final prefJson = prefs.getString(key);
        if (prefJson != null) {
          final box = await dataBox;
          if (!box.containsKey(key)) {
            await box.put(key, prefJson);
          }
        }
      }
      
      Logger.info('ユーザー設定移行完了');
    } catch (e) {
      Logger.error('ユーザー設定移行エラー', e);
    }
  }
  
  /// バックアップデータの移行
  static Future<void> _migrateBackupData(SharedPreferences prefs) async {
    try {
      final backupBox = Hive.openBox<String>('backup_data');
      
      // バックアップ履歴を移行
      final backupHistoryJson = prefs.getString(StorageKeys.backupHistoryKey);
      if (backupHistoryJson != null) {
        final box = await backupBox;
        if (!box.containsKey(StorageKeys.backupHistoryKey)) {
          await box.put(StorageKeys.backupHistoryKey, backupHistoryJson);
        }
      }
      
      // 個別のバックアップデータも移行
      final allKeys = prefs.getKeys();
      int migratedBackups = 0;
      for (final key in allKeys) {
        if (key.contains('_backup') || key.startsWith('backup_')) {
          try {
            final backupJson = prefs.getString(key);
            if (backupJson != null) {
              final box = await backupBox;
              if (!box.containsKey(key)) {
                await box.put(key, backupJson);
                migratedBackups++;
              }
            }
          } catch (e) {
            Logger.warning('バックアップ移行エラー: $key - $e');
          }
        }
      }
      
      Logger.info('バックアップデータ移行完了: ${migratedBackups}件');
    } catch (e) {
      Logger.error('バックアップデータ移行エラー', e);
    }
  }
  
  /// その他のレガシーデータの移行
  static Future<void> _migrateLegacyData(SharedPreferences prefs) async {
    try {
      final dataBox = Hive.openBox<String>('medication_data');
      final box = await dataBox;
      
      // 追加メディケーション
      final addedMedicationsKeys = [
        StorageKeys.addedMedicationsKey,
        'added_medications', // 旧キー
      ];
      
      for (final key in addedMedicationsKeys) {
        final addedJson = prefs.getString(key);
        if (addedJson != null && !box.containsKey(key)) {
          await box.put(key, addedJson);
        }
      }
      
      // メディケーションデータ
      final medicationDataKeys = [
        StorageKeys.medicationDataKey,
        'medication_data', // 旧キー
      ];
      
      for (final key in medicationDataKeys) {
        final dataJson = prefs.getString(key);
        if (dataJson != null && !box.containsKey(key)) {
          await box.put(key, dataJson);
        }
      }
      
      Logger.info('レガシーデータ移行完了');
    } catch (e) {
      Logger.error('レガシーデータ移行エラー', e);
    }
  }
  
  /// 移行状態を確認
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationVersion = prefs.getInt(_migrationVersionKey) ?? 0;
      
      final memoBox = Hive.box<MedicationMemo>('medication_memos');
      final memoCount = memoBox.length;
      
      return {
        'migrationVersion': migrationVersion,
        'currentVersion': _currentMigrationVersion,
        'needsMigration': migrationVersion < _currentMigrationVersion,
        'memoCount': memoCount,
        'isMigrated': migrationVersion >= _currentMigrationVersion,
      };
    } catch (e) {
      Logger.error('移行状態確認エラー', e);
      return {
        'migrationVersion': 0,
        'currentVersion': _currentMigrationVersion,
        'needsMigration': true,
        'memoCount': 0,
        'isMigrated': false,
      };
    }
  }
}

