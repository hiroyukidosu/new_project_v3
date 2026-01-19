import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// データ暗号化機能 - 機密データの安全な保存
class DataEncryption {
  static const String _encryptionKey = 'medication_app_encryption_key_2024';
  static const String _ivKey = 'medication_app_iv_key_2024';
  static const String _saltKey = 'medication_app_salt_key_2024';
  
  /// 暗号化されたデータの保存
  static Future<void> saveEncrypted(String key, String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = _encryptData(data);
      await prefs.setString(key, encryptedData);
      Logger.debug('暗号化データ保存完了: $key');
    } catch (e) {
      Logger.error('暗号化データ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// 暗号化されたデータの読み込み
  static Future<String?> loadEncrypted(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = prefs.getString(key);
      if (encryptedData == null) {
        Logger.debug('暗号化データが見つかりません: $key');
        return null;
      }
      
      final decryptedData = _decryptData(encryptedData);
      Logger.debug('暗号化データ読み込み完了: $key');
      return decryptedData;
    } catch (e) {
      Logger.error('暗号化データ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// 暗号化されたJSONデータの保存
  static Future<void> saveEncryptedJson(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      await saveEncrypted(key, jsonString);
      Logger.debug('暗号化JSONデータ保存完了: $key');
    } catch (e) {
      Logger.error('暗号化JSONデータ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// 暗号化されたJSONデータの読み込み
  static Future<Map<String, dynamic>?> loadEncryptedJson(String key) async {
    try {
      final jsonString = await loadEncrypted(key);
      if (jsonString == null) {
        return null;
      }
      
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      Logger.debug('暗号化JSONデータ読み込み完了: $key');
      return data;
    } catch (e) {
      Logger.error('暗号化JSONデータ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// データの暗号化
  static String _encryptData(String data) {
    try {
      // シンプルなXOR暗号化（本格的な暗号化ライブラリの代替）
      final key = _generateKey();
      final encrypted = _xorEncrypt(data, key);
      final encoded = base64Encode(utf8.encode(encrypted));
      return encoded;
    } catch (e) {
      Logger.error('データ暗号化エラー', e);
      rethrow;
    }
  }
  
  /// データの復号化
  static String _decryptData(String encryptedData) {
    try {
      // シンプルなXOR復号化
      final decoded = utf8.decode(base64Decode(encryptedData));
      final key = _generateKey();
      final decrypted = _xorDecrypt(decoded, key);
      return decrypted;
    } catch (e) {
      Logger.error('データ復号化エラー', e);
      rethrow;
    }
  }
  
  /// XOR暗号化
  static String _xorEncrypt(String data, String key) {
    final result = StringBuffer();
    for (int i = 0; i < data.length; i++) {
      final dataChar = data.codeUnitAt(i);
      final keyChar = key.codeUnitAt(i % key.length);
      final encryptedChar = dataChar ^ keyChar;
      result.writeCharCode(encryptedChar);
    }
    return result.toString();
  }
  
  /// XOR復号化
  static String _xorDecrypt(String encryptedData, String key) {
    final result = StringBuffer();
    for (int i = 0; i < encryptedData.length; i++) {
      final encryptedChar = encryptedData.codeUnitAt(i);
      final keyChar = key.codeUnitAt(i % key.length);
      final decryptedChar = encryptedChar ^ keyChar;
      result.writeCharCode(decryptedChar);
    }
    return result.toString();
  }
  
  /// 暗号化キーの生成
  static String _generateKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(keyBytes);
  }
  
  /// データの整合性チェック
  static bool verifyDataIntegrity(String data, String checksum) {
    try {
      final calculatedChecksum = _calculateChecksum(data);
      return calculatedChecksum == checksum;
    } catch (e) {
      Logger.error('データ整合性チェックエラー', e);
      return false;
    }
  }
  
  /// チェックサムの計算
  static String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    int checksum = 0;
    for (final byte in bytes) {
      checksum = (checksum + byte) % 256;
    }
    return checksum.toString();
  }
  
  /// 暗号化されたデータの保存（整合性チェック付き）
  static Future<void> saveEncryptedWithIntegrity(String key, String data) async {
    try {
      final checksum = _calculateChecksum(data);
      final dataWithChecksum = '$data|$checksum';
      await saveEncrypted(key, dataWithChecksum);
      Logger.debug('整合性チェック付き暗号化データ保存完了: $key');
    } catch (e) {
      Logger.error('整合性チェック付き暗号化データ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// 暗号化されたデータの読み込み（整合性チェック付き）
  static Future<String?> loadEncryptedWithIntegrity(String key) async {
    try {
      final dataWithChecksum = await loadEncrypted(key);
      if (dataWithChecksum == null) {
        return null;
      }
      
      final parts = dataWithChecksum.split('|');
      if (parts.length != 2) {
        Logger.warning('整合性チェックデータの形式が不正です: $key');
        return null;
      }
      
      final data = parts[0];
      final checksum = parts[1];
      
      if (!verifyDataIntegrity(data, checksum)) {
        Logger.warning('データの整合性チェックに失敗しました: $key');
        return null;
      }
      
      Logger.debug('整合性チェック付き暗号化データ読み込み完了: $key');
      return data;
    } catch (e) {
      Logger.error('整合性チェック付き暗号化データ読み込みエラー: $key', e);
      return null;
    }
  }
}

/// セキュアストレージ管理
class SecureStorageManager {
  static const String _encryptedPrefix = 'encrypted_';
  static const String _backupPrefix = 'backup_';
  
  /// セキュアなデータ保存
  static Future<void> saveSecure(String key, String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 暗号化データの保存
      await DataEncryption.saveEncryptedWithIntegrity('$_encryptedPrefix$key', data);
      
      // バックアップの保存
      await DataEncryption.saveEncryptedWithIntegrity('$_backupPrefix$key', data);
      
      Logger.debug('セキュアデータ保存完了: $key');
    } catch (e) {
      Logger.error('セキュアデータ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// セキュアなデータ読み込み
  static Future<String?> loadSecure(String key) async {
    try {
      // メインデータの読み込み
      String? data = await DataEncryption.loadEncryptedWithIntegrity('$_encryptedPrefix$key');
      
      // メインデータが読み込めない場合はバックアップから読み込み
      if (data == null) {
        Logger.warning('メインデータの読み込みに失敗、バックアップから読み込み: $key');
        data = await DataEncryption.loadEncryptedWithIntegrity('$_backupPrefix$key');
      }
      
      if (data != null) {
        Logger.debug('セキュアデータ読み込み完了: $key');
      } else {
        Logger.warning('セキュアデータが見つかりません: $key');
      }
      
      return data;
    } catch (e) {
      Logger.error('セキュアデータ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// セキュアなJSONデータ保存
  static Future<void> saveSecureJson(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      await saveSecure(key, jsonString);
      Logger.debug('セキュアJSONデータ保存完了: $key');
    } catch (e) {
      Logger.error('セキュアJSONデータ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// セキュアなJSONデータ読み込み
  static Future<Map<String, dynamic>?> loadSecureJson(String key) async {
    try {
      final jsonString = await loadSecure(key);
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
  static Future<void> deleteSecure(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_encryptedPrefix$key');
      await prefs.remove('$_backupPrefix$key');
      Logger.debug('セキュアデータ削除完了: $key');
    } catch (e) {
      Logger.error('セキュアデータ削除エラー: $key', e);
    }
  }
  
  /// 全セキュアデータの削除
  static Future<void> deleteAllSecure() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_encryptedPrefix) || key.startsWith(_backupPrefix)) {
          await prefs.remove(key);
        }
      }
      
      Logger.info('全セキュアデータ削除完了');
    } catch (e) {
      Logger.error('全セキュアデータ削除エラー', e);
    }
  }
  
  /// セキュアデータの統計
  static Future<Map<String, dynamic>> getSecureDataStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int encryptedCount = 0;
      int backupCount = 0;
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_encryptedPrefix)) {
          encryptedCount++;
          final data = prefs.getString(key);
          if (data != null) {
            totalSize += data.length;
          }
        } else if (key.startsWith(_backupPrefix)) {
          backupCount++;
        }
      }
      
      return {
        'encryptedDataCount': encryptedCount,
        'backupDataCount': backupCount,
        'totalSize': totalSize,
        'totalSizeKB': (totalSize / 1024).round(),
      };
    } catch (e) {
      Logger.error('セキュアデータ統計取得エラー', e);
      return {};
    }
  }
}
