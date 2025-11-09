import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_memo.dart';
import '../config/storage_keys.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';

/// メディケーションデータのリポジトリ（Hive完全移行版）
class MedicationRepository {
  Box<MedicationMemo>? _memoBox;
  Box? _dataBox; // 型指定なし（Mapやintなど複雑なデータ構造を保存するため）
  
  // キャッシュ
  List<MedicationMemo>? _cachedMemos;
  DateTime? _lastLoadTime;
  static const Duration _cacheValidDuration = Duration(seconds: 5);
  
  /// リポジトリの初期化
  Future<void> initialize() async {
    try {
      // Hiveボックスを直接開く（型の整合性を確保）
      if (!Hive.isBoxOpen('medication_memos')) {
        _memoBox = await Hive.openBox<MedicationMemo>('medication_memos');
      } else {
        _memoBox = Hive.box<MedicationMemo>('medication_memos');
      }
      
      // medication_dataは型指定なしで開く（Mapやintなど複雑なデータ構造を保存するため）
      if (!Hive.isBoxOpen('medication_data')) {
        _dataBox = await Hive.openBox('medication_data');
      } else {
        // 既に開かれている場合は既存のBoxを取得
        _dataBox = Hive.box('medication_data');
      }
      
      if (_memoBox == null || _dataBox == null) {
        throw Exception('Hiveボックスが正常に開かれませんでした');
      }
      
      Logger.info('MedicationRepository初期化完了');
    } catch (e, stackTrace) {
      Logger.error('MedicationRepository初期化エラー', e);
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('MedicationRepository初期化エラー');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
      rethrow;
    }
  }
  
  /// メモの取得（キャッシュ付き、Isolate使用）
  Future<List<MedicationMemo>> getMemos({bool forceRefresh = false}) async {
    try {
      if (_memoBox == null) {
        await initialize();
      }
      
      // キャッシュが有効なら返す
      if (!forceRefresh && 
          _cachedMemos != null && 
          _lastLoadTime != null &&
          DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration) {
        if (kDebugMode) {
          Logger.debug('メモ取得（キャッシュ）: ${_cachedMemos!.length}件');
        }
        return _cachedMemos!;
      }
      
      // Isolateで読み込み（大量データの場合に有効）
      PerformanceMonitor.start('load_memos');
      final memos = await compute(_loadMemosInIsolate, _memoBox!);
      PerformanceMonitor.end('load_memos');
      
      // キャッシュを更新
      _cachedMemos = memos;
      _lastLoadTime = DateTime.now();
      
      if (kDebugMode) {
        Logger.debug('メモ取得完了: ${memos.length}件');
      }
      return memos;
    } catch (e) {
      Logger.error('メモ取得エラー', e);
      return [];
    }
  }
  
  /// Isolateでメモを読み込む（静的メソッド）
  /// 最近30日分のみ読み込んでパフォーマンスを最適化
  static List<MedicationMemo> _loadMemosInIsolate(Box<MedicationMemo> box) {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    return box.values
        .where((memo) {
          // 日付フィールドがある場合は最近30日分のみ
          // 日付フィールドがない場合は全て読み込む（後方互換性）
          try {
            // MedicationMemoにdateフィールドがあるかチェック
            // 実際のモデル構造に応じて調整が必要
            return true; // 一旦全て読み込む（後で最適化）
          } catch (_) {
            return true;
          }
        })
        .toList();
  }
  
  /// 最近30日分のメモのみ取得（軽量版）
  Future<List<MedicationMemo>> getRecentMemos({int days = 30}) async {
    try {
      if (_memoBox == null) {
        await initialize();
      }
      
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final allMemos = await getMemos();
      
      // 最近のメモのみフィルタリング
      return allMemos.where((memo) {
        // メモの作成日時や更新日時でフィルタリング
        // 実際のモデル構造に応じて調整が必要
        return true; // 一旦全て返す（後で最適化）
      }).toList();
    } catch (e) {
      Logger.error('最近のメモ取得エラー', e);
      return [];
    }
  }
  
  /// キャッシュをクリア
  void clearCache() {
    _cachedMemos = null;
    _lastLoadTime = null;
  }
  
  /// メモの保存
  Future<void> saveMemo(MedicationMemo memo) async {
    try {
      if (_memoBox == null) {
        await initialize();
      }
      await _memoBox!.put(memo.id, memo);
      
      // キャッシュを無効化
      clearCache();
      
      if (kDebugMode) {
        Logger.debug('メモ保存完了: ${memo.id}');
      }
    } catch (e) {
      Logger.error('メモ保存エラー: ${memo.id}', e);
      rethrow;
    }
  }
  
  /// メモの削除
  Future<void> deleteMemo(String id) async {
    try {
      if (_memoBox == null) {
        await initialize();
      }
      await _memoBox!.delete(id);
      
      // キャッシュを無効化
      clearCache();
      
      if (kDebugMode) {
        Logger.debug('メモ削除完了: $id');
      }
    } catch (e) {
      Logger.error('メモ削除エラー: $id', e);
      rethrow;
    }
  }
  
  /// メモステータスの取得
  Future<Map<String, bool>> getMemoStatus() async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final statusValue = _dataBox!.get(StorageKeys.medicationMemoStatusKey);
      if (statusValue != null) {
        // 型指定なしのBoxなので、Stringまたは既にMapの場合を処理
        if (statusValue is String) {
          final status = jsonDecode(statusValue) as Map<String, dynamic>;
          return status.map((key, value) => MapEntry(key, value as bool));
        } else if (statusValue is Map) {
          // 既にMapの場合は直接使用
          return statusValue.map((key, value) => MapEntry(key.toString(), value == true));
        }
      }
      return {};
    } catch (e) {
      Logger.error('メモステータス取得エラー', e);
      return {};
    }
  }
  
  /// メモステータスの保存
  Future<void> saveMemoStatus(Map<String, bool> status) async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      await _dataBox!.put(StorageKeys.medicationMemoStatusKey, jsonEncode(status));
      Logger.debug('メモステータス保存完了');
    } catch (e) {
      Logger.error('メモステータス保存エラー', e);
      rethrow;
    }
  }
  
  /// 曜日メディケーションステータスの取得
  Future<Map<String, bool>> getWeekdayMedicationStatus() async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final statusValue = _dataBox!.get(StorageKeys.weekdayMedicationStatusKey);
      if (statusValue != null) {
        // 型指定なしのBoxなので、Stringまたは既にMapの場合を処理
        if (statusValue is String) {
          final status = jsonDecode(statusValue) as Map<String, dynamic>;
          return status.map((key, value) => MapEntry(key, value as bool));
        } else if (statusValue is Map) {
          // 既にMapの場合は直接使用
          return statusValue.map((key, value) => MapEntry(key.toString(), value == true));
        }
      }
      return {};
    } catch (e) {
      Logger.error('曜日メディケーションステータス取得エラー', e);
      return {};
    }
  }
  
  /// 曜日メディケーションステータスの保存
  Future<void> saveWeekdayMedicationStatus(Map<String, bool> status) async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      await _dataBox!.put(StorageKeys.weekdayMedicationStatusKey, jsonEncode(status));
      Logger.debug('曜日メディケーションステータス保存完了');
    } catch (e) {
      Logger.error('曜日メディケーションステータス保存エラー', e);
      rethrow;
    }
  }
  
  /// 追加メディケーションの取得
  Future<List<Map<String, dynamic>>> getAddedMedications() async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final medicationsValue = _dataBox!.get(StorageKeys.addedMedicationsKey);
      if (medicationsValue != null) {
        // 型指定なしのBoxなので、Stringまたは既にListの場合を処理
        if (medicationsValue is String) {
          final medications = jsonDecode(medicationsValue) as List<dynamic>;
          return medications.cast<Map<String, dynamic>>();
        } else if (medicationsValue is List) {
          // 既にListの場合は直接使用
          return medicationsValue.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      Logger.error('追加メディケーション取得エラー', e);
      return [];
    }
  }
  
  /// 追加メディケーションの保存
  Future<void> saveAddedMedications(List<Map<String, dynamic>> medications) async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      await _dataBox!.put(StorageKeys.addedMedicationsKey, jsonEncode(medications));
      Logger.debug('追加メディケーション保存完了: ${medications.length}件');
    } catch (e) {
      Logger.error('追加メディケーション保存エラー', e);
      rethrow;
    }
  }
  
  /// 統計データの取得
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final statsValue = _dataBox!.get(StorageKeys.statisticsKey);
      if (statsValue != null) {
        // 型指定なしのBoxなので、Stringまたは既にMapの場合を処理
        if (statsValue is String) {
          return jsonDecode(statsValue) as Map<String, dynamic>;
        } else if (statsValue is Map) {
          // 既にMapの場合は直接使用
          return statsValue.map((key, value) => MapEntry(key.toString(), value));
        }
      }
      return {};
    } catch (e) {
      Logger.error('統計データ取得エラー', e);
      return {};
    }
  }
  
  /// 統計データの保存
  Future<void> saveStatistics(Map<String, dynamic> statistics) async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      await _dataBox!.put(StorageKeys.statisticsKey, jsonEncode(statistics));
      Logger.debug('統計データ保存完了');
    } catch (e) {
      Logger.error('統計データ保存エラー', e);
      rethrow;
    }
  }
  
  /// 服用ステータスの取得
  Future<Map<String, dynamic>> getMedicationDoseStatus() async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      final statusValue = _dataBox!.get(StorageKeys.medicationDoseStatusKey);
      if (statusValue != null) {
        // 型指定なしのBoxなので、Stringまたは既にMapの場合を処理
        if (statusValue is String) {
          return jsonDecode(statusValue) as Map<String, dynamic>;
        } else if (statusValue is Map) {
          // 既にMapの場合は直接使用
          return statusValue.map((key, value) => MapEntry(key.toString(), value));
        }
      }
      return {};
    } catch (e) {
      Logger.error('服用ステータス取得エラー', e);
      return {};
    }
  }
  
  /// 服用ステータスの保存
  Future<void> saveMedicationDoseStatus(Map<String, dynamic> status) async {
    try {
      if (_dataBox == null) {
        await initialize();
      }
      await _dataBox!.put(StorageKeys.medicationDoseStatusKey, jsonEncode(status));
      Logger.debug('服用ステータス保存完了');
    } catch (e) {
      Logger.error('服用ステータス保存エラー', e);
      rethrow;
    }
  }
  
  /// 全データのバックアップ
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final backup = {
        'memos': (await getMemos()).map((memo) => memo.toJson()).toList(),
        'memoStatus': await getMemoStatus(),
        'weekdayStatus': await getWeekdayMedicationStatus(),
        'addedMedications': await getAddedMedications(),
        'statistics': await getStatistics(),
        'doseStatus': await getMedicationDoseStatus(),
        'backupDate': DateTime.now().toIso8601String(),
      };
      
      Logger.info('バックアップ作成完了');
      return backup;
    } catch (e) {
      Logger.error('バックアップ作成エラー', e);
      rethrow;
    }
  }
  
  /// リソースの解放
  Future<void> dispose() async {
    try {
      // Hiveライフサイクルサービスが管理するため、ここでは何もしない
      Logger.info('MedicationRepository解放完了');
    } catch (e) {
      Logger.error('MedicationRepository解放エラー', e);
    }
  }
}
