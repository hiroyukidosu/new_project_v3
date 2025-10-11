import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/medication_memo.dart';
import '../models/medicine_data.dart';
import '../utils/logger.dart';

// 服用データ管理サービス
class MedicationService {
  static SharedPreferences? _prefs;
  static Box? _hiveBox;
  
  // 初期化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _hiveBox = await Hive.openBox('medication_data');
    Logger.info('MedicationService初期化完了');
  }
  
  // バッチ処理でのデータ保存（最適化版）
  static Future<void> saveAllDataOptimized({
    required Map<String, dynamic> medicationData,
    required Map<String, dynamic> memoData,
    required Map<String, dynamic> settingsData,
  }) async {
    try {
      final batch = <String, String>{};
      
      // データをバッチに追加
      batch['medication_data'] = jsonEncode(medicationData);
      batch['memo_data'] = jsonEncode(memoData);
      batch['settings_data'] = jsonEncode(settingsData);
      batch['last_saved'] = DateTime.now().toIso8601String();
      
      // バックアップも同時に作成
      final backupBatch = <String, String>{};
      for (final entry in batch.entries) {
        backupBatch['${entry.key}_backup'] = entry.value;
      }
      
      // 並列保存
      await Future.wait([
        _saveBatch(batch),
        _saveBatch(backupBatch),
        _saveToHive(medicationData),
      ]);
      
      Logger.info('バッチデータ保存完了');
    } catch (e) {
      Logger.error('バッチデータ保存エラー', e);
      rethrow;
    }
  }
  
  // バッチ保存の実装
  static Future<void> _saveBatch(Map<String, String> batch) async {
    for (final entry in batch.entries) {
      await _prefs!.setString(entry.key, entry.value);
    }
  }
  
  // Hiveへの保存
  static Future<void> _saveToHive(Map<String, dynamic> data) async {
    await _hiveBox!.put('medication_data', data);
  }
  
  // 服用メモの保存
  static Future<void> saveMedicationMemo(MedicationMemo memo) async {
    try {
      final json = memo.toJson();
      await _prefs!.setString('medication_memo_${memo.id}', jsonEncode(json));
      await _prefs!.setString('medication_memo_${memo.id}_backup', jsonEncode(json));
      Logger.info('服用メモ保存完了: ${memo.name}');
    } catch (e) {
      Logger.error('服用メモ保存エラー', e);
      rethrow;
    }
  }
  
  // 服用メモの読み込み
  static Future<MedicationMemo?> loadMedicationMemo(String id) async {
    try {
      final jsonStr = _prefs!.getString('medication_memo_$id');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return MedicationMemo.fromJson(json);
      }
      return null;
    } catch (e) {
      Logger.error('服用メモ読み込みエラー', e);
      return null;
    }
  }
  
  // 全服用メモの読み込み
  static Future<List<MedicationMemo>> loadAllMedicationMemos() async {
    try {
      final keys = _prefs!.getKeys().where((key) => key.startsWith('medication_memo_') && !key.contains('_backup'));
      final memos = <MedicationMemo>[];
      
      for (final key in keys) {
        final memo = await loadMedicationMemo(key.replaceFirst('medication_memo_', ''));
        if (memo != null) {
          memos.add(memo);
        }
      }
      
      Logger.info('全服用メモ読み込み完了: ${memos.length}件');
      return memos;
    } catch (e) {
      Logger.error('全服用メモ読み込みエラー', e);
      return [];
    }
  }
  
  // 薬データの保存
  static Future<void> saveMedicineData(MedicineData medicine) async {
    try {
      final json = medicine.toJson();
      await _prefs!.setString('medicine_${medicine.id}', jsonEncode(json));
      await _prefs!.setString('medicine_${medicine.id}_backup', jsonEncode(json));
      Logger.info('薬データ保存完了: ${medicine.name}');
    } catch (e) {
      Logger.error('薬データ保存エラー', e);
      rethrow;
    }
  }
  
  // 薬データの読み込み
  static Future<MedicineData?> loadMedicineData(String id) async {
    try {
      final jsonStr = _prefs!.getString('medicine_$id');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return MedicineData.fromJson(json);
      }
      return null;
    } catch (e) {
      Logger.error('薬データ読み込みエラー', e);
      return null;
    }
  }
  
  // 統計データの計算（メモ化対応）
  static Map<String, double> _cachedStats = {};
  static DateTime? _lastStatsCalculation;
  
  static Map<String, double> calculateAdherenceStats(List<MedicationMemo> memos) {
    final now = DateTime.now();
    
    // キャッシュが有効な場合は返す
    if (_cachedStats.isNotEmpty && 
        _lastStatsCalculation != null && 
        now.difference(_lastStatsCalculation!).inMinutes < 5) {
      return _cachedStats;
    }
    
    // 統計計算
    final stats = <String, double>{};
    for (final memo in memos) {
      final adherenceRate = _calculateMemoAdherence(memo);
      stats[memo.id] = adherenceRate;
    }
    
    // キャッシュ更新
    _cachedStats = stats;
    _lastStatsCalculation = now;
    
    Logger.info('統計データ計算完了: ${stats.length}件');
    return stats;
  }
  
  static double _calculateMemoAdherence(MedicationMemo memo) {
    // 遵守率の計算ロジック
    // 実装は既存のロジックを移植
    return 0.0; // プレースホルダー
  }
  
  // キャッシュの無効化
  static void invalidateStatsCache() {
    _cachedStats.clear();
    _lastStatsCalculation = null;
    Logger.debug('統計キャッシュを無効化しました');
  }
  
  // リソースの解放
  static Future<void> dispose() async {
    try {
      await _hiveBox?.close();
      Logger.info('MedicationServiceリソース解放完了');
    } catch (e) {
      Logger.error('MedicationServiceリソース解放エラー', e);
    }
  }
}
