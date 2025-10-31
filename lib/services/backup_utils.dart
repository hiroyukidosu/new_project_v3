// バックアップ関連のユーティリティ関数
// 暗号化、復号化、JSONエンコードなどの共通機能を提供

import 'dart:convert';
import 'package:flutter/foundation.dart';

/// バックアップ関連のユーティリティ関数
class BackupUtils {
  // XOR暗号化用のキー
  static const String _encryptionKey = 'medication_app_backup_key_2024';

  /// データを暗号化（XOR暗号化）
  static Future<String> encryptData(String data) async {
    final encrypted = StringBuffer();
    for (int i = 0; i < data.length; i++) {
      encrypted.write(String.fromCharCode(
        data.codeUnitAt(i) ^ _encryptionKey.codeUnitAt(i % _encryptionKey.length)
      ));
    }
    return encrypted.toString();
  }

  /// データを復号化（XOR暗号化の復号化）
  static Future<String> decryptData(String encryptedData) async {
    final decrypted = StringBuffer();
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted.write(String.fromCharCode(
        encryptedData.codeUnitAt(i) ^ _encryptionKey.codeUnitAt(i % _encryptionKey.length)
      ));
    }
    return decrypted.toString();
  }

  /// 同期的な復号化
  static String decryptDataSync(String encryptedData) {
    final decrypted = StringBuffer();
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted.write(String.fromCharCode(
        encryptedData.codeUnitAt(i) ^ _encryptionKey.codeUnitAt(i % _encryptionKey.length)
      ));
    }
    return decrypted.toString();
  }

  /// 安全なJSONエンコード（エラーハンドリング付き）
  static Future<String> safeJsonEncode(Map<String, dynamic> data) async {
    try {
      return jsonEncode(data);
    } catch (e) {
      debugPrint('JSONエンコードエラー: $e');
      debugPrint('問題のあるデータ: ${data.keys}');
      
      // エラーが発生した場合、問題のあるフィールドを特定
      final safeData = <String, dynamic>{};
      for (final entry in data.entries) {
        try {
          jsonEncode({entry.key: entry.value}); // 個別にテスト
          safeData[entry.key] = entry.value;
        } catch (fieldError) {
          debugPrint('フィールド ${entry.key} でエラー: $fieldError');
          safeData[entry.key] = null; // 問題のあるフィールドはnullに
        }
      }
      
      return jsonEncode(safeData);
    }
  }
}

