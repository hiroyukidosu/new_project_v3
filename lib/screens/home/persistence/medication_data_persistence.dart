// lib/screens/home/persistence/medication_data_persistence.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/medication_memo.dart';
import '../../../utils/logger.dart';

/// 服用メモデータの永続化を管理するクラス
class MedicationDataPersistence {
  /// 複数のバックアップキー（3重バックアップ）
  static const List<String> _backupKeys = [
    'medication_memos_backup',
    'medication_memos_backup2',
    'medication_memos_backup3',
    'medication_memos_v2',
  ];

  /// Hiveボックスからメモを読み込み
  Future<List<MedicationMemo>> loadMedicationMemos() async {
    try {
      // 1. Hiveから読み込み
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        final memos = box.values.toList();
        if (memos.isNotEmpty) {
          Logger.info('Hiveから読み込み成功: ${memos.length}件');
          return memos;
        }
      }

      // 2. SharedPreferencesからバックアップ復元
      return await _loadFromSharedPreferences();
    } catch (e) {
      Logger.error('メモ読み込みエラー', e);
      return [];
    }
  }

  /// SharedPreferencesから復元
  Future<List<MedicationMemo>> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final key in _backupKeys) {
      try {
        final jsonString = prefs.getString(key);
        if (jsonString != null && jsonString.isNotEmpty) {
          final List<dynamic> memosList = jsonDecode(jsonString);
          final memos = memosList
              .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
              .toList();
          Logger.info('SharedPreferencesから復元: ${memos.length}件 ($key)');
          return memos;
        }
      } catch (e) {
        Logger.warning('キー $key の読み込みエラー: $e');
        continue;
      }
    }
    
    Logger.warning('全てのバックアップが見つかりません');
    return [];
  }

  /// メモをHiveとSharedPreferencesに保存
  Future<void> saveMedicationMemo(MedicationMemo memo) async {
    try {
      // 1. Hiveに保存
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        await box.put(memo.id, memo);
      }
      
      // 2. SharedPreferencesにバックアップ
      await _backupToSharedPreferences();
      
      Logger.info('メモ保存完了: ${memo.name}');
    } catch (e) {
      Logger.error('メモ保存エラー', e);
      rethrow;
    }
  }

  /// 複数のメモを一括保存
  Future<void> saveMedicationMemos(List<MedicationMemo> memos) async {
    try {
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        for (final memo in memos) {
          await box.put(memo.id, memo);
        }
      }
      
      await _backupToSharedPreferences();
      Logger.info('メモ一括保存完了: ${memos.length}件');
    } catch (e) {
      Logger.error('メモ一括保存エラー', e);
      rethrow;
    }
  }

  /// メモを削除
  Future<void> deleteMedicationMemo(String memoId) async {
    try {
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        await box.delete(memoId);
      }
      
      await _backupToSharedPreferences();
      Logger.info('メモ削除完了: $memoId');
    } catch (e) {
      Logger.error('メモ削除エラー', e);
      rethrow;
    }
  }

  /// SharedPreferencesへのバックアップ保存
  Future<void> _backupToSharedPreferences() async {
    try {
      if (!Hive.isBoxOpen('medication_memos')) return;
      
      final box = Hive.box<MedicationMemo>('medication_memos');
      final memos = box.values.toList();
      
      if (memos.isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      final memosJson = memos.map((memo) => memo.toJson()).toList();
      final jsonString = jsonEncode(memosJson);
      
      // 複数キーに保存（3重バックアップ）
      await Future.wait(_backupKeys.map((key) => 
        prefs.setString(key, jsonString)
      ));
      
      Logger.debug('バックアップ保存完了: ${memos.length}件');
    } catch (e) {
      Logger.error('バックアップ保存エラー', e);
    }
  }

  /// メモステータスを保存
  Future<void> saveMedicationMemoStatus(Map<String, bool> status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = status.map((key, value) => MapEntry(key, value));
      
      await prefs.setString('medication_memo_status_v2', jsonEncode(statusJson));
      await prefs.setString('medication_memo_status_backup', jsonEncode(statusJson));
      
      Logger.debug('メモステータス保存完了: ${status.length}件');
    } catch (e) {
      Logger.error('メモステータス保存エラー', e);
    }
  }

  /// メモステータスを読み込み
  Future<Map<String, bool>> loadMedicationMemoStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final key in ['medication_memo_status_v2', 'medication_memo_status_backup']) {
        final jsonString = prefs.getString(key);
        if (jsonString != null && jsonString.isNotEmpty) {
          final Map<String, dynamic> statusJson = jsonDecode(jsonString);
          return statusJson.map((key, value) => MapEntry(key, value as bool));
        }
      }
      
      return {};
    } catch (e) {
      Logger.error('メモステータス読み込みエラー', e);
      return {};
    }
  }

  /// 曜日別服用ステータスを保存
  Future<void> saveWeekdayMedicationStatus(Map<String, Map<String, bool>> status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = status.map((key, value) => MapEntry(key, value));
      
      await prefs.setString('weekday_medication_status_v2', jsonEncode(statusJson));
      Logger.debug('曜日別ステータス保存完了');
    } catch (e) {
      Logger.error('曜日別ステータス保存エラー', e);
    }
  }

  /// 曜日別服用ステータスを読み込み
  Future<Map<String, Map<String, bool>>> loadWeekdayMedicationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('weekday_medication_status_v2');
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> statusJson = jsonDecode(jsonString);
        return statusJson.map((key, value) => 
          MapEntry(key, Map<String, bool>.from(value as Map))
        );
      }
      
      return {};
    } catch (e) {
      Logger.error('曜日別ステータス読み込みエラー', e);
      return {};
    }
  }

  /// 服用回数別ステータスを保存
  Future<void> saveMedicationDoseStatus(
    Map<String, Map<String, Map<int, bool>>> doseStatus
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // JSON変換可能な形式に変換
      final jsonData = doseStatus.map((dateKey, dateValue) => 
        MapEntry(dateKey, dateValue.map((memoKey, memoValue) => 
          MapEntry(memoKey, memoValue.map((doseKey, doseValue) => 
            MapEntry(doseKey.toString(), doseValue)
          ))
        ))
      );
      
      await prefs.setString('medication_dose_status_v2', jsonEncode(jsonData));
      Logger.debug('服用回数別ステータス保存完了');
    } catch (e) {
      Logger.error('服用回数別ステータス保存エラー', e);
    }
  }

  /// 服用回数別ステータスを読み込み
  Future<Map<String, Map<String, Map<int, bool>>>> loadMedicationDoseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('medication_dose_status_v2');
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        
        return jsonData.map((dateKey, dateValue) => 
          MapEntry(dateKey, (dateValue as Map<String, dynamic>).map((memoKey, memoValue) => 
            MapEntry(memoKey, (memoValue as Map<String, dynamic>).map((doseKey, doseValue) => 
              MapEntry(int.parse(doseKey), doseValue as bool)
            ))
          ))
        );
      }
      
      return {};
    } catch (e) {
      Logger.error('服用回数別ステータス読み込みエラー', e);
      return {};
    }
  }
}

