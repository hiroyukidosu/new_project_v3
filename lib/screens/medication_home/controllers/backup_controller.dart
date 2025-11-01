// lib/screens/medication_home/controllers/backup_controller.dart

import 'package:flutter/material.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';
import '../../../models/medicine_data.dart';
import '../../../core/result.dart';
import '../../../utils/logger.dart';
import '../repositories/backup_repository.dart';
import '../use_cases/backup/create_backup_use_case.dart';
import '../use_cases/backup/restore_backup_use_case.dart';

/// バックアップ専用Controller
class BackupController extends ChangeNotifier {
  final BackupRepository _repository;
  final CreateBackupUseCase _createUseCase;
  final RestoreBackupUseCase _restoreUseCase;

  List<Map<String, dynamic>> _backupHistory = [];
  bool _isLoading = false;
  String? _error;
  String? _lastOperationMessage;

  BackupController({
    required BackupRepository repository,
  })  : _repository = repository,
        _createUseCase = CreateBackupUseCase(repository),
        _restoreUseCase = RestoreBackupUseCase(repository);

  // ゲッター
  List<Map<String, dynamic>> get backupHistory => _backupHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastOperationMessage => _lastOperationMessage;

  /// 初期化（バックアップ履歴を読み込み）
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getBackupHistory();
      
      if (result.isSuccess) {
        _backupHistory = (result as Success<List<Map<String, dynamic>>>).data;
        Logger.info('バックアップ履歴読み込み成功: ${_backupHistory.length}件');
      } else {
        _error = (result as Error<List<Map<String, dynamic>>>).message;
      }
    } catch (e, stackTrace) {
      Logger.error('バックアップ初期化エラー', e, stackTrace);
      _error = 'バックアップ履歴の読み込みに失敗しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// バックアップを作成
  Future<Result<String>> createBackup({
    required String backupName,
    required List<MedicationMemo> medicationMemos,
    required List<Map<String, dynamic>> addedMedications,
    required List<MedicineData> medicines,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus,
    required Map<String, bool> medicationMemoStatus,
    required Map<String, Color> dayColors,
    required List<Map<String, dynamic>> alarmList,
    required Map<String, dynamic> alarmSettings,
    required Map<String, double> adherenceRates,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _createUseCase.execute(
        backupName: backupName,
        medicationMemos: medicationMemos,
        addedMedications: addedMedications,
        medicines: medicines,
        medicationData: medicationData,
        weekdayMedicationStatus: weekdayMedicationStatus,
        weekdayMedicationDoseStatus: weekdayMedicationDoseStatus,
        medicationMemoStatus: medicationMemoStatus,
        dayColors: dayColors,
        alarmList: alarmList,
        alarmSettings: alarmSettings,
        adherenceRates: adherenceRates,
      );

      if (result.isSuccess) {
        final backupKey = (result as Success<String>).data;
        _lastOperationMessage = 'バックアップ「$backupName」を作成しました';
        
        // 履歴を再読み込み
        await initialize();
        
        Logger.info('バックアップ作成成功: $backupKey');
      } else {
        _error = (result as Error<String>).message;
        _lastOperationMessage = _error;
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('バックアップ作成エラー', e, stackTrace);
      final error = Error<String>('バックアップの作成に失敗しました: $e', e);
      _error = error.message;
      _lastOperationMessage = _error;
      return error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// バックアップを復元
  Future<Result<Map<String, dynamic>>> restoreBackup(String backupKey) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _restoreUseCase.execute(backupKey);

      if (result.isSuccess) {
        final restored = (result as Success<Map<String, dynamic>>).data;
        _lastOperationMessage = 'バックアップを復元しました';
        Logger.info('バックアップ復元成功: $backupKey');
      } else {
        _error = (result as Error<Map<String, dynamic>>).message;
        _lastOperationMessage = _error;
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('バックアップ復元エラー', e, stackTrace);
      final error = Error<Map<String, dynamic>>(
        'バックアップの復元に失敗しました: $e',
        e,
      );
      _error = error.message;
      _lastOperationMessage = _error;
      return error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// バックアップを削除
  Future<Result<void>> deleteBackup(String backupKey) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.deleteBackupData(backupKey);

      if (result.isSuccess) {
        _lastOperationMessage = 'バックアップを削除しました';
        
        // 履歴を再読み込み
        await initialize();
        
        Logger.info('バックアップ削除成功: $backupKey');
      } else {
        _error = (result as Error<void>).message;
        _lastOperationMessage = _error;
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('バックアップ削除エラー', e, stackTrace);
      final error = Error<void>('バックアップの削除に失敗しました: $e', e);
      _error = error.message;
      _lastOperationMessage = _error;
      return error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// メッセージをクリア
  void clearMessage() {
    _lastOperationMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    Logger.debug('BackupController dispose');
    super.dispose();
  }
}

