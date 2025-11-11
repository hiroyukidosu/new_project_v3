import '../../core/result.dart';
import '../../repositories/backup_repository.dart';
import '../../repositories/medication_repository.dart';
import '../../repositories/calendar_repository.dart';
import '../../repositories/alarm_repository.dart';
import '../../models/medication_memo.dart';
import '../../services/daily_memo_service.dart';
import '../../screens/home/persistence/medication_data_persistence.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// バックアップ復元のUseCase
class RestoreBackupUseCase {
  final BackupRepository _backupRepo;
  final MedicationRepository _medicationRepo;
  final CalendarRepository _calendarRepo;
  final AlarmRepository _alarmRepo;
  
  RestoreBackupUseCase(
    this._backupRepo,
    this._medicationRepo,
    this._calendarRepo,
    this._alarmRepo,
  );
  
  /// バックアップを復元
  Future<Result<void>> execute(String backupKey) async {
    try {
      // バックアップデータを読み込み
      final backupData = await _backupRepo.loadBackup(backupKey);
      if (backupData == null) {
        return const Error('バックアップが見つかりません');
      }
      
      // メディケーションデータの復元（全削除→全保存で確実に復元）
      if (backupData.containsKey('medicationMemos')) {
        final memosList = backupData['medicationMemos'] as List<dynamic>;
        
        // 既存のメモを全て削除（変更・削除を反映するため）
        // 重要: MedicationDataPersistenceを使って削除IDリストに記録
        try {
          final existingMemos = await _medicationRepo.getMemos(forceRefresh: true);
          
          // 削除IDリストを取得
          final prefs = await SharedPreferences.getInstance();
          final deletedIdsKey = 'deleted_medication_memo_ids';
          final deletedIds = prefs.getStringList(deletedIdsKey) ?? <String>[];
          
          // バックアップに含まれていない既存メモを削除IDリストに追加
          final backupMemoIds = memosList
              .map((json) => (json as Map<String, dynamic>)['id'] as String)
              .toSet();
          
          for (final existingMemo in existingMemos) {
            // バックアップに含まれていないメモは削除されたとみなす
            if (!backupMemoIds.contains(existingMemo.id)) {
              if (!deletedIds.contains(existingMemo.id)) {
                deletedIds.add(existingMemo.id);
              }
              // Hiveからも削除
              await _medicationRepo.deleteMemo(existingMemo.id);
            }
          }
          
          // 削除IDリストを保存
          await prefs.setStringList(deletedIdsKey, deletedIds);
          
          // バックアップに含まれているメモは削除IDリストから削除（復元されるため）
          for (final memoId in backupMemoIds) {
            deletedIds.remove(memoId);
          }
          await prefs.setStringList(deletedIdsKey, deletedIds);
          
        } catch (e) {
          // 削除エラーは無視して続行
          print('⚠️ 既存メモ削除エラー: $e');
        }
        
        // バックアップからメモを復元（作成・変更を反映）
        for (final memoJson in memosList) {
          try {
            final memo = MedicationMemo.fromJson(memoJson as Map<String, dynamic>);
            await _medicationRepo.saveMemo(memo);
          } catch (e) {
            // 個別のメモの復元エラーは無視して続行
            print('⚠️ メモ復元エラー: $e');
            continue;
          }
        }
        
        // バックアップを更新（削除IDリストを反映）
        // MedicationDataPersistenceのバックアップ更新を呼ぶ
        try {
          final medicationDataPersistence = MedicationDataPersistence();
          await medicationDataPersistence.saveMedicationMemos(
            memosList.map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>)).toList()
          );
        } catch (e) {
          print('⚠️ バックアップ更新エラー: $e');
        }
        
        // キャッシュをクリアして再読み込みを強制
        _medicationRepo.clearCache();
        print('✅ 服用メモ復元完了: ${memosList.length}件（既存メモを削除してから復元、削除IDリストを更新）');
      }
      
      // メモステータスの復元
      if (backupData.containsKey('medicationMemoStatus')) {
        final status = backupData['medicationMemoStatus'] as Map<String, dynamic>;
        await _medicationRepo.saveMemoStatus(
          status.map((key, value) => MapEntry(key, value as bool)),
        );
      }
      
      // 曜日メディケーションステータスの復元
      if (backupData.containsKey('weekdayMedicationStatus')) {
        final status = backupData['weekdayMedicationStatus'] as Map<String, dynamic>;
        await _medicationRepo.saveWeekdayMedicationStatus(
          status.map((key, value) => MapEntry(key, value as bool)),
        );
      }
      
      // 追加メディケーションの復元
      if (backupData.containsKey('addedMedications')) {
        final medications = backupData['addedMedications'] as List<dynamic>;
        await _medicationRepo.saveAddedMedications(
          medications.cast<Map<String, dynamic>>(),
        );
      }
      
      // カレンダーデータの復元
      if (backupData.containsKey('dayColors')) {
        final colorsMap = backupData['dayColors'] as Map<String, dynamic>;
        final colors = colorsMap.map((key, value) {
          final colorValue = value is int ? value : int.parse(value.toString());
          return MapEntry(key, Color(colorValue));
        });
        await _calendarRepo.saveDayColors(colors);
      }
      
      if (backupData.containsKey('selectedDates')) {
        final datesList = backupData['selectedDates'] as List<dynamic>;
        final dates = datesList.map((dateStr) => DateTime.parse(dateStr as String)).toSet();
        await _calendarRepo.saveSelectedDates(dates);
      }
      
      if (backupData.containsKey('calendarMarks')) {
        final marks = backupData['calendarMarks'] as Map<String, dynamic>;
        await _calendarRepo.saveCalendarMarks(marks);
      }
      
      // DailyMemoServiceのメモを復元
      if (backupData.containsKey('dailyMemos')) {
        try {
          final dailyMemos = backupData['dailyMemos'] as Map<String, dynamic>;
          await DailyMemoService.initialize();
          for (final entry in dailyMemos.entries) {
            final dateStr = entry.key;
            final memo = entry.value as String;
            if (memo.isNotEmpty) {
              await DailyMemoService.setMemo(dateStr, memo);
            }
          }
        } catch (e) {
          // DailyMemoServiceの復元エラーは無視（後で再試行可能）
          print('⚠️ DailyMemoService復元エラー: $e');
        }
      }
      
      // アラームデータの復元
      if (backupData.containsKey('alarmList')) {
        final alarmList = backupData['alarmList'] as List<dynamic>;
        await _alarmRepo.saveAlarmList(alarmList.cast<Map<String, dynamic>>());
      }
      
      if (backupData.containsKey('alarmSettings')) {
        final settings = backupData['alarmSettings'] as Map<String, dynamic>;
        await _alarmRepo.saveAlarmSettings(settings);
      }
      
      return const Success(null);
    } catch (e) {
      return Error('バックアップの復元に失敗しました', e);
    }
  }
}

