import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

/// 統一リポジトリ - データ保存の重複排除
class UnifiedRepository {
  static SharedPreferences? _prefs;
  static Box<String>? _hiveBox;
  static bool _isInitialized = false;
  
  /// 初期化
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await Hive.initFlutter();
      _hiveBox = await Hive.openBox<String>('unified_data');
      _isInitialized = true;
      Logger.info('UnifiedRepository初期化完了');
    } catch (e) {
      Logger.error('UnifiedRepository初期化エラー', e);
      rethrow;
    }
  }
  
  /// アプリ状態の統一保存
  static Future<void> saveAll(AppState state) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final batch = {
        'memos': state.memos,
        'alarms': state.alarms,
        'medications': state.medications,
        'calendarMarks': state.calendarMarks,
        'userPreferences': state.userPreferences,
        'medicationData': state.medicationData,
        'dayColors': state.dayColors,
        'statistics': state.statistics,
        'appSettings': state.appSettings,
        'doseStatus': state.doseStatus,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      final jsonString = jsonEncode(batch);
      
      // SharedPreferencesとHiveの両方に保存
      await Future.wait([
        _prefs!.setString('app_state', jsonString),
        _hiveBox!.put('app_state', jsonString),
      ]);
      
      Logger.info('アプリ状態統一保存完了');
    } catch (e) {
      Logger.error('アプリ状態統一保存エラー', e);
      rethrow;
    }
  }
  
  /// アプリ状態の統一読み込み
  static Future<AppState> loadAll() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      String? jsonString;
      
      // Hiveから読み込みを試行
      jsonString = _hiveBox!.get('app_state');
      
      // Hiveにない場合はSharedPreferencesから読み込み
      if (jsonString == null || jsonString.isEmpty) {
        jsonString = _prefs!.getString('app_state');
      }
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        return AppState.fromJson(data);
      }
      
      // デフォルト状態を返す
      return AppState.empty();
    } catch (e) {
      Logger.error('アプリ状態統一読み込みエラー', e);
      return AppState.empty();
    }
  }
  
  /// 部分的なデータ保存
  static Future<void> savePartial(String key, dynamic data) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final jsonString = jsonEncode(data);
      
      await Future.wait([
        _prefs!.setString(key, jsonString),
        _hiveBox!.put(key, jsonString),
      ]);
      
      Logger.debug('部分データ保存完了: $key');
    } catch (e) {
      Logger.error('部分データ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// 部分的なデータ読み込み
  static Future<T?> loadPartial<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      String? jsonString;
      
      // Hiveから読み込みを試行
      jsonString = _hiveBox!.get(key);
      
      // Hiveにない場合はSharedPreferencesから読み込み
      if (jsonString == null || jsonString.isEmpty) {
        jsonString = _prefs!.getString(key);
      }
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        return fromJson(data);
      }
      
      return null;
    } catch (e) {
      Logger.error('部分データ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// データの削除
  static Future<void> delete(String key) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await Future.wait([
        _prefs!.remove(key),
        _hiveBox!.delete(key),
      ]);
      
      Logger.debug('データ削除完了: $key');
    } catch (e) {
      Logger.error('データ削除エラー: $key', e);
      rethrow;
    }
  }
  
  /// バックアップの作成
  static Future<Map<String, dynamic>> createBackup() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final state = await loadAll();
      final backup = {
        'appState': state.toJson(),
        'backupDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
      
      Logger.info('バックアップ作成完了');
      return backup;
    } catch (e) {
      Logger.error('バックアップ作成エラー', e);
      rethrow;
    }
  }
  
  /// バックアップからの復元
  static Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final appState = AppState.fromJson(backup['appState'] as Map<String, dynamic>);
      await saveAll(appState);
      
      Logger.info('バックアップからの復元完了');
    } catch (e) {
      Logger.error('バックアップからの復元エラー', e);
      rethrow;
    }
  }
  
  /// 統計情報の取得
  static Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final state = await loadAll();
      return {
        'memosCount': state.memos.length,
        'alarmsCount': state.alarms.length,
        'medicationsCount': state.medications.length,
        'calendarMarksCount': state.calendarMarks.length,
        'lastUpdated': state.lastUpdated,
        'isInitialized': _isInitialized,
      };
    } catch (e) {
      Logger.error('統計情報取得エラー', e);
      return {};
    }
  }
  
  /// リソースの解放
  static Future<void> dispose() async {
    try {
      await _hiveBox?.close();
      _isInitialized = false;
      Logger.info('UnifiedRepository解放完了');
    } catch (e) {
      Logger.error('UnifiedRepository解放エラー', e);
    }
  }
}

/// アプリ状態の統一管理
class AppState {
  final List<dynamic> memos;
  final List<dynamic> alarms;
  final List<dynamic> medications;
  final Map<String, dynamic> calendarMarks;
  final Map<String, dynamic> userPreferences;
  final Map<String, dynamic> medicationData;
  final Map<String, String> dayColors;
  final Map<String, dynamic> statistics;
  final Map<String, dynamic> appSettings;
  final Map<String, dynamic> doseStatus;
  final DateTime? lastUpdated;
  
  AppState({
    required this.memos,
    required this.alarms,
    required this.medications,
    required this.calendarMarks,
    required this.userPreferences,
    required this.medicationData,
    required this.dayColors,
    required this.statistics,
    required this.appSettings,
    required this.doseStatus,
    this.lastUpdated,
  });
  
  /// 空の状態
  factory AppState.empty() {
    return AppState(
      memos: [],
      alarms: [],
      medications: [],
      calendarMarks: {},
      userPreferences: {},
      medicationData: {},
      dayColors: {},
      statistics: {},
      appSettings: {},
      doseStatus: {},
      lastUpdated: DateTime.now(),
    );
  }
  
  /// JSONから作成
  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      memos: (json['memos'] as List<dynamic>?)?.cast<dynamic>() ?? [],
      alarms: (json['alarms'] as List<dynamic>?)?.cast<dynamic>() ?? [],
      medications: (json['medications'] as List<dynamic>?)?.cast<dynamic>() ?? [],
      calendarMarks: (json['calendarMarks'] as Map<String, dynamic>?) ?? {},
      userPreferences: (json['userPreferences'] as Map<String, dynamic>?) ?? {},
      medicationData: (json['medicationData'] as Map<String, dynamic>?) ?? {},
      dayColors: (json['dayColors'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      statistics: (json['statistics'] as Map<String, dynamic>?) ?? {},
      appSettings: (json['appSettings'] as Map<String, dynamic>?) ?? {},
      doseStatus: (json['doseStatus'] as Map<String, dynamic>?) ?? {},
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }
  
  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'memos': memos,
      'alarms': alarms,
      'medications': medications,
      'calendarMarks': calendarMarks,
      'userPreferences': userPreferences,
      'medicationData': medicationData,
      'dayColors': dayColors,
      'statistics': statistics,
      'appSettings': appSettings,
      'doseStatus': doseStatus,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
  
  /// コピーコンストラクタ
  AppState copyWith({
    List<dynamic>? memos,
    List<dynamic>? alarms,
    List<dynamic>? medications,
    Map<String, dynamic>? calendarMarks,
    Map<String, dynamic>? userPreferences,
    Map<String, dynamic>? medicationData,
    Map<String, String>? dayColors,
    Map<String, dynamic>? statistics,
    Map<String, dynamic>? appSettings,
    Map<String, dynamic>? doseStatus,
    DateTime? lastUpdated,
  }) {
    return AppState(
      memos: memos ?? this.memos,
      alarms: alarms ?? this.alarms,
      medications: medications ?? this.medications,
      calendarMarks: calendarMarks ?? this.calendarMarks,
      userPreferences: userPreferences ?? this.userPreferences,
      medicationData: medicationData ?? this.medicationData,
      dayColors: dayColors ?? this.dayColors,
      statistics: statistics ?? this.statistics,
      appSettings: appSettings ?? this.appSettings,
      doseStatus: doseStatus ?? this.doseStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  @override
  String toString() {
    return 'AppState(memos: ${memos.length}, alarms: ${alarms.length}, medications: ${medications.length})';
  }
}
