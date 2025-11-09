// lib/screens/home/persistence/medication_data_persistence.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/medication_memo.dart';
import '../../../utils/logger.dart';

/// 服用メモデータの永続化を管理するクラス
class MedicationDataPersistence {
  // Hive box name for monthly-segmented app data
  static const String _appDataBox = 'medication_data';

  /// 複数のバックアップキー（3重バックアップ）
  static const List<String> _backupKeys = [
    'medication_memos_backup',
    'medication_memos_backup2',
    'medication_memos_backup3',
    'medication_memos_v2',
  ];

  // Monthly-segmented key prefixes
  static const String _dosePrefix = 'dose_status'; // dose_status_YYYY-MM
  static const String _weekdayPrefix = 'weekday_status'; // weekday_status_YYYY-MM
  static const String _memoEnabledPrefix = 'memo_enabled'; // memo_enabled_YYYY-MM

  // Data versioning for migration control
  static const String _dataVersionKey = 'data_version';
  static const int _currentVersion = 2; // v2 => Hive monthly segmented

  static String _monthKey(String prefix, DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '${prefix}_${y}-${m}';
  }

  static bool _isMonthlyKey(String key, String prefix) {
    return key.startsWith('${prefix}_') && RegExp(r'_\d{4}-\d{2}$').hasMatch(key);
  }

  Future<Box> _openAppDataBox() async {
    // medication_dataボックスを型指定なしで開く（Mapやintなど複雑なデータ構造を保存するため）
    if (!Hive.isBoxOpen(_appDataBox)) {
      return await Hive.openBox(_appDataBox);
    } else {
      // 既に開かれている場合は既存のBoxを返す
      return Hive.box(_appDataBox);
    }
  }

  Future<void> _ensureMigratedToHiveMonthly() async {
    final box = await _openAppDataBox();
    // 型指定なしのBoxなので、intとして取得可能（型チェック付き）
    final versionValue = box.get(_dataVersionKey);
    final version = versionValue is int 
        ? versionValue 
        : (versionValue is String 
            ? int.tryParse(versionValue) ?? 1 
            : 1);
    if (version >= _currentVersion) return;

    try {
      // 1) migrate dose status
      final prefs = await SharedPreferences.getInstance();
      final doseJson = prefs.getString('medication_dose_status_v2');
      if (doseJson != null && doseJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(doseJson);
        final Map<String, Map<String, Map<int, bool>>> doseStatus = data.map((dateKey, dateValue) =>
          MapEntry(dateKey, (dateValue as Map<String, dynamic>).map((memoKey, memoValue) =>
            MapEntry(memoKey, (memoValue as Map<String, dynamic>).map((doseKey, doseValue) =>
              MapEntry(int.parse(doseKey), doseValue as bool)
            ))
          ))
        );

        final Map<String, Map<String, dynamic>> monthly = {};
        doseStatus.forEach((dateStr, memoMap) {
          // dateStr expected yyyy-MM-dd
          final parts = dateStr.split('-');
          if (parts.length < 2) return;
          final monthKey = '${_dosePrefix}_${parts[0]}-${parts[1]}';
          monthly.putIfAbsent(monthKey, () => {
            'month': '${parts[0]}-${parts[1]}',
            'records': <String, dynamic>{},
            'updated_at': DateTime.now().toIso8601String(),
          });
          // store original per-date memo/dose map to keep fidelity
          (monthly[monthKey]!['records'] as Map<String, dynamic>)[dateStr] = memoMap.map((memoId, doseMap) =>
            MapEntry(memoId, doseMap.map((k, v) => MapEntry(k.toString(), v)))
          );
        });

        for (final entry in monthly.entries) {
          await box.put(entry.key, entry.value);
        }
        await prefs.remove('medication_dose_status_v2');
      }

      // 2) migrate weekday status
      final weekdayJson = prefs.getString('weekday_medication_status_v2');
      if (weekdayJson != null && weekdayJson.isNotEmpty) {
        // 可能な限り、既存のdose_status月に複製して配置
        final weekdayData = jsonDecode(weekdayJson);
        final Set<String> doseMonths = box.keys.whereType<String>()
            .where((k) => _isMonthlyKey(k, _dosePrefix))
            .map((k) => k.split('_').last)
            .toSet();
        if (doseMonths.isEmpty) {
          final now = DateTime.now();
          doseMonths.add('${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}');
        }
        for (final month in doseMonths) {
          await box.put('${_weekdayPrefix}_$month', {
            'month': month,
            'weekdays': weekdayData,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
        await prefs.remove('weekday_medication_status_v2');
      }

      // 3) medication memo ON/OFF status
      final memoStatusJson = prefs.getString('medication_memo_status_v2');
      if (memoStatusJson != null && memoStatusJson.isNotEmpty) {
        final enabledData = jsonDecode(memoStatusJson);
        final Set<String> doseMonths = box.keys.whereType<String>()
            .where((k) => _isMonthlyKey(k, _dosePrefix))
            .map((k) => k.split('_').last)
            .toSet();
        if (doseMonths.isEmpty) {
          final now = DateTime.now();
          doseMonths.add('${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}');
        }
        for (final month in doseMonths) {
          await box.put('${_memoEnabledPrefix}_$month', {
            'month': month,
            'enabled': enabledData,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
        await prefs.remove('medication_memo_status_v2');
        await prefs.remove('medication_memo_status_backup');
      }

      // 型指定なしのBoxなので、intを直接保存可能
      await box.put(_dataVersionKey, _currentVersion);
      Logger.info('Hive monthly migration completed');
    } catch (e, stackTrace) {
      Logger.error('Hive monthly migration failed', e);
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('Hive monthly migration failed: _ensureMigratedToHiveMonthly');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
    }
  }

  /// Hiveボックスからメモを読み込み（フレーム分散対応）
  Future<List<MedicationMemo>> loadMedicationMemos() async {
    try {
      // 1. Hiveから読み込み
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        
        // フレーム分散で読み込み（大量データの場合に有効）
        final allValues = box.values;
        final memos = <MedicationMemo>[];
        
        // バッチ処理でフレーム分散
        const batchSize = 50;
        int count = 0;
        
        for (final memo in allValues) {
          memos.add(memo);
          count++;
          
          // 一定数ごとにUIスレッドに制御を返す
          if (count % batchSize == 0) {
            await Future.delayed(Duration.zero);
          }
        }
        
        if (memos.isNotEmpty) {
          Logger.info('Hiveから読み込み成功: ${memos.length}件');
          return memos;
        }
      }

      // 2. SharedPreferencesからバックアップ復元
      return await _loadFromSharedPreferences();
    } catch (e, stackTrace) {
      Logger.error('メモ読み込みエラー', e);
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('メモ読み込みエラー: loadMedicationMemos');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
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
      await _ensureMigratedToHiveMonthly();
      final box = await _openAppDataBox();
      final now = DateTime.now();
      final monthKey = _monthKey(_memoEnabledPrefix, now);
      final existing = (box.get(monthKey) as Map?) ?? {
        'month': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}',
        'enabled': <String, dynamic>{},
        'updated_at': DateTime.now().toIso8601String(),
      };
      existing['enabled'] = status.map((k, v) => MapEntry(k, v));
      existing['updated_at'] = DateTime.now().toIso8601String();
      await box.put(monthKey, existing);
      Logger.debug('メモステータス保存完了(Hive): ${status.length}件');
    } catch (e) {
      Logger.error('メモステータス保存エラー', e);
    }
  }

  /// メモステータスを読み込み
  Future<Map<String, bool>> loadMedicationMemoStatus() async {
    try {
      await _ensureMigratedToHiveMonthly();
      final box = await _openAppDataBox();
      final Map<String, bool> result = {};
      for (final key in box.keys) {
        if (key is String && _isMonthlyKey(key, _memoEnabledPrefix)) {
          final data = box.get(key);
          if (data is Map && data['enabled'] is Map) {
            (data['enabled'] as Map).forEach((k, v) {
              result[k.toString()] = v == true;
            });
          }
        }
      }
      return result;
    } catch (e) {
      Logger.error('メモステータス読み込みエラー', e);
      return {};
    }
  }

  /// 曜日別服用ステータスを保存
  Future<void> saveWeekdayMedicationStatus(Map<String, Map<String, bool>> status) async {
    try {
      await _ensureMigratedToHiveMonthly();
      final box = await _openAppDataBox();
      final now = DateTime.now();
      final monthKey = _monthKey(_weekdayPrefix, now);
      final existing = (box.get(monthKey) as Map?) ?? {
        'month': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}',
        'weekdays': <String, dynamic>{},
        'updated_at': DateTime.now().toIso8601String(),
      };
      existing['weekdays'] = status.map((k, v) => MapEntry(k, v));
      existing['updated_at'] = DateTime.now().toIso8601String();
      await box.put(monthKey, existing);
      Logger.debug('曜日別ステータス保存完了(Hive)');
    } catch (e) {
      Logger.error('曜日別ステータス保存エラー', e);
    }
  }

  /// 曜日別服用ステータスを読み込み
  /// 戻り値: Map<月別キー, Map<日付文字列, Map<メモID, bool>>>
  Future<Map<String, Map<String, Map<String, bool>>>> loadWeekdayMedicationStatus() async {
    try {
      await _ensureMigratedToHiveMonthly();
      final box = await _openAppDataBox();
      final Map<String, Map<String, Map<String, bool>>> result = {};
      for (final key in box.keys) {
        if (key is String && _isMonthlyKey(key, _weekdayPrefix)) {
          final data = box.get(key);
          if (data is Map && data['weekdays'] is Map) {
            final weekdays = data['weekdays'] as Map;
            final monthData = <String, Map<String, bool>>{};
            
            // weekdaysは Map<日付文字列, Map<メモID, bool>> 形式
            for (final dateEntry in weekdays.entries) {
              final dateStr = dateEntry.key.toString();
              final memoStatus = dateEntry.value;
              
              if (memoStatus is Map) {
                monthData[dateStr] = Map<String, bool>.from(
                  memoStatus.map((k, v) => MapEntry(k.toString(), v == true))
                );
              }
            }
            
            result[key] = monthData;
          }
        }
      }
      return result;
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
      await _ensureMigratedToHiveMonthly();
      final box = await _openAppDataBox();
      // Group by month (YYYY-MM)
      final Map<String, Map<String, dynamic>> monthly = {};
      doseStatus.forEach((dateStr, memoMap) {
        // dateStr expected yyyy-MM-dd
        final parts = dateStr.split('-');
        if (parts.length < 2) return;
        final monthKey = '${_dosePrefix}_${parts[0]}-${parts[1]}';
        monthly.putIfAbsent(monthKey, () => {
          'month': '${parts[0]}-${parts[1]}',
          'records': <String, dynamic>{},
          'updated_at': DateTime.now().toIso8601String(),
        });
        (monthly[monthKey]!['records'] as Map<String, dynamic>)[dateStr] = memoMap.map((memoId, doseMap) =>
          MapEntry(memoId, doseMap.map((k, v) => MapEntry(k.toString(), v)))
        );
        monthly[monthKey]!['updated_at'] = DateTime.now().toIso8601String();
      });

      for (final entry in monthly.entries) {
        // Merge with existing month to avoid overwriting other dates
        final existing = (box.get(entry.key) as Map?) ?? {
          'month': entry.value['month'],
          'records': <String, dynamic>{},
          'updated_at': DateTime.now().toIso8601String(),
        };
        final existingRecords = Map<String, dynamic>.from(existing['records'] as Map);
        existingRecords.addAll(entry.value['records'] as Map<String, dynamic>);
        existing['records'] = existingRecords;
        existing['updated_at'] = DateTime.now().toIso8601String();
        await box.put(entry.key, existing);
      }

      Logger.debug('服用回数別ステータス保存完了(Hive)');
    } catch (e) {
      Logger.error('服用回数別ステータス保存エラー', e);
    }
  }

  /// 服用回数別ステータスを読み込み
  Future<Map<String, Map<String, Map<int, bool>>>> loadMedicationDoseStatus() async {
    try {
      await _ensureMigratedToHiveMonthly();
      final box = await _openAppDataBox();
      final Map<String, Map<String, Map<int, bool>>> result = {};
      for (final key in box.keys) {
        if (key is String && _isMonthlyKey(key, _dosePrefix)) {
          final data = box.get(key);
          if (data is Map && data['records'] is Map) {
            final recs = data['records'] as Map;
            for (final entry in recs.entries) {
              final dateStr = entry.key.toString();
              final memoMap = entry.value as Map;
              result[dateStr] = memoMap.map((memoId, doseMap) =>
                MapEntry(memoId.toString(), (doseMap as Map).map((k, v) => MapEntry(int.parse(k.toString()), v == true)))
              );
            }
          }
        }
      }
      return result;
    } catch (e) {
      Logger.error('服用回数別ステータス読み込みエラー', e);
      return {};
    }
  }
}

