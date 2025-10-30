import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/medication_info.dart';
import '../models/notification_types.dart';

/// 通知サービス
/// アプリ通知の設定・管理を行う
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
     
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.request();
        if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
          if (notificationStatus.isPermanentlyDenied) await openAppSettings();
          return false;
        }
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      }
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      
      final initialized = await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // 通知タップ時の処理
        },
      );
      
      if ((initialized ?? false) && Platform.isAndroid) {
        final channels = [
          const AndroidNotificationChannel(
            'medication_sound',
            '薬物アラーム',
            description: '服薬時間の通知',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        ];
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        for (final channel in channels) {
          await androidPlugin?.createNotificationChannel(channel);
        }
      }
      
      _isInitialized = initialized ?? false;
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> scheduleNotifications(
    Map<String, List<TimeOfDay>> notificationTimes,
    Map<String, Map<String, MedicationInfo>> medicationData,
    Map<String, NotificationType> notificationTypes,
  ) async {
    if (!_isInitialized) return;
    try {
      // 既存の通知を全てキャンセル
      await _plugin.cancelAll();
      int notificationId = 1;
      final now = DateTime.now();
      
      // medicationDataの全てのエントリーに対して通知をスケジュール
      for (final entry in medicationData.entries) {
        final dateStr = entry.key;
        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          
        for (final timeSlot in notificationTimes.keys) {
          final times = notificationTimes[timeSlot] ?? [];
          
          for (final time in times) {
            var scheduledDate = DateTime(
              date.year, date.month, date.day, 
              time.hour, time.minute
            );
            
            // 未来の日付・時刻のみスケジュール
            if (scheduledDate.isAfter(DateTime.now())) {
              final medicines = entry.value[timeSlot]?.medicine ?? '';
              final displayMedicines = medicines.isNotEmpty ? medicines : '薬';
          
              const androidDetails = AndroidNotificationDetails(
                'medication_sound',
                '薬物アラーム',
                channelDescription: '服薬時間の通知',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                icon: '@mipmap/ic_launcher',
                autoCancel: true,
                ongoing: false,
                actions: [
                  AndroidNotificationAction(
                    'stop_alarm',
                    '停止',
                    cancelNotification: true,
                  ),
                ],
              );
          
              const iosDetails = DarwinNotificationDetails(
                sound: 'default',
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              );
          
              final notificationDetails = NotificationDetails(
                android: androidDetails, 
                iOS: iosDetails,
              );
          
              // ZonedScheduleを使用して正確な時刻にスケジュール
              await _plugin.zonedSchedule(
                notificationId++,
                '薬物アラーム',
                '$displayMedicines を飲む時間です',
                tz.TZDateTime.from(scheduledDate, tz.local),
                notificationDetails,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                uiLocalNotificationDateInterpretation: 
                  UILocalNotificationDateInterpretation.absoluteTime,
              );
            }
          }
        }
      }
    } catch (e) {
      // エラー処理
    }
  }
}
