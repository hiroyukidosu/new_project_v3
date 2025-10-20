import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_encryption.dart';
import '../utils/logger.dart';

/// セキュアストレージの実装 - 機密データの安全な管理
class SecureStorageImplementation {
  static const String _securePrefix = 'secure_';
  static const String _backupPrefix = 'backup_secure_';
  static const String _integrityPrefix = 'integrity_';
  
  /// セキュアなデータ保存
  static Future<void> saveSecureData(String key, String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // データの暗号化
      final encryptedData = DataEncryption._encryptData(data);
      
      // 整合性チェック用のハッシュ
      final integrityHash = _calculateIntegrityHash(data);
      
      // セキュアデータの保存
      await prefs.setString('$_securePrefix$key', encryptedData);
      
      // バックアップの保存
      await prefs.setString('$_backupPrefix$key', encryptedData);
      
      // 整合性ハッシュの保存
      await prefs.setString('$_integrityPrefix$key', integrityHash);
      
      Logger.debug('セキュアデータ保存完了: $key');
    } catch (e) {
      Logger.error('セキュアデータ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// セキュアなデータ読み込み
  static Future<String?> loadSecureData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // メインデータの読み込み
      String? encryptedData = prefs.getString('$_securePrefix$key');
      
      // メインデータが読み込めない場合はバックアップから読み込み
      if (encryptedData == null) {
        Logger.warning('メインデータの読み込みに失敗、バックアップから読み込み: $key');
        encryptedData = prefs.getString('$_backupPrefix$key');
      }
      
      if (encryptedData == null) {
        Logger.warning('セキュアデータが見つかりません: $key');
        return null;
      }
      
      // データの復号化
      final decryptedData = DataEncryption._decryptData(encryptedData);
      
      // 整合性チェック
      final storedHash = prefs.getString('$_integrityPrefix$key');
      if (storedHash != null) {
        final calculatedHash = _calculateIntegrityHash(decryptedData);
        if (storedHash != calculatedHash) {
          Logger.warning('データの整合性チェックに失敗: $key');
          return null;
        }
      }
      
      Logger.debug('セキュアデータ読み込み完了: $key');
      return decryptedData;
    } catch (e) {
      Logger.error('セキュアデータ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// セキュアなJSONデータ保存
  static Future<void> saveSecureJson(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      await saveSecureData(key, jsonString);
      Logger.debug('セキュアJSONデータ保存完了: $key');
    } catch (e) {
      Logger.error('セキュアJSONデータ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// セキュアなJSONデータ読み込み
  static Future<Map<String, dynamic>?> loadSecureJson(String key) async {
    try {
      final jsonString = await loadSecureData(key);
      if (jsonString == null) {
        return null;
      }
      
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      Logger.debug('セキュアJSONデータ読み込み完了: $key');
      return data;
    } catch (e) {
      Logger.error('セキュアJSONデータ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// セキュアデータの削除
  static Future<void> deleteSecureData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_securePrefix$key');
      await prefs.remove('$_backupPrefix$key');
      await prefs.remove('$_integrityPrefix$key');
      Logger.debug('セキュアデータ削除完了: $key');
    } catch (e) {
      Logger.error('セキュアデータ削除エラー: $key', e);
    }
  }
  
  /// 全セキュアデータの削除
  static Future<void> deleteAllSecureData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_securePrefix) || 
            key.startsWith(_backupPrefix) || 
            key.startsWith(_integrityPrefix)) {
          await prefs.remove(key);
        }
      }
      
      Logger.info('全セキュアデータ削除完了');
    } catch (e) {
      Logger.error('全セキュアデータ削除エラー', e);
    }
  }
  
  /// 整合性ハッシュの計算
  static String _calculateIntegrityHash(String data) {
    final bytes = utf8.encode(data);
    int hash = 0;
    for (final byte in bytes) {
      hash = ((hash << 5) - hash + byte) & 0xffffffff;
    }
    return hash.toString();
  }
  
  /// セキュアデータの統計
  static Future<Map<String, dynamic>> getSecureDataStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int secureDataCount = 0;
      int backupDataCount = 0;
      int integrityDataCount = 0;
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_securePrefix)) {
          secureDataCount++;
          final data = prefs.getString(key);
          if (data != null) {
            totalSize += data.length;
          }
        } else if (key.startsWith(_backupPrefix)) {
          backupDataCount++;
        } else if (key.startsWith(_integrityPrefix)) {
          integrityDataCount++;
        }
      }
      
      return {
        'secureDataCount': secureDataCount,
        'backupDataCount': backupDataCount,
        'integrityDataCount': integrityDataCount,
        'totalSize': totalSize,
        'totalSizeKB': (totalSize / 1024).round(),
        'totalSizeMB': (totalSize / (1024 * 1024)).round(),
      };
    } catch (e) {
      Logger.error('セキュアデータ統計取得エラー', e);
      return {};
    }
  }
}

/// 機密データの分類管理
class SensitiveDataManager {
  static const String _medicationDataKey = 'medication_data_secure';
  static const String _userPreferencesKey = 'user_preferences_secure';
  static const String _purchaseDataKey = 'purchase_data_secure';
  static const String _alarmDataKey = 'alarm_data_secure';
  static const String _statisticsKey = 'statistics_secure';
  
  /// 服用データのセキュア保存
  static Future<void> saveMedicationDataSecure(Map<String, dynamic> data) async {
    try {
      await SecureStorageImplementation.saveSecureJson(_medicationDataKey, data);
      Logger.info('服用データのセキュア保存完了');
    } catch (e) {
      Logger.error('服用データのセキュア保存エラー', e);
      rethrow;
    }
  }
  
  /// 服用データのセキュア読み込み
  static Future<Map<String, dynamic>?> loadMedicationDataSecure() async {
    try {
      final data = await SecureStorageImplementation.loadSecureJson(_medicationDataKey);
      if (data != null) {
        Logger.info('服用データのセキュア読み込み完了');
      }
      return data;
    } catch (e) {
      Logger.error('服用データのセキュア読み込みエラー', e);
      return null;
    }
  }
  
  /// ユーザー設定のセキュア保存
  static Future<void> saveUserPreferencesSecure(Map<String, dynamic> data) async {
    try {
      await SecureStorageImplementation.saveSecureJson(_userPreferencesKey, data);
      Logger.info('ユーザー設定のセキュア保存完了');
    } catch (e) {
      Logger.error('ユーザー設定のセキュア保存エラー', e);
      rethrow;
    }
  }
  
  /// ユーザー設定のセキュア読み込み
  static Future<Map<String, dynamic>?> loadUserPreferencesSecure() async {
    try {
      final data = await SecureStorageImplementation.loadSecureJson(_userPreferencesKey);
      if (data != null) {
        Logger.info('ユーザー設定のセキュア読み込み完了');
      }
      return data;
    } catch (e) {
      Logger.error('ユーザー設定のセキュア読み込みエラー', e);
      return null;
    }
  }
  
  /// 課金データのセキュア保存
  static Future<void> savePurchaseDataSecure(Map<String, dynamic> data) async {
    try {
      await SecureStorageImplementation.saveSecureJson(_purchaseDataKey, data);
      Logger.info('課金データのセキュア保存完了');
    } catch (e) {
      Logger.error('課金データのセキュア保存エラー', e);
      rethrow;
    }
  }
  
  /// 課金データのセキュア読み込み
  static Future<Map<String, dynamic>?> loadPurchaseDataSecure() async {
    try {
      final data = await SecureStorageImplementation.loadSecureJson(_purchaseDataKey);
      if (data != null) {
        Logger.info('課金データのセキュア読み込み完了');
      }
      return data;
    } catch (e) {
      Logger.error('課金データのセキュア読み込みエラー', e);
      return null;
    }
  }
  
  /// アラームデータのセキュア保存
  static Future<void> saveAlarmDataSecure(Map<String, dynamic> data) async {
    try {
      await SecureStorageImplementation.saveSecureJson(_alarmDataKey, data);
      Logger.info('アラームデータのセキュア保存完了');
    } catch (e) {
      Logger.error('アラームデータのセキュア保存エラー', e);
      rethrow;
    }
  }
  
  /// アラームデータのセキュア読み込み
  static Future<Map<String, dynamic>?> loadAlarmDataSecure() async {
    try {
      final data = await SecureStorageImplementation.loadSecureJson(_alarmDataKey);
      if (data != null) {
        Logger.info('アラームデータのセキュア読み込み完了');
      }
      return data;
    } catch (e) {
      Logger.error('アラームデータのセキュア読み込みエラー', e);
      return null;
    }
  }
  
  /// 統計データのセキュア保存
  static Future<void> saveStatisticsSecure(Map<String, dynamic> data) async {
    try {
      await SecureStorageImplementation.saveSecureJson(_statisticsKey, data);
      Logger.info('統計データのセキュア保存完了');
    } catch (e) {
      Logger.error('統計データのセキュア保存エラー', e);
      rethrow;
    }
  }
  
  /// 統計データのセキュア読み込み
  static Future<Map<String, dynamic>?> loadStatisticsSecure() async {
    try {
      final data = await SecureStorageImplementation.loadSecureJson(_statisticsKey);
      if (data != null) {
        Logger.info('統計データのセキュア読み込み完了');
      }
      return data;
    } catch (e) {
      Logger.error('統計データのセキュア読み込みエラー', e);
      return null;
    }
  }
  
  /// 全機密データの削除
  static Future<void> deleteAllSensitiveData() async {
    try {
      await SecureStorageImplementation.deleteSecureData(_medicationDataKey);
      await SecureStorageImplementation.deleteSecureData(_userPreferencesKey);
      await SecureStorageImplementation.deleteSecureData(_purchaseDataKey);
      await SecureStorageImplementation.deleteSecureData(_alarmDataKey);
      await SecureStorageImplementation.deleteSecureData(_statisticsKey);
      Logger.info('全機密データ削除完了');
    } catch (e) {
      Logger.error('全機密データ削除エラー', e);
    }
  }
}

/// セキュリティ監査機能
class SecurityAuditManager {
  static const String _auditLogKey = 'security_audit_log';
  static const int _maxAuditLogEntries = 1000;
  
  /// セキュリティイベントの記録
  static Future<void> recordSecurityEvent({
    required String eventType,
    required String description,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditLog = await _loadAuditLog();
      
      final event = {
        'timestamp': DateTime.now().toIso8601String(),
        'eventType': eventType,
        'description': description,
        'userId': userId,
        'metadata': metadata ?? {},
      };
      
      auditLog.add(event);
      
      // ログエントリ数の制限
      if (auditLog.length > _maxAuditLogEntries) {
        auditLog.removeRange(0, auditLog.length - _maxAuditLogEntries);
      }
      
      await _saveAuditLog(auditLog);
      Logger.info('セキュリティイベント記録完了: $eventType');
    } catch (e) {
      Logger.error('セキュリティイベント記録エラー: $eventType', e);
    }
  }
  
  /// 監査ログの読み込み
  static Future<List<Map<String, dynamic>>> _loadAuditLog() async {
    try {
      final data = await SecureStorageImplementation.loadSecureJson(_auditLogKey);
      if (data != null && data['auditLog'] is List) {
        return (data['auditLog'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      Logger.error('監査ログ読み込みエラー', e);
      return [];
    }
  }
  
  /// 監査ログの保存
  static Future<void> _saveAuditLog(List<Map<String, dynamic>> auditLog) async {
    try {
      await SecureStorageImplementation.saveSecureJson(_auditLogKey, {
        'auditLog': auditLog,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Logger.error('監査ログ保存エラー', e);
    }
  }
  
  /// セキュリティ統計の取得
  static Future<Map<String, dynamic>> getSecurityStats() async {
    try {
      final auditLog = await _loadAuditLog();
      
      final eventTypes = <String, int>{};
      final recentEvents = <Map<String, dynamic>>[];
      final now = DateTime.now();
      
      for (final event in auditLog) {
        final eventType = event['eventType']?.toString() ?? 'unknown';
        eventTypes[eventType] = (eventTypes[eventType] ?? 0) + 1;
        
        final timestamp = DateTime.tryParse(event['timestamp']?.toString() ?? '');
        if (timestamp != null && now.difference(timestamp).inDays <= 7) {
          recentEvents.add(event);
        }
      }
      
      return {
        'totalEvents': auditLog.length,
        'eventTypes': eventTypes,
        'recentEvents': recentEvents.length,
        'lastUpdated': auditLog.isNotEmpty ? auditLog.last['timestamp'] : null,
      };
    } catch (e) {
      Logger.error('セキュリティ統計取得エラー', e);
      return {};
    }
  }
  
  /// 監査ログのクリア
  static Future<void> clearAuditLog() async {
    try {
      await SecureStorageImplementation.deleteSecureData(_auditLogKey);
      Logger.info('監査ログクリア完了');
    } catch (e) {
      Logger.error('監査ログクリアエラー', e);
    }
  }
}
