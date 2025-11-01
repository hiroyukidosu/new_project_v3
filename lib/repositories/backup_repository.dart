import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/storage_keys.dart';
import '../utils/logger.dart';

/// バックアップ情報モデル
class BackupInfo {
  final String key;
  final String name;
  final DateTime createdAt;
  final int size; // バックアップサイズ（バイト）
  
  BackupInfo({
    required this.key,
    required this.name,
    required this.createdAt,
    required this.size,
  });
  
  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'size': size,
  };
  
  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
    key: json['key'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    size: json['size'] as int,
  );
}

/// バックアップ関連データのリポジトリ
class BackupRepository {
  late SharedPreferences _prefs;
  late Box<String> _dataBox;
  
  /// リポジトリの初期化
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _dataBox = await Hive.openBox<String>('backup_data');
      Logger.info('BackupRepository初期化完了');
    } catch (e) {
      Logger.error('BackupRepository初期化エラー', e);
      rethrow;
    }
  }
  
  /// バックアップの作成
  Future<String> createBackup(String name, Map<String, dynamic> data) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final key = '${StorageKeys.backupSuffix}_$timestamp';
      
      final backupData = {
        ...data,
        'backupName': name,
        'backupDate': DateTime.now().toIso8601String(),
      };
      
      final backupJson = jsonEncode(backupData);
      final backupSize = utf8.encode(backupJson).length;
      
      // SharedPreferencesとHiveの両方に保存
      await Future.wait([
        _prefs.setString(key, backupJson),
        _dataBox.put(key, backupJson),
      ]);
      
      // バックアップ履歴に追加
      await _addToHistory(BackupInfo(
        key: key,
        name: name,
        createdAt: DateTime.now(),
        size: backupSize,
      ));
      
      Logger.info('バックアップ作成完了: $name ($backupSize bytes)');
      return key;
    } catch (e) {
      Logger.error('バックアップ作成エラー', e);
      rethrow;
    }
  }
  
  /// バックアップの読み込み
  Future<Map<String, dynamic>?> loadBackup(String key) async {
    try {
      String? backupJson;
      
      // Hiveから読み込みを試行
      backupJson = _dataBox.get(key);
      
      // Hiveにない場合はSharedPreferencesから読み込み
      if (backupJson == null || backupJson.isEmpty) {
        backupJson = _prefs.getString(key);
      }
      
      if (backupJson != null && backupJson.isNotEmpty) {
        return jsonDecode(backupJson) as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      Logger.error('バックアップ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// バックアップ履歴の取得
  Future<List<BackupInfo>> getBackupHistory() async {
    try {
      final historyJson = _prefs.getString(StorageKeys.backupHistoryKey);
      if (historyJson != null) {
        final historyList = jsonDecode(historyJson) as List<dynamic>;
        return historyList.map((json) => BackupInfo.fromJson(json as Map<String, dynamic>)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 新しい順
      }
      return [];
    } catch (e) {
      Logger.error('バックアップ履歴取得エラー', e);
      return [];
    }
  }
  
  /// バックアップ履歴に追加
  Future<void> _addToHistory(BackupInfo backupInfo) async {
    try {
      final history = await getBackupHistory();
      history.insert(0, backupInfo);
      
      // 最大件数を超えた場合は古いものを削除
      const maxHistory = 10;
      if (history.length > maxHistory) {
        history.removeRange(maxHistory, history.length);
      }
      
      final historyJson = jsonEncode(history.map((info) => info.toJson()).toList());
      await _prefs.setString(StorageKeys.backupHistoryKey, historyJson);
    } catch (e) {
      Logger.error('バックアップ履歴追加エラー', e);
    }
  }
  
  /// バックアップの削除
  Future<void> deleteBackup(String key) async {
    try {
      await Future.wait([
        _prefs.remove(key),
        _dataBox.delete(key),
      ]);
      
      // 履歴からも削除
      final history = await getBackupHistory();
      history.removeWhere((info) => info.key == key);
      final historyJson = jsonEncode(history.map((info) => info.toJson()).toList());
      await _prefs.setString(StorageKeys.backupHistoryKey, historyJson);
      
      Logger.info('バックアップ削除完了: $key');
    } catch (e) {
      Logger.error('バックアップ削除エラー: $key', e);
      rethrow;
    }
  }
  
  /// リソースの解放
  Future<void> dispose() async {
    try {
      await _dataBox.close();
      Logger.info('BackupRepository解放完了');
    } catch (e) {
      Logger.error('BackupRepository解放エラー', e);
    }
  }
}

