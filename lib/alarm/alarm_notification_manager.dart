// lib/alarm/alarm_notification_manager.dart
// アラーム通知管理機能を分離

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// アラーム通知管理クラス
class AlarmNotificationManager {
  final FlutterLocalNotificationsPlugin notifications;
  final Function() onStopAlarm;
  final Function() onSnoozeAlarm;
  final BuildContext? context;
  final bool Function()? isMounted;

  AlarmNotificationManager({
    required this.notifications,
    required this.onStopAlarm,
    required this.onSnoozeAlarm,
    this.context,
    this.isMounted,
  });

  /// 通知を初期化
  Future<void> initialize() async {
    try {
      // 通知権限のみを要求（他の権限は必要に応じて後で要求）
      await Permission.notification.request();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 通知チャンネルを作成
      await createNotificationChannels();
      debugPrint('通知初期化完了');
    } catch (e) {
      debugPrint('通知初期化エラー: $e');
    }
  }

  /// 通知チャンネルを作成
  Future<void> createNotificationChannels() async {
    // アラーム用チャンネル（スマホのデフォルト音を使用）
    const alarmChannel = AndroidNotificationChannel(
      'alarm_channel',
      '服用時間のアラーム',
      description: '服用時間のアラーム通知',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('default'),
    );

    // バイブレーション用チャンネル
    const vibrationChannel = AndroidNotificationChannel(
      'vibration_channel',
      'バイブ',
      description: 'バイブ通知',
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
    );

    // サイレント用チャンネル
    const silentChannel = AndroidNotificationChannel(
      'silent_channel',
      'サイレント',
      description: 'サイレント通知',
      importance: Importance.min,
      playSound: false,
      enableVibration: false,
    );

    final androidPlugin = notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(alarmChannel);
    await androidPlugin?.createNotificationChannel(vibrationChannel);
    await androidPlugin?.createNotificationChannel(silentChannel);
  }

  /// 通知タップ時の処理
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('通知がタップされました: ${response.payload}, actionId: ${response.actionId}');
    
    // UIスレッドで確実に実行されるようにする
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        try {
          if (response.actionId == 'stop') {
            await onStopAlarm();
          } else if (response.actionId == 'snooze') {
            await onSnoozeAlarm();
          } else {
            // 通知自体をタップした場合も停止
            await onStopAlarm();
          }
        } catch (e) {
          debugPrint('通知タップ処理エラー: $e');
          // エラー時でもアラームを停止しようとする
          if (isMounted?.call() ?? false) {
            try {
              await onStopAlarm();
            } catch (stopError) {
              debugPrint('_stopAlarm呼び出しエラー: $stopError');
            }
          }
        }
      });
    });
  }

  /// アラーム通知を表示
  Future<void> showAlarmNotification(
    Map<String, dynamic> alarm,
    String selectedNotificationType,
  ) async {
    final alarmType = alarm['alarmType'] ?? selectedNotificationType;
    
    // 服用時間のアラーム種類に応じてチャンネルと設定を選択
    String channelId;
    String channelName;
    String channelDescription;
    bool playSound;
    bool enableVibration;
    
    switch (alarmType) {
      case 'sound':
        channelId = 'alarm_channel';
        channelName = '服用時間のアラーム';
        channelDescription = '服用時間のアラーム通知';
        playSound = true;
        enableVibration = false;
        break;
      case 'sound_vibration':
        channelId = 'alarm_channel';
        channelName = '服用時間のアラーム';
        channelDescription = '服用時間のアラーム通知';
        playSound = true;
        enableVibration = true;
        break;
      case 'vibration':
        channelId = 'vibration_channel';
        channelName = 'バイブ';
        channelDescription = 'バイブ通知';
        playSound = false;
        enableVibration = true;
        break;
      case 'silent':
        channelId = 'silent_channel';
        channelName = 'サイレント';
        channelDescription = 'サイレント通知';
        playSound = false;
        enableVibration = false;
        break;
      default:
        channelId = 'alarm_channel';
        channelName = '服用時間のアラーム';
        channelDescription = '服用時間のアラーム通知';
        playSound = true;
        enableVibration = false;
    }
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      // actions パラメータを削除（通知とスヌーズボタンを消す）
      ongoing: true,
      autoCancel: false,
      playSound: playSound,
      enableVibration: enableVibration,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      categoryIdentifier: 'alarm_category',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notifications.show(
      alarm.hashCode,
      alarm['name'] as String,
      'お薬を飲む時間になりました - 通知をタップしてアプリを開く',
      details,
      payload: 'alarm_${alarm.hashCode}',
    );
  }

  /// 通知をキャンセル
  Future<void> cancelAll() async {
    await notifications.cancelAll();
  }
}

