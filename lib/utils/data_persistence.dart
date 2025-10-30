// ✅ 包括的なデータ永続化機能
// 動的薬リスト、アラームリスト等の改善コード

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataPersistence {
  // ✅ 改善版：動的薬リスト保存機能（多重バックアップ付き）
  static Future<void> saveMedicationList(List<Map<String, dynamic>> addedMedications) async {
    try {
      debugPrint('💾 動的薬リスト保存開始...');
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ 1. 個別データ保存（従来方式）
      final medicationListJson = <String, dynamic>{};
      for (int i = 0; i < addedMedications.length; i++) {
        final med = addedMedications[i];
        medicationListJson['medication_$i'] = {
          'id': med['id'],
          'name': med['name'],
          'type': med['type'],
          'dosage': med['dosage'],
          'color': (med['color'] as Color).value,
          'taken': med['taken'],
          'takenTime': med['takenTime']?.toIso8601String(),
          'notes': med['notes'],
          'isChecked': med['isChecked'],
          'createdAt': med['createdAt']?.toIso8601String(),
        };
      }
      
      // ✅ 2. 複数キーに保存（4重バックアップ）
      final jsonString = jsonEncode(medicationListJson);
      await Future.wait([
        prefs.setString('medicationList', jsonString),
        prefs.setString('medicationList_backup', jsonString),
        prefs.setString('medicationList_backup2', jsonString),
        prefs.setString('medicationList_backup3', jsonString),
      ]);
      
      // ✅ 3. カウント保存
      await Future.wait([
        prefs.setInt('medicationList_count', addedMedications.length),
        prefs.setInt('medicationList_count_backup', addedMedications.length),
      ]);
      
      // ✅ 4. JSON配列形式でも保存（さらなるバックアップ）
      final jsonArray = jsonEncode(addedMedications.map((med) => {
        'id': med['id'],
        'name': med['name'],
        'type': med['type'],
        'dosage': med['dosage'],
        'color': (med['color'] as Color).value,
        'taken': med['taken'],
        'takenTime': med['takenTime']?.toIso8601String(),
        'notes': med['notes'],
        'isChecked': med['isChecked'],
        'createdAt': med['createdAt']?.toIso8601String(),
      }).toList());
      await Future.wait([
        prefs.setString('medicationList_array', jsonArray),
        prefs.setString('medicationList_array_backup', jsonArray),
      ]);
      
      debugPrint('✅ 動的薬リスト保存完了: ${addedMedications.length}件（4重バックアップ）');
    } catch (e, stackTrace) {
      debugPrint('❌ 動的薬リスト保存エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }

  // ✅ 改善版：動的薬リスト読み込み機能（フォールバック付き）
  static Future<List<Map<String, dynamic>>> loadMedicationList() async {
    try {
      debugPrint('📖 動的薬リスト読み込み開始...');
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ 1. 複数キーから読み込みを試行
      final keys = [
        'medicationList', 
        'medicationList_backup', 
        'medicationList_backup2', 
        'medicationList_backup3'
      ];
      
      String? medicationListStr;
      String? usedKey;
      
      for (final key in keys) {
        try {
          medicationListStr = prefs.getString(key);
          if (medicationListStr != null && medicationListStr.isNotEmpty) {
            usedKey = key;
            debugPrint('✅ 動的薬リスト読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('⚠️ キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (medicationListStr != null && medicationListStr.isNotEmpty) {
        try {
          final medicationListJson = jsonDecode(medicationListStr) as Map<String, dynamic>;
          final addedMedications = <Map<String, dynamic>>[];
          
          final count = prefs.getInt('medicationList_count') ?? 
                       prefs.getInt('medicationList_count_backup') ?? 0;
          
          for (int i = 0; i < count; i++) {
            final medKey = 'medication_$i';
            if (medicationListJson.containsKey(medKey)) {
              final medData = medicationListJson[medKey] as Map<String, dynamic>;
              addedMedications.add({
                'id': medData['id'] ?? '',
                'name': medData['name'] ?? '',
                'type': medData['type'] ?? '薬品',
                'dosage': medData['dosage'] ?? '',
                'color': Color(medData['color'] as int? ?? Colors.blue.value),
                'taken': medData['taken'] ?? false,
                'takenTime': medData['takenTime'] != null 
                    ? DateTime.parse(medData['takenTime'] as String) 
                    : null,
                'notes': medData['notes'] ?? '',
                'isChecked': medData['isChecked'] ?? false,
                'createdAt': medData['createdAt'] != null 
                    ? DateTime.parse(medData['createdAt'] as String) 
                    : DateTime.now(),
              });
            }
          }
          
          debugPrint('✅ 動的薬リスト読み込み完了: ${addedMedications.length}件');
          return addedMedications;
        } catch (e) {
          debugPrint('❌ 動的薬リストJSON解析エラー: $e');
          // ✅ フォールバック: 配列形式から読み込み
          return await loadMedicationListFromArray();
        }
      } else {
        debugPrint('⚠️ 動的薬リストが見つかりません');
        // ✅ フォールバック: 配列形式から読み込み
        return await loadMedicationListFromArray();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 動的薬リスト読み込みエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      return [];
    }
  }

  // ✅ フォールバック: 配列形式からの読み込み
  static Future<List<Map<String, dynamic>>> loadMedicationListFromArray() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final arrayKeys = ['medicationList_array', 'medicationList_array_backup'];
      
      for (final key in arrayKeys) {
        try {
          final jsonArray = prefs.getString(key);
          if (jsonArray != null && jsonArray.isNotEmpty) {
            final List<dynamic> medicationsList = jsonDecode(jsonArray) as List<dynamic>;
            final addedMedications = <Map<String, dynamic>>[];
            
            for (final medData in medicationsList) {
              final med = medData as Map<String, dynamic>;
              addedMedications.add({
                'id': med['id'] ?? '',
                'name': med['name'] ?? '',
                'type': med['type'] ?? '薬品',
                'dosage': med['dosage'] ?? '',
                'color': Color(med['color'] as int? ?? Colors.blue.value),
                'taken': med['taken'] ?? false,
                'takenTime': med['takenTime'] != null 
                    ? DateTime.parse(med['takenTime'] as String) 
                    : null,
                'notes': med['notes'] ?? '',
                'isChecked': med['isChecked'] ?? false,
                'createdAt': med['createdAt'] != null 
                    ? DateTime.parse(med['createdAt'] as String) 
                    : DateTime.now(),
              });
            }
            
            debugPrint('✅ 配列形式から復元: ${addedMedications.length}件 ($key)');
            return addedMedications;
          }
        } catch (e) {
          debugPrint('⚠️ 配列形式読み込みエラー ($key): $e');
          continue;
        }
      }
      
      debugPrint('⚠️ 全てのバックアップが見つかりません');
      return [];
    } catch (e) {
      debugPrint('❌ 配列形式フォールバックエラー: $e');
      return [];
    }
  }

  // ✅ 改善版：アラームデータ保存機能（多重バックアップ付き）
  static Future<void> saveAlarmData(
    List<Map<String, dynamic>> alarmList,
    Map<String, dynamic> alarmSettings,
  ) async {
    try {
      debugPrint('🔔 アラームデータ保存開始...');
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ 1. アラーム数を保存（複数キー）
      await Future.wait([
        prefs.setInt('alarm_count', alarmList.length),
        prefs.setInt('alarm_count_backup', alarmList.length),
        prefs.setInt('alarm_count_backup2', alarmList.length),
      ]);
      
      // ✅ 2. 各アラームのデータを個別に保存（複数キー）
      for (int i = 0; i < alarmList.length; i++) {
        final alarm = alarmList[i];
        final alarmData = {
          'name': alarm['name'] ?? '',
          'time': alarm['time'] ?? '00:00',
          'repeat': alarm['repeat'] ?? '一度だけ',
          'enabled': alarm['enabled'] ?? true,
          'alarmType': alarm['alarmType'] ?? 'sound',
          'volume': alarm['volume'] ?? 80,
          'message': alarm['message'] ?? '薬を服用する時間です',
          'isRepeatEnabled': alarm['isRepeatEnabled'] ?? false,
          'selectedDays': alarm['selectedDays'] ?? [false, false, false, false, false, false, false],
        };
        
        // 個別キーで保存
        final alarmJson = jsonEncode(alarmData);
        await Future.wait([
          prefs.setString('alarm_$i', alarmJson),
          prefs.setString('alarm_${i}_backup', alarmJson),
          prefs.setString('alarm_${i}_backup2', alarmJson),
        ]);
        
        // 曜日データも個別に保存
        final selectedDays = alarm['selectedDays'] as List<bool>? ?? 
                            [false, false, false, false, false, false, false];
        for (int j = 0; j < 7; j++) {
          await Future.wait([
            prefs.setBool('alarm_${i}_day_$j', j < selectedDays.length ? selectedDays[j] : false),
            prefs.setBool('alarm_${i}_day_${j}_backup', j < selectedDays.length ? selectedDays[j] : false),
          ]);
        }
      }
      
      // ✅ 3. JSON配列形式でも保存（さらなるバックアップ）
      final alarmJson = jsonEncode(alarmList);
      await Future.wait([
        prefs.setString('alarm_list_json', alarmJson),
        prefs.setString('alarm_list_json_backup', alarmJson),
        prefs.setString('alarm_list_json_backup2', alarmJson),
      ]);
      
      // ✅ 4. アラーム設定も保存
      final settingsJson = jsonEncode(alarmSettings);
      await Future.wait([
        prefs.setString('alarm_settings', settingsJson),
        prefs.setString('alarm_settings_backup', settingsJson),
      ]);
      
      debugPrint('✅ アラームデータ保存完了: ${alarmList.length}件（多重バックアップ）');
    } catch (e, stackTrace) {
      debugPrint('❌ アラームデータ保存エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }

  // ✅ 改善版：アラームデータ読み込み機能（フォールバック付き）
  static Future<Map<String, dynamic>> loadAlarmData() async {
    try {
      debugPrint('📖 アラームデータ読み込み開始...');
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ 1. JSON配列形式から読み込みを試行
      final jsonKeys = ['alarm_list_json', 'alarm_list_json_backup', 'alarm_list_json_backup2'];
      String? alarmJson;
      String? usedKey;
      
      for (final key in jsonKeys) {
        try {
          alarmJson = prefs.getString(key);
          if (alarmJson != null && alarmJson.isNotEmpty) {
            usedKey = key;
            debugPrint('✅ アラームJSON読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('⚠️ キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      List<Map<String, dynamic>> alarmList = [];
      
      if (alarmJson != null && alarmJson.isNotEmpty) {
        try {
          final List<dynamic> alarmJsonList = jsonDecode(alarmJson) as List<dynamic>;
          alarmList = alarmJsonList.map((alarm) {
            final alarmMap = alarm as Map<String, dynamic>;
            return {
              'name': alarmMap['name'] ?? '',
              'time': alarmMap['time'] ?? '00:00',
              'repeat': alarmMap['repeat'] ?? '一度だけ',
              'enabled': alarmMap['enabled'] ?? true,
              'alarmType': alarmMap['alarmType'] ?? 'sound',
              'volume': alarmMap['volume'] ?? 80,
              'message': alarmMap['message'] ?? '薬を服用する時間です',
              'isRepeatEnabled': alarmMap['isRepeatEnabled'] ?? false,
              'selectedDays': List<bool>.from(alarmMap['selectedDays'] as List<dynamic>? ?? [false, false, false, false, false, false, false]),
            };
          }).toList();
          
          debugPrint('✅ アラームリスト読み込み完了: ${alarmList.length}件');
        } catch (e) {
          debugPrint('❌ アラームJSON解析エラー: $e');
          // ✅ フォールバック: 個別キーから読み込み
          alarmList = await loadAlarmDataFromIndividualKeys();
        }
      } else {
        debugPrint('⚠️ アラームJSONが見つかりません');
        // ✅ フォールバック: 個別キーから読み込み
        alarmList = await loadAlarmDataFromIndividualKeys();
      }
      
      // ✅ 2. アラーム設定の読み込み
      Map<String, dynamic> alarmSettings = {};
      final settingsKeys = ['alarm_settings', 'alarm_settings_backup'];
      
      for (final key in settingsKeys) {
        try {
          final settingsJson = prefs.getString(key);
          if (settingsJson != null && settingsJson.isNotEmpty) {
            alarmSettings = Map<String, dynamic>.from(jsonDecode(settingsJson) as Map<dynamic, dynamic>);
            debugPrint('✅ アラーム設定読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('⚠️ アラーム設定読み込みエラー ($key): $e');
          continue;
        }
      }
      
      return {
        'alarmList': alarmList,
        'alarmSettings': alarmSettings,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ アラームデータ読み込みエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      return {
        'alarmList': <Map<String, dynamic>>[],
        'alarmSettings': <String, dynamic>{},
      };
    }
  }

  // ✅ フォールバック: 個別キーからの読み込み
  static Future<List<Map<String, dynamic>>> loadAlarmDataFromIndividualKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmList = <Map<String, dynamic>>[];
      
      // アラーム数を取得
      final countKeys = ['alarm_count', 'alarm_count_backup', 'alarm_count_backup2'];
      int? count;
      
      for (final key in countKeys) {
        count = prefs.getInt(key);
        if (count != null && count > 0) {
          debugPrint('✅ アラーム数読み込み成功: $count件 ($key)');
          break;
        }
      }
      
      if (count == null || count == 0) {
        debugPrint('⚠️ アラーム数が見つかりません');
        return [];
      }
      
      // 各アラームを個別に読み込み
      for (int i = 0; i < count; i++) {
        final alarmKeys = ['alarm_$i', 'alarm_${i}_backup', 'alarm_${i}_backup2'];
        String? alarmJson;
        
        for (final key in alarmKeys) {
          try {
            alarmJson = prefs.getString(key);
            if (alarmJson != null && alarmJson.isNotEmpty) {
              break;
            }
          } catch (e) {
            continue;
          }
        }
        
        if (alarmJson != null && alarmJson.isNotEmpty) {
          try {
            final alarmData = jsonDecode(alarmJson) as Map<String, dynamic>;
            
            // 曜日データを読み込み
            final selectedDays = <bool>[];
            for (int j = 0; j < 7; j++) {
              final dayValue = prefs.getBool('alarm_${i}_day_$j') ?? 
                              prefs.getBool('alarm_${i}_day_${j}_backup') ?? 
                              false;
              selectedDays.add(dayValue);
            }
            
            alarmList.add({
              'name': alarmData['name'] ?? '',
              'time': alarmData['time'] ?? '00:00',
              'repeat': alarmData['repeat'] ?? '一度だけ',
              'enabled': alarmData['enabled'] ?? true,
              'alarmType': alarmData['alarmType'] ?? 'sound',
              'volume': alarmData['volume'] ?? 80,
              'message': alarmData['message'] ?? '薬を服用する時間です',
              'isRepeatEnabled': alarmData['isRepeatEnabled'] ?? false,
              'selectedDays': selectedDays,
            });
          } catch (e) {
            debugPrint('⚠️ アラーム $i の解析エラー: $e');
            continue;
          }
        }
      }
      
      debugPrint('✅ 個別キーから復元: ${alarmList.length}件');
      return alarmList;
    } catch (e) {
      debugPrint('❌ 個別キーフォールバックエラー: $e');
      return [];
    }
  }
}

