import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'core/alarm_optimization.dart';

class SimpleAlarmApp extends StatefulWidget {
  const SimpleAlarmApp({super.key});

  @override
  State<SimpleAlarmApp> createState() => _SimpleAlarmAppState();
}

class _SimpleAlarmAppState extends State<SimpleAlarmApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isAlarmPlaying = false;
  String _currentTime = '';
  List<Map<String, dynamic>> _alarms = [];
  Timer? _alarmTimer;
  Timer? _vibrationTimer;
  String _selectedNotificationType = 'sound';
  int _notificationVolume = 80;
  String _selectedAlarmSound = 'default';
  String _selectedNotificationSound = 'loop_notification';
  bool _isAlarmEnabled = true;
  DateTime? _lastCheckTime;
  SharedPreferences? _prefs;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // 非同期初期化を適切に処理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      // 通知の初期化を非同期で実行（アプリ起動をブロックしない）
      _initializeNotifications().catchError((e) {
        debugPrint('通知初期化エラー: $e');
      });
      
      // mountedチェック付きで初期化
      if (!mounted || _disposed) return;
      if (context.mounted == false) return;
      
      _updateTime();
      _startAlarmCheck();
      debugPrint('アプリ初期化完了');
    } catch (e) {
      debugPrint('初期化エラー: $e');
      // エラーが発生してもアプリは動作を続ける（mountedチェック付き）
      if (!mounted || _disposed) return;
      if (context.mounted == false) return;
      
      _updateTime();
      _startAlarmCheck();
    }
  }

  Future<void> _loadSettings() async {
    if (_prefs != null) {
      _isAlarmEnabled = _prefs!.getBool('alarm_enabled') ?? true;
      _selectedNotificationType = _prefs!.getString('notification_type') ?? 'sound';
      _selectedAlarmSound = _prefs!.getString('alarm_sound') ?? 'default';
      _notificationVolume = _prefs!.getInt('notification_volume') ?? 80;
      
      // アラームデータを読み込み
      await _loadAlarms();
    }
  }

  Future<void> _saveSettings() async {
    if (_prefs != null) {
      await _prefs!.setBool('alarm_enabled', _isAlarmEnabled);
      await _prefs!.setString('notification_type', _selectedNotificationType);
      await _prefs!.setString('alarm_sound', _selectedAlarmSound);
      await _prefs!.setInt('notification_volume', _notificationVolume);
      
      // アラームデータを保存
      await _saveAlarms();
    }
  }

  // アラームデータ保存機能（再起動後も保持）
  Future<void> _saveAlarms() async {
    debugPrint('アラーム保存開始: ${_alarms.length}件');
    if (_prefs != null) {
      try {
        // アラーム数を保存
        await _prefs!.setInt('alarm_count', _alarms.length);
        debugPrint('アラーム数保存完了: ${_alarms.length}件');
        
        // 各アラームのデータを個別に保存
        for (int i = 0; i < _alarms.length; i++) {
          final alarm = _alarms[i];
          debugPrint('アラーム $i 保存: ${alarm.toString()}');
          await _prefs!.setString('alarm_${i}_name', alarm['name'] ?? '');
          await _prefs!.setString('alarm_${i}_time', alarm['time'] ?? '00:00');
          await _prefs!.setString('alarm_${i}_repeat', alarm['repeat'] ?? '一度だけ');
          await _prefs!.setBool('alarm_${i}_enabled', alarm['enabled'] ?? true);
          await _prefs!.setString('alarm_${i}_alarmType', alarm['alarmType'] ?? 'sound');
          await _prefs!.setInt('alarm_${i}_volume', alarm['volume'] ?? 80);
        }
        
        debugPrint('アラームデータを保存しました: ${_alarms.length}件');
      } catch (e) {
        debugPrint('アラームデータ保存エラー: $e');
      }
    } else {
      debugPrint('SharedPreferencesがnullのため保存をスキップ');
    }
  }

  // アラームデータ読み込み機能（再起動後も保持）
  Future<void> _loadAlarms() async {
    debugPrint('アラーム読み込み開始');
    if (_prefs != null) {
      try {
        final alarmCount = _prefs!.getInt('alarm_count') ?? 0;
        debugPrint('保存されているアラーム数: $alarmCount件');
        final alarmsList = <Map<String, dynamic>>[];
        
        for (int i = 0; i < alarmCount; i++) {
          final name = _prefs!.getString('alarm_${i}_name');
          final time = _prefs!.getString('alarm_${i}_time');
          final repeat = _prefs!.getString('alarm_${i}_repeat');
          final enabled = _prefs!.getBool('alarm_${i}_enabled');
          final alarmType = _prefs!.getString('alarm_${i}_alarmType');
          final volume = _prefs!.getInt('alarm_${i}_volume');
          
          debugPrint('アラーム $i 読み込み: name=$name, time=$time, repeat=$repeat, enabled=$enabled, alarmType=$alarmType, volume=$volume');
          
          if (name != null && time != null) {
            alarmsList.add({
              'name': name,
              'time': time,
              'repeat': repeat ?? '一度だけ',
              'enabled': enabled ?? true,
              'alarmType': alarmType ?? 'sound',
              'volume': volume ?? 80,
            });
            debugPrint('アラーム $i 追加完了');
          } else {
            debugPrint('アラーム $i は無効なデータのためスキップ');
          }
        }
        
        debugPrint('読み込み完了: ${alarmsList.length}件のアラーム');
        
        // 安全なsetState呼び出し
        if (!mounted || _disposed) return;
        if (context.mounted == false) return;
        
        try {
          setState(() {
            _alarms = alarmsList;
          });
          debugPrint('setState完了: _alarms.length=${_alarms.length}');
        } catch (e) {
          debugPrint('_loadAlarms setState エラー: $e');
        }
        debugPrint('アラームデータを読み込みました: ${_alarms.length}件');
      } catch (e) {
        debugPrint('アラームデータ読み込みエラー: $e');
      }
    } else {
      debugPrint('SharedPreferencesがnullのため読み込みをスキップ');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _alarmTimer?.cancel();
    _vibrationTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // アラーム停止機能
  Future<void> _stopAlarm() async {
    try {
      debugPrint('服用時間のアラーム停止開始');
      
      // 音声を停止
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      
      // バイブレーションを停止
      _vibrationTimer?.cancel();
      
      // 通知をキャンセル
      await _notifications.cancelAll();
      
      // 現在鳴っているアラームのlastTriggeredを更新して重複実行を防ぐ
      final now = DateTime.now();
      for (final alarm in _alarms) {
        if (alarm['enabled'] && alarm['time'] == '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}') {
          alarm['lastTriggered'] = now;
          // 一時的にアラームを無効化（次の分まで）
          alarm['temporarilyDisabled'] = true;
          debugPrint('アラーム ${alarm['name']} のlastTriggeredを更新し、一時的に無効化: $now');
        }
      }
      
      // 状態を更新
      if (!mounted || _disposed) return;
      if (context.mounted == false) return;
      
      try {
        // 最終的なmountedチェック
        if (!mounted || _disposed) return;
        
        setState(() {
          _isAlarmPlaying = false;
        });
      } catch (e) {
        debugPrint('_stopAlarm setState エラー: $e');
        return;
      }
      
      debugPrint('服用時間のアラームが停止されました');
    } catch (e) {
      debugPrint('服用時間のアラーム停止エラー: $e');
      
      // エラー時の安全な状態更新
      if (!mounted || _disposed) return;
      if (context.mounted == false) return;
      
      try {
        // 最終的なmountedチェック
        if (!mounted || _disposed) return;
        
        setState(() {
          _isAlarmPlaying = false;
        });
      } catch (setStateError) {
        debugPrint('_stopAlarm catch内 setState エラー: $setStateError');
        return;
      }
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      // 通知権限のみを要求（他の権限は必要に応じて後で要求）
      await Permission.notification.request();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 通知チャンネルを作成
      await _createNotificationChannels();
      debugPrint('通知初期化完了');
    } catch (e) {
      debugPrint('通知初期化エラー: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    // アラーム用チャンネル（スマホのデフォルト音を使用）
    const alarmChannel = AndroidNotificationChannel(
      'alarm_channel',
      '服用時間のアラーム',
      description: '服用時間のアラーム通知',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('default'),
    );

    // バイブレーション用チャンネル
    const vibrationChannel = AndroidNotificationChannel(
      'vibration_channel',
      'バイブ',
      description: 'バイブ通知',
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
    );

    // サイレント用チャンネル
    const silentChannel = AndroidNotificationChannel(
      'silent_channel',
      'サイレント',
      description: 'サイレント通知',
      importance: Importance.min,
      playSound: false,
      enableVibration: false,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(alarmChannel);
    await androidPlugin?.createNotificationChannel(vibrationChannel);
    await androidPlugin?.createNotificationChannel(silentChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('通知がタップされました: ${response.payload}');
    
    if (response.actionId == 'stop') {
      _stopAlarm();
    } else if (response.actionId == 'snooze') {
      _snoozeAlarm();
    } else {
      // 通知自体をタップした場合も停止
      _stopAlarm();
    }
  }

  void _startAlarmCheck() {
    // 既存のタイマーをキャンセル
    _alarmTimer?.cancel();
    
    // ✅ 修正：アラームが鳴るように1秒間隔に戻す（ログ制限は別途対応）
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // タイマー内での安全チェック
      if (!mounted || _disposed) {
        timer.cancel();
        return;
      }
      
      try {
        await _checkAlarms();
      } catch (e) {
        debugPrint('_checkAlarms エラー: $e');
      }
    });
  }

  Future<void> _checkAlarms() async {
      if (!_isAlarmEnabled) {
      return; // 服用時間のアラームが無効の場合は何もしない
    }
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final currentWeekday = now.weekday; // 1=月曜日, 7=日曜日
    
    // 分が変わった時に一時的に無効化されたアラームを再有効化
    if (_lastCheckTime != null && _lastCheckTime!.minute != now.minute) {
      for (final alarm in _alarms) {
        if (alarm['temporarilyDisabled'] == true) {
          alarm['temporarilyDisabled'] = false;
          debugPrint('アラーム ${alarm['name']} を再有効化');
        }
      }
    }
    _lastCheckTime = now;
    
    // ✅ 修正：ログの頻度制限（5分に1回のみ出力）
    if (AlarmOptimization.shouldLogAlarmCheck()) {
      debugPrint('服用時間のアラームチェック: $currentTime, アラーム数: ${_alarms.length}, 有効: $_isAlarmEnabled');
    }
    
    for (final alarm in _alarms) {
      // ✅ 修正：ログの頻度制限のみ適用（アラーム機能は正常に動作）
      if (AlarmOptimization.shouldLogAlarmCheck()) {
        debugPrint('服用時間のアラーム: ${alarm['name']}, 時間: ${alarm['time']}, 有効: ${alarm['enabled']}');
      }
      
      if (alarm['enabled'] && alarm['time'] == currentTime) {
        // 一時的に無効化されたアラームはスキップ
        if (alarm['temporarilyDisabled'] == true) {
          // ✅ 修正：スキップログの頻度制限（5分に1回のみ）
          if (AlarmOptimization.shouldLogAlarmCheck()) {
            debugPrint('服用時間のアラームスキップ: ${alarm['name']} (一時的に無効化中)');
          }
          continue;
        }
        
        // 繰り返し設定のチェック
        if (_shouldTriggerAlarm(alarm, currentWeekday)) {
          // 同じアラームが連続で発火しないようにチェック（1分間隔で制限）
          final lastTriggered = alarm['lastTriggered'] as DateTime?;
          if (lastTriggered == null || 
              now.difference(lastTriggered).inMinutes >= 1) {
            // ✅ 修正：アラーム発火ログは制限なし（重要な情報）
            debugPrint('服用時間のアラーム発火: ${alarm['name']}');
            await _triggerAlarm(alarm);
            // 発火時刻を記録
            alarm['lastTriggered'] = now;
          } else {
            // ✅ 修正：スキップログの頻度制限（5分に1回のみ）
            if (AlarmOptimization.shouldLogAlarmCheck()) {
              debugPrint('服用時間のアラームスキップ: ${alarm['name']} (最近発火済み)');
            }
          }
        } else {
          // ✅ 修正：スキップログの頻度制限（5分に1回のみ）
          if (AlarmOptimization.shouldLogAlarmCheck()) {
            debugPrint('服用時間のアラームスキップ: ${alarm['name']} (繰り返し条件に合わない)');
          }
        }
      }
    }
  }

  bool _shouldTriggerAlarm(Map<String, dynamic> alarm, int currentWeekday) {
    final repeat = alarm['repeat'] ?? '一度だけ';
    final isRepeatEnabled = alarm['isRepeatEnabled'] ?? false;
    final selectedDays = alarm['selectedDays'] as List<bool>?;
    
    // 一度だけの場合は常に発火
    if (!isRepeatEnabled || repeat == '一度だけ') {
      return true;
    }
    
    switch (repeat) {
      case '毎日':
        return true;
      case '平日':
        return currentWeekday >= 1 && currentWeekday <= 5; // 月〜金
      case '週末':
        return currentWeekday == 6 || currentWeekday == 7; // 土・日
      case '曜日':
        if (selectedDays != null && selectedDays.length == 7) {
          // 曜日配列のインデックス調整（月曜日=0, 日曜日=6）
          final dayIndex = currentWeekday == 7 ? 6 : currentWeekday - 1;
          return selectedDays[dayIndex];
        }
        return false;
      default:
        return true;
    }
  }

  Future<void> _triggerAlarm(Map<String, dynamic> alarm) async {
    if (_isAlarmPlaying) {
      debugPrint('服用時間のアラーム既に再生中: ${alarm['name']}');
      return;
    }

    debugPrint('服用時間のアラーム開始: ${alarm['name']}');
    
    // 複数の安全チェックを実行
    if (!mounted || _disposed) return;
    if (context.mounted == false) return;
    
    try {
      // 最終的なmountedチェック
      if (!mounted || _disposed) return;
      
      setState(() {
        _isAlarmPlaying = true;
      });
    } catch (e) {
      debugPrint('_triggerAlarm setState エラー: $e');
      return;
    }

    try {
      // 通知を表示
      await _showAlarmNotification(alarm);
      
      // 服用時間のアラーム種類に応じた処理
      final alarmType = alarm['alarmType'] ?? _selectedNotificationType;
      debugPrint('服用時間のアラーム種類: $alarmType');
      
      switch (alarmType) {
        case 'sound':
          // 音声のみ（ループ設定）
          debugPrint('音声服用時間のアラーム開始: ${_selectedAlarmSound}');
          await _playAlarmSound();
          break;
        case 'sound_vibration':
          // 音声＋バイブレーション（ループ設定）
          debugPrint('音声+バイブ服用時間のアラーム開始: ${_selectedAlarmSound}');
          await _playAlarmSound();
          _startContinuousVibration();
          break;
        case 'vibration':
          // バイブレーションのみ（連続）
          debugPrint('バイブレーション服用時間のアラーム開始');
          _startContinuousVibration();
          break;
        case 'silent':
          // サイレント（音もバイブもなし）
          debugPrint('サイレント服用時間のアラーム');
          break;
      }

      // 服用時間のアラーム停止ダイアログ
      _showAlarmStopDialog();
    } catch (e) {
      debugPrint('服用時間のアラーム再生エラー: $e');
      
      // エラー時の安全な状態更新
      if (!mounted || _disposed) return;
      if (context.mounted == false) return;
      
      try {
        // 最終的なmountedチェック
        if (!mounted || _disposed) return;
        
        setState(() {
          _isAlarmPlaying = false;
        });
      } catch (setStateError) {
        debugPrint('_triggerAlarm catch内 setState エラー: $setStateError');
      }
    }
  }

  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_notificationVolume / 100.0);
      
      // 服用時間のアラーム音ファイルを再生（ループ）
      String soundFile = 'assets/sounds/${_selectedAlarmSound}.mp3';
      debugPrint('服用時間のアラーム音再生開始: $soundFile');
      
      try {
        await _audioPlayer.play(AssetSource('sounds/${_selectedAlarmSound}.mp3'));
        debugPrint('服用時間のアラーム音再生成功');
      } catch (e) {
        debugPrint('服用時間のアラーム音ファイル再生エラー: $e');
        // フォールバック: デフォルト音を使用
        try {
          await _audioPlayer.play(AssetSource('sounds/default.mp3'));
          debugPrint('デフォルト音再生開始');
        } catch (e2) {
          debugPrint('デフォルト音再生エラー: $e2');
        }
      }
    } catch (e) {
      debugPrint('服用時間のアラーム音設定エラー: $e');
    }
  }

  Future<void> _showAlarmNotification(Map<String, dynamic> alarm) async {
    final alarmType = alarm['alarmType'] ?? _selectedNotificationType;
    
    // 服用時間のアラーム種類に応じてチャンネルと設定を選択
    String channelId;
    String channelName;
    String channelDescription;
    bool playSound;
    bool enableVibration;
    
    switch (alarmType) {
      case 'sound':
        channelId = 'alarm_channel';
        channelName = '服用時間のアラーム';
        channelDescription = '服用時間のアラーム通知';
        playSound = true;
        enableVibration = false;
        break;
      case 'sound_vibration':
        channelId = 'alarm_channel';
        channelName = '服用時間のアラーム';
        channelDescription = '服用時間のアラーム通知';
        playSound = true;
        enableVibration = true;
        break;
      case 'vibration':
        channelId = 'vibration_channel';
        channelName = 'バイブ';
        channelDescription = 'バイブ通知';
        playSound = false;
        enableVibration = true;
        break;
      case 'silent':
        channelId = 'silent_channel';
        channelName = 'サイレント';
        channelDescription = 'サイレント通知';
        playSound = false;
        enableVibration = false;
        break;
      default:
        channelId = 'alarm_channel';
        channelName = '服用時間のアラーム';
        channelDescription = '服用時間のアラーム通知';
        playSound = true;
        enableVibration = false;
    }
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      // actions パラメータを削除（通知とスヌーズボタンを消す）
      ongoing: true,
      autoCancel: false,
      playSound: playSound,
      enableVibration: enableVibration,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      categoryIdentifier: 'alarm_category',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      alarm.hashCode,
      alarm['name'],
      'お薬を飲む時間になりました - 通知をタップしてアプリを開く',
      details,
      payload: 'alarm_${alarm.hashCode}',
    );
  }

  NotificationDetails _getNotificationDetails(String type) {
    switch (type) {
      case 'sound':
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'sound_channel',
            '音',
            channelDescription: '音通知',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            actions: [
              AndroidNotificationAction('stop', '停止'),
              AndroidNotificationAction('snooze', 'スヌーズ'),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            categoryIdentifier: 'sound_category',
          ),
        );
      
      case 'sound_vibration':
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'sound_vibration_channel',
            '音＋バイブ',
            channelDescription: '音＋バイブ通知',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            actions: [
              AndroidNotificationAction('stop', '停止'),
              AndroidNotificationAction('snooze', 'スヌーズ'),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            categoryIdentifier: 'sound_vibration_category',
          ),
        );
      
      case 'vibration':
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'vibration_channel',
            'バイブ',
            channelDescription: 'バイブ通知',
            importance: Importance.high,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            silent: true,
            actions: [
              AndroidNotificationAction('stop', '停止'),
              AndroidNotificationAction('snooze', 'スヌーズ'),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
            categoryIdentifier: 'vibration_category',
          ),
        );
      
      case 'silent':
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'silent_channel',
            'サイレント',
            channelDescription: 'サイレント通知',
            importance: Importance.min,
            priority: Priority.min,
            category: AndroidNotificationCategory.reminder,
            silent: true,
            actions: [
              AndroidNotificationAction('dismiss', '閉じる'),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
            categoryIdentifier: 'silent_category',
          ),
        );
      
      default:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'デフォルト',
            channelDescription: 'デフォルト通知',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        );
    }
  }

  String _getNotificationMessage(String type) {
    switch (type) {
      case 'sound':
        return       '服用時間のアラームが鳴っています（音）';
      case 'sound_vibration':
        return '服用時間のアラームが鳴っています（音＋バイブ）';
      case 'vibration':
        return '服用時間のアラームが鳴っています（バイブ）';
      case 'silent':
        return 'サイレント通知です';
      default:
        return '服用時間のアラーム通知です';
    }
  }

  void _updateTime() {
    // 複数の安全チェックを実行
    if (!mounted || _disposed) return;
    
    // コンテキストの有効性を確認
    if (context.mounted == false) return;
    
    // setState前に再度mountedチェック
    if (!mounted || _disposed) return;
    
    try {
      // 現在時刻を安全に取得
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      // 最終的なmountedチェック
      if (!mounted || _disposed) return;
      
      setState(() {
        _currentTime = timeString;
      });
    } catch (e) {
      debugPrint('_updateTime setState エラー: $e');
      return;
    }
    
    // 次の更新をスケジュール（より安全なmountedチェック）
    Future.delayed(const Duration(seconds: 1), () {
      // 非同期処理内でのmountedチェックを強化
      if (mounted && !_disposed && context.mounted) {
        _updateTime();
      }
    });
  }

  void _addAlarm() {
    debugPrint('アラーム追加ダイアログを表示');
    showDialog(
      context: context,
      builder: (context) => _AddAlarmDialog(
        onAlarmAdded: (alarm) async {
          debugPrint('アラーム追加コールバック実行: ${alarm.toString()}');
          // ✅ 修正：状態チェックを完全に削除してアラーム追加を確実に実行
          debugPrint('アラーム追加前のリスト数: ${_alarms.length}');
          try {
            // 直接アラームを追加（setStateを使わない）
            _alarms.add(alarm);
            debugPrint('アラーム追加後のリスト数: ${_alarms.length}');
            
            // アラーム追加後に自動保存
            await _saveAlarms();
            debugPrint('アラーム保存完了');
            
            // 保存後にsetStateでUI更新
            if (mounted) {
              setState(() {
                // UI更新を強制
              });
            }
          } catch (e) {
            debugPrint('アラーム追加エラー: $e');
            // エラーが発生してもアラームを追加
            _alarms.add(alarm);
            await _saveAlarms();
            if (mounted) {
              setState(() {
                // UI更新を強制
              });
            }
          }
        },
      ),
    );
  }

  void _editAlarm(int index, Map<String, dynamic> alarm) {
    showDialog(
      context: context,
      builder: (context) => _AddAlarmDialog(
        initialAlarm: alarm,
        onAlarmAdded: (updatedAlarm) async {
          // ✅ 修正：状態チェックを完全に削除してアラーム編集を確実に実行
          try {
            // 直接アラームを更新（setStateを使わない）
            _alarms[index] = updatedAlarm;
            // アラーム編集後に自動保存
            await _saveAlarms();
            
            // 保存後にsetStateでUI更新
            if (mounted) {
              setState(() {
                // UI更新を強制
              });
            }
          } catch (e) {
            debugPrint('アラーム編集エラー: $e');
            // エラーが発生してもアラームを更新
            _alarms[index] = updatedAlarm;
            await _saveAlarms();
            if (mounted) {
              setState(() {
                // UI更新を強制
              });
            }
          }
        },
      ),
    );
  }


  String _getNotificationTypeName(String type) {
    switch (type) {
      case 'sound':
        return '音';
      case 'sound_vibration':
        return '音＋バイブ';
      case 'vibration':
        return 'バイブ';
      case 'silent':
        return 'サイレント';
      default:
        return 'デフォルト';
    }
  }

  void _showAlarmStopDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 外側タップで閉じない
      builder: (BuildContext context) {
        // 5秒後に自動的にダイアログを閉じる
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && !_disposed && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });
        
        return WillPopScope(
          onWillPop: () async => false, // 戻るボタンで閉じない
          child: AlertDialog(
            title: const Text(
              '服用時間です',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.alarm,
                  size: 60,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'お薬を飲む時間になりました',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'この通知は5秒後に自動的に消えます',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            // ボタンを削除（actionsプロパティを削除）
          ),
        );
      },
    );
  }

  void _snoozeAlarm() async {
    _stopAlarm();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('スヌーズ機能は無効化されました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAlarmTypeChip(String type) {
    final typeInfo = _getAlarmTypeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: typeInfo['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeInfo['color'].withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(typeInfo['icon'], style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            typeInfo['name'],
            style: TextStyle(
              fontSize: 10,
              color: typeInfo['color'],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChip(int volume) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.volume_up, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '$volume%',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibrationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vibration, size: 12, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            'バイブ',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getAlarmTypeInfo(String type) {
    switch (type) {
      case 'sound':
        return {'name': '音', 'icon': '🔊', 'color': Colors.blue};
      case 'sound_vibration':
        return {'name': '音＋バイブ', 'icon': '🔊📳', 'color': Colors.green};
      case 'vibration':
        return {'name': 'バイブ', 'icon': '📳', 'color': Colors.orange};
      case 'silent':
        return {'name': 'サイレント', 'icon': '🔇', 'color': Colors.grey};
      default:
        return {'name': 'デフォルト', 'icon': '🔔', 'color': Colors.blue};
    }
  }

  String _getRepeatDisplayText(Map<String, dynamic> alarm) {
    final repeat = alarm['repeat'] ?? '一度だけ';
    final isRepeatEnabled = alarm['isRepeatEnabled'] ?? false;
    final selectedDays = alarm['selectedDays'] as List<bool>?;
    
    if (!isRepeatEnabled || repeat == '一度だけ') {
      return '一度だけ';
    }
    
    if (repeat == '曜日' && selectedDays != null) {
      const days = ['月', '火', '水', '木', '金', '土', '日'];
      final selectedDayNames = <String>[];
      for (int i = 0; i < 7; i++) {
        if (selectedDays[i]) {
          selectedDayNames.add(days[i]);
        }
      }
      return selectedDayNames.isEmpty ? '曜日未選択' : selectedDayNames.join(',');
    }
    
    return repeat;
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('通知設定'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // 通知タイプ選択
              const Text('通知タイプ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedNotificationType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'sound', child: Text('🔊 音')),
                  DropdownMenuItem(value: 'sound_vibration', child: Text('🔊📳 音＋バイブ')),
                  DropdownMenuItem(value: 'vibration', child: Text('📳 バイブ')),
                  DropdownMenuItem(value: 'silent', child: Text('🔇 サイレント')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedNotificationType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // アラーム音選択
              const Text('アラーム音', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAlarmSound,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'default', child: Text('🔔 デフォルト音')),
                  DropdownMenuItem(value: 'gentle', child: Text('🌸 優しい音')),
                  DropdownMenuItem(value: 'urgent', child: Text('⚠️ 緊急音')),
                  DropdownMenuItem(value: 'classic', child: Text('🎵 クラシック')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAlarmSound = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 通知音選択
              const Text('通知音', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedNotificationSound,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'single_notification', child: Text('🔔 単発通知')),
                  DropdownMenuItem(value: 'loop_notification', child: Text('🔄 ループ通知')),
                  DropdownMenuItem(value: 'short_loop', child: Text('⏰ 短いループ')),
                  DropdownMenuItem(value: 'long_loop', child: Text('📢 長いループ')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedNotificationSound = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 音量設定
              const Text('音量', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('0%'),
                  Expanded(
                    child: Slider(
                      value: _notificationVolume.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() {
                          _notificationVolume = value.round();
                        });
                      },
                    ),
                  ),
                  Text('${_notificationVolume}%'),
                ],
              ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveSettings();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('通知設定を保存しました')),
                );
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _startContinuousVibration() async {
    debugPrint('連続バイブレーション開始');
    try {
      if (await Vibration.hasVibrator() == true) {
        debugPrint('バイブレーション機能利用可能');
        // 即座にバイブレーションを開始
        await Vibration.vibrate(duration: 2000);
        // 連続バイブレーション用のタイマー（より頻繁に）
        _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
          if (_isAlarmPlaying) {
            debugPrint('バイブレーション実行');
            try {
              await Vibration.vibrate(duration: 2000);
            } catch (e) {
              debugPrint('バイブレーションエラー: $e');
            }
          } else {
            timer.cancel();
            debugPrint('バイブレーション停止（服用時間のアラーム停止）');
          }
        });
      } else {
        debugPrint('バイブレーション機能利用不可');
      }
    } catch (e) {
      debugPrint('バイブレーション初期化エラー: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
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
            // 現在時刻表示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateTime.now().toString().substring(0, 10),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // アラーム有効/無効トグル
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isAlarmEnabled ? Icons.alarm : Icons.alarm_off,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isAlarmEnabled ? 'アラーム有効' : 'アラーム無効',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: _isAlarmEnabled,
                        onChanged: (value) async {
                          setState(() {
                            _isAlarmEnabled = value;
                          });
                          
                          // アラームを無効にした場合、現在鳴っているアラームを停止
                          if (!value && _isAlarmPlaying) {
                            await _stopAlarm();
                          }
                          
                          await _saveSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? 'アラームを有効にしました' : 'アラームを無効にしました'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.white70,
                        inactiveThumbColor: Colors.white70,
                        inactiveTrackColor: Colors.white30,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // アラーム一覧
            Expanded(
              child: Builder(
                builder: (context) {
                  debugPrint('アラームリスト表示: ${_alarms.length}件');
                  return _alarms.isEmpty
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
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _alarms.length,
                          itemBuilder: (context, index) {
                        final alarm = _alarms[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _editAlarm(index, alarm),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        alarm['enabled'] ? Icons.alarm : Icons.alarm_off,
                                        color: alarm['enabled'] ? const Color(0xFF2196F3) : Colors.grey,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              alarm['name'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${alarm['time']} (${_getRepeatDisplayText(alarm)})',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: alarm['enabled'],
                                        onChanged: (value) async {
                                          // ✅ 修正：状態チェックを完全に削除してアラーム切り替えを確実に実行
                                          try {
                                            // 直接アラームを切り替え（setStateを使わない）
                                            alarm['enabled'] = value;
                                            
                                            // アラーム切り替え後に自動保存
                                            await _saveAlarms();
                                            
                                            // 保存後にsetStateでUI更新
                                            if (mounted) {
                                              setState(() {
                                                // UI更新を強制
                                              });
                                            }
                                          } catch (e) {
                                            debugPrint('アラーム切り替えエラー: $e');
                                            // エラーが発生してもアラームを切り替え
                                            alarm['enabled'] = value;
                                            await _saveAlarms();
                                            if (mounted) {
                                              setState(() {
                                                // UI更新を強制
                                              });
                                            }
                                          }
                                          
                                          // アラームを無効にした場合、現在鳴っているアラームを停止
                                          if (!value && _isAlarmPlaying) {
                                            await _stopAlarm();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _buildAlarmTypeChip(alarm['alarmType'] ?? 'sound'),
                                      if (alarm['volume'] != null)
                                        _buildVolumeChip(alarm['volume']),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          // ✅ 修正：状態チェックを完全に削除してアラーム削除を確実に実行
                                          try {
                                            // 直接アラームを削除（setStateを使わない）
                                            _alarms.removeAt(index);
                                            
                                            // アラーム削除後に自動保存
                                            await _saveAlarms();
                                            
                                            // 保存後にsetStateでUI更新
                                            if (mounted) {
                                              setState(() {
                                                // UI更新を強制
                                              });
                                            }
                                          } catch (e) {
                                            debugPrint('アラーム削除エラー: $e');
                                            // エラーが発生してもアラームを削除
                                            _alarms.removeAt(index);
                                            await _saveAlarms();
                                            if (mounted) {
                                              setState(() {
                                                // UI更新を強制
                                              });
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        iconSize: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddAlarmDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAlarmAdded;
  final Map<String, dynamic>? initialAlarm;

  const _AddAlarmDialog({
    required this.onAlarmAdded,
    this.initialAlarm,
  });

  @override
  State<_AddAlarmDialog> createState() => _AddAlarmDialogState();
}

class _AddAlarmDialogState extends State<_AddAlarmDialog> {
  final _nameController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _repeatType = '一度だけ';
  String _selectedAlarmType = 'sound';
  int _volume = 80;
  bool _isRepeatEnabled = false;
  List<bool> _selectedDays = [false, false, false, false, false, false, false]; // 月〜日

  @override
  void initState() {
    super.initState();
    if (widget.initialAlarm != null) {
      _nameController.text = widget.initialAlarm!['name'] ?? '';
      _selectedAlarmType = widget.initialAlarm!['alarmType'] ?? 'sound';
      _volume = widget.initialAlarm!['volume'] ?? 80;
      _isRepeatEnabled = widget.initialAlarm!['isRepeatEnabled'] ?? false;
      _selectedDays = List<bool>.from(widget.initialAlarm!['selectedDays'] ?? [false, false, false, false, false, false, false]);
      
      // 繰り返し設定の初期化
      final repeat = widget.initialAlarm!['repeat'] ?? '一度だけ';
      if (_isRepeatEnabled && repeat != '一度だけ') {
        _repeatType = repeat;
      } else {
        _repeatType = '毎日'; // デフォルト値
      }
      
      // 時間の設定
      final timeStr = widget.initialAlarm!['time'] ?? '00:00';
      final timeParts = timeStr.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialAlarm != null ? 'アラーム編集' : 'アラーム追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // アラーム名
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'アラーム名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            
            // 時間選択
            ListTile(
              title: const Text('時間'),
              subtitle: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // 繰り返し設定
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.repeat, color: Color(0xFF2196F3)),
                        const SizedBox(width: 8),
                        const Text('繰り返し', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Switch(
                          value: _isRepeatEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isRepeatEnabled = value;
                              if (!value) {
                                _repeatType = '一度だけ';
                              } else {
                                // 繰り返しが有効になった時はデフォルトで「毎日」を設定
                                if (_repeatType == '一度だけ') {
                                  _repeatType = '毎日';
                                }
                              }
                            });
                          },
                          activeColor: const Color(0xFF2196F3),
                        ),
                      ],
                    ),
                    if (_isRepeatEnabled) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _isRepeatEnabled ? _repeatType : '一度だけ',
                        decoration: const InputDecoration(
                          labelText: '繰り返しパターン',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: const [
                          DropdownMenuItem(value: '毎日', child: Text('毎日')),
                          DropdownMenuItem(value: '曜日', child: Text('曜日')),
                          DropdownMenuItem(value: '平日', child: Text('平日')),
                          DropdownMenuItem(value: '週末', child: Text('週末')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _repeatType = value!;
                          });
                        },
                      ),
                      if (_repeatType == '曜日') ...[
                        const SizedBox(height: 16),
                        const Text('曜日を選択', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildDaySelector(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // アラーム種類選択
            DropdownButtonFormField<String>(
              value: _selectedAlarmType,
              decoration: const InputDecoration(
                labelText: '服用アラーム種類',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications),
              ),
              items: const [
                DropdownMenuItem(value: 'sound', child: Text('🔊 音')),
                DropdownMenuItem(value: 'sound_vibration', child: Text('🔊📳 音＋バイブ')),
                DropdownMenuItem(value: 'vibration', child: Text('📳 バイブ')),
                DropdownMenuItem(value: 'silent', child: Text('🔇 サイレント')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAlarmType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 音量設定
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('音量', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$_volume%', style: const TextStyle(color: Color(0xFF2196F3))),
                      ],
                    ),
                    Slider(
                      value: _volume.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: const Color(0xFF2196F3),
                      onChanged: (value) {
                        setState(() {
                          _volume = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final alarm = {
              'name': _nameController.text.isEmpty ? 'アラーム' : _nameController.text,
              'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              'repeat': _isRepeatEnabled ? _repeatType : '一度だけ',
              'enabled': true,
              'alarmType': _selectedAlarmType,
              'volume': _volume,
              'isRepeatEnabled': _isRepeatEnabled,
              'selectedDays': _selectedDays,
            };
            debugPrint('アラーム追加ボタン押下: ${alarm.toString()}');
            widget.onAlarmAdded(alarm);
            debugPrint('アラーム追加コールバック呼び出し完了');
            Navigator.pop(context);
          },
          child: Text(widget.initialAlarm != null ? '更新' : '追加'),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    const days = ['月', '火', '水', '木', '金', '土', '日'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDays[index] = !_selectedDays[index];
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _selectedDays[index] 
                  ? const Color(0xFF2196F3) 
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedDays[index] 
                    ? const Color(0xFF2196F3) 
                    : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  color: _selectedDays[index] 
                      ? Colors.white 
                      : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}