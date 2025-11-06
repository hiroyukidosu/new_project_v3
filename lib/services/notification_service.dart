// lib/services/notification_service.dart
// 通知関連サービス

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import 'storage_service.dart';
import 'audio_service.dart';

// バックグラウンド通知ハンドラー（トップレベル関数）
@pragma('vm:entry-point')
void notificationActionHandler(NotificationResponse response) async {
  if (response.actionId == 'stop') {
    // バックグラウンドで即座にアラームを停止
    await _stopAlarmFromBackground(response);
    
    // 停止フラグも設定（念のため）
    await _setAlarmStopFlag();
  }
}

// バックグラウンドでのアラーム停止処理
Future<void> _stopAlarmFromBackground(NotificationResponse response) async {
  try {
    // 1. 音声とバイブレーションを即座に停止
    // AudioServiceはstaticなので、直接アクセス可能
    await AudioService.stopAlarm();
    
    // 2. 通知をキャンセル
    final notifications = FlutterLocalNotificationsPlugin();
    if (response.id != null) {
      try {
        await notifications.cancel(response.id!);
      } catch (e) {
        // 個別キャンセル失敗時は全キャンセルを試行
        try {
          await notifications.cancelAll();
        } catch (e2) {
          // エラーは無視
        }
      }
    } else {
      // IDが不明な場合は全通知をキャンセル
      try {
        await notifications.cancelAll();
      } catch (e) {
        // エラーは無視
      }
    }
  } catch (e) {
    // エラーは無視（ログに記録するだけ）
    debugPrint('バックグラウンドアラーム停止エラー: $e');
  }
}

// バックグラウンドでの停止フラグ設定
Future<void> _setAlarmStopFlag() async {
  try {
    await StorageService.initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_should_stop', true);
    await prefs.setInt('alarm_stop_timestamp', DateTime.now().millisecondsSinceEpoch);
  } catch (e) {
    // エラーは無視
  }
}

/// 通知サービス
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Function(NotificationResponse)? _onNotificationTappedCallback;
  static Function(String)? _onStopAlarmCallback;

  /// 通知を初期化
  static Future<void> initialize(
    Function(NotificationResponse) onNotificationTapped,
    Function(String)? onStopAlarm,
  ) async {
    if (_initialized) return;

    _onNotificationTappedCallback = onNotificationTapped;
    _onStopAlarmCallback = onStopAlarm; // 使用しないが互換性のために保持

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

    // 初期化（バックグラウンドハンドラーも設定）
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        try {
          // 停止アクションの処理（フォアグラウンドでも動作するように）
          if (response.actionId == 'stop') {
            // 1. 即座にアラームを停止（音声・バイブレーション・通知）
            try {
              await AudioService.stopAlarm();
            } catch (e) {
              debugPrint('フォアグラウンドアラーム停止エラー（AudioService）: $e');
            }
            
            // 2. 通知を確実にキャンセル（特定IDと全キャンセルの両方を試行）
            if (response.id != null) {
              try {
                await _notifications.cancel(response.id!);
              } catch (e) {
                // 個別キャンセル失敗時は全キャンセルを試行
                try {
                  await _notifications.cancelAll();
                } catch (e2) {
                  // エラーは無視
                }
              }
            } else {
              // IDが不明な場合は全通知をキャンセル
              try {
                await _notifications.cancelAll();
              } catch (e) {
                // エラーは無視
              }
            }
            
            // 3. バックグラウンドでも停止フラグを設定（アプリがバックグラウンドの時用）
            await _setAlarmStopFlag();
            
            // 4. フォアグラウンドでもコールバックを呼び出してアラームを停止（コミットbb37ef5の実装に合わせて）
            try {
              if (_onNotificationTappedCallback != null) {
                _onNotificationTappedCallback!(response);
              } else {
                onNotificationTapped(response);
              }
            } catch (e) {
              // コールバックエラーは無視
              debugPrint('通知コールバックエラー: $e');
            }
            return;
          }
          // その他の通知応答はコールバックを呼び出す
          try {
            if (_onNotificationTappedCallback != null) {
              _onNotificationTappedCallback!(response);
            } else {
              onNotificationTapped(response);
            }
          } catch (e) {
            // コールバックエラーは無視
          }
        } catch (e) {
          // 全体のエラーハンドリング（予期しないエラーを捕捉）
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationActionHandler,
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
    
    // 停止アクションを定義（アプリを開くように設定）
    const stopAction = AndroidNotificationAction(
      'stop',
      '停止',
      showsUserInterface: true,  // アプリを開く
      cancelNotification: true,
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ongoing: false,  // 5秒後に自動的に消えるように変更
      autoCancel: true,  // 通知をタップした時に自動的に消えるように変更
      playSound: playSound,
      enableVibration: enableVibration,
      actions: [stopAction],
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

  /// 通知をキャンセル
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// すべての通知をキャンセル
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
