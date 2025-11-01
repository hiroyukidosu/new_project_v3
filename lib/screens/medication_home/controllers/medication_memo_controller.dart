// lib/screens/medication_home/controllers/medication_memo_controller.dart

import 'package:flutter/material.dart';
import '../../../models/medication_memo.dart';
import '../../../core/result.dart';
import '../../../utils/logger.dart';
import '../repositories/medication_repository.dart';
import '../use_cases/medication/add_medication_memo_use_case.dart';
import '../use_cases/medication/edit_medication_memo_use_case.dart';
import '../use_cases/medication/delete_medication_memo_use_case.dart';
import '../use_cases/medication/mark_as_taken_use_case.dart';

/// 服用メモ専用Controller
class MedicationMemoController extends ChangeNotifier {
  final MedicationRepository _repository;
  final AddMedicationMemoUseCase _addUseCase;
  final EditMedicationMemoUseCase _editUseCase;
  final DeleteMedicationMemoUseCase _deleteUseCase;
  final MarkAsTakenUseCase _markAsTakenUseCase;

  List<MedicationMemo> _memos = [];
  Map<String, bool> _medicationMemoStatus = {};
  Map<String, Map<String, Map<int, bool>>> _weekdayMedicationDoseStatus = {};
  bool _isLoading = false;
  String? _error;

  MedicationMemoController({
    required MedicationRepository repository,
  })  : _repository = repository,
        _addUseCase = AddMedicationMemoUseCase(repository),
        _editUseCase = EditMedicationMemoUseCase(repository),
        _deleteUseCase = DeleteMedicationMemoUseCase(repository),
        _markAsTakenUseCase = MarkAsTakenUseCase(repository);

  // ゲッター
  List<MedicationMemo> get memos => _memos;
  Map<String, bool> get medicationMemoStatus => _medicationMemoStatus;
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus =>
      _weekdayMedicationDoseStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初期化
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.loadMemos(),
        _repository.loadMemoStatus(),
        _repository.loadWeekdayDoseStatus(),
      ]);

      if (results[0].isSuccess) {
        _memos = (results[0] as Success<List<MedicationMemo>>).data;
      }

      if (results[1].isSuccess) {
        _medicationMemoStatus =
            (results[1] as Success<Map<String, bool>>).data;
      }

      if (results[2].isSuccess) {
        _weekdayMedicationDoseStatus = (results[2]
            as Success<Map<String, Map<String, Map<int, bool>>>>).data;
      }

      Logger.info('メモ初期化完了: ${_memos.length}件');
    } catch (e, stackTrace) {
      Logger.error('メモ初期化エラー', e, stackTrace);
      _error = 'メモの読み込みに失敗しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// メモを追加
  Future<Result<MedicationMemo>> addMemo(MedicationMemo memo) async {
    try {
      final result = await _addUseCase.execute(
        memo: memo,
        existingMemos: _memos,
      );

      if (result.isSuccess) {
        final savedMemo = (result as Success<MedicationMemo>).data;
        _memos.add(savedMemo);
        notifyListeners();
        Logger.info('メモ追加成功: ${savedMemo.name}');
      } else {
        _error = (result as Error<MedicationMemo>).message;
        notifyListeners();
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('メモ追加エラー', e, stackTrace);
      final error = Error<MedicationMemo>('メモの追加に失敗しました: $e', e);
      _error = error.message;
      notifyListeners();
      return error;
    }
  }

  /// メモを編集
  Future<Result<MedicationMemo>> editMemo(
    MedicationMemo originalMemo,
    MedicationMemo updatedMemo,
  ) async {
    try {
      final result = await _editUseCase.execute(
        originalMemo: originalMemo,
        updatedMemo: updatedMemo,
        existingMemos: _memos,
      );

      if (result.isSuccess) {
        final savedMemo = (result as Success<MedicationMemo>).data;
        final index = _memos.indexWhere((m) => m.id == originalMemo.id);
        if (index >= 0) {
          _memos[index] = savedMemo;
          notifyListeners();
          Logger.info('メモ編集成功: ${savedMemo.name}');
        }
      } else {
        _error = (result as Error<MedicationMemo>).message;
        notifyListeners();
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('メモ編集エラー', e, stackTrace);
      final error = Error<MedicationMemo>('メモの編集に失敗しました: $e', e);
      _error = error.message;
      notifyListeners();
      return error;
    }
  }

  /// メモを削除
  Future<Result<void>> deleteMemo(String memoId) async {
    try {
      final result = await _deleteUseCase.execute(memoId);

      if (result.isSuccess) {
        _memos.removeWhere((m) => m.id == memoId);
        notifyListeners();
        Logger.info('メモ削除成功: $memoId');
      } else {
        _error = (result as Error<void>).message;
        notifyListeners();
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('メモ削除エラー', e, stackTrace);
      final error = Error<void>('メモの削除に失敗しました: $e', e);
      _error = error.message;
      notifyListeners();
      return error;
    }
  }

  /// 服用済みとしてマーク
  Future<Result<MedicationMemo>> markAsTaken(
    MedicationMemo memo, [
    DateTime? date,
  ]) async {
    final targetDate = date ?? DateTime.now();
    try {
      final result = await _markAsTakenUseCase.execute(
        memo: memo,
        date: targetDate,
        currentStatus: _medicationMemoStatus,
      );

      if (result.isSuccess) {
        final updatedMemo = (result as Success<MedicationMemo>).data;
        final index = _memos.indexWhere((m) => m.id == memo.id);
        if (index >= 0) {
          _memos[index] = updatedMemo;
        }
        notifyListeners();
        Logger.info('服用済みマーク成功: ${memo.name}');
      } else {
        _error = (result as Error<MedicationMemo>).message;
        notifyListeners();
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('服用済みマークエラー', e, stackTrace);
      final error = Error<MedicationMemo>('服用済みマークに失敗しました: $e', e);
      _error = error.message;
      notifyListeners();
      return error;
    }
  }

  /// メモステータスを更新
  void updateMemoStatus(String key, bool value) {
    _medicationMemoStatus[key] = value;
    notifyListeners();
  }

  @override
  void dispose() {
    Logger.debug('MedicationMemoController dispose');
    super.dispose();
  }
}

