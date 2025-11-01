// lib/screens/medication_home/repositories/alarm_repository.dart

import '../../../core/result.dart';
import '../../../utils/logger.dart';
import '../../home/persistence/alarm_data_persistence.dart';

/// アラーム関連のデータアクセスを管理するRepository
class AlarmRepository {
  final AlarmDataPersistence _persistence;

  AlarmRepository({
    AlarmDataPersistence? persistence,
  }) : _persistence = persistence ?? AlarmDataPersistence();

  /// アラーム一覧を読み込み
  Future<Result<List<Map<String, dynamic>>>> loadAlarms() async {
    try {
      final alarms = await _persistence.loadAlarmData();
      Logger.info('アラーム読み込み成功: ${alarms.length}件');
      return Success(alarms);
    } catch (e, stackTrace) {
      Logger.error('アラーム読み込みエラー', e, stackTrace);
      return Error('アラームの読み込みに失敗しました: $e', e);
    }
  }

  /// アラームを保存
  Future<Result<void>> saveAlarms(List<Map<String, dynamic>> alarms) async {
    try {
      await _persistence.saveAlarmData(alarms);
      Logger.info('アラーム保存成功: ${alarms.length}件');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('アラーム保存エラー', e, stackTrace);
      return Error('アラームの保存に失敗しました: $e', e);
    }
  }

  /// アラームを追加
  Future<Result<void>> addAlarm(Map<String, dynamic> alarm) async {
    try {
      await _persistence.addAlarm(alarm);
      Logger.info('アラーム追加成功');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('アラーム追加エラー', e, stackTrace);
      return Error('アラームの追加に失敗しました: $e', e);
    }
  }

  /// アラームを削除
  Future<Result<void>> deleteAlarm(int index) async {
    try {
      await _persistence.deleteAlarm(index);
      Logger.info('アラーム削除成功: index=$index');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('アラーム削除エラー', e, stackTrace);
      return Error('アラームの削除に失敗しました: $e', e);
    }
  }

  /// アラームを更新
  Future<Result<void>> updateAlarm(
    int index,
    Map<String, dynamic> updatedAlarm,
  ) async {
    try {
      await _persistence.updateAlarm(index, updatedAlarm);
      Logger.info('アラーム更新成功: index=$index');
      return const Success(null);
    } catch (e, stackTrace) {
      Logger.error('アラーム更新エラー', e, stackTrace);
      return Error('アラームの更新に失敗しました: $e', e);
    }
  }
}

