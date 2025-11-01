import '../../core/result.dart';
import '../../repositories/backup_repository.dart';
import '../../repositories/medication_repository.dart';
import '../../repositories/calendar_repository.dart';
import '../../repositories/alarm_repository.dart';
import '../../models/medication_memo.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

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
      
      // メディケーションデータの復元
      if (backupData.containsKey('medicationMemos')) {
        final memosList = backupData['medicationMemos'] as List<dynamic>;
        for (final memoJson in memosList) {
          try {
            final memo = MedicationMemo.fromJson(memoJson as Map<String, dynamic>);
            await _medicationRepo.saveMemo(memo);
          } catch (e) {
            // 個別のメモの復元エラーは無視して続行
            continue;
          }
        }
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

