// lib/services/notification_service.dart
// 通知関連サービス

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm_model.dart';

/// 通知サービス
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Function(NotificationResponse)? _onNotificationTappedCallback;

  /// 通知を初期化
  static Future<void> initialize(Function(NotificationResponse) onNotificationTapped) async {
    if (_initialized) return;

    _onNotificationTappedCallback = onNotificationTapped;

    // 権限リクエスト
    await _requestPermissions();

    // Android初期化設定
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS初期化設定
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 初期化
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onNotificationTapped,
    );

    // チャンネル作成
    await createNotificationChannels();

    _initialized = true;
  }

  /// 権限リクエスト
  static Future<void> _requestPermissions() async {
    try {
      await Permission.notification.request();
    } catch (e) {
      // エラーは無視
    }
  }

  /// 通知チャンネルを作成
  static Future<void> createNotificationChannels() async {
    // アラームチャンネル（音声+バイブレーション）
    const alarmChannel = AndroidNotificationChannel(
      'alarm_channel',
      '服用時間のアラーム',
      description: '服用時間のアラーム通知',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // バイブレーションチャンネル
    const vibrationChannel = AndroidNotificationChannel(
      'vibration_channel',
      'バイブ',
      description: 'バイブ通知',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
    );

    // サイレントチャンネル
    const silentChannel = AndroidNotificationChannel(
      'silent_channel',
      'サイレント',
      description: 'サイレント通知',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    );

    // チャンネル作成
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(vibrationChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(silentChannel);
  }

  /// アラーム通知を表示
  static Future<void> showAlarmNotification({
    required Alarm alarm,
    required String selectedNotificationType,
  }) async {
    if (!_initialized) {
      return;
    }

    final alarmType = alarm.alarmType.isEmpty ? selectedNotificationType : alarm.alarmType;
    
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

    await _notifications.show(
      alarm.hashCode,
      alarm.name,
      'お薬を飲む時間になりました - 通知をタップしてアプリを開く',
      details,
      payload: 'alarm_${alarm.hashCode}',
    );
  }

  /// 通知詳細を取得
  static NotificationDetails getNotificationDetails(String type) {
    switch (type) {
      case 'sound':
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            '服用時間のアラーム',
            channelDescription: '服用時間のアラーム通知',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        );
      case 'sound_vibration':
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            '服用時間のアラーム',
            channelDescription: '服用時間のアラーム通知',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        );
      case 'vibration':
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'vibration_channel',
            'バイブ',
            channelDescription: 'バイブ通知',
            importance: Importance.max,
            priority: Priority.high,
            playSound: false,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        );
      case 'silent':
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'silent_channel',
            'サイレント',
            channelDescription: 'サイレント通知',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        );
      default:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            '服用時間のアラーム',
            channelDescription: '服用時間のアラーム通知',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        );
    }
  }

  /// 通知メッセージを取得
  static String getNotificationMessage(String type) {
    switch (type) {
      case 'sound':
        return '服用時間のアラームが鳴っています（音のみ）';
      case 'sound_vibration':
        return '服用時間のアラームが鳴っています（音+バイブ）';
      case 'vibration':
        return '服用時間のアラームが鳴っています（バイブ）';
      case 'silent':
        return 'サイレント通知です';
      default:
        return '服用時間のアラーム通知です';
    }
  }
}
