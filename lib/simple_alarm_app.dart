import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'core/alarm_optimization.dart';
import 'core/snapshot_service.dart';

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
  // 同一分内の重複発火防止用
  String? _lastFiredTimeLabel; // 'HH:mm'
  int? _lastFiredMinuteMarker; // 日内分番号 (hour*60+minute)

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
      // SharedPreferencesを確実に初期化
      _prefs = await SharedPreferences.getInstance();
      debugPrint('✅ SharedPreferences初期化完了');
      
      // 設定とアラームを読み込み
      await _loadSettings();
      debugPrint('✅ 設定読み込み完了');
      
      // アラームデータを明示的に読み込み
      await _loadAlarms();
      debugPrint('✅ アラーム読み込み完了: ${_alarms.length}件');
      
      // データ整合性チェック
      await _validateAlarmData();
      
      // 通知の初期化
      _initializeNotifications().catchError((e) {
        debugPrint('通知初期化エラー: $e');
      });
      
      // UIを更新
      if (mounted && !_disposed) {
        setState(() {});
        _updateTime();
        _startAlarmCheck();
        debugPrint('✅ アプリ初期化完了');
      }
    } catch (e) {
      debugPrint('❌ 初期化エラー: $e');
      if (mounted && !_disposed) {
        _updateTime();
        _startAlarmCheck();
      }
    }
  }

  Future<void> _loadSettings() async {
    if (_prefs != null) {
      _isAlarmEnabled = _prefs!.getBool('alarm_enabled') ?? true;
      _selectedNotificationType = _prefs!.getString('notification_type') ?? 'sound';
      _selectedAlarmSound = _prefs!.getString('alarm_sound') ?? 'default';
      
      // ✅ 修正: 型安全な読み込み（古いStringデータにも対応）
      try {
        // まずint型で読み込みを試行
        final volumeInt = _prefs!.getInt('notification_volume');
        if (volumeInt != null) {
          _notificationVolume = volumeInt;
          debugPrint('✅ notification_volume読み込み成功: $_notificationVolume (int型)');
        } else {
          // int型で読み込めない場合、古いStringデータの可能性をチェック
          debugPrint('⚠️ notification_volumeがint型で読み込めません。古いデータ形式の可能性があります。');
          final volumeStr = _prefs!.getString('notification_volume');
          if (volumeStr != null && volumeStr.isNotEmpty) {
            _notificationVolume = int.tryParse(volumeStr) ?? 80;
            debugPrint('⚠️ volumeを文字列から整数に変換: $volumeStr -> $_notificationVolume');
            // 次回は正しい型で保存されるように即座に保存
            await _prefs!.setInt('notification_volume', _notificationVolume);
            debugPrint('✅ notification_volumeを正しい型で再保存: $_notificationVolume');
          } else {
            _notificationVolume = 80;
            debugPrint('⚠️ notification_volumeのデータが見つかりません。デフォルト値80を使用');
          }
        }
      } catch (e) {
        debugPrint('❌ notification_volume読み込みエラー: $e');
        _notificationVolume = 80;
        debugPrint('⚠️ デフォルト値80を使用し、正しい型で保存します');
        // エラーが出たので正しい型で保存
        await _prefs!.setInt('notification_volume', _notificationVolume);
      }
      
      debugPrint('✅ 設定読み込み完了');
      // ⚠️ ここでは_loadAlarms()を呼ばない（_initializeApp()で明示的に呼ぶ）
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



  // ✅ 曜日データを読み込むヘルパーメソッドを追加
  List<bool> _loadSelectedDays(int index) {
    final selectedDays = <bool>[];
    for (int j = 0; j < 7; j++) {
      final day = _prefs!.getBool('alarm_${index}_day_$j') ?? false;
      selectedDays.add(day);
    }
    return selectedDays;
  }

  // ✅ データ整合性チェック機能を追加（強化版）
  Future<void> _validateAlarmData() async {
    if (_prefs == null) return;
    
    try {
      final alarmCount = _prefs!.getInt('alarm_count') ?? 0;
      debugPrint('🔍 データ整合性チェック開始: $alarmCount件のアラーム');
      
      // 通知設定の型チェック（強化版）
      debugPrint('🔍 notification_volumeの型チェック開始');
      try {
        final notificationVolume = _prefs!.getInt('notification_volume');
        if (notificationVolume != null) {
          debugPrint('✅ notification_volume: $notificationVolume (int型)');
        } else {
          debugPrint('⚠️ notification_volumeがint型で読み込めません');
          // 古いStringデータをチェック
          final volumeStr = _prefs!.getString('notification_volume');
          if (volumeStr != null) {
            debugPrint('⚠️ notification_volumeが文字列として保存されています: $volumeStr');
            // 正しい型で再保存
            final volumeInt = int.tryParse(volumeStr) ?? 80;
            await _prefs!.setInt('notification_volume', volumeInt);
            debugPrint('✅ notification_volumeを正しい型で再保存: $volumeInt');
          } else {
            debugPrint('⚠️ notification_volumeのデータが見つかりません。デフォルト値80で保存');
            await _prefs!.setInt('notification_volume', 80);
          }
        }
      } catch (e) {
        debugPrint('❌ notification_volume型チェックエラー: $e');
        // エラーが発生した場合、デフォルト値で保存
        await _prefs!.setInt('notification_volume', 80);
        debugPrint('✅ notification_volumeをデフォルト値80で保存');
      }
      
      for (int i = 0; i < alarmCount; i++) {
        // 各フィールドの型をチェック
        final name = _prefs!.getString('alarm_${i}_name');
        final time = _prefs!.getString('alarm_${i}_time');
        final volume = _prefs!.getInt('alarm_${i}_volume');
        
        if (name == null || name.isEmpty) {
          debugPrint('⚠️ アラーム $i: nameが無効');
        }
        if (time == null || time.isEmpty) {
          debugPrint('⚠️ アラーム $i: timeが無効');
        }
        if (volume == null) {
          debugPrint('⚠️ アラーム $i: volumeが無効（型エラーの可能性）');
          // 古いStringデータをチェック
          final volumeStr = _prefs!.getString('alarm_${i}_volume');
          if (volumeStr != null) {
            debugPrint('⚠️ アラーム $i: volumeが文字列として保存されています: $volumeStr');
            // 正しい型で再保存
            final volumeInt = int.tryParse(volumeStr) ?? 80;
            await _prefs!.setInt('alarm_${i}_volume', volumeInt);
            debugPrint('✅ アラーム $i: volumeを正しい型で再保存: $volumeInt');
          }
        }
      }
      
      debugPrint('✅ データ整合性チェック完了');
    } catch (e) {
      debugPrint('❌ データ整合性チェックエラー: $e');
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
        if ((alarm['enabled'] as bool) && alarm['time'] == '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}') {
          alarm['lastTriggered'] = now;
          // 一時的にアラームを無効化（次の分まで）
          alarm['temporarilyDisabled'] = true;
          debugPrint('アラーム ${alarm['name']} のlastTriggeredを更新し、一時的に無効化: $now');
        }
      }
      
      // 状態を更新
      if (mounted && !_disposed) {
        try {
          setState(() {
            _isAlarmPlaying = false;
          });
        } catch (e) {
          debugPrint('_stopAlarm setState エラー: $e');
        }
      }
      
      debugPrint('服用時間のアラームが停止されました');
    } catch (e) {
      debugPrint('服用時間のアラーム停止エラー: $e');
      
      // エラー時の安全な状態更新
      if (mounted && !_disposed) {
        try {
          setState(() {
            _isAlarmPlaying = false;
          });
        } catch (setStateError) {
          debugPrint('_stopAlarm catch内 setState エラー: $setStateError');
        }
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
    debugPrint('通知がタップされました: ${response.payload}, actionId: ${response.actionId}');
    
    // UIスレッドで確実に実行されるようにする
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        try {
          if (response.actionId == 'stop') {
            await _stopAlarm();
          } else if (response.actionId == 'snooze') {
            await _snoozeAlarm();
          } else {
            // 通知自体をタップした場合も停止
            await _stopAlarm();
          }
        } catch (e) {
          debugPrint('通知タップ処理エラー: $e');
          // エラー時でもアラームを停止しようとする
          if (mounted && !_disposed) {
            try {
              await _stopAlarm();
            } catch (stopError) {
              debugPrint('_stopAlarm呼び出しエラー: $stopError');
            }
          }
        }
      });
    });
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
    
    bool firedThisMinute = false;
    for (final alarm in _alarms) {
      // ✅ 修正：ログの頻度制限のみ適用（アラーム機能は正常に動作）
      if (AlarmOptimization.shouldLogAlarmCheck()) {
        debugPrint('服用時間のアラーム: ${alarm['name']}, 時間: ${alarm['time']}, 有効: ${alarm['enabled']}');
      }
      
      if ((alarm['enabled'] as bool) && alarm['time'] == currentTime) {
        // 同一分内に既にどれかのアラームが発火していればスキップ
        final minuteMarker = now.hour * 60 + now.minute;
        if (_lastFiredTimeLabel == currentTime && _lastFiredMinuteMarker == minuteMarker) {
          continue;
        }
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
            _lastFiredTimeLabel = currentTime;
            _lastFiredMinuteMarker = minuteMarker;
            firedThisMinute = true;
            break; // 同じ分に複数発火しないように打ち切る
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
    if (!(isRepeatEnabled as bool) || repeat == '一度だけ') {
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
        if (!context.mounted) return;
    
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
        if (!context.mounted) return;
      
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
        alarm['name'] as String,
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

  // ✅ 修正1: アラーム追加メソッドを完全に作り直し
  void _addAlarm() {
    debugPrint('📝 アラーム追加ダイアログを表示');
    showDialog(
      context: context,
      builder: (context) => _AddAlarmDialog(
        onAlarmAdded: (alarm) async {
          // ✅ 変更前スナップショット（メインに委譲）
          await SnapshotService.saveBeforeChange('アラーム追加_${alarm['name'] ?? '無題'}');
          debugPrint('📝 アラーム追加開始: ${alarm.toString()}');
          
          try {
            // ✅ 型安全性を確保：volumeを確実にint型に変換
            final safeAlarm = Map<String, dynamic>.from(alarm);
            if (safeAlarm['volume'] is String) {
              safeAlarm['volume'] = int.tryParse(safeAlarm['volume'] as String) ?? 80;
            } else if (safeAlarm['volume'] is! int) {
              safeAlarm['volume'] = 80;
            }
            
            // ✅ その他の必須フィールドも確実に設定
            safeAlarm['enabled'] = safeAlarm['enabled'] ?? true;
            safeAlarm['alarmType'] = safeAlarm['alarmType'] ?? 'sound';
            safeAlarm['isRepeatEnabled'] = safeAlarm['isRepeatEnabled'] ?? false;
            safeAlarm['selectedDays'] = safeAlarm['selectedDays'] ?? [false, false, false, false, false, false, false];
            
            debugPrint('📝 型安全なアラーム: $safeAlarm');
            debugPrint('📝 追加前のアラーム数: ${_alarms.length}');
            
            // ✅ アラームリストに追加
            _alarms.add(safeAlarm);
            debugPrint('📝 追加後のアラーム数: ${_alarms.length}');
            
            // ✅ まずUIを更新（即座に表示）
            if (mounted && !_disposed) {
              setState(() {
                debugPrint('✅ UI更新完了: ${_alarms.length}件表示');
              });
            }
            
            // ✅ その後にデータを保存
            await _saveAlarms();
            debugPrint('✅ アラーム保存完了');
            
            // ✅ 保存後に再度データを読み込んで確認
            await _loadAlarms();
            debugPrint('✅ アラーム再読み込み完了: ${_alarms.length}件');
            
            // ✅ 確認用のスナックバー
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('アラーム「${safeAlarm['name']}」を追加しました'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
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

  // ✅ 修正2: アラーム編集メソッドを完全に作り直し
  void _editAlarm(int index, Map<String, dynamic> alarm) {
    showDialog(
      context: context,
      builder: (context) => _AddAlarmDialog(
        initialAlarm: alarm,
        onAlarmAdded: (updatedAlarm) async {
          // ✅ 変更前スナップショット（メインに委譲）
          await SnapshotService.saveBeforeChange('アラーム編集_${updatedAlarm['name'] ?? '無題'}');
          try {
            debugPrint('📝 アラーム編集開始: インデックス $index');
            
            // ✅ 型安全性を確保
            final safeAlarm = Map<String, dynamic>.from(updatedAlarm);
            if (safeAlarm['volume'] is String) {
              safeAlarm['volume'] = int.tryParse(safeAlarm['volume'] as String) ?? 80;
            } else if (safeAlarm['volume'] is! int) {
              safeAlarm['volume'] = 80;
            }
            
            // ✅ アラームを更新
            _alarms[index] = safeAlarm;
            debugPrint('✅ アラーム更新完了');
            
            // ✅ まずUIを更新
            if (mounted && !_disposed) {
              setState(() {
                debugPrint('✅ UI更新完了');
              });
            }
            
            // ✅ データを保存
            await _saveAlarms();
            debugPrint('✅ アラーム保存完了');
            
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('アラーム「${safeAlarm['name']}」を更新しました'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
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

  // アラーム保存メソッド
  Future<void> _saveAlarms() async {
    if (_prefs == null) {
      debugPrint('⚠️ SharedPreferencesがnullのため保存をスキップ');
      return;
    }
    
    try {
      // ✅ アラーム数を保存
      await _prefs!.setInt('alarm_count', _alarms.length);
      debugPrint('✅ アラーム数保存完了: ${_alarms.length}件');
      
      // ✅ 各アラームのデータを個別に保存（完全な型安全性）
      for (int i = 0; i < _alarms.length; i++) {
        try {
          final alarm = _alarms[i];
          debugPrint('💾 アラーム $i 保存: ${alarm['name']}');
          
          // ✅ 文字列フィールド
          await _prefs!.setString('alarm_${i}_name', alarm['name']?.toString() ?? 'アラーム');
          await _prefs!.setString('alarm_${i}_time', alarm['time']?.toString() ?? '00:00');
          await _prefs!.setString('alarm_${i}_repeat', alarm['repeat']?.toString() ?? '一度だけ');
          await _prefs!.setString('alarm_${i}_alarmType', alarm['alarmType']?.toString() ?? 'sound');
          
          // ✅ ブール値
          final enabled = alarm['enabled'] is bool ? alarm['enabled'] as bool : true;
          await _prefs!.setBool('alarm_${i}_enabled', enabled);
          
          final isRepeatEnabled = alarm['isRepeatEnabled'] is bool ? alarm['isRepeatEnabled'] as bool : false;
          await _prefs!.setBool('alarm_${i}_isRepeatEnabled', isRepeatEnabled);
          
          // ✅ 整数値（volumeの型安全性を完全保証）
          int volume = 80;
          if (alarm['volume'] is int) {
            volume = alarm['volume'] as int;
          } else if (alarm['volume'] is String) {
            volume = int.tryParse(alarm['volume'] as String) ?? 80;
            debugPrint('⚠️ アラーム $i: volumeを文字列から整数に変換: ${alarm['volume']} -> $volume');
          } else if (alarm['volume'] is double) {
            volume = (alarm['volume'] as double).round();
          }
          await _prefs!.setInt('alarm_${i}_volume', volume);
          debugPrint('✅ アラーム $i volume保存: $volume');
          
          // ✅ 曜日データ
          final selectedDays = alarm['selectedDays'] is List ? 
                              (alarm['selectedDays'] as List).cast<bool>() : 
                              [false, false, false, false, false, false, false];
          for (int j = 0; j < 7; j++) {
            await _prefs!.setBool('alarm_${i}_day_$j', j < selectedDays.length ? selectedDays[j] : false);
          }
          
          debugPrint('✅ アラーム $i 保存完了');
        } catch (e) {
          debugPrint('❌ アラーム $i 保存エラー: $e');
          continue;
        }
      }
      
      // ✅ 保存完了を確認
      final savedCount = _prefs!.getInt('alarm_count') ?? 0;
      debugPrint('✅ 保存確認: $savedCount件のアラームが保存されました');
      
    } catch (e, stackTrace) {
      debugPrint('❌ アラームデータ保存エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }

  // アラーム読み込みメソッド
  Future<void> _loadAlarms() async {
    debugPrint('📂 アラーム読み込み開始');
    if (_prefs == null) {
      debugPrint('⚠️ SharedPreferencesがnullのため読み込みをスキップ');
      return;
    }
    
    try {
      final alarmCount = _prefs!.getInt('alarm_count') ?? 0;
      debugPrint('📂 保存されているアラーム数: $alarmCount件');
      
      if (alarmCount == 0) {
        debugPrint('ℹ️ アラームデータなし');
        if (mounted && !_disposed) {
          setState(() {
            _alarms = [];
          });
        }
        return;
      }
      
      final alarmsList = <Map<String, dynamic>>[];
      
      for (int i = 0; i < alarmCount; i++) {
        try {
          // ✅ 各フィールドを型安全に取得
          final name = _prefs!.getString('alarm_${i}_name') ?? 'アラーム';
          final time = _prefs!.getString('alarm_${i}_time') ?? '00:00';
          final repeat = _prefs!.getString('alarm_${i}_repeat') ?? '一度だけ';
          final enabled = _prefs!.getBool('alarm_${i}_enabled') ?? true;
          final alarmType = _prefs!.getString('alarm_${i}_alarmType') ?? 'sound';
          final isRepeatEnabled = _prefs!.getBool('alarm_${i}_isRepeatEnabled') ?? false;
          
          // ✅ volumeの完全な型安全性
          int volume = 80;
          final volumeInt = _prefs!.getInt('alarm_${i}_volume');
          if (volumeInt != null) {
            volume = volumeInt;
          } else {
            final volumeStr = _prefs!.getString('alarm_${i}_volume');
            if (volumeStr != null && volumeStr.isNotEmpty) {
              volume = int.tryParse(volumeStr) ?? 80;
              debugPrint('⚠️ アラーム $i: volumeを文字列から整数に変換: $volumeStr -> $volume');
            }
          }
          
          // ✅ 曜日データを読み込み
          final selectedDays = <bool>[];
          for (int j = 0; j < 7; j++) {
            selectedDays.add(_prefs!.getBool('alarm_${i}_day_$j') ?? false);
          }
          
          debugPrint('📂 アラーム $i 読み込み: name=$name, time=$time, volume=$volume');
          
          // ✅ アラームをリストに追加
          alarmsList.add({
            'name': name,
            'time': time,
            'repeat': repeat,
            'enabled': enabled,
            'alarmType': alarmType,
            'volume': volume,
            'isRepeatEnabled': isRepeatEnabled,
            'selectedDays': selectedDays,
          });
          
          debugPrint('✅ アラーム $i 追加完了');
        } catch (e) {
          debugPrint('❌ アラーム $i 読み込みエラー: $e');
          continue;
        }
      }
      
      debugPrint('📂 読み込み完了: ${alarmsList.length}件のアラーム');
      
      // ✅ UI更新
      if (mounted && !_disposed) {
        setState(() {
          _alarms = alarmsList;
        });
        debugPrint('✅ setState完了: _alarms.length=${_alarms.length}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ アラームデータ読み込みエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
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

  Future<void> _snoozeAlarm() async {
    await _stopAlarm();
    
    // contextが利用可能な場合のみSnackBarを表示
    if (mounted && !_disposed) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('スヌーズ機能は無効化されました'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        debugPrint('_snoozeAlarm SnackBar表示エラー: $e');
      }
    }
  }

  Widget _buildAlarmTypeChip(String type) {
    final typeInfo = _getAlarmTypeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (typeInfo['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (typeInfo['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(typeInfo['icon'] as String, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            typeInfo['name'] as String,
            style: TextStyle(
              fontSize: 10,
              color: typeInfo['color'] as Color,
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
    
    if (!(isRepeatEnabled as bool) || repeat == '一度だけ') {
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
    
    return repeat as String;
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
                        if (AlarmOptimization.shouldLogAlarmCheck()) {
                          debugPrint('🔍 アラーム表示[$index]: ${_alarms[index]['name']}');
                        }
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
                                        (alarm['enabled'] as bool) ? Icons.alarm : Icons.alarm_off,
                                        color: (alarm['enabled'] as bool) ? const Color(0xFF2196F3) : Colors.grey,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              alarm['name'] as String,
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
                                        value: alarm['enabled'] as bool,
                                        onChanged: (value) async {
                                          // ✅ 修正：アラーム切り替えを確実に実行
                                          try {
                                            // ✅ スナップショット（切替前）
                                            await SnapshotService.saveBeforeChange('アラーム切替_${alarm['name'] ?? '無題'}');
                                            // 直接アラームを切り替え
                                            alarm['enabled'] = value;
                                            debugPrint('✅ アラーム切り替え完了: ${alarm['name']} = $value');
                                            
                                            // アラーム切り替え後に自動保存
                                            await _saveAlarms();
                                            
                                            // 保存後にsetStateでUI更新
                                            if (mounted) {
                                              setState(() {
                                                debugPrint('✅ アラーム切り替えUI更新完了');
                                              });
                                            }
                                          } catch (e) {
                                            debugPrint('アラーム切り替えエラー: $e');
                                            // エラーが発生してもアラームを切り替え
                                            alarm['enabled'] = value;
                                            await _saveAlarms();
                                            if (mounted) {
                                              setState(() {
                                                debugPrint('✅ アラーム切り替え完了（エラー後）');
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
                                      _buildAlarmTypeChip(alarm['alarmType'] as String? ?? 'sound'),
                                      if (alarm['volume'] != null)
                                        _buildVolumeChip(alarm['volume'] as int),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          // ✅ 修正：アラーム削除を確実に実行
                                          try {
                                            // ✅ スナップショット（削除前）
                                            final name = _alarms[index]['name'] ?? 'アラーム$index';
                                            await SnapshotService.saveBeforeChange('アラーム削除_$name');
                                            // 直接アラームを削除
                                            _alarms.removeAt(index);
                                            debugPrint('✅ アラーム削除完了: ${_alarms.length}件残り');
                                            
                                            // アラーム削除後に自動保存
                                            await _saveAlarms();
                                            
                                            // 保存後にsetStateでUI更新
                                            if (mounted) {
                                              setState(() {
                                                debugPrint('✅ アラーム削除UI更新完了: ${_alarms.length}件表示');
                                              });
                                            }
                                          } catch (e) {
                                            debugPrint('アラーム削除エラー: $e');
                                            // エラーが発生してもアラームを削除
                                            _alarms.removeAt(index);
                                            await _saveAlarms();
                                            if (mounted) {
                                              setState(() {
                                                debugPrint('✅ アラーム削除完了（エラー後）: ${_alarms.length}件表示');
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
      _nameController.text = (widget.initialAlarm!['name'] as String?) ?? '';
      _selectedAlarmType = (widget.initialAlarm!['alarmType'] as String?) ?? 'sound';
      _volume = (widget.initialAlarm!['volume'] as int?) ?? 80;
      _isRepeatEnabled = (widget.initialAlarm!['isRepeatEnabled'] as bool?) ?? false;
      _selectedDays = List<bool>.from((widget.initialAlarm!['selectedDays'] as List?) ?? [false, false, false, false, false, false, false]);
      
      // 繰り返し設定の初期化
      final repeat = (widget.initialAlarm!['repeat'] as String?) ?? '一度だけ';
      if (_isRepeatEnabled && repeat != '一度だけ') {
        _repeatType = repeat;
      } else {
        _repeatType = '毎日'; // デフォルト値
      }
      
      // 時間の設定
      final timeStr = (widget.initialAlarm!['time'] as String?) ?? '00:00';
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
            final alarm = <String, dynamic>{
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