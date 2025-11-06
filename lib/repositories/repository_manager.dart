// リポジトリ管理サービス
// リポジトリインスタンスのシングルトン管理と初期化を提供します

import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'medication_repository.dart';
import 'calendar_repository.dart';
import 'backup_repository.dart';
import 'alarm_repository.dart';

/// リポジトリ管理クラス
/// アプリ全体でリポジトリインスタンスを一元管理します
class RepositoryManager {
  static MedicationRepository? _medicationRepository;
  static CalendarRepository? _calendarRepository;
  static BackupRepository? _backupRepository;
  static AlarmRepository? _alarmRepository;
  
  static bool _isInitialized = false;
  
  /// 全リポジトリの初期化（並列実行で高速化）
  static Future<Map<String, bool>> initializeAll() async {
    // 初期化済みかつ全リポジトリが存在する場合のみ早期リターン
    if (_isInitialized && 
        _medicationRepository != null &&
        _calendarRepository != null &&
        _backupRepository != null &&
        _alarmRepository != null) {
      Logger.debug('リポジトリは既に初期化済みです');
      return {
        'medication': true,
        'calendar': true,
        'backup': true,
        'alarm': true,
      };
    }
    
    // 初期化が不完全な場合は再初期化を試みる
    if (!_isInitialized) {
      Logger.debug('リポジトリ初期化が不完全なため、再初期化を実行します');
    }
    
    Logger.info('🗄️ リポジトリ初期化開始（並列実行）...');
    
    final results = <String, bool>{};
    final List<String> failedRepos = [];
    
    // リポジトリインスタンスを作成（並列実行、タイムアウト付き）
    final initTasks = [
      _initializeMedicationRepository(),
      _initializeCalendarRepository(),
      _initializeBackupRepository(),
      _initializeAlarmRepository(),
    ];
    
    // タイムアウトを設定（AppConstantsから取得）
    final timeoutDuration = AppConstants.repositoryInitTimeout;
    final initResults = await Future.wait(
      initTasks.map((task) => task.timeout(
        timeoutDuration,
        onTimeout: () {
          Logger.error('リポジトリ初期化タイムアウト', '${timeoutDuration.inSeconds}秒以内に完了しませんでした');
          return false;
        },
      )),
      eagerError: false,
    );
    
    results['medication'] = initResults[0];
    results['calendar'] = initResults[1];
    results['backup'] = initResults[2];
    results['alarm'] = initResults[3];
    
    if (!results['medication']!) failedRepos.add('MedicationRepository');
    if (!results['calendar']!) failedRepos.add('CalendarRepository');
    if (!results['backup']!) failedRepos.add('BackupRepository');
    if (!results['alarm']!) failedRepos.add('AlarmRepository');
    
    // 全リポジトリが成功した場合のみ初期化済みとマーク
    if (failedRepos.isEmpty) {
      _isInitialized = true;
      Logger.info('✅ 全リポジトリ初期化完了');
    } else {
      // 一部失敗した場合は初期化済みとしない（初期化が不完全）
      _isInitialized = false;
      Logger.warning('⚠️ 一部のリポジトリ初期化に失敗: ${failedRepos.join(", ")}');
      Logger.warning('⚠️ リポジトリは初期化不完全な状態です');
    }
    
    return results;
  }
  
  /// メディケーションリポジトリの初期化
  static Future<bool> _initializeMedicationRepository() async {
    try {
      if (_medicationRepository == null) {
        _medicationRepository = MedicationRepository();
        await _medicationRepository!.initialize();
        Logger.debug('✅ MedicationRepository初期化完了');
      }
      return true;
    } catch (e) {
      Logger.error('MedicationRepository初期化エラー', e);
      return false;
    }
  }
  
  /// カレンダーリポジトリの初期化
  static Future<bool> _initializeCalendarRepository() async {
    try {
      if (_calendarRepository == null) {
        _calendarRepository = CalendarRepository();
        await _calendarRepository!.initialize();
        Logger.debug('✅ CalendarRepository初期化完了');
      }
      return true;
    } catch (e) {
      Logger.error('CalendarRepository初期化エラー', e);
      return false;
    }
  }
  
  /// バックアップリポジトリの初期化
  static Future<bool> _initializeBackupRepository() async {
    try {
      if (_backupRepository == null) {
        _backupRepository = BackupRepository();
        await _backupRepository!.initialize();
        Logger.debug('✅ BackupRepository初期化完了');
      }
      return true;
    } catch (e) {
      Logger.error('BackupRepository初期化エラー', e);
      return false;
    }
  }
  
  /// アラームリポジトリの初期化
  static Future<bool> _initializeAlarmRepository() async {
    try {
      if (_alarmRepository == null) {
        _alarmRepository = AlarmRepository();
        await _alarmRepository!.initialize();
        Logger.debug('✅ AlarmRepository初期化完了');
      }
      return true;
    } catch (e) {
      Logger.error('AlarmRepository初期化エラー', e);
      return false;
    }
  }
  
  /// メディケーションリポジトリの取得（nullチェック付き）
  static MedicationRepository? get medicationRepository {
    if (_medicationRepository == null) {
      Logger.warning('MedicationRepositoryが初期化されていません');
    }
    return _medicationRepository;
  }
  
  /// カレンダーリポジトリの取得（nullチェック付き）
  static CalendarRepository? get calendarRepository {
    if (_calendarRepository == null) {
      Logger.warning('CalendarRepositoryが初期化されていません');
    }
    return _calendarRepository;
  }
  
  /// バックアップリポジトリの取得（nullチェック付き）
  static BackupRepository? get backupRepository {
    if (_backupRepository == null) {
      Logger.warning('BackupRepositoryが初期化されていません');
    }
    return _backupRepository;
  }
  
  /// アラームリポジトリの取得（nullチェック付き）
  static AlarmRepository? get alarmRepository {
    if (_alarmRepository == null) {
      Logger.warning('AlarmRepositoryが初期化されていません');
    }
    return _alarmRepository;
  }
  
  /// 初期化状態の確認
  static bool get isInitialized => _isInitialized;
  
  /// リポジトリの解放（テスト用）
  static void dispose() {
    _medicationRepository = null;
    _calendarRepository = null;
    _backupRepository = null;
    _alarmRepository = null;
    _isInitialized = false;
  }
}

