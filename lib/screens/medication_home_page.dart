// Dart core imports
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:table_calendar/table_calendar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Local imports
import '../models/medication_memo.dart';
import '../models/medicine_data.dart';
import '../models/medication_info.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../services/trial_service.dart';
import '../services/in_app_purchase_service.dart';
import '../services/data_repository.dart';
import '../services/data_manager.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import '../widgets/common_widgets.dart';
import '../widgets/trial_widgets.dart';
import '../core/snapshot_service.dart';
import '../utils/locale_helper.dart';

// メインの薬物管理ホームページ
class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});
  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}

class _MedicationHomePageState extends State<MedicationHomePage> with TickerProviderStateMixin {
  // 状態変数
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _selectedDates = <DateTime>{};
  Map<String, String> _calendarMemos = {};
  List<Map<String, dynamic>> _addedMedications = [];
  late TabController _tabController;
  bool _notificationError = false;
  bool _isInitialized = false;
  bool _isAlarmPlaying = false;
  bool _isLoading = false;
  Map<String, Map<String, MedicationInfo>> _medicationData = {};
  Map<String, double> _adherenceRates = {};
  List<MedicineData> _medicines = [];
  List<MedicationMemo> _medicationMemos = [];
  Timer? _debounce;
  Timer? _saveDebounceTimer;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 変更フラグ変数
  bool _medicationMemoStatusChanged = false;
  bool _weekdayMedicationStatusChanged = false;
  bool _addedMedicationsChanged = false;
  
  // アラームタブのキー（強制再構築用）
  Key _alarmTabKey = UniqueKey();
  
  // 統計タブ用のScrollController
  final ScrollController _statsScrollController = ScrollController();
  
  // 任意の日数の遵守率機能用の変数
  double? _customAdherenceResult;
  int? _customDaysResult;
  final TextEditingController _customDaysController = TextEditingController();
  final FocusNode _customDaysFocusNode = FocusNode();
  
  // 手動復元機能のための変数
  DateTime? _lastOperationTime;
  
  // 自動バックアップ機能のための変数
  Timer? _autoBackupTimer;
  bool _autoBackupEnabled = true;
  
  // メモ用の状態変数
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();
  bool _isMemoFocused = false;
  bool _memoSnapshotSaved = false;
  final ValueNotifier<String> _memoTextNotifier = ValueNotifier<String>('');
  final ValueNotifier<Map<String, Color>> _dayColorsNotifier = ValueNotifier<Map<String, Color>>({});
  
  // 曜日設定された薬の服用状況を管理
  Map<String, Map<String, bool>> _weekdayMedicationStatus = {};
  
  // 服用回数別の服用状況を管理
  Map<String, Map<String, Map<int, bool>>> _weekdayMedicationDoseStatus = {};
  
  // 服用メモのチェック状況を管理
  Map<String, bool> _medicationMemoStatus = {};
  
  // メモ選択状態を管理
  bool _isMemoSelected = false;
  MedicationMemo? _selectedMemo;
  
  // アラームデータを管理
  List<Map<String, dynamic>> _alarmList = [];
  Map<String, dynamic> _alarmSettings = {};
  
  // オーバースクロール検出用の状態変数
  bool _isAtTop = false;
  double _lastScrollPosition = 0.0;
  
  // カレンダータブのスクロール制御用
  final ScrollController _calendarScrollController = ScrollController();
  
  // 服用履歴メモ用のScrollController
  final ScrollController _medicationHistoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _saveDebounceTimer?.cancel();
    _subscription?.cancel();
    _autoBackupTimer?.cancel();
    _memoController.dispose();
    _memoFocusNode.dispose();
    _customDaysController.dispose();
    _customDaysFocusNode.dispose();
    _statsScrollController.dispose();
    _calendarScrollController.dispose();
    _medicationHistoryScrollController.dispose();
    _memoTextNotifier.dispose();
    _dayColorsNotifier.dispose();
    InAppPurchaseService.dispose();
    super.dispose();
  }

  // アプリ初期化
  Future<void> _initializeApp() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      if (mounted) setState(() {});
      
      // タブコントローラーの初期化
      _tabController = TabController(length: 4, vsync: this);
      
      // 各種サービスの初期化
      await _initializeServices();
      
      // データの読み込み
      await _loadData();
      
      // 通知の初期化
      _notificationError = !await NotificationService.initialize();
      
      // アプリ内課金の初期化
      await InAppPurchaseService.restorePurchases();
      
      _isInitialized = true;
      _isLoading = false;
      
      if (mounted) setState(() {});
    } catch (e) {
      Logger.error('アプリ初期化エラー', e);
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  // サービスの初期化
  Future<void> _initializeServices() async {
    await MedicationService.initialize();
    await DataRepository.initialize();
    await DataManager.initialize();
    await TrialService.initializeTrial();
  }

  // データの読み込み
  Future<void> _loadData() async {
    try {
      // 各種データの読み込み
      _medicationData = await MedicationService.loadMedicationData();
      _medicines = await MedicationService.loadMedicines();
      _adherenceRates = await MedicationService.loadAdherenceStats();
      
      // メモデータの読み込み
      await _loadMedicationMemos();
      
      // アラームデータの読み込み
      await _loadAlarmData();
      
      // 設定の読み込み
      await _loadSettings();
      
    } catch (e) {
      Logger.error('データ読み込みエラー', e);
    }
  }

  // メモデータの読み込み
  Future<void> _loadMedicationMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memosJson = prefs.getString(AppConstants.medicationMemosKey);
      if (memosJson != null) {
        final List<dynamic> memosList = jsonDecode(memosJson);
        _medicationMemos = memosList.map((json) => MedicationMemo.fromJson(json)).toList();
      }
    } catch (e) {
      Logger.error('メモデータ読み込みエラー', e);
    }
  }

  // アラームデータの読み込み
  Future<void> _loadAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmListJson = prefs.getString('alarm_list');
      if (alarmListJson != null) {
        final List<dynamic> alarmList = jsonDecode(alarmListJson);
        _alarmList = alarmList.cast<Map<String, dynamic>>();
      }
      
      final alarmSettingsJson = prefs.getString('alarm_settings');
      if (alarmSettingsJson != null) {
        _alarmSettings = jsonDecode(alarmSettingsJson);
      }
    } catch (e) {
      Logger.error('アラームデータ読み込みエラー', e);
    }
  }

  // 設定の読み込み
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarMemosJson = prefs.getString(AppConstants.calendarMarksKey);
      if (calendarMemosJson != null) {
        _calendarMemos = Map<String, String>.from(jsonDecode(calendarMemosJson));
      }
      
      final addedMedicationsJson = prefs.getString(AppConstants.addedMedicationsKey);
      if (addedMedicationsJson != null) {
        final List<dynamic> addedMedicationsList = jsonDecode(addedMedicationsJson);
        _addedMedications = addedMedicationsList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      Logger.error('設定読み込みエラー', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('薬物管理アプリ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'カレンダー'),
            Tab(icon: Icon(Icons.medication), text: 'メモ'),
            Tab(icon: Icon(Icons.alarm), text: 'アラーム'),
            Tab(icon: Icon(Icons.bar_chart), text: '統計'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildMemoTab(),
          _buildAlarmTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // カレンダータブの構築
  Widget _buildCalendarTab() {
    return const Center(
      child: Text('カレンダータブ - 実装中'),
    );
  }

  // メモタブの構築
  Widget _buildMemoTab() {
    return const Center(
      child: Text('メモタブ - 実装中'),
    );
  }

  // アラームタブの構築
  Widget _buildAlarmTab() {
    return const Center(
      child: Text('アラームタブ - 実装中'),
    );
  }

  // 統計タブの構築
  Widget _buildStatsTab() {
    return const Center(
      child: Text('統計タブ - 実装中'),
    );
  }
}
