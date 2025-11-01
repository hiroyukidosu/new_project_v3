// lib/screens/medication_home/use_cases/backup/create_backup_use_case.dart

import '../../../../models/medication_memo.dart';
import '../../../../models/medication_info.dart';
import '../../../../models/medicine_data.dart';
import '../../../../core/result.dart';
import '../../../../utils/logger.dart';
import '../../../repositories/backup_repository.dart';
import '../../../../screens/helpers/home_page_backup_helper.dart';
import 'package:flutter/material.dart';

/// バックアップを作成するUseCase
class CreateBackupUseCase {
  final BackupRepository _repository;

  CreateBackupUseCase(this._repository);

  /// バックアップを作成
  Future<Result<String>> execute({
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
    try {
      // バックアップデータを作成
      final backupData = await HomePageBackupHelper.createSafeBackupData(
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

      // バックアップを保存
      final saveResult = await _repository.saveBackupData(
        backupData,
        backupName,
      );

      if (saveResult.isSuccess) {
        final backupKey = (saveResult as Success<String>).data;
        Logger.info('バックアップ作成成功: $backupName ($backupKey)');
        return Success(backupKey);
      } else {
        final error = saveResult as Error<String>;
        Logger.error('バックアップ作成失敗: ${error.message}');
        return Error(error.message, error.error);
      }
    } catch (e, stackTrace) {
      Logger.error('バックアップ作成エラー', e, stackTrace);
      return Error('バックアップの作成に失敗しました: $e', e);
    }
  }
}

