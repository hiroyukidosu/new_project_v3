// lib/screens/home/persistence/snapshot_persistence.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/logger.dart';
// import '../handlers/backup_handler.dart'; // 必要に応じて使用

/// スナップショット機能の永続化を管理するクラス
class SnapshotPersistence {
  static const String _lastSnapshotKey = 'last_snapshot_key';
  static const String _snapshotPrefix = 'snapshot_before_';

  /// 変更前スナップショットを保存
  Future<String?> saveSnapshotBeforeChange(
    String operationType,
    Future<Map<String, dynamic>> Function() createBackupData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // バックアップデータを作成
      final backupData = await createBackupData();
      final jsonString = jsonEncode(backupData);
      final snapshotKey = '$_snapshotPrefix$timestamp';
      
      // 暗号化（必要に応じて）
      final encryptedData = await _encryptDataAsync(jsonString);
      
      // 保存
      final ok1 = await prefs.setString(snapshotKey, encryptedData);
      final ok2 = await prefs.setString(_lastSnapshotKey, snapshotKey);
      
      if (!(ok1 && ok2)) {
        Logger.warning('スナップショット保存フラグがfalse: $ok1, $ok2');
        return null;
      }
      
      Logger.info('変更前スナップショット保存完了: $operationType (key: $snapshotKey)');
      return snapshotKey;
    } catch (e) {
      Logger.error('スナップショット保存エラー', e);
      return null;
    }
  }

  /// 1つ前の状態に復元（最新スナップショットから）
  Future<Map<String, dynamic>?> restoreLastSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSnapshotKey = prefs.getString(_lastSnapshotKey);
      
      if (lastSnapshotKey == null) {
        Logger.warning('スナップショットキーが見つかりません');
        return null;
      }
      
      final snapshotData = await loadSnapshot(lastSnapshotKey);
      
      if (snapshotData != null) {
        // 復元に使用したスナップショットは削除（1回使い切り）
        await prefs.remove(lastSnapshotKey);
        await prefs.remove(_lastSnapshotKey);
      }
      
      return snapshotData;
    } catch (e) {
      Logger.error('スナップショット復元エラー', e);
      return null;
    }
  }

  /// スナップショットを読み込み
  Future<Map<String, dynamic>?> loadSnapshot(String snapshotKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = prefs.getString(snapshotKey);
      
      if (encryptedData == null) {
        Logger.warning('スナップショットデータが見つかりません: $snapshotKey');
        return null;
      }
      
      // 復号化（必要に応じて）
      final jsonString = await _decryptDataAsync(encryptedData);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return backupData;
    } catch (e) {
      Logger.error('スナップショット読み込みエラー', e);
      return null;
    }
  }

  /// スナップショットが利用可能か確認
  Future<bool> hasUndoAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastKey = prefs.getString(_lastSnapshotKey);
      
      if (lastKey == null) {
        return false;
      }
      
      final data = prefs.getString(lastKey);
      return data != null;
    } catch (e) {
      Logger.error('スナップショット確認エラー', e);
      return false;
    }
  }

  /// データを暗号化（簡易版）
  Future<String> _encryptDataAsync(String data) async {
    // 実際の実装では適切な暗号化を使用
    // ここではBase64エンコードを例として使用
    return base64Encode(utf8.encode(data));
  }

  /// データを復号化（簡易版）
  Future<String> _decryptDataAsync(String encryptedData) async {
    // 実際の実装では適切な復号化を使用
    // ここではBase64デコードを例として使用
    try {
      return utf8.decode(base64Decode(encryptedData));
    } catch (e) {
      // Base64デコードに失敗した場合は、そのまま返す（暗号化されていない場合）
      return encryptedData;
    }
  }
}

