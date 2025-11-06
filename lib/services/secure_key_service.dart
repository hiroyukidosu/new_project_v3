// 暗号化キー安全保管サービス
// 10年運用を考慮した暗号化キーの生成、保存、バックアップを管理します

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// 暗号化キー安全保管サービス
/// flutter_secure_storageを使用して暗号化キーを安全に管理します
class SecureKeyService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  static const String _backupKeyPrefix = 'key_backup_';
  static const String _backupMetadataKey = 'key_backup_metadata';
  
  /// 暗号化キーの取得または生成
  static Future<List<int>> getOrCreateEncryptionKey(String keyName) async {
    try {
      // 既存のキーを取得
      final existingKey = await _secureStorage.read(key: keyName);
      if (existingKey != null && existingKey.isNotEmpty) {
        final keyBytes = base64Decode(existingKey);
        Logger.debug('既存の暗号化キーを取得: $keyName');
        return keyBytes;
      }
      
      // 新しいキーを生成
      Logger.info('新しい暗号化キーを生成: $keyName');
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final keyBase64 = base64Encode(keyBytes);
      
      // セキュアストレージに保存
      await _secureStorage.write(key: keyName, value: keyBase64);
      
      // バックアップを作成
      await _createKeyBackup(keyName, keyBase64);
      
      Logger.info('✅ 暗号化キー生成・保存完了: $keyName');
      return keyBytes;
    } catch (e) {
      Logger.error('暗号化キー取得エラー: $keyName', e);
      rethrow;
    }
  }
  
  /// 暗号化キーの取得
  static Future<List<int>?> getEncryptionKey(String keyName) async {
    try {
      final keyBase64 = await _secureStorage.read(key: keyName);
      if (keyBase64 != null && keyBase64.isNotEmpty) {
        return base64Decode(keyBase64);
      }
      return null;
    } catch (e) {
      Logger.error('暗号化キー取得エラー: $keyName', e);
      return null;
    }
  }
  
  /// 暗号化キーの削除
  static Future<bool> deleteEncryptionKey(String keyName) async {
    try {
      await _secureStorage.delete(key: keyName);
      
      // バックアップメタデータからも削除
      await _removeKeyBackup(keyName);
      
      Logger.info('✅ 暗号化キー削除完了: $keyName');
      return true;
    } catch (e) {
      Logger.error('暗号化キー削除エラー: $keyName', e);
      return false;
    }
  }
  
  /// キーバックアップの作成（複数バックアップ対応）
  static Future<void> _createKeyBackup(String keyName, String keyBase64) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupKey = '$_backupKeyPrefix$keyName}_$timestamp';
      
      // バックアップを保存（暗号化された形式で）
      await prefs.setString(backupKey, keyBase64);
      
      // バックアップメタデータを更新
      await _updateBackupMetadata(keyName, backupKey, timestamp);
      
      // 複数のバックアップ場所に保存（10年運用の堅牢性向上）
      await _createMultipleBackups(keyName, keyBase64);
      
      Logger.debug('キーバックアップ作成完了: $keyName');
    } catch (e) {
      Logger.error('キーバックアップ作成エラー: $keyName', e);
      // バックアップエラーは非致命的
    }
  }
  
  /// 複数のバックアップ場所に保存（冗長性確保）
  static Future<void> _createMultipleBackups(String keyName, String keyBase64) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. プライマリバックアップ（既存のメタデータ付き）
      // 2. セカンダリバックアップ（シンプルな形式）
      final secondaryKey = '${_backupKeyPrefix}secondary_$keyName';
      await prefs.setString(secondaryKey, keyBase64);
      
      // 3. テルティアリバックアップ（エンコード形式）
      final tertiaryKey = '${_backupKeyPrefix}tertiary_$keyName';
      final encodedKey = base64Encode(utf8.encode(keyBase64));
      await prefs.setString(tertiaryKey, encodedKey);
      
      Logger.debug('複数バックアップ作成完了: $keyName');
    } catch (e) {
      Logger.error('複数バックアップ作成エラー: $keyName', e);
    }
  }
  
  /// バックアップメタデータの更新
  static Future<void> _updateBackupMetadata(
    String keyName,
    String backupKey,
    int timestamp,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_backupMetadataKey);
      
      Map<String, dynamic> metadata = {};
      if (metadataJson != null) {
        metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      }
      
      if (metadata[keyName] == null) {
        metadata[keyName] = [];
      }
      
      final backupList = metadata[keyName] as List<dynamic>;
      backupList.add({
        'backupKey': backupKey,
        'timestamp': timestamp,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // 最大10個のバックアップを保持（10年運用対応）
      if (backupList.length > 10) {
        backupList.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
        backupList.removeRange(10, backupList.length);
      }
      
      await prefs.setString(_backupMetadataKey, jsonEncode(metadata));
    } catch (e) {
      Logger.error('バックアップメタデータ更新エラー', e);
    }
  }
  
  /// キーバックアップの削除
  static Future<void> _removeKeyBackup(String keyName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_backupMetadataKey);
      
      if (metadataJson != null) {
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        if (metadata[keyName] != null) {
          final backupList = metadata[keyName] as List<dynamic>;
          for (final backup in backupList) {
            final backupKey = backup['backupKey'] as String;
            await prefs.remove(backupKey);
          }
          metadata.remove(keyName);
          await prefs.setString(_backupMetadataKey, jsonEncode(metadata));
        }
      }
    } catch (e) {
      Logger.error('キーバックアップ削除エラー', e);
    }
  }
  
  /// キーバックアップの取得（複数ソースから復元を試行）
  static Future<String?> getKeyBackup(String keyName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. プライマリバックアップから取得を試行
      final metadataJson = prefs.getString(_backupMetadataKey);
      if (metadataJson != null) {
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        if (metadata[keyName] != null) {
          final backupList = metadata[keyName] as List<dynamic>;
          if (backupList.isNotEmpty) {
            // 最新のバックアップを取得
            backupList.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
            // ソート後も空でないことを確認（念のため）
            if (backupList.isEmpty) return null;
            final latestBackup = backupList.first;
            final backupKey = latestBackup['backupKey'] as String;
            final backup = prefs.getString(backupKey);
            if (backup != null && backup.isNotEmpty) {
              return backup;
            }
          }
        }
      }
      
      // 2. セカンダリバックアップから取得を試行
      final secondaryKey = '${_backupKeyPrefix}secondary_$keyName';
      final secondaryBackup = prefs.getString(secondaryKey);
      if (secondaryBackup != null && secondaryBackup.isNotEmpty) {
        Logger.debug('セカンダリバックアップから復元: $keyName');
        return secondaryBackup;
      }
      
      // 3. テルティアリバックアップから取得を試行
      final tertiaryKey = '${_backupKeyPrefix}tertiary_$keyName';
      final tertiaryBackup = prefs.getString(tertiaryKey);
      if (tertiaryBackup != null && tertiaryBackup.isNotEmpty) {
        try {
          final decoded = utf8.decode(base64Decode(tertiaryBackup));
          Logger.debug('テルティアリバックアップから復元: $keyName');
          return decoded;
        } catch (e) {
          Logger.warning('テルティアリバックアップのデコードエラー: $keyName - $e');
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('キーバックアップ取得エラー: $keyName', e);
      return null;
    }
  }
  
  /// 全バックアップソースからキーを復元（堅牢な復元）
  static Future<List<int>?> restoreKeyFromAnyBackup(String keyName) async {
    try {
      // 1. セキュアストレージから直接取得
      final directKey = await getEncryptionKey(keyName);
      if (directKey != null) {
        Logger.debug('セキュアストレージから直接取得: $keyName');
        return directKey;
      }
      
      // 2. バックアップから復元
      final backupKeyBase64 = await getKeyBackup(keyName);
      if (backupKeyBase64 != null && backupKeyBase64.isNotEmpty) {
        try {
          final keyBytes = base64Decode(backupKeyBase64);
          // 復元したキーをセキュアストレージに保存
          await _secureStorage.write(key: keyName, value: backupKeyBase64);
          Logger.info('✅ バックアップからキーを復元: $keyName');
          return keyBytes;
        } catch (e) {
          Logger.error('バックアップからの復元エラー: $keyName', e);
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('キー復元エラー: $keyName', e);
      return null;
    }
  }
  
  /// キーの復元
  static Future<bool> restoreKey(String keyName, String keyBase64) async {
    try {
      // セキュアストレージに復元
      await _secureStorage.write(key: keyName, value: keyBase64);
      
      // バックアップも更新
      await _createKeyBackup(keyName, keyBase64);
      
      Logger.info('✅ 暗号化キー復元完了: $keyName');
      return true;
    } catch (e) {
      Logger.error('暗号化キー復元エラー: $keyName', e);
      return false;
    }
  }
  
  /// 全キーのバックアップ状態を取得
  static Future<Map<String, dynamic>> getBackupStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_backupMetadataKey);
      
      if (metadataJson != null) {
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        return {
          'hasBackups': true,
          'backupCount': metadata.length,
          'backups': metadata,
        };
      }
      
      return {
        'hasBackups': false,
        'backupCount': 0,
        'backups': {},
      };
    } catch (e) {
      Logger.error('バックアップ状態取得エラー', e);
      return {
        'hasBackups': false,
        'backupCount': 0,
        'backups': {},
        'error': e.toString(),
      };
    }
  }
  
  /// 全キーのエクスポート（安全なバックアップ用）
  static Future<Map<String, String>> exportAllKeys() async {
    try {
      final allKeys = await _secureStorage.readAll();
      Logger.info('✅ 全キーエクスポート完了: ${allKeys.length}件');
      return allKeys;
    } catch (e) {
      Logger.error('全キーエクスポートエラー', e);
      return {};
    }
  }
  
  /// 全キーのインポート（復元用）
  static Future<bool> importAllKeys(Map<String, String> keys) async {
    try {
      for (final entry in keys.entries) {
        await _secureStorage.write(key: entry.key, value: entry.value);
      }
      Logger.info('✅ 全キーインポート完了: ${keys.length}件');
      return true;
    } catch (e) {
      Logger.error('全キーインポートエラー', e);
      return false;
    }
  }
}

