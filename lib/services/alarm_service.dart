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
  Timer? _notificationAutoCancelTimer;  // 通知自動キャンセル用タイマー
  DateTime? _lastCheckTime;
  String? _lastFiredTimeLabel; // 'HH:mm'
  int? _lastFiredMinuteMarker; // 日付番号 (hour*60+minute)
  int? _currentNotificationId;  // 現在表示中の通知ID
  
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
        // エラーログは不要
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
        }
      }
    }
    _lastCheckTime = now;
    
    for (final alarm in alarms) {
      
      if (alarm.enabled && AlarmHelpers.isTimeMatch(alarm.time, currentTime)) {
        // 同一時刻に既にどれかのアラームが発火していればスキップ
        final minuteMarker = now.hour * 60 + now.minute;
        if (_lastFiredTimeLabel == currentTime && _lastFiredMinuteMarker == minuteMarker) {
          continue;
        }
        // 一時的に無効化されたアラームはスキップ
        if (alarm.temporarilyDisabled) {
          continue;
        }
        
        // 繰り返し設定のチェック
        if (AlarmHelpers.shouldTriggerAlarm(alarm, currentWeekday)) {
          // 同じアラームが連続で発火しないようにチェック（1分間隔で制限）
          if (!AlarmHelpers.wasRecentlyTriggered(alarm)) {
            await triggerAlarm(alarm);
            // 発火時刻を記録
            final updatedAlarm = alarm.copyWith(lastTriggered: now);
            alarms[alarms.indexOf(alarm)] = updatedAlarm;
            _lastFiredTimeLabel = currentTime;
            _lastFiredMinuteMarker = minuteMarker;
            break; // 同じ分内で発火しないように打ち切る
          }
        }
      }
    }
  }

  /// アラームを発火
  Future<void> triggerAlarm(Alarm alarm) async {
    if (AudioService.isPlaying) {
      return;
    }
    
    if (!isMounted()) return;
    
    try {
      triggerStateUpdate();
      
      // 通知IDを保存
      _currentNotificationId = alarm.hashCode;
      
      // 通知を表示
      await NotificationService.showAlarmNotification(
        alarm: alarm,
        selectedNotificationType: selectedNotificationType,
      );
      
      // 5秒後に通知を自動的にキャンセル
      _notificationAutoCancelTimer?.cancel();
      _notificationAutoCancelTimer = Timer(const Duration(seconds: 5), () async {
        try {
          if (_currentNotificationId != null && isMounted()) {
            await NotificationService.cancelNotification(_currentNotificationId!);
            _currentNotificationId = null;
          }
        } catch (e) {
          // エラーは無視（通知キャンセル失敗は致命的ではない）
        }
      });
      
      // アラーム種類に応じた処理
      final alarmType = alarm.alarmType.isEmpty ? selectedNotificationType : alarm.alarmType;
      
      switch (alarmType) {
        case 'sound':
          await AudioService.playAlarmSound(
            selectedAlarmSound: selectedAlarmSound,
            notificationVolume: notificationVolume,
          );
          break;
        case 'sound_vibration':
          await AudioService.playAlarmSound(
            selectedAlarmSound: selectedAlarmSound,
            notificationVolume: notificationVolume,
          );
          await AudioService.startContinuousVibration();
          break;
        case 'vibration':
          await AudioService.startContinuousVibration();
          break;
        case 'silent':
          break;
      }

      // アラーム停止ダイアログ
      onAlarmStopDialog();
    } catch (e) {
      if (!isMounted()) return;
      triggerStateUpdate();
    }
  }

  /// アラームを停止
  Future<void> stopAlarm(List<Alarm> alarms) async {
    try {
      await AudioService.stopAlarm();
      
      // 通知自動キャンセルタイマーをキャンセル
      _notificationAutoCancelTimer?.cancel();
      _notificationAutoCancelTimer = null;
      
      // 現在の通知IDを明示的にキャンセル
      if (_currentNotificationId != null) {
        try {
          await NotificationService.cancelNotification(_currentNotificationId!);
        } catch (e) {
          // 個別キャンセル失敗時は無視
        }
      }
      
      // すべての通知をキャンセル（念のため）
      try {
        await NotificationService.cancelAllNotifications();
      } catch (e) {
        // 全キャンセル失敗時は無視
      }
      
      _currentNotificationId = null;
      
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
        }
      }
      
      if (isMounted()) {
        triggerStateUpdate();
      }
    } catch (e) {
      if (isMounted()) {
        triggerStateUpdate();
      }
    }
  }

  /// タイマーを停止
  void stopTimer() {
    _alarmTimer?.cancel();
    _alarmTimer = null;
    _notificationAutoCancelTimer?.cancel();
    _notificationAutoCancelTimer = null;
  }

  /// クリーンアップ
  void dispose() {
    stopTimer();
    _lastCheckTime = null;
    _lastFiredTimeLabel = null;
    _lastFiredMinuteMarker = null;
    _currentNotificationId = null;
  }
}

