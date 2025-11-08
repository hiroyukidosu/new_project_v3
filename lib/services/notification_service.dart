// lib/services/notification_service.dart
// 通知関連サービス

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import 'storage_service.dart';

// バックグラウンド通知ハンドラー（トップレベル関数）
@pragma('vm:entry-point')
void notificationActionHandler(NotificationResponse response) async {
  if (response.actionId == 'stop') {
    // バックグラウンドで停止フラグを設定
    await _setAlarmStopFlag();
    // 通知をキャンセル
    try {
      final notifications = FlutterLocalNotificationsPlugin();
      if (response.id != null) {
        await notifications.cancel(response.id!);
      }
      // すべての通知をキャンセル（念のため）
      await notifications.cancelAll();
    } catch (e, stackTrace) {
      // Crashlyticsに記録（非致命的）
      try {
        FirebaseCrashlytics.instance.log('通知キャンセルエラー: cancelAllNotifications');
        FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
    }
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
            // バックグラウンドでも停止フラグを設定（アプリがバックグラウンドの時用）
            await _setAlarmStopFlag();
            // 通知をキャンセル（IDが指定されている場合）
            if (response.id != null) {
              try {
                await _notifications.cancel(response.id!);
              } catch (e, stackTrace) {
                // Crashlyticsに記録（非致命的）
                try {
                  FirebaseCrashlytics.instance.log('通知キャンセルエラー: onDidReceiveNotificationResponse');
                  FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
                } catch (_) {
                  // Crashlytics記録失敗時は無視
                }
              }
            }
            // すべての通知をキャンセル（念のため）
            try {
              await _notifications.cancelAll();
            } catch (e, stackTrace) {
              // Crashlyticsに記録（非致命的）
              try {
                FirebaseCrashlytics.instance.log('通知全キャンセルエラー: onDidReceiveNotificationResponse');
                FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
              } catch (_) {
                // Crashlytics記録失敗時は無視
              }
            }
            // フォアグラウンドでもコールバックを呼び出してアラームを停止（コミットbb37ef5の実装に合わせて）
            try {
              if (_onNotificationTappedCallback != null) {
                _onNotificationTappedCallback!(response);
              } else {
                onNotificationTapped(response);
              }
            } catch (e, stackTrace) {
              // Crashlyticsに記録
              try {
                FirebaseCrashlytics.instance.log('通知コールバックエラー: onDidReceiveNotificationResponse');
                FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
              } catch (_) {
                // Crashlytics記録失敗時は無視
              }
            }
            return;
          }
          // その他の通知応答（通知タップ時など）も通知をキャンセル
          if (response.id != null) {
            try {
              await _notifications.cancel(response.id!);
            } catch (e, stackTrace) {
              // Crashlyticsに記録（非致命的）
              try {
                FirebaseCrashlytics.instance.log('通知キャンセルエラー: onDidReceiveNotificationResponse (other)');
                FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
              } catch (_) {
                // Crashlytics記録失敗時は無視
              }
            }
          }
          // コールバックを呼び出す
          try {
            if (_onNotificationTappedCallback != null) {
              _onNotificationTappedCallback!(response);
            } else {
              onNotificationTapped(response);
            }
          } catch (e, stackTrace) {
            // Crashlyticsに記録
            try {
              FirebaseCrashlytics.instance.log('通知コールバックエラー: onDidReceiveNotificationResponse (other)');
              FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
            } catch (_) {
              // Crashlytics記録失敗時は無視
            }
          }
        } catch (e, stackTrace) {
          // Crashlyticsに記録（全体のエラーハンドリング）
          try {
            FirebaseCrashlytics.instance.log('通知サービス全体エラー: onDidReceiveNotificationResponse');
            FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
          } catch (_) {
            // Crashlytics記録失敗時は無視
          }
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
    } catch (e, stackTrace) {
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('通知権限リクエストエラー: _requestPermissions');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
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
      ongoing: false,  // 継続通知ではない（自動的に消える）
      autoCancel: true,  // 通知をタップした時に自動的に消える
      playSound: playSound,
      enableVibration: enableVibration,
      actions: [stopAction],
      channelShowBadge: false,  // バッジを表示しない
      onlyAlertOnce: false,  // 毎回アラートを表示
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
