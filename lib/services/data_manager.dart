// Dart core imports
import 'dart:convert';

// Flutter core imports
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local imports
import '../utils/logger.dart';

// ✅ 修正：統一されたデータ管理システム
class DataManager {
  static final Map<String, bool> _dirtyFlags = <String, bool>{};
  static bool _isSaving = false;
  static SharedPreferences? _prefs;
  
  // 初期化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    Logger.info('DataManager初期化完了');
  }
  
  // データが変更されたことをマーク
  static void markDirty(String key) {
    _dirtyFlags[key] = true;
    Logger.debug('データ変更マーク: $key');
  }
  
  // 統一されたデータ保存（重複排除）
  static Future<void> save() async {
    if (_isSaving) {
      Logger.warning('データ保存中です。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      final data = {
        'medications': _serializeMedications(),
        'memos': _serializeMemos(),
        'settings': _serializeSettings(),
        'version': '1.0.0',
        'lastSaved': DateTime.now().toIso8601String(),
      };
      
      await Future.wait([
        _prefs!.setString('app_data', jsonEncode(data)),
        _prefs!.setString('app_data_backup', jsonEncode(data)),
      ]);
      
      Logger.info('統一データ保存完了');
    } catch (e) {
      Logger.error('統一データ保存エラー', e);
    } finally {
      _isSaving = false;
    }
  }
  
  // 変更されたデータのみ保存（差分保存）
  static Future<void> saveOnlyDirty() async {
    if (_isSaving) {
      Logger.warning('データ保存中です。スキップします。');
      return;
    }
    
    if (_dirtyFlags.isEmpty) {
      Logger.debug('変更されたデータがありません。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      final tasks = <Future>[];
      
      if (_dirtyFlags['memos'] == true) {
        tasks.add(_saveMemos());
      }
      if (_dirtyFlags['medications'] == true) {
        tasks.add(_saveMedications());
      }
      if (_dirtyFlags['alarms'] == true) {
        tasks.add(_saveAlarms());
      }
      if (_dirtyFlags['settings'] == true) {
        tasks.add(_saveSettings());
      }
      
      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
        Logger.info('差分保存完了: ${tasks.length}件');
      }
      
      _dirtyFlags.clear();
    } catch (e) {
      Logger.error('差分保存エラー', e);
    } finally {
      _isSaving = false;
    }
  }
  
  // データのシリアライズ
  static Map<String, dynamic> _serializeMedications() {
    // 服用薬データのシリアライズ
    return {};
  }
  
  static Map<String, dynamic> _serializeMemos() {
    // メモデータのシリアライズ
    return {};
  }
  
  static Map<String, dynamic> _serializeSettings() {
    // 設定データのシリアライズ
    return {};
  }
  
  // 個別保存メソッド
  static Future<void> _saveMemos() async {
    // メモ保存の実装
  }
  
  static Future<void> _saveMedications() async {
    // 薬物保存の実装
  }
  
  static Future<void> _saveAlarms() async {
    // アラーム保存の実装
  }
  
  static Future<void> _saveSettings() async {
    // 設定保存の実装
  }
}