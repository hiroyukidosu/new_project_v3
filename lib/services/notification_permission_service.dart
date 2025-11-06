// 通知権限管理サービス
// 通知権限の要求、確認、管理を安全に処理します

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app_preferences.dart';
import '../utils/logger.dart';

/// 通知権限管理サービス
/// 通知権限の要求と状態管理を提供します
class NotificationPermissionService {
  static const String _permissionRequestedKey = 'notification_permission_requested';
  static const String _permissionDeniedKey = 'notification_permission_denied';
  static const String _permissionDeniedPermanentlyKey = 'notification_permission_denied_permanently';
  
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  /// 通知権限の状態を確認
  static Future<PermissionStatus> checkPermission() async {
    try {
      final status = await Permission.notification.status;
      Logger.debug('通知権限状態: $status');
      return status;
    } catch (e) {
      Logger.error('通知権限確認エラー', e);
      return PermissionStatus.denied;
    }
  }
  
  /// 通知権限を要求
  static Future<bool> requestPermission() async {
    try {
      // 既に許可されている場合はスキップ
      final currentStatus = await checkPermission();
      if (currentStatus.isGranted) {
        Logger.debug('通知権限は既に許可されています');
        return true;
      }
      
      // 権限を要求
      final status = await Permission.notification.request();
      
      // 要求済みフラグを設定
      await AppPreferences.saveBool(_permissionRequestedKey, true);
      
      // 永続的に拒否された場合のフラグ
      if (status.isPermanentlyDenied) {
        await AppPreferences.saveBool(_permissionDeniedPermanentlyKey, true);
        Logger.warning('通知権限が永続的に拒否されました');
      } else if (status.isDenied) {
        await AppPreferences.saveBool(_permissionDeniedKey, true);
        Logger.warning('通知権限が拒否されました');
      } else {
        // 許可された場合はフラグをクリア
        await AppPreferences.saveBool(_permissionDeniedKey, false);
        await AppPreferences.saveBool(_permissionDeniedPermanentlyKey, false);
      }
      
      Logger.info('通知権限要求結果: $status');
      return status.isGranted;
    } catch (e) {
      Logger.error('通知権限要求エラー', e);
      return false;
    }
  }
  
  /// 通知権限が許可されているか
  static Future<bool> isPermissionGranted() async {
    final status = await checkPermission();
    return status.isGranted;
  }
  
  /// 通知権限が永続的に拒否されているか
  static Future<bool> isPermissionPermanentlyDenied() async {
    final status = await checkPermission();
    return status.isPermanentlyDenied;
  }
  
  /// 通知権限が要求済みか
  static bool hasRequestedPermission() {
    return AppPreferences.getBool(_permissionRequestedKey) ?? false;
  }
  
  /// 通知権限が以前に拒否されたか
  static bool wasPermissionDenied() {
    return AppPreferences.getBool(_permissionDeniedKey) ?? false;
  }
  
  /// 通知権限が以前に永続的に拒否されたか
  static bool wasPermissionPermanentlyDenied() {
    return AppPreferences.getBool(_permissionDeniedPermanentlyKey) ?? false;
  }
  
  /// 設定アプリを開く（永続的に拒否された場合）
  static Future<bool> openAppSettings() async {
    try {
      final opened = await openAppSettings();
      Logger.info('設定アプリを開きました');
      return opened;
    } catch (e) {
      Logger.error('設定アプリオープンエラー', e);
      return false;
    }
  }
  
  /// 通知権限の初期化（アプリ起動時）
  static Future<void> initialize() async {
    try {
      // 通知プラグインの初期化
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // 通知タップ時の処理
          Logger.debug('通知タップ: ${details.id}');
        },
      );
      
      Logger.info('通知プラグイン初期化完了');
    } catch (e) {
      Logger.error('通知プラグイン初期化エラー', e);
    }
  }
  
  /// 通知権限の状態情報を取得
  static Future<Map<String, dynamic>> getPermissionInfo() async {
    try {
      final status = await checkPermission();
      final isGranted = status.isGranted;
      final isPermanentlyDenied = status.isPermanentlyDenied;
      final hasRequested = hasRequestedPermission();
      final wasDenied = wasPermissionDenied();
      final wasPermanentlyDenied = wasPermissionPermanentlyDenied();
      
      return {
        'status': status.toString(),
        'isGranted': isGranted,
        'isPermanentlyDenied': isPermanentlyDenied,
        'hasRequested': hasRequested,
        'wasDenied': wasDenied,
        'wasPermanentlyDenied': wasPermanentlyDenied,
        'canRequest': !isPermanentlyDenied,
        'needsSettings': isPermanentlyDenied,
      };
    } catch (e) {
      Logger.error('通知権限情報取得エラー', e);
      return {
        'error': e.toString(),
      };
    }
  }
  
  /// 権限要求フラグのリセット（テスト用）
  static Future<void> resetRequestFlag() async {
    await AppPreferences.remove(_permissionRequestedKey);
    await AppPreferences.remove(_permissionDeniedKey);
    await AppPreferences.remove(_permissionDeniedPermanentlyKey);
  }
}

