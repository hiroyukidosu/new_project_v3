import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_memo.dart';
import '../config/storage_keys.dart';
import '../services/hive_lifecycle_service.dart';
import '../utils/logger.dart';

/// メディケーションデータのリポジトリ（Hive完全移行版）
class MedicationRepository {
  Box<MedicationMemo>? _memoBox;
  Box? _dataBox; // 型指定なし（medication_data_persistence.dartとの互換性のため）
  
  /// リポジトリの初期化
  Future<void> initialize() async {
    try {
      // Hiveライフサイクルサービスからボックスを取得
      _memoBox = HiveLifecycleService.getBox<MedicationMemo>('medication_memos');
      // medication_dataは型指定なしで開かれているため、型指定なしで取得
      _dataBox = HiveLifecycleService.getBoxUntyped('medication_data');
      
      if (_memoBox == null || _dataBox == null) {
        throw Exception('Hiveボックスが初期化されていません');
      }
      
      Logger.info('MedicationRepository初期化完了');
    } catch (e) {
      Logger.error('MedicationRepository初期化エラー', e);
      rethrow;
    }
  }
  
  /// メモの取得
  Future<List<MedicationMemo>> getMemos() async {
    try {
      if (_memoBox == null) {
        await initialize();
      }
      final memos = _memoBox!.values.toList();
      Logger.debug('メモ取得完了: ${memos.length}件');
      return memos;
    } catch (e) {
      Logger.error('メモ取得エラー', e);
      return [];
    }
  }
  
  /// メモの保存
  Future<void> saveMemo(MedicationMemo memo) async {
    try {
      if (_memoBox == null) {
        await initialize();
      }
      await _memoBox!.put(memo.id, memo);
      Logger.debug('メモ保存完了: ${memo.id}');
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
      Logger.debug('メモ削除完了: $id');
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
        // Stringまたは既にMapの場合を処理
        final statusJson = statusValue is String ? statusValue : jsonEncode(statusValue);
        final status = jsonDecode(statusJson) as Map<String, dynamic>;
        return status.map((key, value) => MapEntry(key, value as bool));
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
        final statusJson = statusValue is String ? statusValue : jsonEncode(statusValue);
        final status = jsonDecode(statusJson) as Map<String, dynamic>;
        return status.map((key, value) => MapEntry(key, value as bool));
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
        final medicationsJson = medicationsValue is String ? medicationsValue : jsonEncode(medicationsValue);
        final medications = jsonDecode(medicationsJson) as List<dynamic>;
        return medications.cast<Map<String, dynamic>>();
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
        final statsJson = statsValue is String ? statsValue : jsonEncode(statsValue);
        return jsonDecode(statsJson) as Map<String, dynamic>;
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
        final statusJson = statusValue is String ? statusValue : jsonEncode(statusValue);
        return jsonDecode(statusJson) as Map<String, dynamic>;
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
