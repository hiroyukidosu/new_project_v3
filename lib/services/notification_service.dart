// Dart core imports
import 'dart:io';

// Flutter core imports
import 'package:flutter/material.dart';

// Third-party package imports
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

// Local imports
import '../models/medication_info.dart';
import '../utils/constants.dart';

// 通知管理サービス
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      tz.initializeTimeZones();
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
        },
      );
      if ((initialized ?? false) && Platform.isAndroid) {
        final channels = [
          const AndroidNotificationChannel(
            'medication_sound',
            '服用アラーム',
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
      // 既存の通知をすべてキャンセル
      await _plugin.cancelAll();
      int notificationId = 1;
      final now = DateTime.now();
      
      // medicationDataの各エントリに対して通知をスケジュール
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
            
            // 過去の日時はスケジュールしない
            if (scheduledDate.isAfter(DateTime.now())) {
              final medicines = entry.value[timeSlot]?.medicine ?? '';
              final displayMedicines = medicines.isNotEmpty ? medicines : '薬';
          
              const androidDetails = AndroidNotificationDetails(
                'medication_sound',
                '服用アラーム',
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
          
              // zonedScheduleを使用して正確なスケジュール
              await _plugin.zonedSchedule(
                notificationId++,
                '服用アラーム',
                '$displayMedicines を服用しましょう',
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
    }
  }
}
