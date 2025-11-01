// lib/screens/medication_home/repositories/preference_repository.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/result.dart';
import '../../../utils/logger.dart';
import '../../../models/medication_info.dart';
import '../../../services/medication_service.dart';
import '../../home/persistence/data_sync_manager.dart';

/// アプリ設定とユーザー設定のデータアクセスを管理するRepository
class PreferenceRepository {
  final DataSyncManager _dataSyncManager;

  PreferenceRepository({
    DataSyncManager? dataSyncManager,
  }) : _dataSyncManager = dataSyncManager ?? DataSyncManager(
          medicationPersistence: MedicationDataPersistence(),
          alarmPersistence: AlarmDataPersistence(),
        );

  /// 統計データ（遵守率）を読み込み
  Future<Result<Map<String, double>>> loadAdherenceRates() async {
    try {
      final allData = await _dataSyncManager.loadAllData();
      final rates = allData['adherenceRates'] as Map<String, double>;
      Logger.debug('遵守率読み込み成功: ${rates.length}件');
      return Success(rates);
    } catch (e, stackTrace) {
      Logger.error('遵守率読み込みエラー', e, stackTrace);
      return Error('遵守率の読み込みに失敗しました: $e', e);
    }
  }

  /// 統計データ（遵守率）を保存
  Future<Result<void>> saveAdherenceRates(
    Map<String, double> adherenceRates,
  ) async {
    try {
      // 既存データを読み込み
      final allData = await _dataSyncManager.loadAllData();
      
      // 遵守率を更新して保存
      await _dataSyncManager.saveAllData(
        selectedDay: null,
        medicationMemoStatus: allData['medicationMemoStatus'] 
            as Map<String, bool>,
        addedMedications: allData['addedMedications'] 
            as List<Map<String, dynamic>>,
        alarmList: allData['alarmList'] as List<Map<String, dynamic>>,
        dayColors: (allData['dayColors'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as Color),
        ),
        adherenceRates: adherenceRates,
      );
      
      Logger.debug('遵守率保存成功: ${adherenceRates.length}件');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('遵守率保存エラー', e, stackTrace);
      return Error('遵守率の保存に失敗しました: $e', e);
    }
  }

  /// 特定日の服用データを読み込み
  Future<Result<Map<String, MedicationInfo>>> loadMedicationDataForDay(
    DateTime day,
  ) async {
    try {
      final dateStr = day.toIso8601String().split('T')[0];
      final medicationData = await MedicationService.loadMedicationData();
      final dayData = medicationData[dateStr] ?? <String, MedicationInfo>{};
      
      Logger.debug('服用データ読み込み成功: $dateStr');
      return Success(dayData);
    } catch (e, stackTrace) {
      Logger.error('服用データ読み込みエラー', e, stackTrace);
      return Error('服用データの読み込みに失敗しました: $e', e);
    }
  }

  /// 特定日の服用データを保存
  Future<Result<void>> saveMedicationDataForDay(
    DateTime day,
    Map<String, MedicationInfo> medicationData,
  ) async {
    try {
      final dateStr = day.toIso8601String().split('T')[0];
      await MedicationService.saveMedicationData({dateStr: medicationData});
      
      Logger.debug('服用データ保存成功: $dateStr');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('服用データ保存エラー', e, stackTrace);
      return Error('服用データの保存に失敗しました: $e', e);
    }
  }

  /// 追加薬品リストを読み込み
  Future<Result<List<Map<String, dynamic>>>> loadAddedMedications() async {
    try {
      final allData = await _dataSyncManager.loadAllData();
      final medications = allData['addedMedications'] 
          as List<Map<String, dynamic>>;
      
      Logger.debug('追加薬品リスト読み込み成功: ${medications.length}件');
      return Success(medications);
    } catch (e, stackTrace) {
      Logger.error('追加薬品リスト読み込みエラー', e, stackTrace);
      return Error('追加薬品リストの読み込みに失敗しました: $e', e);
    }
  }

  /// 追加薬品リストを保存
  Future<Result<void>> saveAddedMedications(
    List<Map<String, dynamic>> medications,
  ) async {
    try {
      final allData = await _dataSyncManager.loadAllData();
      
      await _dataSyncManager.saveAllData(
        selectedDay: null,
        medicationMemoStatus: allData['medicationMemoStatus'] 
            as Map<String, bool>,
        addedMedications: medications,
        alarmList: allData['alarmList'] as List<Map<String, dynamic>>,
        dayColors: (allData['dayColors'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as Color),
        ),
        adherenceRates: allData['adherenceRates'] as Map<String, double>,
      );
      
      Logger.debug('追加薬品リスト保存成功: ${medications.length}件');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('追加薬品リスト保存エラー', e, stackTrace);
      return Error('追加薬品リストの保存に失敗しました: $e', e);
    }
  }

  /// メモテキストを読み込み（特定日のメモ）
  Future<Result<String>> loadMemoText(DateTime day) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = day.toIso8601String().split('T')[0];
      final memo = prefs.getString('memo_$dateStr') ?? '';
      
      Logger.debug('メモテキスト読み込み成功: $dateStr');
      return Success(memo);
    } catch (e, stackTrace) {
      Logger.error('メモテキスト読み込みエラー', e, stackTrace);
      return Error('メモテキストの読み込みに失敗しました: $e', e);
    }
  }

  /// メモテキストを保存（特定日のメモ）
  Future<Result<void>> saveMemoText(DateTime day, String memoText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = day.toIso8601String().split('T')[0];
      await prefs.setString('memo_$dateStr', memoText);
      
      Logger.debug('メモテキスト保存成功: $dateStr');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('メモテキスト保存エラー', e, stackTrace);
      return Error('メモテキストの保存に失敗しました: $e', e);
    }
  }
}

