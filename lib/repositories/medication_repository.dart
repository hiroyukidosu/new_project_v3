import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication_memo.dart';
import '../utils/logger.dart';

/// メディケーションデータのリポジトリ
class MedicationRepository {
  static const String _memosKey = 'medication_memos';
  static const String _statusKey = 'medication_memo_status';
  static const String _weekdayKey = 'weekday_medication_status';
  static const String _addedKey = 'added_medications';
  static const String _alarmKey = 'alarm_data';
  static const String _calendarKey = 'calendar_marks';
  static const String _preferencesKey = 'user_preferences';
  static const String _medicationDataKey = 'medication_data';
  static const String _dayColorsKey = 'day_colors';
  static const String _statisticsKey = 'statistics';
  static const String _appSettingsKey = 'app_settings';
  static const String _doseStatusKey = 'medication_dose_status';
  
  late SharedPreferences _prefs;
  late Box<MedicationMemo> _memoBox;
  late Box<String> _dataBox;
  
  /// リポジトリの初期化
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await Hive.initFlutter();
      
      // Hiveアダプターの登録
      if (!Hive.isAdapterRegistered(MedicationMemoAdapter().typeId)) {
        Hive.registerAdapter(MedicationMemoAdapter());
      }
      
      _memoBox = await Hive.openBox<MedicationMemo>('medication_memos');
      _dataBox = await Hive.openBox<String>('medication_data');
      
      Logger.info('MedicationRepository初期化完了');
    } catch (e) {
      Logger.error('MedicationRepository初期化エラー', e);
      rethrow;
    }
  }
  
  /// メモの取得
  Future<List<MedicationMemo>> getMemos() async {
    try {
      final memos = _memoBox.values.toList();
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
      await _memoBox.put(memo.id, memo);
      await _prefs.setString('memo_${memo.id}', jsonEncode(memo.toJson()));
      Logger.debug('メモ保存完了: ${memo.id}');
    } catch (e) {
      Logger.error('メモ保存エラー: ${memo.id}', e);
      rethrow;
    }
  }
  
  /// メモの削除
  Future<void> deleteMemo(String id) async {
    try {
      await _memoBox.delete(id);
      await _prefs.remove('memo_$id');
      Logger.debug('メモ削除完了: $id');
    } catch (e) {
      Logger.error('メモ削除エラー: $id', e);
      rethrow;
    }
  }
  
  /// メモステータスの取得
  Future<Map<String, bool>> getMemoStatus() async {
    try {
      final statusJson = _prefs.getString(_statusKey);
      if (statusJson != null) {
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
      await _prefs.setString(_statusKey, jsonEncode(status));
      await _dataBox.put(_statusKey, jsonEncode(status));
      Logger.debug('メモステータス保存完了');
    } catch (e) {
      Logger.error('メモステータス保存エラー', e);
      rethrow;
    }
  }
  
  /// 曜日メディケーションステータスの取得
  Future<Map<String, bool>> getWeekdayMedicationStatus() async {
    try {
      final statusJson = _prefs.getString(_weekdayKey);
      if (statusJson != null) {
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
      await _prefs.setString(_weekdayKey, jsonEncode(status));
      await _dataBox.put(_weekdayKey, jsonEncode(status));
      Logger.debug('曜日メディケーションステータス保存完了');
    } catch (e) {
      Logger.error('曜日メディケーションステータス保存エラー', e);
      rethrow;
    }
  }
  
  /// 追加メディケーションの取得
  Future<List<Map<String, dynamic>>> getAddedMedications() async {
    try {
      final medicationsJson = _prefs.getString(_addedKey);
      if (medicationsJson != null) {
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
      await _prefs.setString(_addedKey, jsonEncode(medications));
      await _dataBox.put(_addedKey, jsonEncode(medications));
      Logger.debug('追加メディケーション保存完了: ${medications.length}件');
    } catch (e) {
      Logger.error('追加メディケーション保存エラー', e);
      rethrow;
    }
  }
  
  /// アラームデータの取得
  Future<Map<String, dynamic>> getAlarmData() async {
    try {
      final alarmJson = _prefs.getString(_alarmKey);
      if (alarmJson != null) {
        return jsonDecode(alarmJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      Logger.error('アラームデータ取得エラー', e);
      return {};
    }
  }
  
  /// アラームデータの保存
  Future<void> saveAlarmData(Map<String, dynamic> alarmData) async {
    try {
      await _prefs.setString(_alarmKey, jsonEncode(alarmData));
      await _dataBox.put(_alarmKey, jsonEncode(alarmData));
      Logger.debug('アラームデータ保存完了');
    } catch (e) {
      Logger.error('アラームデータ保存エラー', e);
      rethrow;
    }
  }
  
  /// カレンダーマークの取得
  Future<Map<String, dynamic>> getCalendarMarks() async {
    try {
      final marksJson = _prefs.getString(_calendarKey);
      if (marksJson != null) {
        return jsonDecode(marksJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      Logger.error('カレンダーマーク取得エラー', e);
      return {};
    }
  }
  
  /// カレンダーマークの保存
  Future<void> saveCalendarMarks(Map<String, dynamic> marks) async {
    try {
      await _prefs.setString(_calendarKey, jsonEncode(marks));
      await _dataBox.put(_calendarKey, jsonEncode(marks));
      Logger.debug('カレンダーマーク保存完了');
    } catch (e) {
      Logger.error('カレンダーマーク保存エラー', e);
      rethrow;
    }
  }
  
  /// ユーザー設定の取得
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefsJson = _prefs.getString(_preferencesKey);
      if (prefsJson != null) {
        return jsonDecode(prefsJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      Logger.error('ユーザー設定取得エラー', e);
      return {};
    }
  }
  
  /// ユーザー設定の保存
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _prefs.setString(_preferencesKey, jsonEncode(preferences));
      await _dataBox.put(_preferencesKey, jsonEncode(preferences));
      Logger.debug('ユーザー設定保存完了');
    } catch (e) {
      Logger.error('ユーザー設定保存エラー', e);
      rethrow;
    }
  }
  
  /// メディケーションデータの取得
  Future<Map<String, dynamic>> getMedicationData() async {
    try {
      final dataJson = _prefs.getString(_medicationDataKey);
      if (dataJson != null) {
        return jsonDecode(dataJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      Logger.error('メディケーションデータ取得エラー', e);
      return {};
    }
  }
  
  /// メディケーションデータの保存
  Future<void> saveMedicationData(Map<String, dynamic> data) async {
    try {
      await _prefs.setString(_medicationDataKey, jsonEncode(data));
      await _dataBox.put(_medicationDataKey, jsonEncode(data));
      Logger.debug('メディケーションデータ保存完了');
    } catch (e) {
      Logger.error('メディケーションデータ保存エラー', e);
      rethrow;
    }
  }
  
  /// 日付色の取得
  Future<Map<String, String>> getDayColors() async {
    try {
      final colorsJson = _prefs.getString(_dayColorsKey);
      if (colorsJson != null) {
        final colors = jsonDecode(colorsJson) as Map<String, dynamic>;
        return colors.map((key, value) => MapEntry(key, value as String));
      }
      return {};
    } catch (e) {
      Logger.error('日付色取得エラー', e);
      return {};
    }
  }
  
  /// 日付色の保存
  Future<void> saveDayColors(Map<String, String> colors) async {
    try {
      await _prefs.setString(_dayColorsKey, jsonEncode(colors));
      await _dataBox.put(_dayColorsKey, jsonEncode(colors));
      Logger.debug('日付色保存完了');
    } catch (e) {
      Logger.error('日付色保存エラー', e);
      rethrow;
    }
  }
  
  /// 統計データの取得
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final statsJson = _prefs.getString(_statisticsKey);
      if (statsJson != null) {
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
      await _prefs.setString(_statisticsKey, jsonEncode(statistics));
      await _dataBox.put(_statisticsKey, jsonEncode(statistics));
      Logger.debug('統計データ保存完了');
    } catch (e) {
      Logger.error('統計データ保存エラー', e);
      rethrow;
    }
  }
  
  /// アプリ設定の取得
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final settingsJson = _prefs.getString(_appSettingsKey);
      if (settingsJson != null) {
        return jsonDecode(settingsJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      Logger.error('アプリ設定取得エラー', e);
      return {};
    }
  }
  
  /// アプリ設定の保存
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      await _prefs.setString(_appSettingsKey, jsonEncode(settings));
      await _dataBox.put(_appSettingsKey, jsonEncode(settings));
      Logger.debug('アプリ設定保存完了');
    } catch (e) {
      Logger.error('アプリ設定保存エラー', e);
      rethrow;
    }
  }
  
  /// 服用ステータスの取得
  Future<Map<String, dynamic>> getMedicationDoseStatus() async {
    try {
      final statusJson = _prefs.getString(_doseStatusKey);
      if (statusJson != null) {
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
      await _prefs.setString(_doseStatusKey, jsonEncode(status));
      await _dataBox.put(_doseStatusKey, jsonEncode(status));
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
        'alarmData': await getAlarmData(),
        'calendarMarks': await getCalendarMarks(),
        'userPreferences': await getUserPreferences(),
        'medicationData': await getMedicationData(),
        'dayColors': await getDayColors(),
        'statistics': await getStatistics(),
        'appSettings': await getAppSettings(),
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
      await _memoBox.close();
      await _dataBox.close();
      Logger.info('MedicationRepository解放完了');
    } catch (e) {
      Logger.error('MedicationRepository解放エラー', e);
    }
  }
}
