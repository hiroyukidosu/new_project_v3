// lib/alarm/alarm_logic_manager.dart
// アラームチェック・発火ロジックを分離

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import '../core/alarm_optimization.dart';

/// アラームチェック・発火ロジック管理クラス
class AlarmLogicManager {
  final AudioPlayer audioPlayer;
  final int notificationVolume;
  final String selectedAlarmSound;
  final Function(Map<String, dynamic>) onShowAlarmNotification;
  final Function() onShowAlarmStopDialog;
  final Function() isMounted;
  final Function() triggerStateUpdate;
  
  Timer? vibrationTimer;
  bool isAlarmPlaying = false;

  AlarmLogicManager({
    required this.audioPlayer,
    required this.notificationVolume,
    required this.selectedAlarmSound,
    required this.onShowAlarmNotification,
    required this.onShowAlarmStopDialog,
    required this.isMounted,
    required this.triggerStateUpdate,
  });

  /// アラームをチェック（発火判定）
  Future<void> checkAlarms({
    required bool isAlarmEnabled,
    required List<Map<String, dynamic>> alarms,
    required DateTime? lastCheckTime,
    required String? lastFiredTimeLabel,
    required int? lastFiredMinuteMarker,
    required Function(DateTime) setLastCheckTime,
    required Function(String?) setLastFiredTimeLabel,
    required Function(int?) setLastFiredMinuteMarker,
  }) async {
    if (!isAlarmEnabled) {
      return; // 服用時間のアラームが無効の場合は何もしない
    }
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final currentWeekday = now.weekday; // 1=月曜日, 7=日曜日
    
    // 分が変わった時に一時的に無効化されたアラームを再有効化
    if (lastCheckTime != null && lastCheckTime.minute != now.minute) {
      for (final alarm in alarms) {
        if (alarm['temporarilyDisabled'] == true) {
          alarm['temporarilyDisabled'] = false;
          debugPrint('アラーム ${alarm['name']} を再有効化');
        }
      }
    }
    setLastCheckTime(now);
    
    // ログの頻度制限（5分に1回のみ出力）
    if (AlarmOptimization.shouldLogAlarmCheck()) {
      debugPrint('服用時間のアラームチェック: $currentTime, アラーム数: ${alarms.length}, 有効: $isAlarmEnabled');
    }
    
    bool firedThisMinute = false;
    for (final alarm in alarms) {
      // ログの頻度制限のみ適用（アラーム機能は正常に動作）
      if (AlarmOptimization.shouldLogAlarmCheck()) {
        debugPrint('服用時間のアラーム: ${alarm['name']}, 時間: ${alarm['time']}, 有効: ${alarm['enabled']}');
      }
      
      if ((alarm['enabled'] as bool) && alarm['time'] == currentTime) {
        // 同一分内に既にどれかのアラームが発火していればスキップ
        final minuteMarker = now.hour * 60 + now.minute;
        if (lastFiredTimeLabel == currentTime && lastFiredMinuteMarker == minuteMarker) {
          continue;
        }
        // 一時的に無効化されたアラームはスキップ
        if (alarm['temporarilyDisabled'] == true) {
          // スキップログの頻度制限（5分に1回のみ）
          if (AlarmOptimization.shouldLogAlarmCheck()) {
            debugPrint('服用時間のアラームスキップ: ${alarm['name']} (一時的に無効化中)');
          }
          continue;
        }
        
        // 繰り返し設定のチェック
        if (shouldTriggerAlarm(alarm, currentWeekday)) {
          // 同じアラームが連続で発火しないようにチェック（1分間隔で制限）
          final lastTriggered = alarm['lastTriggered'] as DateTime?;
          if (lastTriggered == null || 
              now.difference(lastTriggered).inMinutes >= 1) {
            // アラーム発火ログは制限なし（重要な情報）
            debugPrint('服用時間のアラーム発火: ${alarm['name']}');
            await triggerAlarm(alarm);
            // 発火時刻を記録
            alarm['lastTriggered'] = now;
            setLastFiredTimeLabel(currentTime);
            setLastFiredMinuteMarker(minuteMarker);
            firedThisMinute = true;
            break; // 同じ分に複数発火しないように打ち切る
          } else {
            // スキップログの頻度制限（5分に1回のみ）
            if (AlarmOptimization.shouldLogAlarmCheck()) {
              debugPrint('服用時間のアラームスキップ: ${alarm['name']} (最近発火済み)');
            }
          }
        } else {
          // スキップログの頻度制限（5分に1回のみ）
          if (AlarmOptimization.shouldLogAlarmCheck()) {
            debugPrint('服用時間のアラームスキップ: ${alarm['name']} (繰り返し条件に合わない)');
          }
        }
      }
    }
  }

  /// アラームを発火すべきか判定
  bool shouldTriggerAlarm(Map<String, dynamic> alarm, int currentWeekday) {
    final repeat = alarm['repeat'] ?? '一度だけ';
    final isRepeatEnabled = alarm['isRepeatEnabled'] ?? false;
    final selectedDays = alarm['selectedDays'] as List<bool>?;
    
    // 一度だけの場合は常に発火
    if (!(isRepeatEnabled as bool) || repeat == '一度だけ') {
      return true;
    }
    
    switch (repeat) {
      case '毎日':
        return true;
      case '平日':
        return currentWeekday >= 1 && currentWeekday <= 5; // 月〜金
      case '週末':
        return currentWeekday == 6 || currentWeekday == 7; // 土・日
      case '曜日':
        if (selectedDays != null && selectedDays.length == 7) {
          // 曜日配列のインデックス調整（月曜日=0, 日曜日=6）
          final dayIndex = currentWeekday == 7 ? 6 : currentWeekday - 1;
          return selectedDays[dayIndex];
        }
        return false;
      default:
        return true;
    }
  }

  /// アラームを発火
  Future<void> triggerAlarm(Map<String, dynamic> alarm) async {
    if (isAlarmPlaying) {
      debugPrint('服用時間のアラーム既に再生中: ${alarm['name']}');
      return;
    }

    debugPrint('服用時間のアラーム開始: ${alarm['name']}');
    
    // 複数の安全チェックを実行
    if (!isMounted()) return;
    
    try {
      // 最終的なmountedチェック
      if (!isMounted()) return;
      
      triggerStateUpdate();
      isAlarmPlaying = true;
    } catch (e) {
      debugPrint('_triggerAlarm setState エラー: $e');
      return;
    }

    try {
      // 通知を表示
      await onShowAlarmNotification(alarm);
      
      // 服用時間のアラーム種類に応じた処理
      final alarmType = alarm['alarmType'] ?? 'sound';
      debugPrint('服用時間のアラーム種類: $alarmType');
      
      switch (alarmType) {
        case 'sound':
          // 音声のみ（ループ設定）
          debugPrint('音声服用時間のアラーム開始: $selectedAlarmSound');
          await playAlarmSound();
          break;
        case 'sound_vibration':
          // 音声＋バイブレーション（ループ設定）
          debugPrint('音声+バイブ服用時間のアラーム開始: $selectedAlarmSound');
          await playAlarmSound();
          startContinuousVibration();
          break;
        case 'vibration':
          // バイブレーションのみ（連続）
          debugPrint('バイブレーション服用時間のアラーム開始');
          startContinuousVibration();
          break;
        case 'silent':
          // サイレント（音もバイブもなし）
          debugPrint('サイレント服用時間のアラーム');
          break;
      }

      // 服用時間のアラーム停止ダイアログ
      onShowAlarmStopDialog();
    } catch (e) {
      debugPrint('服用時間のアラーム再生エラー: $e');
      
      // エラー時の安全な状態更新
      if (!isMounted()) return;
      
      try {
        // 最終的なmountedチェック
        if (!isMounted()) return;
        
        triggerStateUpdate();
        isAlarmPlaying = false;
      } catch (setStateError) {
        debugPrint('_triggerAlarm catch内 setState エラー: $setStateError');
      }
    }
  }

  /// アラーム音を再生
  Future<void> playAlarmSound() async {
    try {
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.setVolume(notificationVolume / 100.0);
      
      // 服用時間のアラーム音ファイルを再生（ループ）
      String soundFile = 'assets/sounds/$selectedAlarmSound.mp3';
      debugPrint('服用時間のアラーム音再生開始: $soundFile');
      
      try {
        await audioPlayer.play(AssetSource('sounds/$selectedAlarmSound.mp3'));
        debugPrint('服用時間のアラーム音再生成功');
      } catch (e) {
        debugPrint('服用時間のアラーム音ファイル再生エラー: $e');
        // フォールバック: デフォルト音を使用
        try {
          await audioPlayer.play(AssetSource('sounds/default.mp3'));
          debugPrint('デフォルト音再生開始');
        } catch (e2) {
          debugPrint('デフォルト音再生エラー: $e2');
        }
      }
    } catch (e) {
      debugPrint('服用時間のアラーム音設定エラー: $e');
    }
  }

  /// 連続バイブレーションを開始
  void startContinuousVibration() async {
    debugPrint('連続バイブレーション開始');
    try {
      if (await Vibration.hasVibrator() == true) {
        debugPrint('バイブレーション機能利用可能');
        // 即座にバイブレーションを開始
        await Vibration.vibrate(duration: 2000);
        // 連続バイブレーション用のタイマー（より頻繁に）
        vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
          if (isAlarmPlaying) {
            debugPrint('バイブレーション実行');
            try {
              await Vibration.vibrate(duration: 2000);
            } catch (e) {
              debugPrint('バイブレーションエラー: $e');
            }
          } else {
            timer.cancel();
            debugPrint('バイブレーション停止（服用時間のアラーム停止）');
          }
        });
      } else {
        debugPrint('バイブレーション機能利用不可');
      }
    } catch (e) {
      debugPrint('バイブレーション初期化エラー: $e');
    }
  }

  /// アラームを停止
  Future<void> stopAlarm() async {
    try {
      debugPrint('服用時間のアラーム停止開始');
      
      // 音声を停止
      await audioPlayer.stop();
      await audioPlayer.setReleaseMode(ReleaseMode.release);
      
      // バイブレーションを停止
      vibrationTimer?.cancel();
      vibrationTimer = null;
      
      // 通知をキャンセル
      // (通知は外部でキャンセルする必要があるため、コールバックで処理)
      
      // 現在鳴っているアラームのlastTriggeredを更新して重複実行を防ぐ
      final now = DateTime.now();
      // (アラームリストは外部で管理されるため、コールバックで処理)
      
      if (isMounted()) {
        triggerStateUpdate();
        isAlarmPlaying = false;
      }
      
      debugPrint('服用時間のアラーム停止完了');
    } catch (e) {
      debugPrint('服用時間のアラーム停止エラー: $e');
      
      // エラー時の安全な状態更新
      if (isMounted()) {
        try {
          if (isMounted()) {
            triggerStateUpdate();
            isAlarmPlaying = false;
          }
        } catch (setStateError) {
          debugPrint('_stopAlarm catch内 setState エラー: $setStateError');
        }
      }
    }
  }

  /// 破棄処理
  void dispose() {
    vibrationTimer?.cancel();
    vibrationTimer = null;
  }
}

