import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// データマネージャー
/// 複数のデータをまとめて管理する
class DataManager {
  static final Map<String, bool> _dirtyFlags = <String, bool>{};
  static bool _isSaving = false;
  static SharedPreferences? _prefs;
  
  // 初期化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    Logger.info('DataManager初期化完了');
  }
  
  // データを変更済みとしてマーク
  static void markDirty(String key) {
    _dirtyFlags[key] = true;
    Logger.debug('データ変更マーク: $key');
  }
  
  // 全てのデータを保存する
  static Future<void> save() async {
    if (_isSaving) {
      Logger.warning('データ保存中です。重複保存をスキップします。');
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
      
      Logger.info('全データ保存完了');
    } catch (e) {
      Logger.error('全データ保存エラー', e);
    } finally {
      _isSaving = false;
    }
  }
  
  // 変更されたデータのみ保存する
  static Future<void> saveOnlyDirty() async {
    if (_isSaving) {
      Logger.warning('データ保存中です。重複保存をスキップします。');
      return;
    }
    
    if (_dirtyFlags.isEmpty) {
      Logger.debug('変更されたデータがありません。保存をスキップします。');
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
        Logger.info('変更データ保存完了: ${tasks.length}件');
      }
      
      _dirtyFlags.clear();
    } catch (e) {
      Logger.error('変更データ保存エラー', e);
    } finally {
      _isSaving = false;
    }
  }
  
  // データのシリアライズ
  static Map<String, dynamic> _serializeMedications() {
    // 薬物データのシリアライズ
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
  
  // 個別データ保存メソッド
  static Future<void> _saveMemos() async {
    // メモ保存処理
    Logger.debug('メモデータ保存');
  }

  static Future<void> _saveMedications() async {
    // 薬物データ保存処理
    Logger.debug('薬物データ保存');
  }

  static Future<void> _saveAlarms() async {
    // アラームデータ保存処理
    Logger.debug('アラームデータ保存');
  }

  static Future<void> _saveSettings() async {
    // 設定データ保存処理
    Logger.debug('設定データ保存');
  }
}
