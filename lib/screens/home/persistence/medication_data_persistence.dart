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

  /// 削除されたメモIDのリスト（復元を防ぐため）
  static const String _deletedMemoIdsKey = 'deleted_medication_memo_ids';

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

  /// Hiveボックスからメモを読み込み（フレーム分散対応、2年分のみ）
  /// 重要: Hiveが存在する場合は、SharedPreferencesから復元しない（削除された状態を反映）
  Future<List<MedicationMemo>> loadMedicationMemos() async {
    try {
      // 1. Hiveから読み込み（常にHiveを優先、削除された状態を反映）
      Box<MedicationMemo>? box;
      
      // Hiveボックスを開く（既に開かれている場合は取得）
      if (Hive.isBoxOpen('medication_memos')) {
        box = Hive.box<MedicationMemo>('medication_memos');
      } else {
        // ボックスが開かれていない場合、開いてみる
        try {
          box = await Hive.openBox<MedicationMemo>('medication_memos');
        } catch (e) {
          // ボックスが存在しない場合（初回起動時）
          Logger.warning('Hiveボックスが存在しません。初回起動とみなし、SharedPreferencesから復元を試みます');
          return await _loadFromSharedPreferences();
        }
      }

      // Hiveボックスが存在する場合は、Hiveから読み込む（削除された状態を反映）
      // 2年分のみ読み込む（10年運用時のパフォーマンス最適化）
      final cutoffDate = DateTime.now().subtract(const Duration(days: 365 * 2));
      
      // 削除されたメモIDのリストを取得（念のため二重チェック）
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList(_deletedMemoIdsKey) ?? <String>[];
      
      // 削除IDリストに含まれているメモをHiveから物理的に削除（確実に削除するため）
      // 重要: allValuesを取得する前に削除する（削除されたメモが含まれないようにする）
      if (deletedIds.isNotEmpty) {
        int physicallyDeletedCount = 0;
        for (final deletedId in deletedIds) {
          try {
            if (box.containsKey(deletedId)) {
              await box.delete(deletedId);
              physicallyDeletedCount++;
            }
          } catch (e) {
            Logger.warning('削除IDリストのメモをHiveから削除エラー: $deletedId - $e');
          }
        }
        if (physicallyDeletedCount > 0) {
          Logger.info('削除IDリストのメモをHiveから物理的に削除: ${physicallyDeletedCount}件');
          // 削除後にバックアップを更新（削除された状態を反映）
          await _backupToSharedPreferences();
        }
      }
      
      // フレーム分散で読み込み（大量データの場合に有効）
      // 削除IDリストのメモは既に物理的に削除されているため、allValuesには含まれない
      final allValues = box.values;
      final memos = <MedicationMemo>[];
      
      // バッチ処理でフレーム分散
      const batchSize = 50;
      int count = 0;
      int filteredCount = 0;
      int deletedCount = 0;
      
      for (final memo in allValues) {
        // 削除されたメモIDリストに含まれている場合は除外（念のため二重チェック）
        // 既に物理的に削除されているはずだが、念のためチェック
        if (deletedIds.contains(memo.id)) {
          deletedCount++;
          // 念のため、まだHiveに残っている場合は削除（通常は発生しない）
          try {
            await box.delete(memo.id);
            Logger.warning('削除IDリストのメモがまだHiveに残っていたため削除: ${memo.id}');
          } catch (_) {
            // 削除エラーは無視
          }
          continue;
        }
        
        // 2年以内のメモのみ追加
        if (memo.createdAt.isAfter(cutoffDate)) {
          memos.add(memo);
          count++;
          
          // 一定数ごとにUIスレッドに制御を返す
          if (count % batchSize == 0) {
            await Future.delayed(Duration.zero);
          }
        } else {
          filteredCount++;
        }
      }
      
      // Hiveから読み込めた場合は、そのまま返す（削除されたメモは含まれない）
      // 空のリストでも返す（削除された状態を反映）
      // 重要: SharedPreferencesから復元しない（削除された状態を維持）
      if (deletedCount > 0) {
        Logger.info('Hiveから読み込み成功: ${memos.length}件（${filteredCount}件をフィルタリング、${deletedCount}件の削除されたメモを除外）');
      } else {
        Logger.info('Hiveから読み込み成功: ${memos.length}件（${filteredCount}件をフィルタリング、削除されたメモは含まれない）');
      }
      
      // 新しい順にソート
      memos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return memos;
    } catch (e, stackTrace) {
      Logger.error('メモ読み込みエラー', e);
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('メモ読み込みエラー: loadMedicationMemos');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
      // エラー時は空のリストを返す（削除された状態を反映）
      return [];
    }
  }

  /// SharedPreferencesから復元（削除されたメモは除外）
  /// 重要: このメソッドは初回起動時のみ呼ばれる（Hiveが存在しない場合）
  Future<List<MedicationMemo>> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 削除されたメモIDのリストを取得
    final deletedIds = prefs.getStringList(_deletedMemoIdsKey) ?? <String>[];
    Logger.debug('削除されたメモID: ${deletedIds.length}件');
    
    for (final key in _backupKeys) {
      try {
        final jsonString = prefs.getString(key);
        if (jsonString != null && jsonString.isNotEmpty) {
          final List<dynamic> memosList = jsonDecode(jsonString);
          
          // 削除されたメモを除外
          final memos = memosList
              .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
              .where((memo) => !deletedIds.contains(memo.id)) // 削除されたメモを除外
              .toList();
          
          final filteredCount = memosList.length - memos.length;
          if (filteredCount > 0) {
            Logger.info('SharedPreferencesから復元: ${memos.length}件（${filteredCount}件の削除されたメモを除外） ($key)');
          } else {
            Logger.info('SharedPreferencesから復元: ${memos.length}件 ($key)');
          }
          
          // 復元したメモをHiveに保存（次回からHiveから読み込むため）
          if (memos.isNotEmpty && Hive.isBoxOpen('medication_memos')) {
            final box = Hive.box<MedicationMemo>('medication_memos');
            for (final memo in memos) {
              await box.put(memo.id, memo);
            }
            Logger.debug('復元したメモをHiveに保存: ${memos.length}件');
          }
          
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
      
      // 2. 削除IDリストから削除（メモが再作成された場合）
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList(_deletedMemoIdsKey) ?? <String>[];
      if (deletedIds.contains(memo.id)) {
        deletedIds.remove(memo.id);
        await prefs.setStringList(_deletedMemoIdsKey, deletedIds);
        Logger.debug('削除IDリストから削除: ${memo.id}（メモが再作成されました）');
      }
      
      // 3. SharedPreferencesにバックアップ
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
      
      // 削除IDリストから削除（メモが再作成された場合）
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList(_deletedMemoIdsKey) ?? <String>[];
      bool deletedIdsUpdated = false;
      for (final memo in memos) {
        if (deletedIds.contains(memo.id)) {
          deletedIds.remove(memo.id);
          deletedIdsUpdated = true;
        }
      }
      if (deletedIdsUpdated) {
        await prefs.setStringList(_deletedMemoIdsKey, deletedIds);
        Logger.debug('削除IDリストから削除: ${memos.length}件のメモが再作成されました');
      }
      
      await _backupToSharedPreferences();
      Logger.info('メモ一括保存完了: ${memos.length}件');
    } catch (e) {
      Logger.error('メモ一括保存エラー', e);
      rethrow;
    }
  }

  /// メモを削除（HiveとSharedPreferencesの両方から削除）
  /// 重要: 削除後に必ずバックアップを更新して、削除された状態を反映
  Future<void> deleteMedicationMemo(String memoId) async {
    try {
      Logger.info('🔴 メモ削除開始: $memoId');
      
      // 1. 削除されたメモIDをSharedPreferencesに記録（復元を防ぐため）
      // 重要: Hiveから削除する前に記録する（確実に記録されるように）
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList(_deletedMemoIdsKey) ?? <String>[];
      if (!deletedIds.contains(memoId)) {
        deletedIds.add(memoId);
        await prefs.setStringList(_deletedMemoIdsKey, deletedIds);
        Logger.info('✅ 削除されたメモIDを記録: $memoId（削除IDリスト: ${deletedIds.length}件）');
      } else {
        Logger.debug('削除IDリストに既に記録済み: $memoId');
      }
      
      // 2. Hiveから削除
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        if (box.containsKey(memoId)) {
          await box.delete(memoId);
          Logger.info('✅ Hiveからメモ削除: $memoId');
        } else {
          Logger.warning('⚠️ Hiveにメモが存在しません: $memoId');
        }
      } else {
        Logger.warning('⚠️ medication_memosボックスが開かれていません');
      }
      
      // 3. SharedPreferencesのバックアップを更新（削除されたメモは含まれない）
      // 重要: 削除後に必ずバックアップを更新して、削除された状態を反映
      // これにより、次回起動時に削除されたメモが復元されない
      await _backupToSharedPreferences();
      
      Logger.info('✅ メモ削除完了: $memoId（Hiveから削除、削除IDリストに記録、バックアップ更新）');
    } catch (e) {
      Logger.error('メモ削除エラー', e);
      rethrow;
    }
  }

  /// 古いメモをアーカイブ（2年以上前のメモをアーカイブボックスに移動）
  Future<int> archiveOldMemos({int keepYears = 2}) async {
    try {
      if (!Hive.isBoxOpen('medication_memos')) {
        Logger.warning('medication_memosボックスが開かれていません');
        return 0;
      }

      final box = Hive.box<MedicationMemo>('medication_memos');
      final cutoffDate = DateTime.now().subtract(Duration(days: 365 * keepYears));
      
      // アーカイブボックスを開く（存在しない場合は作成）
      Box<MedicationMemo> archiveBox;
      if (Hive.isBoxOpen('medication_memos_archive')) {
        archiveBox = Hive.box<MedicationMemo>('medication_memos_archive');
      } else {
        archiveBox = await Hive.openBox<MedicationMemo>('medication_memos_archive');
      }

      final oldMemos = box.values
          .where((memo) => memo.createdAt.isBefore(cutoffDate))
          .toList();

      int archivedCount = 0;
      for (final memo in oldMemos) {
        try {
          // アーカイブボックスに移動
          await archiveBox.put(memo.id, memo);
          // 元のボックスから削除
          await box.delete(memo.id);
          archivedCount++;
        } catch (e) {
          Logger.error('メモアーカイブエラー: ${memo.id}', e);
        }
      }

      if (archivedCount > 0) {
        // アーカイブ後にバックアップを更新
        await _backupToSharedPreferences();
        Logger.info('古いメモをアーカイブ完了: ${archivedCount}件（${keepYears}年以上前）');
      }

      return archivedCount;
    } catch (e) {
      Logger.error('古いメモアーカイブエラー', e);
      return 0;
    }
  }

  /// アーカイブからメモを復元（必要に応じて）
  Future<List<MedicationMemo>> loadArchivedMemos({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!Hive.isBoxOpen('medication_memos_archive')) {
        return [];
      }

      final archiveBox = Hive.box<MedicationMemo>('medication_memos_archive');
      final memos = archiveBox.values.where((memo) {
        if (startDate != null && memo.createdAt.isBefore(startDate)) return false;
        if (endDate != null && memo.createdAt.isAfter(endDate)) return false;
        return true;
      }).toList();

      memos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      Logger.info('アーカイブから読み込み: ${memos.length}件');
      return memos;
    } catch (e) {
      Logger.error('アーカイブ読み込みエラー', e);
      return [];
    }
  }

  /// SharedPreferencesへのバックアップ保存
  /// 重要: 削除されたメモは含まれない（Hiveの現在の状態を反映）
  Future<void> _backupToSharedPreferences() async {
    try {
      if (!Hive.isBoxOpen('medication_memos')) {
        Logger.warning('medication_memosボックスが開かれていません。バックアップをスキップします');
        return;
      }
      
      final box = Hive.box<MedicationMemo>('medication_memos');
      // 重要: Hiveの現在の状態をそのまま保存（削除されたメモは含まれない）
      final memos = box.values.toList();
      
      // 空のリストでも保存する（削除された状態を反映するため）
      final prefs = await SharedPreferences.getInstance();
      
      // 削除されたメモIDのリストも取得（念のため）
      final deletedIds = prefs.getStringList(_deletedMemoIdsKey) ?? <String>[];
      
      // 削除されたメモを除外（二重チェック）
      final validMemos = memos.where((memo) => !deletedIds.contains(memo.id)).toList();
      
      final memosJson = validMemos.map((memo) => memo.toJson()).toList();
      final jsonString = jsonEncode(memosJson);
      
      // 複数キーに保存（3重バックアップ）
      // 重要: 削除されたメモは含まれない（Hiveの現在の状態を反映）
      await Future.wait(_backupKeys.map((key) => 
        prefs.setString(key, jsonString)
      ));
      
      Logger.debug('バックアップ保存完了: ${validMemos.length}件（削除されたメモは含まれない、削除IDリスト: ${deletedIds.length}件）');
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

