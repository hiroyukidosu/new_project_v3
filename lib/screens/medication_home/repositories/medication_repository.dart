// lib/screens/medication_home/repositories/medication_repository.dart

import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';
import '../../../core/result.dart';
import '../../../utils/logger.dart';
import '../../home/persistence/medication_data_persistence.dart';

/// 服用メモ関連のデータアクセスを管理するRepository
class MedicationRepository {
  final MedicationDataPersistence _persistence;

  MedicationRepository({
    MedicationDataPersistence? persistence,
  }) : _persistence = persistence ?? MedicationDataPersistence();

  /// メモ一覧を読み込み
  Future<Result<List<MedicationMemo>>> loadMemos() async {
    try {
      final memos = await _persistence.loadMedicationMemos();
      Logger.info('メモ読み込み成功: ${memos.length}件');
      return Success(memos);
    } catch (e, stackTrace) {
      Logger.error('メモ読み込みエラー', e, stackTrace);
      return Error('メモの読み込みに失敗しました: $e', e);
    }
  }

  /// メモを保存
  Future<Result<void>> saveMemo(MedicationMemo memo) async {
    try {
      await _persistence.saveMedicationMemo(memo);
      Logger.info('メモ保存成功: ${memo.name}');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('メモ保存エラー', e, stackTrace);
      return Error('メモの保存に失敗しました: $e', e);
    }
  }

  /// メモを削除
  Future<Result<void>> deleteMemo(String id) async {
    try {
      await _persistence.deleteMedicationMemo(id);
      Logger.info('メモ削除成功: $id');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('メモ削除エラー', e, stackTrace);
      return Error('メモの削除に失敗しました: $e', e);
    }
  }

  /// メモの状態を読み込み
  Future<Result<Map<String, bool>>> loadMemoStatus() async {
    try {
      final status = await _persistence.loadMedicationMemoStatus();
      Logger.debug('メモ状態読み込み成功: ${status.length}件');
      return Success(status);
    } catch (e, stackTrace) {
      Logger.error('メモ状態読み込みエラー', e, stackTrace);
      return Error('メモ状態の読み込みに失敗しました: $e', e);
    }
  }

  /// メモの状態を保存
  Future<Result<void>> saveMemoStatus(Map<String, bool> status) async {
    try {
      await _persistence.saveMedicationMemoStatus(status);
      Logger.debug('メモ状態保存成功: ${status.length}件');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('メモ状態保存エラー', e, stackTrace);
      return Error('メモ状態の保存に失敗しました: $e', e);
    }
  }

  /// 曜日別メモの状態を読み込み
  Future<Result<Map<String, Map<String, bool>>>> loadWeekdayStatus() async {
    try {
      final status = await _persistence.loadWeekdayMedicationStatus();
      Logger.debug('曜日別メモ状態読み込み成功: ${status.length}件');
      return Success(status);
    } catch (e, stackTrace) {
      Logger.error('曜日別メモ状態読み込みエラー', e, stackTrace);
      return Error('曜日別メモ状態の読み込みに失敗しました: $e', e);
    }
  }

  /// 曜日別メモの状態を保存
  Future<Result<void>> saveWeekdayStatus(
    Map<String, Map<String, bool>> status,
  ) async {
    try {
      await _persistence.saveWeekdayMedicationStatus(status);
      Logger.debug('曜日別メモ状態保存成功: ${status.length}件');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('曜日別メモ状態保存エラー', e, stackTrace);
      return Error('曜日別メモ状態の保存に失敗しました: $e', e);
    }
  }

  /// 服用回数別の状態を読み込み
  Future<Result<Map<String, Map<String, Map<int, bool>>>>> 
      loadWeekdayDoseStatus() async {
    try {
      final status = await _persistence.loadMedicationDoseStatus();
      Logger.debug('服用回数別状態読み込み成功: ${status.length}件');
      return Success(status);
    } catch (e, stackTrace) {
      Logger.error('服用回数別状態読み込みエラー', e, stackTrace);
      return Error('服用回数別状態の読み込みに失敗しました: $e', e);
    }
  }

  /// 服用回数別の状態を保存
  Future<Result<void>> saveWeekdayDoseStatus(
    Map<String, Map<String, Map<int, bool>>> status,
  ) async {
    try {
      await _persistence.saveMedicationDoseStatus(status);
      Logger.debug('服用回数別状態保存成功: ${status.length}件');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('服用回数別状態保存エラー', e, stackTrace);
      return Error('服用回数別状態の保存に失敗しました: $e', e);
    }
  }
}

