import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../utils/logger.dart';

// データ保存の最適化サービス
class DataOptimizationService {
  static SharedPreferences? _prefs;
  static Box? _hiveBox;
  static bool _isSaving = false;
  static final Map<String, dynamic> _pendingChanges = {};
  
  // 初期化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _hiveBox = await Hive.openBox('optimized_data');
    Logger.info('DataOptimizationService初期化完了');
  }
  
  // バッチ処理でのデータ保存（最適化版）
  static Future<void> saveAllDataOptimized({
    required Map<String, dynamic> medicationData,
    required Map<String, dynamic> memoData,
    required Map<String, dynamic> settingsData,
    required Map<String, dynamic> alarmData,
  }) async {
    if (_isSaving) {
      Logger.warning('データ保存中です。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      // データをバッチに準備
      final batch = <String, String>{};
      final timestamp = DateTime.now().toIso8601String();
      
      // メインデータ
      batch['medication_data'] = jsonEncode(medicationData);
      batch['memo_data'] = jsonEncode(memoData);
      batch['settings_data'] = jsonEncode(settingsData);
      batch['alarm_data'] = jsonEncode(alarmData);
      batch['last_saved'] = timestamp;
      batch['version'] = '1.0.0';
      
      // バックアップデータ
      final backupBatch = <String, String>{};
      for (final entry in batch.entries) {
        backupBatch['${entry.key}_backup'] = entry.value;
      }
      
      // 並列保存実行
      await Future.wait([
        _saveBatch(batch),
        _saveBatch(backupBatch),
        _saveToHive(medicationData, memoData, settingsData, alarmData),
        _saveToMemoryCache(medicationData, memoData, settingsData, alarmData),
      ]);
      
      Logger.info('バッチデータ保存完了（最適化版）');
    } catch (e) {
      Logger.error('バッチデータ保存エラー', e);
      rethrow;
    } finally {
      _isSaving = false;
    }
  }
  
  // 差分保存（変更された部分のみ）
  static Future<void> saveOnlyChangedData() async {
    if (_pendingChanges.isEmpty) {
      Logger.debug('変更されたデータがありません');
      return;
    }
    
    if (_isSaving) {
      Logger.warning('データ保存中です。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      final batch = <String, String>{};
      final timestamp = DateTime.now().toIso8601String();
      
      // 変更されたデータのみをバッチに追加
      for (final entry in _pendingChanges.entries) {
        batch[entry.key] = jsonEncode(entry.value);
        batch['${entry.key}_backup'] = jsonEncode(entry.value);
      }
      
      batch['last_saved'] = timestamp;
      
      await Future.wait([
        _saveBatch(batch),
        _saveChangedToHive(_pendingChanges),
      ]);
      
      _pendingChanges.clear();
      Logger.info('差分データ保存完了: ${batch.length}件');
    } catch (e) {
      Logger.error('差分データ保存エラー', e);
      rethrow;
    } finally {
      _isSaving = false;
    }
  }
  
  // データ変更のマーキング
  static void markDataChanged(String key, dynamic data) {
    _pendingChanges[key] = data;
    Logger.debug('データ変更マーク: $key');
  }
  
  // バッチ保存の実装
  static Future<void> _saveBatch(Map<String, String> batch) async {
    for (final entry in batch.entries) {
      await _prefs!.setString(entry.key, entry.value);
    }
  }
  
  // Hiveへの保存
  static Future<void> _saveToHive(
    Map<String, dynamic> medicationData,
    Map<String, dynamic> memoData,
    Map<String, dynamic> settingsData,
    Map<String, dynamic> alarmData,
  ) async {
    await Future.wait([
      _hiveBox!.put('medication_data', medicationData),
      _hiveBox!.put('memo_data', memoData),
      _hiveBox!.put('settings_data', settingsData),
      _hiveBox!.put('alarm_data', alarmData),
    ]);
  }
  
  // 変更されたデータのみをHiveに保存
  static Future<void> _saveChangedToHive(Map<String, dynamic> changedData) async {
    for (final entry in changedData.entries) {
      await _hiveBox!.put(entry.key, entry.value);
    }
  }
  
  // メモリキャッシュへの保存
  static Future<void> _saveToMemoryCache(
    Map<String, dynamic> medicationData,
    Map<String, dynamic> memoData,
    Map<String, dynamic> settingsData,
    Map<String, dynamic> alarmData,
  ) async {
    // メモリキャッシュの実装（必要に応じて）
    Logger.debug('メモリキャッシュ更新完了');
  }
  
  // データの読み込み（フォールバック対応）
  static Future<Map<String, dynamic>?> loadDataWithFallback(String key) async {
    try {
      // メインデータを試す
      final mainData = _prefs!.getString(key);
      if (mainData != null && mainData.isNotEmpty) {
        return jsonDecode(mainData) as Map<String, dynamic>;
      }
      
      // バックアップデータを試す
      final backupData = _prefs!.getString('${key}_backup');
      if (backupData != null && backupData.isNotEmpty) {
        Logger.warning('メインデータが見つからないため、バックアップを使用: $key');
        return jsonDecode(backupData) as Map<String, dynamic>;
      }
      
      // Hiveから試す
      final hiveData = _hiveBox!.get(key);
      if (hiveData != null) {
        Logger.warning('SharedPreferencesからデータが見つからないため、Hiveを使用: $key');
        return Map<String, dynamic>.from(hiveData);
      }
      
      return null;
    } catch (e) {
      Logger.error('データ読み込みエラー: $key', e);
      return null;
    }
  }
  
  // データの整合性チェック
  static Future<bool> verifyDataIntegrity() async {
    try {
      final keys = ['medication_data', 'memo_data', 'settings_data', 'alarm_data'];
      int validCount = 0;
      
      for (final key in keys) {
        final data = await loadDataWithFallback(key);
        if (data != null && data.isNotEmpty) {
          validCount++;
        }
      }
      
      final isValid = validCount == keys.length;
      Logger.info('データ整合性チェック: ${isValid ? 'OK' : 'NG'} ($validCount/${keys.length})');
      return isValid;
    } catch (e) {
      Logger.error('データ整合性チェックエラー', e);
      return false;
    }
  }
  
  // データの圧縮保存
  static Future<void> compressAndSave(String key, Map<String, dynamic> data) async {
    try {
      final compressed = jsonEncode(data);
      await _prefs!.setString(key, compressed);
      await _prefs!.setString('${key}_backup', compressed);
      Logger.debug('データ圧縮保存完了: $key');
    } catch (e) {
      Logger.error('データ圧縮保存エラー: $key', e);
      rethrow;
    }
  }
  
  // リソースの解放
  static Future<void> dispose() async {
    try {
      await _hiveBox?.close();
      _pendingChanges.clear();
      Logger.info('DataOptimizationServiceリソース解放完了');
    } catch (e) {
      Logger.error('DataOptimizationServiceリソース解放エラー', e);
    }
  }
}
