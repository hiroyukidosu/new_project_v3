// Hive安全ライフサイクル管理サービス
// Hiveの初期化、暗号化、移行、クリーンアップを安全に管理します

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/medication_memo.dart';
import '../models/adapters/medication_memo_adapter.dart';
import '../utils/logger.dart';
import 'hive_migration_service.dart';
import 'secure_key_service.dart';
import 'key_backup_manager.dart';

/// Hiveライフサイクル管理サービス
/// 10年運用を考慮した安全な初期化・終了処理を提供します
class HiveLifecycleService {
  static const String _encryptionKeyName = 'hive_encryption_key';
  static bool _isInitialized = false;
  static final Map<String, Box> _openBoxes = {};
  static final Set<String> _boxNames = {}; // メモリリーク防止のための追跡
  
  /// Hiveの安全な初期化
  static Future<void> initialize() async {
    if (_isInitialized) {
      Logger.debug('Hiveは既に初期化済みです');
      return;
    }
    
    try {
      Logger.info('📦 Hive安全初期化開始...');
      
      // 1. Hive Flutter初期化
      await Hive.initFlutter();
      
      // 2. アダプター登録
      await _registerAdapters();
      
      // 3. 暗号化キーの取得または生成
      final encryptionKey = await SecureKeyService.getOrCreateEncryptionKey(
        _encryptionKeyName,
      );
      
      // 4. 暗号化ボックスのオープン
      await _openEncryptedBoxes(encryptionKey);
      
      // 5. 非暗号化ボックスのオープン
      await _openUnencryptedBoxes();
      
      // 6. 移行チェックと実行
      await _checkAndPerformMigration();
      
      // 7. 暗号化キーの包括的バックアップ（10年運用対応）
      await _initializeKeyBackups(_encryptionKeyName);
      
      _isInitialized = true;
      Logger.info('✅ Hive安全初期化完了');
    } catch (e, stackTrace) {
      Logger.error('Hive初期化エラー', e);
      Logger.error('スタックトレース', stackTrace);
      
      // エラー時は非暗号化でフォールバック
      if (!_isInitialized) {
        await _fallbackInitialization();
      }
    }
  }
  
  /// アダプターの登録
  static Future<void> _registerAdapters() async {
    try {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(MedicationMemoAdapter());
        Logger.debug('✅ MedicationMemoAdapter登録完了');
      }
    } catch (e) {
      Logger.error('アダプター登録エラー', e);
      rethrow;
    }
  }
  
  /// 暗号化ボックスのオープン
  static Future<void> _openEncryptedBoxes(List<int> encryptionKey) async {
    try {
      // 機密データ用の暗号化ボックス
      final encryptionCipher = HiveAesCipher(encryptionKey);
      
      // メディケーションメモ（暗号化）
      if (!Hive.isBoxOpen('medication_memos')) {
        final memoBox = await Hive.openBox<MedicationMemo>(
          'medication_memos',
          encryptionCipher: encryptionCipher,
        );
        _openBoxes['medication_memos'] = memoBox;
        Logger.debug('✅ medication_memosボックス（暗号化）オープン完了');
      }
    } catch (e) {
      Logger.warning('暗号化ボックスオープンエラー（非暗号化で再試行）: $e');
      // 暗号化に失敗した場合は非暗号化で再試行
      await _openUnencryptedBoxes();
    }
  }
  
  /// 非暗号化ボックスのオープン
  static Future<void> _openUnencryptedBoxes() async {
    try {
      final boxNames = [
        'medication_data',
        'alarm_data',
        'calendar_data',
        'backup_data',
      ];
      
      for (final boxName in boxNames) {
        if (!Hive.isBoxOpen(boxName)) {
          // medication_dataは型指定なしで開く（medication_data_persistence.dartとの互換性のため）
          final box = boxName == 'medication_data'
              ? await Hive.openBox(boxName)
              : await Hive.openBox<String>(boxName);
          _openBoxes[boxName] = box;
          Logger.debug('✅ $boxNameボックスオープン完了');
        } else {
          // 既に開かれている場合は既存のBoxを取得
          _openBoxes[boxName] = Hive.box(boxName);
          Logger.debug('✅ $boxNameボックスは既に開かれています');
        }
      }
    } catch (e) {
      Logger.error('非暗号化ボックスオープンエラー', e);
      rethrow;
    }
  }
  
  /// フォールバック初期化（暗号化なし）
  static Future<void> _fallbackInitialization() async {
    try {
      Logger.warning('フォールバック初期化を実行します（非暗号化）');
      
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(MedicationMemoAdapter());
      }
      
      // 非暗号化でボックスをオープン
      if (!Hive.isBoxOpen('medication_memos')) {
        await Hive.openBox<MedicationMemo>('medication_memos');
      }
      
      await _openUnencryptedBoxes();
      
      _isInitialized = true;
      Logger.info('✅ フォールバック初期化完了');
    } catch (e) {
      Logger.error('フォールバック初期化エラー', e);
    }
  }
  
  /// 移行チェックと実行
  static Future<void> _checkAndPerformMigration() async {
    try {
      final needsMigration = await HiveMigrationService.needsMigration();
      if (needsMigration) {
        Logger.info('🔄 データ移行が必要です。移行を開始します...');
        await HiveMigrationService.performFullMigration();
        Logger.info('✅ データ移行完了');
      } else {
        Logger.debug('✅ データ移行は不要です');
      }
    } catch (e) {
      Logger.error('移行チェックエラー', e);
      // 移行エラーはアプリ継続を許可
    }
  }
  
  /// ボックスの安全な取得（レビュー指摘の修正：型安全性の改善）
  /// キャストが失敗する可能性があるため、型チェックを追加
  /// 型指定なしの場合は getBoxUntyped を使用
  static Box<T>? getBox<T>(String boxName) {
    try {
      final box = _openBoxes[boxName];
      if (box is Box<T>) {
        return box;
      }
      // _openBoxesにない場合は、Hiveから直接取得を試みる
      if (Hive.isBoxOpen(boxName)) {
        final hiveBox = Hive.box(boxName);
        if (hiveBox is Box<T>) {
          _openBoxes[boxName] = hiveBox; // 追跡に追加
          return hiveBox;
        }
      }
      Logger.warning('ボックスが開いていません、または型が一致しません: $boxName');
      return null;
    } catch (e) {
      Logger.error('ボックス取得エラー: $boxName', e);
      return null;
    }
  }
  
  /// ボックスの安全な取得（型指定なし版）
  /// medication_dataボックスのように型指定なしで開かれている場合に使用
  static Box? getBoxUntyped(String boxName) {
    try {
      final box = _openBoxes[boxName];
      if (box != null) {
        return box;
      }
      // _openBoxesにない場合は、Hiveから直接取得を試みる
      if (Hive.isBoxOpen(boxName)) {
        final hiveBox = Hive.box(boxName);
        _openBoxes[boxName] = hiveBox; // 追跡に追加
        return hiveBox;
      }
      Logger.warning('ボックスが開いていません: $boxName');
      return null;
    } catch (e) {
      Logger.error('ボックス取得エラー: $boxName', e);
      return null;
    }
  }
  
  /// ボックスの安全なクローズ
  static Future<void> closeBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.close();
        _openBoxes.remove(boxName);
        Logger.debug('✅ ボックスクローズ完了: $boxName');
      }
    } catch (e) {
      Logger.error('ボックスクローズエラー: $boxName', e);
    }
  }
  
  /// 全ボックスの安全なクローズ
  static Future<void> closeAllBoxes() async {
    try {
      Logger.info('📦 全ボックスをクローズ中...');
      
      final boxNames = List<String>.from(_openBoxes.keys);
      for (final boxName in boxNames) {
        await closeBox(boxName);
      }
      
      // 注意: Hive.getAllBoxes()は存在しないため、_openBoxesに記録されているもののみクローズ
      // 他の場所で開かれたボックスは自動的にクローズされる
      
      _openBoxes.clear();
      Logger.info('✅ 全ボックスクローズ完了');
    } catch (e) {
      Logger.error('全ボックスクローズエラー', e);
    }
  }
  
  /// ボックスのコンパクト化（10年運用のための最適化）
  static Future<void> compactBox(String boxName) async {
    try {
      final box = getBoxUntyped(boxName);
      if (box != null && box.isOpen) {
        await box.compact();
        Logger.debug('✅ ボックスコンパクト完了: $boxName');
      }
    } catch (e) {
      Logger.error('ボックスコンパクトエラー: $boxName', e);
    }
  }
  
  /// 全ボックスのコンパクト化
  static Future<void> compactAllBoxes() async {
    try {
      Logger.info('📦 全ボックスのコンパクト化開始...');
      
      final boxNames = [
        'medication_memos',
        'medication_data',
        'alarm_data',
        'calendar_data',
        'backup_data',
      ];
      
      for (final boxName in boxNames) {
        if (Hive.isBoxOpen(boxName)) {
          await compactBox(boxName);
        }
      }
      
      Logger.info('✅ 全ボックスコンパクト完了');
    } catch (e) {
      Logger.error('全ボックスコンパクトエラー', e);
    }
  }
  
  /// ボックスの健全性チェック
  static Future<Map<String, dynamic>> checkBoxHealth(String boxName) async {
    try {
      final box = getBoxUntyped(boxName);
      if (box == null) {
        return {
          'healthy': false,
          'error': 'ボックスが開いていません',
        };
      }
      
      final length = box.length;
      final keys = box.keys.toList();
      final isOpen = box.isOpen;
      
      // データ整合性チェック
      int validEntries = 0;
      for (final key in keys) {
        try {
          final value = box.get(key);
          if (value != null) {
            validEntries++;
          }
        } catch (e) {
          Logger.warning('無効なエントリ: $key - $e');
        }
      }
      
      return {
        'healthy': true,
        'isOpen': isOpen,
        'length': length,
        'validEntries': validEntries,
        'invalidEntries': length - validEntries,
      };
    } catch (e) {
      return {
        'healthy': false,
        'error': e.toString(),
      };
    }
  }
  
  /// 全ボックスの健全性チェック
  static Future<Map<String, Map<String, dynamic>>> checkAllBoxesHealth() async {
    final results = <String, Map<String, dynamic>>{};
    
    final boxNames = [
      'medication_memos',
      'medication_data',
      'alarm_data',
      'calendar_data',
      'backup_data',
    ];
    
    for (final boxName in boxNames) {
      results[boxName] = await checkBoxHealth(boxName);
    }
    
    return results;
  }
  
  /// 初期化状態の確認
  static bool get isInitialized => _isInitialized;
  
  /// 暗号化キーのバックアップ初期化
  static Future<void> _initializeKeyBackups(String keyName) async {
    try {
      Logger.info('🔐 暗号化キーバックアップ初期化開始...');
      
      // 包括的バックアップを実行
      await KeyBackupManager.backupKeyComprehensively(keyName);
      
      // 自動バックアップを有効化（設定値を使用）
      await KeyBackupManager.enableAutoBackup(keyName);
      
      // バックアップの検証
      final verificationResults = await KeyBackupManager.verifyAllBackups(keyName);
      final verifiedCount = verificationResults.values.where((v) => v).length;
      Logger.info('✅ バックアップ検証完了: $verifiedCount/${verificationResults.length}件が有効');
      
      Logger.info('✅ 暗号化キーバックアップ初期化完了');
    } catch (e) {
      Logger.error('暗号化キーバックアップ初期化エラー', e);
      // バックアップエラーは非致命的
    }
  }
  
  /// アプリ終了時のクリーンアップ
  static Future<void> dispose() async {
    try {
      Logger.info('📦 Hiveライフサイクル終了処理開始...');
      
      // 全ボックスをコンパクト化（10年運用の最適化）
      await compactAllBoxes();
      
      // 全ボックスをクローズ
      await closeAllBoxes();
      
      // キーバックアップマネージャーの解放
      KeyBackupManager.dispose();
      
      _isInitialized = false;
      Logger.info('✅ Hiveライフサイクル終了処理完了');
    } catch (e) {
      Logger.error('Hiveライフサイクル終了処理エラー', e);
    }
  }
}

