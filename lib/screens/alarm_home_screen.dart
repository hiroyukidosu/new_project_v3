// lib/screens/alarm_home_screen.dart
// 主要な画面UI

import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../widgets/current_time_card.dart';
import '../widgets/alarm_list_item.dart';
import '../widgets/alarm_stop_dialog.dart';
import '../widgets/notification_settings_dialog.dart';
import '../widgets/add_alarm_dialog.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../core/snapshot_service.dart';

/// アラームホーム画面
class AlarmHomeScreen extends StatefulWidget {
  const AlarmHomeScreen({super.key});

  @override
  State<AlarmHomeScreen> createState() => _AlarmHomeScreenState();
}

class _AlarmHomeScreenState extends State<AlarmHomeScreen> {
  String _currentTime = '';
  String _currentDate = '';
  List<Alarm> _alarms = [];
  bool _isAlarmEnabled = true;
  bool _isAlarmPlaying = false;
  
  String _selectedNotificationType = 'sound';
  int _notificationVolume = 80;
  String _selectedAlarmSound = 'default';
  String _selectedNotificationSound = 'loop_notification';
  
  AlarmService? _alarmService;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // ストレージサービス初期化
      await StorageService.initialize();
      debugPrint('✅ StorageService初期化完了');
      
      // 設定とアラームを読み込み
      await _loadSettings();
      debugPrint('✅ 設定読み込み完了');
      
      await _loadAlarms();
      debugPrint('✅ アラーム読み込み完了 ${_alarms.length}件');
      
      // データ整合性チェック
      await StorageService.validateAlarmData();
      
      // アラームサービス初期化
      _alarmService = AlarmService(
        onAlarmTriggered: (alarm) {
          setState(() {
            _isAlarmPlaying = true;
          });
        },
        onAlarmStopDialog: _showAlarmStopDialog,
        isMounted: () => mounted && !_disposed,
        triggerStateUpdate: () {
          if (mounted && !_disposed) {
            setState(() {});
          }
        },
        selectedNotificationType: _selectedNotificationType,
        selectedAlarmSound: _selectedAlarmSound,
        notificationVolume: _notificationVolume,
      );
      
      // 通知初期化
      await _initializeNotifications();
      
      // UIを更新
      if (mounted && !_disposed) {
        setState(() {});
        _updateTime();
        _alarmService?.startAlarmCheck();
        debugPrint('✅ アプリ初期化完了');
      }
    } catch (e) {
      debugPrint('❌ 初期化エラー: $e');
      if (mounted && !_disposed) {
        _updateTime();
        _alarmService?.startAlarmCheck();
      }
    }
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.loadSettings();
    setState(() {
      _isAlarmEnabled = settings['isAlarmEnabled'] as bool;
      _selectedNotificationType = settings['selectedNotificationType'] as String;
      _selectedAlarmSound = settings['selectedAlarmSound'] as String;
      _notificationVolume = settings['notificationVolume'] as int;
    });
  }

  Future<void> _saveSettings() async {
    await StorageService.saveSettings(
      isAlarmEnabled: _isAlarmEnabled,
      selectedNotificationType: _selectedNotificationType,
      selectedAlarmSound: _selectedAlarmSound,
      notificationVolume: _notificationVolume,
    );
    await _saveAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await StorageService.loadAlarms();
    if (mounted && !_disposed) {
      setState(() {
        _alarms = alarms;
      });
    }
  }

  Future<void> _saveAlarms() async {
    await StorageService.saveAlarms(_alarms);
  }

  Future<void> _initializeNotifications() async {
    // NotificationServiceの初期化は別途実装
  }

  void _updateTime() {
    if (!mounted || _disposed) return;
    
    if (context.mounted == false) return;
    
    try {
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dateString = now.toString().substring(0, 10);
      
      if (mounted && !_disposed) {
        setState(() {
          _currentTime = timeString;
          _currentDate = dateString;
        });
      }
    } catch (e) {
      debugPrint('_updateTime setState エラー: $e');
      return;
    }
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_disposed && context.mounted) {
        _updateTime();
      }
    });
  }

  void _addAlarm() {
    debugPrint('📝 アラーム追加ダイアログを表示');
    showDialog(
      context: context,
      builder: (context) => AddAlarmDialog(
        onAlarmAdded: (alarmMap) async {
          await SnapshotService.saveBeforeChange('アラーム追加_${alarmMap['name'] ?? '無名'}');
          debugPrint('📝 アラーム追加開始: ${alarmMap.toString()}');
          
          try {
            final alarm = Alarm.fromMap(alarmMap);
            if (alarm.isValid()) {
              setState(() {
                _alarms.add(alarm);
              });
              
              await _saveAlarms();
              await _loadAlarms();
              
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('アラーム「${alarm.name}」を追加しました'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e, stackTrace) {
            debugPrint('❌ アラーム追加エラー: $e');
            debugPrint('スタックトレース: $stackTrace');
            
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('アラームの追加に失敗しました: $e'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _editAlarm(int index, Alarm alarm) {
    showDialog(
      context: context,
      builder: (context) => AddAlarmDialog(
        initialAlarm: alarm.toMap(),
        onAlarmAdded: (alarmMap) async {
          await SnapshotService.saveBeforeChange('アラーム編集_${alarmMap['name'] ?? '無名'}');
          try {
            debugPrint('📝 アラーム編集開始 インデックス $index');
            
            final updatedAlarm = Alarm.fromMap(alarmMap);
            if (updatedAlarm.isValid()) {
              setState(() {
                _alarms[index] = updatedAlarm;
              });
              
              await _saveAlarms();
              
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('アラーム「${updatedAlarm.name}」を更新しました'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('❌ アラーム編集エラー: $e');
            
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('アラームの編集に失敗しました: $e'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteAlarm(int index) async {
    try {
      await SnapshotService.saveBeforeChange('アラーム削除_${_alarms[index].name}');
      setState(() {
        _alarms.removeAt(index);
      });
      
      await _saveAlarms();
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アラームを削除しました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ アラーム削除エラー: $e');
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => NotificationSettingsDialog(
        selectedNotificationType: _selectedNotificationType,
        selectedAlarmSound: _selectedAlarmSound,
        selectedNotificationSound: _selectedNotificationSound,
        notificationVolume: _notificationVolume,
        onSave: ({
          required String selectedNotificationType,
          required String selectedAlarmSound,
          required String selectedNotificationSound,
          required int notificationVolume,
        }) async {
          setState(() {
            _selectedNotificationType = selectedNotificationType;
            _selectedAlarmSound = selectedAlarmSound;
            _selectedNotificationSound = selectedNotificationSound;
            _notificationVolume = notificationVolume;
          });
          await _saveSettings();
        },
      ),
    );
  }

  void _showAlarmStopDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlarmStopDialog(
        onStop: () async {
          await _stopAlarm();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Future<void> _stopAlarm() async {
    await _alarmService?.stopAlarm(_alarms);
    setState(() {
      _isAlarmPlaying = false;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _alarmService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // アラームチェック実行
    if (_alarmService != null && _isAlarmEnabled) {
      _alarmService!.checkAlarms(
        isAlarmEnabled: _isAlarmEnabled,
        alarms: _alarms,
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('服用時間のアラーム'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showNotificationSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // 現在時刻表示カード
            CurrentTimeCard(
              currentTime: _currentTime.isEmpty ? '00:00' : _currentTime,
              currentDate: _currentDate.isEmpty ? DateTime.now().toString().substring(0, 10) : _currentDate,
              isAlarmEnabled: _isAlarmEnabled,
              onAlarmEnabledChanged: (value) async {
                setState(() {
                  _isAlarmEnabled = value;
                });
                
                if (!value && _isAlarmPlaying) {
                  await _stopAlarm();
                }
                
                await _saveSettings();
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? 'アラームを有効にしました' : 'アラームを無効にしました'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              onStopAlarm: _stopAlarm,
              isAlarmPlaying: _isAlarmPlaying,
            ),
            
            const SizedBox(height: 24),
            
            // アラーム一覧
            Expanded(
              child: _alarms.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.alarm_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'アラームが設定されていません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '右下の+ボタンでアラームを追加',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = _alarms[index];
                        return AlarmListItem(
                          alarm: alarm,
                          index: index,
                          onEnabledChanged: (value) async {
                            try {
                              await SnapshotService.saveBeforeChange('アラーム切り替え_${alarm.name}');
                              
                              setState(() {
                                _alarms[index] = alarm.copyWith(enabled: value);
                              });
                              
                              await _saveAlarms();
                              
                              if (!value && _isAlarmPlaying) {
                                await _stopAlarm();
                              }
                            } catch (e) {
                              debugPrint('アラーム切り替えエラー: $e');
                              setState(() {
                                _alarms[index] = alarm.copyWith(enabled: value);
                              });
                              await _saveAlarms();
                            }
                          },
                          onEdit: () => _editAlarm(index, alarm),
                          onDelete: () => _deleteAlarm(index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

