// lib/services/alarm_service.dart
// アラーム管理のコアロジック

import 'package:flutter/material.dart';
import 'dart:async';
import '../models/alarm_model.dart';
import '../utils/alarm_helpers.dart';
import '../core/alarm_optimization.dart';
import 'notification_service.dart';
import 'audio_service.dart';

/// アラームサービス
class AlarmService {
  Timer? _alarmTimer;
  DateTime? _lastCheckTime;
  String? _lastFiredTimeLabel; // 'HH:mm'
  int? _lastFiredMinuteMarker; // 日付番号 (hour*60+minute)
  
  final Function(Alarm) onAlarmTriggered;
  final Function() onAlarmStopDialog;
  final Function() isMounted;
  final Function() triggerStateUpdate;
  final String selectedNotificationType;
  final String selectedAlarmSound;
  final int notificationVolume;

  AlarmService({
    required this.onAlarmTriggered,
    required this.onAlarmStopDialog,
    required this.isMounted,
    required this.triggerStateUpdate,
    required this.selectedNotificationType,
    required this.selectedAlarmSound,
    required this.notificationVolume,
  });

  /// アラームチェックを開始
  void startAlarmCheck() {
    _alarmTimer?.cancel();
    
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!isMounted()) {
        timer.cancel();
        return;
      }
      
      try {
        await checkAlarms(isAlarmEnabled: true, alarms: []);
      } catch (e) {
        debugPrint('_checkAlarms エラー: $e');
      }
    });
  }

  /// アラームをチェック（発火判定）
  Future<void> checkAlarms({
    required bool isAlarmEnabled,
    required List<Alarm> alarms,
  }) async {
    if (!isAlarmEnabled) {
      return;
    }
    
    final now = DateTime.now();
    final currentTime = AlarmHelpers.getCurrentTimeString();
    final currentWeekday = now.weekday; // 1=月曜日, 7=日曜日
    
    // 分が変わった時に一時的に無効化されたアラームを再有効化
    if (_lastCheckTime != null && _lastCheckTime!.minute != now.minute) {
      for (final alarm in alarms) {
        if (alarm.temporarilyDisabled) {
          alarms[alarms.indexOf(alarm)] = alarm.copyWith(temporarilyDisabled: false);
          debugPrint('アラーム ${alarm.name} を再有効化');
        }
      }
    }
    _lastCheckTime = now;
    
    if (AlarmOptimization.shouldLogAlarmCheck()) {
      debugPrint('服用時間のアラームチェック: $currentTime, アラーム数: ${alarms.length}, 有効: $isAlarmEnabled');
    }
    
    for (final alarm in alarms) {
      if (AlarmOptimization.shouldLogAlarmCheck()) {
        debugPrint('服用時間のアラーム: ${alarm.name}, 時間: ${alarm.time}, 有効: ${alarm.enabled}');
      }
      
      if (alarm.enabled && AlarmHelpers.isTimeMatch(alarm.time, currentTime)) {
        // 同一時刻に既にどれかのアラームが発火していればスキップ
        final minuteMarker = now.hour * 60 + now.minute;
        if (_lastFiredTimeLabel == currentTime && _lastFiredMinuteMarker == minuteMarker) {
          continue;
        }
        // 一時的に無効化されたアラームはスキップ
        if (alarm.temporarilyDisabled) {
          if (AlarmOptimization.shouldLogAlarmCheck()) {
            debugPrint('服用時間のアラームスキップ: ${alarm.name} (一時的に無効化中)');
          }
          continue;
        }
        
        // 繰り返し設定のチェック
        if (AlarmHelpers.shouldTriggerAlarm(alarm, currentWeekday)) {
          // 同じアラームが連続で発火しないようにチェック（1分間隔で制限）
          if (!AlarmHelpers.wasRecentlyTriggered(alarm)) {
            debugPrint('服用時間のアラーム発火: ${alarm.name}');
            await triggerAlarm(alarm);
            // 発火時刻を記録
            final updatedAlarm = alarm.copyWith(lastTriggered: now);
            alarms[alarms.indexOf(alarm)] = updatedAlarm;
            _lastFiredTimeLabel = currentTime;
            _lastFiredMinuteMarker = minuteMarker;
            break; // 同じ分内で発火しないように打ち切る
          } else {
            if (AlarmOptimization.shouldLogAlarmCheck()) {
              debugPrint('服用時間のアラームスキップ: ${alarm.name} (最近発火済み)');
            }
          }
        } else {
          if (AlarmOptimization.shouldLogAlarmCheck()) {
            debugPrint('服用時間のアラームスキップ: ${alarm.name} (繰り返し条件に合わない)');
          }
        }
      }
    }
  }

  /// アラームを発火
  Future<void> triggerAlarm(Alarm alarm) async {
    if (AudioService.isPlaying) {
      debugPrint('服用時間のアラーム既に再生中: ${alarm.name}');
      return;
    }

    debugPrint('服用時間のアラーム開始: ${alarm.name}');
    
    if (!isMounted()) return;
    
    try {
      triggerStateUpdate();
      
      // 通知を表示
      await NotificationService.showAlarmNotification(
        alarm: alarm,
        selectedNotificationType: selectedNotificationType,
      );
      
      // アラーム種類に応じた処理
      final alarmType = alarm.alarmType.isEmpty ? selectedNotificationType : alarm.alarmType;
      debugPrint('服用時間のアラーム種類: $alarmType');
      
      switch (alarmType) {
        case 'sound':
          debugPrint('音声服用時間のアラーム開始: $selectedAlarmSound');
          await AudioService.playAlarmSound(
            selectedAlarmSound: selectedAlarmSound,
            notificationVolume: notificationVolume,
          );
          break;
        case 'sound_vibration':
          debugPrint('音声+バイブ服用時間のアラーム開始: $selectedAlarmSound');
          await AudioService.playAlarmSound(
            selectedAlarmSound: selectedAlarmSound,
            notificationVolume: notificationVolume,
          );
          await AudioService.startContinuousVibration();
          break;
        case 'vibration':
          debugPrint('バイブレーション服用時間のアラーム開始');
          await AudioService.startContinuousVibration();
          break;
        case 'silent':
          debugPrint('サイレント服用時間のアラーム');
          break;
      }

      // アラーム停止ダイアログ
      onAlarmStopDialog();
    } catch (e) {
      debugPrint('服用時間のアラーム再生エラー: $e');
      if (!isMounted()) return;
      triggerStateUpdate();
    }
  }

  /// アラームを停止
  Future<void> stopAlarm(List<Alarm> alarms) async {
    try {
      debugPrint('服用時間のアラーム停止開始');
      
      await AudioService.stopAlarm();
      
      // 現在鳴っているアラームのlastTriggeredを更新して重複実行を防ぐ
      final now = DateTime.now();
      final currentTime = AlarmHelpers.getCurrentTimeString();
      
      for (int i = 0; i < alarms.length; i++) {
        final alarm = alarms[i];
        if (alarm.enabled && alarm.time == currentTime) {
          alarms[i] = alarm.copyWith(
            lastTriggered: now,
            temporarilyDisabled: true,
          );
          debugPrint('アラーム ${alarm.name} のlastTriggeredを更新し、一時的に無効化: $now');
        }
      }
      
      if (isMounted()) {
        triggerStateUpdate();
      }
      
      debugPrint('服用時間のアラームが停止されました');
    } catch (e) {
      debugPrint('服用時間のアラーム停止エラー: $e');
      if (isMounted()) {
        triggerStateUpdate();
      }
    }
  }

  /// タイマーを停止
  void stopTimer() {
    _alarmTimer?.cancel();
    _alarmTimer = null;
    debugPrint('✅ AlarmService タイマー停止');
  }

  /// クリーンアップ
  void dispose() {
    stopTimer();
    _lastCheckTime = null;
    _lastFiredTimeLabel = null;
    _lastFiredMinuteMarker = null;
    debugPrint('✅ AlarmService dispose完了');
  }
}

