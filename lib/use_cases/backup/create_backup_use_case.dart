import '../../core/result.dart';
import '../../repositories/backup_repository.dart';
import '../../repositories/medication_repository.dart';
import '../../repositories/calendar_repository.dart';
import '../../repositories/alarm_repository.dart';

/// バックアップ作成のUseCase
class CreateBackupUseCase {
  final BackupRepository _backupRepo;
  final MedicationRepository _medicationRepo;
  final CalendarRepository _calendarRepo;
  final AlarmRepository _alarmRepo;
  
  CreateBackupUseCase(
    this._backupRepo,
    this._medicationRepo,
    this._calendarRepo,
    this._alarmRepo,
  );
  
  /// バックアップを作成
  Future<Result<String>> execute(String name) async {
    try {
      // バリデーション
      if (name.trim().isEmpty) {
        return const Error('バックアップ名を入力してください');
      }
      
      // 全データを収集
      final backupData = {
        'medicationMemos': (await _medicationRepo.getMemos())
            .map((memo) => memo.toJson())
            .toList(),
        'medicationMemoStatus': await _medicationRepo.getMemoStatus(),
        'weekdayMedicationStatus': await _medicationRepo.getWeekdayMedicationStatus(),
        'addedMedications': await _medicationRepo.getAddedMedications(),
        'dayColors': (await _calendarRepo.loadDayColors())
            .map((key, value) => MapEntry(key, value.value)),
        'selectedDates': (await _calendarRepo.loadSelectedDates())
            .map((date) => date.toIso8601String())
            .toList(),
        'calendarMarks': await _calendarRepo.loadCalendarMarks(),
        'alarmList': await _alarmRepo.loadAlarmList(),
        'alarmSettings': await _alarmRepo.loadAlarmSettings(),
      };
      
      // バックアップを作成
      final backupKey = await _backupRepo.createBackup(name, backupData);
      return Success(backupKey);
    } catch (e) {
      return Error('バックアップの作成に失敗しました', e);
    }
  }
}

