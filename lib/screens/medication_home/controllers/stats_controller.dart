// lib/screens/medication_home/controllers/stats_controller.dart

import 'package:flutter/material.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';
import '../../../core/result.dart';
import '../../../utils/logger.dart';
import '../use_cases/stats/calculate_adherence_use_case.dart';
import '../use_cases/stats/calculate_custom_adherence_use_case.dart';
import '../repositories/preference_repository.dart';

/// 統計計算専用Controller
class StatsController extends ChangeNotifier {
  final CalculateAdherenceUseCase _calculateAdherenceUseCase;
  final CalculateCustomAdherenceUseCase _calculateCustomAdherenceUseCase;
  final PreferenceRepository _preferenceRepo;

  Map<String, double> _adherenceRates = {};
  double? _customAdherenceResult;
  int? _customDaysResult;
  bool _isCalculating = false;
  String? _error;

  StatsController({
    required PreferenceRepository preferenceRepo,
  })  : _calculateAdherenceUseCase = CalculateAdherenceUseCase(),
        _calculateCustomAdherenceUseCase = CalculateCustomAdherenceUseCase(),
        _preferenceRepo = preferenceRepo;

  // ゲッター
  Map<String, double> get adherenceRates => _adherenceRates;
  double? get customAdherenceResult => _customAdherenceResult;
  int? get customDaysResult => _customDaysResult;
  bool get isCalculating => _isCalculating;
  String? get error => _error;

  /// 初期化
  Future<void> initialize() async {
    try {
      final result = await _preferenceRepo.loadAdherenceRates();
      
      if (result.isSuccess) {
        _adherenceRates = (result as Success<Map<String, double>>).data;
        notifyListeners();
      } else {
        Logger.error('遵守率読み込み失敗', null);
      }
    } catch (e, stackTrace) {
      Logger.error('統計初期化エラー', e, stackTrace);
    }
  }

  /// 遵守率を計算（期間別）
  Future<Result<Map<String, double>>> calculateAdherence({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> memos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, bool> medicationMemoStatus,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) async {
    _isCalculating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _calculateAdherenceUseCase.execute(
        days: days,
        medicationData: medicationData,
        memos: memos,
        weekdayMedicationStatus: weekdayMedicationStatus,
        medicationMemoStatus: medicationMemoStatus,
        getMedicationMemoCheckedCountForDate: getMedicationMemoCheckedCountForDate,
      );

      if (result.isSuccess) {
        _adherenceRates = (result as Success<Map<String, double>>).data;
        
        // 遵守率を保存
        await _preferenceRepo.saveAdherenceRates(_adherenceRates);
        
        Logger.info('遵守率計算成功: ${_adherenceRates.length}件');
      } else {
        _error = (result as Error<Map<String, double>>).message;
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('遵守率計算エラー', e, stackTrace);
      final error = Error<Map<String, double>>(
        '遵守率の計算に失敗しました: $e',
        e,
      );
      _error = error.message;
      return error;
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  /// カスタム期間の遵守率を計算
  Future<Result<double>> calculateCustomAdherence({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> memos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, bool> medicationMemoStatus,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) async {
    _isCalculating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _calculateCustomAdherenceUseCase.execute(
        days: days,
        medicationData: medicationData,
        memos: memos,
        weekdayMedicationStatus: weekdayMedicationStatus,
        medicationMemoStatus: medicationMemoStatus,
        getMedicationMemoCheckedCountForDate: getMedicationMemoCheckedCountForDate,
      );

      if (result.isSuccess) {
        _customAdherenceResult = (result as Success<double>).data;
        _customDaysResult = days;
        Logger.info('カスタム遵守率計算成功: $_customAdherenceResult% ($days日間)');
      } else {
        _error = (result as Error<double>).message;
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('カスタム遵守率計算エラー', e, stackTrace);
      final error = Error<double>(
        'カスタム遵守率の計算に失敗しました: $e',
        e,
      );
      _error = error.message;
      return error;
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  /// カスタム結果をクリア
  void clearCustomResult() {
    _customAdherenceResult = null;
    _customDaysResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    Logger.debug('StatsController dispose');
    super.dispose();
  }
}

