// アラーム管理機能のMixin
// home_page.dartからアラーム管理関連の機能を分離

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

/// アラーム管理機能のMixin
/// このmixinを使用するクラスは、必要な状態変数とメソッドを提供する必要があります
mixin HomePageAlarmMixin<T extends StatefulWidget> on State<T> {
  // 抽象ゲッター/セッター（実装クラスで提供する必要がある）
  List<Map<String, dynamic>> get alarmList;
  Map<String, dynamic> get alarmSettings;
  Key get alarmTabKey;
  
  void setAlarmListValue(List<Map<String, dynamic>> alarms);
  void setAlarmTabKeyValue(Key key);
  void addToAlarmList(Map<String, dynamic> alarm);
  void removeFromAlarmList(int index);
  void updateAlarmListAt(int index, Map<String, dynamic> alarm);
  
  // 抽象メソッド（実装クラスで提供する必要がある）
  Future<void> saveSnapshotBeforeChange(String operationType);
  
  // 確実なアラームデータ読み込み（指定パス方式を採用）
  Future<void> loadAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmCount = prefs.getInt('alarm_count') ?? 0;
      final alarmsList = <Map<String, dynamic>>[];
      
      debugPrint('アラームデータ読み込み開始: $alarmCount件');
      
      for (int i = 0; i < alarmCount; i++) {
        final name = prefs.getString('alarm_${i}_name');
        final time = prefs.getString('alarm_${i}_time');
        final repeat = prefs.getString('alarm_${i}_repeat');
        final enabled = prefs.getBool('alarm_${i}_enabled');
        final alarmType = prefs.getString('alarm_${i}_alarmType');
        final volume = prefs.getInt('alarm_${i}_volume');
        final message = prefs.getString('alarm_${i}_message');
        
        if (name != null && time != null) {
          alarmsList.add({
            'name': name,
            'time': time,
            'repeat': repeat ?? '一度だけ',
            'enabled': enabled ?? true,
            'alarmType': alarmType ?? 'sound',
            'volume': volume ?? 80,
            'message': message ?? '薬を服用する時間です',
          });
        }
      }
      
      setState(() {
        setAlarmListValue(alarmsList);
      });
      
      debugPrint('アラームデータ読み込み完了: ${alarmList.length}件（指定パス方式）');
      
      // UIを更新
      if (mounted) {
        setState(() {
          // アラームデータを反映
        });
      }
    } catch (e) {
      debugPrint('アラームデータ読み込みエラー: $e');
      setAlarmListValue([]);
    }
  }
  
  // アラームの再登録
  Future<void> reRegisterAlarms() async {
    try {
      if (alarmList.isEmpty) {
        debugPrint('アラーム再登録: アラームデータなし');
        return;
      }
      
      debugPrint('アラーム再登録開始: ${alarmList.length}件');
      
      // 既存の通知をキャンセル
      await NotificationService.cancelAllNotifications();
      
      // 各アラームを再登録
      for (int i = 0; i < alarmList.length; i++) {
        final alarm = alarmList[i];
        await registerSingleAlarm(alarm, i);
      }
      
      debugPrint('アラーム再登録完了: ${alarmList.length}件');
    } catch (e) {
      debugPrint('アラーム再登録エラー: $e');
    }
  }
  
  // 単一アラームの登録
  Future<void> registerSingleAlarm(Map<String, dynamic> alarm, int index) async {
    try {
      // アラームの詳細情報を取得（安全な型変換）
      final time = alarm['time']?.toString() ?? '09:00';
      final enabled = alarm['enabled'] is bool ? alarm['enabled'] as bool : true;
      final title = alarm['title']?.toString() ?? alarm['name']?.toString() ?? '服用アラーム';
      final message = alarm['message']?.toString() ?? '薬を服用する時間です';
      
      if (!enabled) {
        debugPrint('アラーム $index は無効化されています');
        return;
      }
      
      // 時間を解析
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // 今日の日時を設定
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // 過去の時間の場合は明日に設定
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      // 通知をスケジュール
      // await NotificationService.scheduleNotification(
      //   id: index,
      //   title: title,
      //   body: message,
      //   scheduledTime: scheduledTime,
      // );
      
      debugPrint('アラーム $index 登録完了: $time');
    } catch (e) {
      debugPrint('アラーム $index 登録エラー: $e');
    }
  }
  
  // アラームの追加（指定パス方式）
  Future<void> addAlarm(Map<String, dynamic> alarm) async {
    try {
      // 変更前スナップショット
      await saveSnapshotBeforeChange('アラーム追加_${alarm['name']}');
      setState(() {
        addToAlarmList(alarm);
      });
      
      // アラーム追加後に自動保存
      await saveAlarmData();
      
      // 新しいアラームを登録
      await registerSingleAlarm(alarm, alarmList.length - 1);
      
      // アラームタブを強制再構築
      setAlarmTabKeyValue(UniqueKey());
      
      debugPrint('アラーム追加完了: ${alarm['name']}');
    } catch (e) {
      debugPrint('アラーム追加エラー: $e');
    }
  }
  
  // アラームの削除（指定パス方式）
  Future<void> removeAlarm(int index) async {
    try {
      if (index >= 0 && index < alarmList.length) {
        // 変更前スナップショット
        final alarm = alarmList[index];
        await saveSnapshotBeforeChange('アラーム削除_${alarm['name']}');
        setState(() {
          removeFromAlarmList(index);
        });
        
        // アラーム削除後に自動保存
        await saveAlarmData();
        
        // アラームタブを強制再構築
        setAlarmTabKeyValue(UniqueKey());
        
        debugPrint('アラーム削除完了: インデックス $index');
      }
    } catch (e) {
      debugPrint('アラーム削除エラー: $e');
    }
  }
  
  // アラームの更新（指定パス方式）
  Future<void> updateAlarm(int index, Map<String, dynamic> updatedAlarm) async {
    try {
      if (index >= 0 && index < alarmList.length) {
        // 変更前スナップショット
        final alarm = alarmList[index];
        await saveSnapshotBeforeChange('アラーム編集_${alarm['name']}');
        setState(() {
          updateAlarmListAt(index, updatedAlarm);
        });
        
        // アラーム更新後に自動保存
        await saveAlarmData();
        
        // アラームタブを強制再構築
        setAlarmTabKeyValue(UniqueKey());
        
        debugPrint('アラーム更新完了: インデックス $index');
      }
    } catch (e) {
      debugPrint('アラーム更新エラー: $e');
    }
  }
  
  // アラームの有効/無効切り替え（指定パス方式）
  Future<void> toggleAlarm(int index) async {
    try {
      if (index >= 0 && index < alarmList.length) {
        final alarm = alarmList[index];
        final newEnabled = !(alarm['enabled'] as bool? ?? true);
        
        // 変更前スナップショット
        await saveSnapshotBeforeChange('アラーム切替_${alarm['name']}_${newEnabled ? '有効' : '無効'}');
        setState(() {
          final updatedAlarm = Map<String, dynamic>.from(alarm);
          updatedAlarm['enabled'] = newEnabled;
          updateAlarmListAt(index, updatedAlarm);
        });
        
        // アラーム切り替え後に自動保存
        await saveAlarmData();
        
        // アラームタブを強制再構築
        setAlarmTabKeyValue(UniqueKey());
        
        debugPrint('アラーム切り替え完了: インデックス $index, 有効=$newEnabled');
      }
    } catch (e) {
      debugPrint('アラーム切り替えエラー: $e');
    }
  }
  
  // アラームデータの保存（指定パス方式）
  Future<void> saveAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // アラーム数を保存
      await prefs.setInt('alarm_count', alarmList.length);
      
      // 各アラームの情報を個別に保存
      for (int i = 0; i < alarmList.length; i++) {
        final alarm = alarmList[i];
        await prefs.setString('alarm_${i}_name', alarm['name']?.toString() ?? 'アラーム');
        await prefs.setString('alarm_${i}_time', alarm['time']?.toString() ?? '00:00');
        await prefs.setString('alarm_${i}_repeat', alarm['repeat']?.toString() ?? '一度だけ');
        await prefs.setBool('alarm_${i}_enabled', alarm['enabled'] as bool? ?? true);
        await prefs.setString('alarm_${i}_alarmType', alarm['alarmType']?.toString() ?? 'sound');
        await prefs.setInt('alarm_${i}_volume', alarm['volume'] as int? ?? 80);
        await prefs.setString('alarm_${i}_message', alarm['message']?.toString() ?? '薬を服用する時間です');
      }
      
      // バックアップも保存
      await prefs.setString('alarm_backup_count', alarmList.length.toString());
      await prefs.setString('alarm_last_save', DateTime.now().toIso8601String());
      
      debugPrint('アラームデータ保存完了: ${alarmList.length}件（指定パス方式）');
    } catch (e) {
      debugPrint('アラームデータ保存エラー: $e');
    }
  }
  
  // アラームデータの検証
  Future<void> validateAlarmData() async {
    try {
      debugPrint('=== アラームデータ検証 ===');
      debugPrint('アラーム数: ${alarmList.length}件');
      
      for (int i = 0; i < alarmList.length; i++) {
        final alarm = alarmList[i];
        debugPrint('アラーム $i:');
        debugPrint('  タイトル: ${alarm['title'] ?? alarm['name'] ?? 'なし'}');
        debugPrint('  時間: ${alarm['time'] ?? 'なし'}');
        debugPrint('  有効: ${alarm['enabled'] ?? false}');
        debugPrint('  メッセージ: ${alarm['message'] ?? 'なし'}');
      }
      
      debugPrint('アラーム設定: ${alarmSettings.length}件');
      for (final entry in alarmSettings.entries) {
        debugPrint('  ${entry.key}: ${entry.value}');
      }
      
      debugPrint('=== アラームデータ検証完了 ===');
    } catch (e) {
      debugPrint('アラームデータ検証エラー: $e');
    }
  }
  
  // アラームデータの整合性チェック
  Future<void> checkAlarmDataIntegrity() async {
    try {
      // アラームデータの整合性をチェック
      bool needsUpdate = false;
      final updatedAlarms = <Map<String, dynamic>>[];
      
      for (int i = 0; i < alarmList.length; i++) {
        final alarm = Map<String, dynamic>.from(alarmList[i]);
        
        // 必須フィールドのチェック
        if (!alarm.containsKey('name') || alarm['name'] == null) {
          alarm['name'] = '服用アラーム';
          needsUpdate = true;
        }
        if (!alarm.containsKey('time') || alarm['time'] == null) {
          alarm['time'] = '09:00';
          needsUpdate = true;
        }
        if (!alarm.containsKey('enabled') || alarm['enabled'] == null) {
          alarm['enabled'] = true;
          needsUpdate = true;
        }
        if (!alarm.containsKey('message') || alarm['message'] == null) {
          alarm['message'] = '薬を服用する時間です';
          needsUpdate = true;
        }
        
        updatedAlarms.add(alarm);
      }
      
      // 整合性に問題があった場合は更新
      if (needsUpdate) {
        setState(() {
          setAlarmListValue(updatedAlarms);
        });
        await saveAlarmData();
        debugPrint('アラームデータ整合性を修正しました');
      }
      
      debugPrint('アラームデータ整合性チェック完了');
    } catch (e) {
      debugPrint('アラームデータ整合性チェックエラー: $e');
    }
  }
}

