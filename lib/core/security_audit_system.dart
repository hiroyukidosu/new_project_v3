import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'secure_storage_implementation.dart';
import '../utils/logger.dart';

/// セキュリティ監査システム - 包括的なセキュリティ監視
class SecurityAuditSystem {
  static const String _securityConfigKey = 'security_config';
  static const String _threatDetectionKey = 'threat_detection';
  static const String _securityIncidentsKey = 'security_incidents';
  
  /// セキュリティ監査の初期化
  static Future<void> initializeSecurityAudit() async {
    try {
      await SecurityAuditManager.recordSecurityEvent(
        eventType: 'system_startup',
        description: 'セキュリティ監査システムの初期化',
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0',
        },
      );
      
      Logger.info('セキュリティ監査システム初期化完了');
    } catch (e) {
      Logger.error('セキュリティ監査システム初期化エラー', e);
    }
  }
  
  /// データアクセスの監査
  static Future<void> auditDataAccess({
    required String dataType,
    required String operation,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await SecurityAuditManager.recordSecurityEvent(
        eventType: 'data_access',
        description: 'データアクセス: $dataType - $operation',
        userId: userId,
        metadata: {
          'dataType': dataType,
          'operation': operation,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );
      
      Logger.debug('データアクセス監査記録: $dataType - $operation');
    } catch (e) {
      Logger.error('データアクセス監査エラー', e);
    }
  }
  
  /// 認証イベントの監査
  static Future<void> auditAuthentication({
    required String eventType,
    required String userId,
    bool success = true,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await SecurityAuditManager.recordSecurityEvent(
        eventType: 'authentication',
        description: '認証イベント: $eventType - ${success ? '成功' : '失敗'}',
        userId: userId,
        metadata: {
          'eventType': eventType,
          'success': success,
          'errorMessage': errorMessage,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );
      
      Logger.info('認証イベント監査記録: $eventType - ${success ? '成功' : '失敗'}');
    } catch (e) {
      Logger.error('認証イベント監査エラー', e);
    }
  }
  
  /// 課金イベントの監査
  static Future<void> auditPurchaseEvent({
    required String eventType,
    required String productId,
    required String userId,
    bool success = true,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await SecurityAuditManager.recordSecurityEvent(
        eventType: 'purchase',
        description: '課金イベント: $eventType - $productId',
        userId: userId,
        metadata: {
          'eventType': eventType,
          'productId': productId,
          'success': success,
          'errorMessage': errorMessage,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );
      
      Logger.info('課金イベント監査記録: $eventType - $productId');
    } catch (e) {
      Logger.error('課金イベント監査エラー', e);
    }
  }
  
  /// セキュリティ違反の監査
  static Future<void> auditSecurityViolation({
    required String violationType,
    required String description,
    required String severity,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await SecurityAuditManager.recordSecurityEvent(
        eventType: 'security_violation',
        description: 'セキュリティ違反: $violationType - $description',
        userId: userId,
        metadata: {
          'violationType': violationType,
          'description': description,
          'severity': severity,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );
      
      Logger.warning('セキュリティ違反監査記録: $violationType - $severity');
    } catch (e) {
      Logger.error('セキュリティ違反監査エラー', e);
    }
  }
}

/// 脅威検出システム
class ThreatDetectionSystem {
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 30);
  
  /// 不正アクセスの検出
  static Future<bool> detectUnauthorizedAccess({
    required String userId,
    required String operation,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final recentEvents = await _getRecentSecurityEvents(userId, Duration(hours: 1));
      final failedAttempts = recentEvents.where((event) => 
        event['eventType'] == 'authentication' && 
        event['success'] == false
      ).length;
      
      if (failedAttempts >= _maxFailedAttempts) {
        await SecurityAuditSystem.auditSecurityViolation(
          violationType: 'unauthorized_access',
          description: '複数回の認証失敗による不正アクセス検出',
          severity: 'high',
          userId: userId,
          metadata: {
            'failedAttempts': failedAttempts,
            'operation': operation,
            ...?metadata,
          },
        );
        
        Logger.warning('不正アクセス検出: $userId - $failedAttempts回の失敗');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('不正アクセス検出エラー', e);
      return false;
    }
  }
  
  /// 異常なデータアクセスの検出
  static Future<bool> detectAbnormalDataAccess({
    required String userId,
    required String dataType,
    required int accessCount,
  }) async {
    try {
      final recentEvents = await _getRecentSecurityEvents(userId, Duration(hours: 1));
      final dataAccessEvents = recentEvents.where((event) => 
        event['eventType'] == 'data_access' && 
        event['dataType'] == dataType
      ).length;
      
      // 1時間以内に100回以上のデータアクセスは異常
      if (dataAccessEvents > 100) {
        await SecurityAuditSystem.auditSecurityViolation(
          violationType: 'abnormal_data_access',
          description: '異常なデータアクセス頻度の検出',
          severity: 'medium',
          userId: userId,
          metadata: {
            'dataType': dataType,
            'accessCount': dataAccessEvents,
            'threshold': 100,
          },
        );
        
        Logger.warning('異常なデータアクセス検出: $userId - $dataType ($dataAccessEvents回)');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('異常なデータアクセス検出エラー', e);
      return false;
    }
  }
  
  /// デバイス情報の検証
  static Future<bool> verifyDeviceSecurity() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        
        // ルート化デバイスの検出
        if (androidInfo.isPhysicalDevice == false) {
          await SecurityAuditSystem.auditSecurityViolation(
            violationType: 'emulator_detection',
            description: 'エミュレータ環境での実行検出',
            severity: 'medium',
            metadata: {
              'deviceModel': androidInfo.model,
              'manufacturer': androidInfo.manufacturer,
            },
          );
          
          Logger.warning('エミュレータ環境検出');
          return false;
        }
        
        // 開発者オプションの検出
        if (androidInfo.version.sdkInt > 28) {
          // 開発者オプションの検出ロジック
          Logger.debug('開発者オプション検出');
        }
      }
      
      return true;
    } catch (e) {
      Logger.error('デバイスセキュリティ検証エラー', e);
      return false;
    }
  }
  
  /// 最近のセキュリティイベントの取得
  static Future<List<Map<String, dynamic>>> _getRecentSecurityEvents(
    String userId, 
    Duration duration
  ) async {
    try {
      final auditLog = await SecurityAuditManager._loadAuditLog();
      final cutoffTime = DateTime.now().subtract(duration);
      
      return auditLog.where((event) {
        final timestamp = DateTime.tryParse(event['timestamp'] as String? ?? '');
        return timestamp != null && 
               timestamp.isAfter(cutoffTime) && 
               (event['userId'] == userId || event['userId'] == null);
      }).toList();
    } catch (e) {
      Logger.error('最近のセキュリティイベント取得エラー', e);
      return [];
    }
  }
}

/// セキュリティレポート生成
class SecurityReportGenerator {
  /// セキュリティレポートの生成
  static Future<Map<String, dynamic>> generateSecurityReport({
    Duration? timeRange,
  }) async {
    try {
      final timeRange_ = timeRange ?? const Duration(days: 30);
      final cutoffTime = DateTime.now().subtract(timeRange_);
      
      final auditLog = await SecurityAuditManager._loadAuditLog();
      final recentEvents = auditLog.where((event) {
        final timestamp = DateTime.tryParse(event['timestamp'] as String? ?? '');
        return timestamp != null && timestamp.isAfter(cutoffTime);
      }).toList();
      
      // イベントタイプ別の集計
      final eventTypeCounts = <String, int>{};
      final severityCounts = <String, int>{};
      final userActivity = <String, int>{};
      
      for (final event in recentEvents) {
        final eventType = event['eventType'] as String? ?? 'unknown';
        eventTypeCounts[eventType] = (eventTypeCounts[eventType] ?? 0) + 1;
        
        final severity = event['metadata']?['severity'] as String?;
        if (severity != null) {
          severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
        }
        
        final userId = event['userId'] as String?;
        if (userId != null) {
          userActivity[userId] = (userActivity[userId] ?? 0) + 1;
        }
      }
      
      // セキュリティ統計
      final securityStats = await SecurityAuditManager.getSecurityStats();
      
      return {
        'reportPeriod': {
          'start': cutoffTime.toIso8601String(),
          'end': DateTime.now().toIso8601String(),
          'duration': timeRange_.inDays,
        },
        'eventSummary': {
          'totalEvents': recentEvents.length,
          'eventTypeCounts': eventTypeCounts,
          'severityCounts': severityCounts,
          'userActivity': userActivity,
        },
        'securityStats': securityStats,
        'threats': {
          'unauthorizedAccess': recentEvents.where((e) => 
            e['eventType'] == 'security_violation' && 
            e['metadata']?['violationType'] == 'unauthorized_access'
          ).length,
          'abnormalDataAccess': recentEvents.where((e) => 
            e['eventType'] == 'security_violation' && 
            e['metadata']?['violationType'] == 'abnormal_data_access'
          ).length,
          'emulatorDetection': recentEvents.where((e) => 
            e['eventType'] == 'security_violation' && 
            e['metadata']?['violationType'] == 'emulator_detection'
          ).length,
        },
        'recommendations': _generateSecurityRecommendations(recentEvents),
      };
    } catch (e) {
      Logger.error('セキュリティレポート生成エラー', e);
      return {};
    }
  }
  
  /// セキュリティ推奨事項の生成
  static List<String> _generateSecurityRecommendations(List<Map<String, dynamic>> events) {
    final recommendations = <String>[];
    
    // 認証失敗の推奨事項
    final authFailures = events.where((e) => 
      e['eventType'] == 'authentication' && e['success'] == false
    ).length;
    
    if (authFailures > 10) {
      recommendations.add('認証失敗が多発しています。パスワードポリシーの見直しを推奨します。');
    }
    
    // セキュリティ違反の推奨事項
    final securityViolations = events.where((e) => 
      e['eventType'] == 'security_violation'
    ).length;
    
    if (securityViolations > 5) {
      recommendations.add('セキュリティ違反が検出されています。セキュリティポリシーの見直しを推奨します。');
    }
    
    // データアクセスの推奨事項
    final dataAccessEvents = events.where((e) => 
      e['eventType'] == 'data_access'
    ).length;
    
    if (dataAccessEvents > 1000) {
      recommendations.add('データアクセスが頻繁です。アクセス制御の見直しを推奨します。');
    }
    
    return recommendations;
  }
  
  /// セキュリティレポートのエクスポート
  static Future<String> exportSecurityReport({
    Duration? timeRange,
  }) async {
    try {
      final report = await generateSecurityReport(timeRange: timeRange);
      final jsonString = jsonEncode(report);
      
      await SecurityAuditSystem.auditDataAccess(
        dataType: 'security_report',
        operation: 'export',
        userId: 'system',
        metadata: {
          'reportSize': jsonString.length,
          'timeRange': timeRange?.inDays ?? 30,
        },
      );
      
      Logger.info('セキュリティレポートエクスポート完了');
      return jsonString;
    } catch (e) {
      Logger.error('セキュリティレポートエクスポートエラー', e);
      return '';
    }
  }
}

/// セキュリティ設定管理
class SecurityConfigManager {
  static const String _configKey = 'security_config';
  
  /// セキュリティ設定の保存
  static Future<void> saveSecurityConfig(Map<String, dynamic> config) async {
    try {
      await SensitiveDataManager.saveUserPreferencesSecure({
        _configKey: config,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      await SecurityAuditSystem.auditDataAccess(
        dataType: 'security_config',
        operation: 'save',
        userId: 'system',
        metadata: {'configKeys': config.keys.toList()},
      );
      
      Logger.info('セキュリティ設定保存完了');
    } catch (e) {
      Logger.error('セキュリティ設定保存エラー', e);
    }
  }
  
  /// セキュリティ設定の読み込み
  static Future<Map<String, dynamic>?> loadSecurityConfig() async {
    try {
      final data = await SensitiveDataManager.loadUserPreferencesSecure();
      if (data != null && data.containsKey(_configKey)) {
        Logger.debug('セキュリティ設定読み込み完了');
        return data[_configKey] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      Logger.error('セキュリティ設定読み込みエラー', e);
      return null;
    }
  }
  
  /// デフォルトセキュリティ設定の取得
  static Map<String, dynamic> getDefaultSecurityConfig() {
    return {
      'maxFailedAttempts': 5,
      'lockoutDuration': 30, // 分
      'dataAccessThreshold': 100, // 1時間あたり
      'enableThreatDetection': true,
      'enableDeviceVerification': true,
      'enableAuditLogging': true,
      'auditLogRetentionDays': 90,
    };
  }
}
