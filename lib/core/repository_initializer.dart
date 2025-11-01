import '../repositories/medication_repository.dart';
import '../repositories/calendar_repository.dart';
import '../repositories/backup_repository.dart';
import '../repositories/alarm_repository.dart';
import '../utils/logger.dart';

/// リポジトリ初期化ヘルパー
/// アプリ起動時にすべてのリポジトリを初期化します
class RepositoryInitializer {
  static MedicationRepository? _medicationRepo;
  static CalendarRepository? _calendarRepo;
  static BackupRepository? _backupRepo;
  static AlarmRepository? _alarmRepo;
  
  /// 全リポジトリを初期化
  static Future<void> initializeAll() async {
    try {
      Logger.info('リポジトリ初期化開始...');
      
      // メディケーションリポジトリ
      _medicationRepo = MedicationRepository();
      await _medicationRepo!.initialize();
      
      // カレンダーリポジトリ
      _calendarRepo = CalendarRepository();
      await _calendarRepo!.initialize();
      
      // バックアップリポジトリ
      _backupRepo = BackupRepository();
      await _backupRepo!.initialize();
      
      // アラームリポジトリ
      _alarmRepo = AlarmRepository();
      await _alarmRepo!.initialize();
      
      Logger.info('全リポジトリ初期化完了');
    } catch (e) {
      Logger.error('リポジトリ初期化エラー', e);
      rethrow;
    }
  }
  
  /// リポジトリインスタンスを取得
  static MedicationRepository get medicationRepository {
    if (_medicationRepo == null) {
      throw StateError('MedicationRepository is not initialized');
    }
    return _medicationRepo!;
  }
  
  static CalendarRepository get calendarRepository {
    if (_calendarRepo == null) {
      throw StateError('CalendarRepository is not initialized');
    }
    return _calendarRepo!;
  }
  
  static BackupRepository get backupRepository {
    if (_backupRepo == null) {
      throw StateError('BackupRepository is not initialized');
    }
    return _backupRepo!;
  }
  
  static AlarmRepository get alarmRepository {
    if (_alarmRepo == null) {
      throw StateError('AlarmRepository is not initialized');
    }
    return _alarmRepo!;
  }
  
  /// 全リポジトリをクリーンアップ
  static Future<void> disposeAll() async {
    try {
      await _medicationRepo?.dispose();
      await _calendarRepo?.dispose();
      await _backupRepo?.dispose();
      await _alarmRepo?.dispose();
      
      _medicationRepo = null;
      _calendarRepo = null;
      _backupRepo = null;
      _alarmRepo = null;
      
      Logger.info('全リポジトリクリーンアップ完了');
    } catch (e) {
      Logger.error('リポジトリクリーンアップエラー', e);
    }
  }
}

