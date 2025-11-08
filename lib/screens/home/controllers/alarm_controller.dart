// lib/screens/home/controllers/alarm_controller.dart
// アラーム関連のビジネスロジックを管理

import 'package:flutter/material.dart';
import '../state/home_page_state_manager.dart';
import '../persistence/snapshot_persistence.dart';
import '../../helpers/home_page_alarm_helper.dart';

/// アラームコントローラー
/// アラームの追加、削除、更新、有効/無効切り替えを管理
class AlarmController {
  final HomePageStateManager stateManager;
  final SnapshotPersistence snapshotPersistence;
  final VoidCallback onStateChanged;
  final Future<void> Function()? onStopAlarm;

  AlarmController({
    required this.stateManager,
    required this.snapshotPersistence,
    required this.onStateChanged,
    this.onStopAlarm,
  });

  /// アラーム追加
  Future<void> addAlarm(Map<String, dynamic> alarm) async {
    try {
      await snapshotPersistence.saveSnapshotBeforeChange(
        'アラーム追加_${alarm['name']}',
        () async => _createBackupData('アラーム追加前'),
      );

      stateManager.alarmList.add(alarm);
      await HomePageAlarmHelper.saveAlarmData(stateManager.alarmList);
      onStateChanged();
    } catch (e) {
      debugPrint('アラーム追加エラー: $e');
    }
  }

  /// アラーム削除
  Future<void> removeAlarm(int index) async {
    try {
      final alarmList = stateManager.alarmList;
      if (index >= 0 && index < alarmList.length) {
        final alarm = alarmList[index];
        await snapshotPersistence.saveSnapshotBeforeChange(
          'アラーム削除_${alarm['name']}',
          () async => _createBackupData('アラーム削除前'),
        );

        alarmList.removeAt(index);
        stateManager.alarmList = List.from(alarmList);
        await HomePageAlarmHelper.saveAlarmData(stateManager.alarmList);
        onStateChanged();
      }
    } catch (e) {
      debugPrint('アラーム削除エラー: $e');
    }
  }

  /// アラーム更新
  Future<void> updateAlarm(int index, Map<String, dynamic> updatedAlarm) async {
    try {
      final alarmList = stateManager.alarmList;
      if (index >= 0 && index < alarmList.length) {
        final alarm = alarmList[index];
        await snapshotPersistence.saveSnapshotBeforeChange(
          'アラーム編集_${alarm['name']}',
          () async => _createBackupData('アラーム編集前'),
        );

        alarmList[index] = updatedAlarm;
        stateManager.alarmList = List.from(alarmList);
        await HomePageAlarmHelper.saveAlarmData(stateManager.alarmList);
        onStateChanged();
      }
    } catch (e) {
      debugPrint('アラーム更新エラー: $e');
    }
  }

  /// アラーム有効/無効切り替え
  Future<void> toggleAlarm(int index) async {
    try {
      final alarmList = stateManager.alarmList;
      if (index >= 0 && index < alarmList.length) {
        final alarm = alarmList[index];
        final wasEnabled = alarm['enabled'] as bool? ?? true;
        final newEnabled = !wasEnabled;

        await snapshotPersistence.saveSnapshotBeforeChange(
          'アラーム切替_${alarm['name']}_${newEnabled ? '有効' : '無効'}',
          () async => _createBackupData('アラーム切替前'),
        );

        alarm['enabled'] = newEnabled;
        stateManager.alarmList = List.from(alarmList);
        await HomePageAlarmHelper.saveAlarmData(stateManager.alarmList);
        
        // アラームが無効になった場合、再生中のアラームを停止
        if (!newEnabled && wasEnabled && onStopAlarm != null) {
          await onStopAlarm!();
        }
        
        onStateChanged();
      }
    } catch (e) {
      debugPrint('アラーム切替エラー: $e');
    }
  }

  /// アラームデータの整合性チェック
  Future<void> checkAlarmDataIntegrity() async {
    try {
      final alarmList = stateManager.alarmList;
      for (int i = 0; i < alarmList.length; i++) {
        final alarm = alarmList[i];
        
        if (!alarm.containsKey('title') || alarm['title'] == null) {
          alarm['title'] = '服用アラーム';
        }
        if (!alarm.containsKey('time') || alarm['time'] == null) {
          alarm['time'] = '09:00';
        }
        if (!alarm.containsKey('enabled') || alarm['enabled'] == null) {
          alarm['enabled'] = true;
        }
        if (!alarm.containsKey('message') || alarm['message'] == null) {
          alarm['message'] = '薬を服用する時間です';
        }
      }
      
      stateManager.alarmList = List.from(alarmList);
      await HomePageAlarmHelper.saveAlarmData(stateManager.alarmList);
      debugPrint('アラームデータ整合性チェック完了');
    } catch (e) {
      debugPrint('アラームデータ整合性チェックエラー: $e');
    }
  }

  /// バックアップデータ作成
  Future<Map<String, dynamic>> _createBackupData(String label) async {
    return {
      'alarmList': List.from(stateManager.alarmList),
      'label': label,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

