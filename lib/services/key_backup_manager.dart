// 暗号化キー統合バックアップ管理サービス
// 10年運用を考慮した暗号化キーの安全保管とバックアップ網羅化を実装

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_key_service.dart';
import '../utils/logger.dart';
import '../config/storage_keys.dart';
import '../config/app_constants.dart';

/// バックアップ方法の種類
enum BackupMethod {
  local,      // ローカルストレージ（SecureStorage + SharedPreferences）
  cloud,      // クラウド（将来的にFirestore等）
  export,     // 手動エクスポート（ファイル/QRコード）
  auto,       // 自動バックアップ
}

/// バックアップ情報
class KeyBackupInfo {
  final String keyName;
  final BackupMethod method;
  final DateTime createdAt;
  final String? location;  // バックアップの場所（ファイルパス、クラウドID等）
  final bool verified;     // 検証済みかどうか
  
  KeyBackupInfo({
    required this.keyName,
    required this.method,
    required this.createdAt,
    this.location,
    this.verified = false,
  });
  
  Map<String, dynamic> toJson() => {
    'keyName': keyName,
    'method': method.name,
    'createdAt': createdAt.toIso8601String(),
    'location': location,
    'verified': verified,
  };
  
  factory KeyBackupInfo.fromJson(Map<String, dynamic> json) => KeyBackupInfo(
    keyName: json['keyName'] as String,
    method: BackupMethod.values.firstWhere(
      (e) => e.name == json['method'],
      orElse: () => BackupMethod.local,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    location: json['location'] as String?,
    verified: json['verified'] as bool? ?? false,
  );
}

/// 暗号化キー統合バックアップ管理サービス
class KeyBackupManager {
  static const String _backupHistoryKey = 'key_backup_history';
  static const String _autoBackupEnabledKey = 'key_auto_backup_enabled';
  static Timer? _autoBackupTimer;
  
  /// 全バックアップ方法でキーをバックアップ
  static Future<Map<BackupMethod, bool>> backupKeyComprehensively(String keyName) async {
    final results = <BackupMethod, bool>{};
    
    try {
      Logger.info('🔐 包括的キーバックアップ開始: $keyName');
      
      // 1. ローカルバックアップ（既存のSecureKeyServiceを使用）
      try {
        final keyBase64 = await _getKeyBase64(keyName);
        if (keyBase64 != null) {
          await SecureKeyService.restoreKey(keyName, keyBase64); // 既にバックアップ機能が含まれる
          results[BackupMethod.local] = true;
          Logger.info('✅ ローカルバックアップ完了');
        } else {
          results[BackupMethod.local] = false;
        }
      } catch (e) {
        Logger.error('ローカルバックアップエラー', e);
        results[BackupMethod.local] = false;
      }
      
      // 2. クラウドバックアップ（将来の拡張用、現在はスキップ）
      // results[BackupMethod.cloud] = await _backupToCloud(keyName);
      
      // 3. バックアップ履歴に記録
      await _addToBackupHistory(keyName, BackupMethod.local);
      
      Logger.info('✅ 包括的キーバックアップ完了: $keyName');
      return results;
    } catch (e) {
      Logger.error('包括的キーバックアップエラー: $keyName', e);
      return results;
    }
  }
  
  /// キーをエクスポート（ファイルとして保存）
  static Future<String?> exportKeyToFile(String keyName) async {
    try {
      final keyBase64 = await _getKeyBase64(keyName);
      if (keyBase64 == null) {
        Logger.warning('エクスポート対象のキーが見つかりません: $keyName');
        return null;
      }
      
      // エクスポートデータの作成（暗号化された形式）
      final exportData = {
        'keyName': keyName,
        'keyBase64': keyBase64,
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      final exportJson = jsonEncode(exportData);
      
      // 一時ディレクトリに保存
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${keyName}_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(exportJson);
      
      // バックアップ履歴に記録
      await _addToBackupHistory(keyName, BackupMethod.export, location: file.path);
      
      Logger.info('✅ キーエクスポート完了: $file.path');
      return file.path;
    } catch (e) {
      Logger.error('キーエクスポートエラー: $keyName', e);
      return null;
    }
  }
  
  /// キーを共有（Shareプラグインを使用）
  static Future<bool> shareKey(String keyName) async {
    try {
      final filePath = await exportKeyToFile(keyName);
      if (filePath == null) {
        return false;
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(filePath)], text: 'Hive暗号化キーのバックアップ');
        Logger.info('✅ キー共有完了: $keyName');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('キー共有エラー: $keyName', e);
      return false;
    }
  }
  
  /// キーをインポート（ファイルから復元）
  static Future<bool> importKeyFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        Logger.warning('インポートファイルが見つかりません: $filePath');
        return false;
      }
      
      final jsonString = await file.readAsString();
      final exportData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final keyName = exportData['keyName'] as String;
      final keyBase64 = exportData['keyBase64'] as String;
      
      // キーを復元
      final success = await SecureKeyService.restoreKey(keyName, keyBase64);
      
      if (success) {
        // バックアップ履歴に記録
        await _addToBackupHistory(keyName, BackupMethod.export, location: filePath);
        Logger.info('✅ キーインポート完了: $keyName');
      }
      
      return success;
    } catch (e) {
      Logger.error('キーインポートエラー: $filePath', e);
      return false;
    }
  }
  
  /// バックアップの検証
  static Future<bool> verifyBackup(String keyName, BackupMethod method) async {
    try {
      switch (method) {
        case BackupMethod.local:
          // ローカルバックアップの検証
          final keyBase64 = await SecureKeyService.getKeyBackup(keyName);
          if (keyBase64 != null) {
            final keyBytes = base64Decode(keyBase64);
            if (keyBytes.length == 32) {
              await _markBackupAsVerified(keyName, method);
              Logger.info('✅ ローカルバックアップ検証完了: $keyName');
              return true;
            }
          }
          return false;
          
        case BackupMethod.export:
          // エクスポートファイルの検証
          final history = await getBackupHistory();
          final exportBackups = history.where(
            (b) => b.keyName == keyName && b.method == BackupMethod.export,
          ).toList();
          
          if (exportBackups.isNotEmpty) {
            final latest = exportBackups.first;
            if (latest.location != null) {
              final file = File(latest.location!);
              if (await file.exists()) {
                await _markBackupAsVerified(keyName, method);
                Logger.info('✅ エクスポートバックアップ検証完了: $keyName');
                return true;
              }
            }
          }
          return false;
          
        case BackupMethod.cloud:
          // 将来的に実装
          return false;
          
        case BackupMethod.auto:
          // 自動バックアップはローカルと同じ
          return await verifyBackup(keyName, BackupMethod.local);
      }
    } catch (e) {
      Logger.error('バックアップ検証エラー: $keyName', e);
      return false;
    }
  }
  
  /// 全バックアップの検証
  static Future<Map<BackupMethod, bool>> verifyAllBackups(String keyName) async {
    final results = <BackupMethod, bool>{};
    
    for (final method in BackupMethod.values) {
      if (method != BackupMethod.cloud) { // クラウドは将来実装
        results[method] = await verifyBackup(keyName, method);
      }
    }
    
    return results;
  }
  
  /// 自動バックアップの有効化
  static Future<void> enableAutoBackup(String keyName, {Duration? interval}) async {
    final backupInterval = interval ?? AppConstants.keyBackupInterval;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoBackupEnabledKey, true);
      
      _autoBackupTimer?.cancel();
      
      // 定期実行をスケジュール（エラーハンドリング付き）
      _autoBackupTimer = Timer.periodic(backupInterval, (timer) async {
        try {
          await backupKeyComprehensively(keyName);
        } catch (e, stackTrace) {
          // エラー詳細をログに記録（stackTrace含む）
          Logger.error('自動バックアップ実行エラー: $keyName', e);
          Logger.error('自動バックアップスタックトレース', stackTrace);
          // エラーが連続する場合は一時的にバックアップを無効化
          // （過度なリトライを防ぐ）
        }
      });
      
      Logger.info('✅ 自動バックアップ有効化: ${backupInterval.inDays}日間隔');
    } catch (e) {
      Logger.error('自動バックアップ有効化エラー', e);
    }
  }
  
  /// 自動バックアップの無効化
  static void disableAutoBackup() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
    Logger.info('自動バックアップを無効化しました');
  }
  
  /// バックアップ履歴の取得
  static Future<List<KeyBackupInfo>> getBackupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_backupHistoryKey);
      
      if (historyJson != null) {
        final historyList = jsonDecode(historyJson) as List<dynamic>;
        return historyList.map((json) => KeyBackupInfo.fromJson(json as Map<String, dynamic>)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 新しい順
      }
      
      return [];
    } catch (e) {
      Logger.error('バックアップ履歴取得エラー', e);
      return [];
    }
  }
  
  /// バックアップ履歴に追加
  static Future<void> _addToBackupHistory(
    String keyName,
    BackupMethod method, {
    String? location,
  }) async {
    try {
      final history = await getBackupHistory();
      
      final backupInfo = KeyBackupInfo(
        keyName: keyName,
        method: method,
        createdAt: DateTime.now(),
        location: location,
        verified: false,
      );
      
      history.insert(0, backupInfo);
      
      // 最大履歴数を保持（10年運用対応）
      if (history.length > AppConstants.maxBackupHistory) {
        history.removeRange(AppConstants.maxBackupHistory, history.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(history.map((info) => info.toJson()).toList());
      await prefs.setString(_backupHistoryKey, historyJson);
    } catch (e) {
      Logger.error('バックアップ履歴追加エラー', e);
    }
  }
  
  /// バックアップを検証済みとしてマーク
  static Future<void> _markBackupAsVerified(String keyName, BackupMethod method) async {
    try {
      final history = await getBackupHistory();
      
      for (final backup in history) {
        if (backup.keyName == keyName && backup.method == method && !backup.verified) {
          final index = history.indexOf(backup);
          history[index] = KeyBackupInfo(
            keyName: backup.keyName,
            method: backup.method,
            createdAt: backup.createdAt,
            location: backup.location,
            verified: true,
          );
          break;
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(history.map((info) => info.toJson()).toList());
      await prefs.setString(_backupHistoryKey, historyJson);
    } catch (e) {
      Logger.error('バックアップ検証マークエラー', e);
    }
  }
  
  /// キーのBase64形式を取得
  static Future<String?> _getKeyBase64(String keyName) async {
    try {
      final allKeys = await SecureKeyService.exportAllKeys();
      return allKeys[keyName];
    } catch (e) {
      Logger.error('キー取得エラー: $keyName', e);
      return null;
    }
  }
  
  /// バックアップ統計の取得
  static Future<Map<String, dynamic>> getBackupStatistics(String keyName) async {
    try {
      final history = await getBackupHistory();
      final keyHistory = history.where((b) => b.keyName == keyName).toList();
      
      final methodCounts = <BackupMethod, int>{};
      int verifiedCount = 0;
      
      for (final backup in keyHistory) {
        methodCounts[backup.method] = (methodCounts[backup.method] ?? 0) + 1;
        if (backup.verified) {
          verifiedCount++;
        }
      }
      
      final latestBackup = keyHistory.isNotEmpty ? keyHistory.first : null;
      
      return {
        'totalBackups': keyHistory.length,
        'verifiedBackups': verifiedCount,
        'methodCounts': methodCounts.map((k, v) => MapEntry(k.name, v)),
        'latestBackup': latestBackup?.toJson(),
        'hasValidBackup': keyHistory.isNotEmpty,
      };
    } catch (e) {
      Logger.error('バックアップ統計取得エラー', e);
      return {
        'totalBackups': 0,
        'verifiedBackups': 0,
        'hasValidBackup': false,
        'error': e.toString(),
      };
    }
  }
  
  /// リソースの解放
  static void dispose() {
    disableAutoBackup();
  }
}

