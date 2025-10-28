import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'dart:convert';

// Local imports
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import '../models/medication_memo.dart';
import '../models/medicine_data.dart';
import '../models/medication_info.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../services/trial_service.dart';
import '../services/in_app_purchase_service.dart';
import '../services/data_repository.dart';
import '../services/data_manager.dart';
import '../widgets/common_widgets.dart';
import '../widgets/trial_widgets.dart';
import '../widgets/calendar/calendar_tab.dart';

class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});

  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}

class _MedicationHomePageState extends State<MedicationHomePage> with TickerProviderStateMixin {
  // カレンダー関連の状態
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _selectedDates = <DateTime>{};
  Map<String, String> _calendarMemos = {};
  
  // 薬物管理関連の状態
  List<Map<String, dynamic>> _addedMedications = [];
  Map<String, Map<String, MedicationInfo>> _medicationData = {};
  Map<String, double> _adherenceRates = {};
  List<MedicineData> _medicines = [];
  List<MedicationMemo> _medicationMemos = [];
  
  // UI制御関連の状態
  late TabController _tabController;
  bool _notificationError = false;
  bool _isInitialized = false;
  bool _isAlarmPlaying = false;
  bool _isLoading = false;
  
  // タイマーとサブスクリプション
  Timer? _debounce;
  Timer? _saveDebounceTimer;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 変更フラグ
  bool _medicationMemoStatusChanged = false;
  bool _weekdayMedicationStatusChanged = false;
  bool _addedMedicationsChanged = false;
  
  // タブキーとスクロールコントローラー
  Key _alarmTabKey = UniqueKey();
  final ScrollController _statsScrollController = ScrollController();
  final ScrollController _calendarScrollController = ScrollController();
  final ScrollController _medicationHistoryScrollController = ScrollController();
  
  // カスタム遵守率機能
  double? _customAdherenceResult;
  int? _customDaysResult;
  final TextEditingController _customDaysController = TextEditingController();
  final FocusNode _customDaysFocusNode = FocusNode();
  
  // バックアップ機能
  DateTime? _lastOperationTime;
  Timer? _autoBackupTimer;
  bool _autoBackupEnabled = true;
  
  // メモ関連の状態
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();
  bool _isMemoFocused = false;
  bool _memoSnapshotSaved = false;
  final ValueNotifier<String> _memoTextNotifier = ValueNotifier<String>('');
  final ValueNotifier<Map<String, Color>> _dayColorsNotifier = ValueNotifier<Map<String, Color>>({});
  
  // 服用状況管理
  Map<String, Map<String, bool>> _weekdayMedicationStatus = {};
  Map<String, Map<String, Map<int, bool>>> _weekdayMedicationDoseStatus = {};
  Map<String, bool> _medicationMemoStatus = {};
  
  // メモ選択状態
  bool _isMemoSelected = false;
  MedicationMemo? _selectedMemo;
  
  // アラーム関連
  List<Map<String, dynamic>> _alarmList = [];
  Map<String, dynamic> _alarmSettings = {};
  
  // スクロール制御
  bool _isAtTop = false;
  double _lastScrollPosition = 0.0;
  
  // データキー定数
  static const String _medicationMemosKey = 'medication_memos_v2';
  static const String _medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String _weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String _addedMedicationsKey = 'added_medications_v2';
  static const String _backupSuffix = '_backup';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    super.dispose();
  }

  // アプリ初期化
  Future<void> _initializeApp() async {
    try {
      setState(() => _isLoading = true);
      
      // 各種データの読み込み
      await _loadMedicationMemos();
      await _loadMedicationData();
      await _loadWeekdayMedicationStatus();
      await _loadAddedMedications();
      await _loadCalendarMemos();
      
      // 通知の初期化
      await _initializeNotifications();
      
      // アプリ内課金の初期化
      await _initializeInAppPurchase();
      
      // 自動バックアップの開始
      _startAutoBackup();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      Logger.info('MedicationHomePage初期化完了');
    } catch (e) {
      Logger.error('MedicationHomePage初期化エラー', e);
      AppErrorHandler.handleError(e, null, context: 'MedicationHomePage._initializeApp');
      setState(() => _isLoading = false);
    }
  }

  // 各種データ読み込みメソッド（簡略化）
  Future<void> _loadMedicationMemos() async {
    // TODO: 実装
  }

  Future<void> _loadMedicationData() async {
    // TODO: 実装
  }

  Future<void> _loadWeekdayMedicationStatus() async {
    // TODO: 実装
  }

  Future<void> _loadAddedMedications() async {
    // TODO: 実装
  }

  Future<void> _loadCalendarMemos() async {
    // TODO: 実装
  }

  Future<void> _initializeNotifications() async {
    // TODO: 実装
  }

  Future<void> _initializeInAppPurchase() async {
    // TODO: 実装
  }

  void _startAutoBackup() {
    // TODO: 実装
  }

  // コールバックメソッド
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedDates.add(_normalizeDate(selectedDay));
    });
  }

  void _onFocusedDayChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  void _onMemoChanged(String value) {
    _memoTextNotifier.value = value;
  }

  void _onMemoSaved() {
    // TODO: メモ保存の実装
  }

  void _onMemoTapped(MedicationMemo memo) {
    setState(() {
      _isMemoSelected = true;
      _selectedMemo = memo;
    });
  }

  void _onMedicationToggled(Map<String, dynamic> medication) {
    // TODO: 薬物のトグル実装
  }

  void _onDoseToggled(String memoId, int doseIndex) {
    // TODO: 服用回数のトグル実装
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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
          _buildMedicineTab(),
          _buildAlarmTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // 各タブのビルドメソッド
  Widget _buildCalendarTab() {
    return CalendarTab(
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      selectedDates: _selectedDates,
      calendarMemos: _calendarMemos,
      addedMedications: _addedMedications,
      medicationData: _medicationData,
      medicationMemos: _medicationMemos,
      weekdayMedicationStatus: _weekdayMedicationStatus,
      weekdayMedicationDoseStatus: _weekdayMedicationDoseStatus,
      medicationMemoStatus: _medicationMemoStatus,
      memoTextNotifier: _memoTextNotifier,
      dayColorsNotifier: _dayColorsNotifier,
      calendarScrollController: _calendarScrollController,
      onDaySelected: _onDaySelected,
      onFocusedDayChanged: _onFocusedDayChanged,
      onMemoChanged: _onMemoChanged,
      onMemoSaved: _onMemoSaved,
      onMemoTapped: _onMemoTapped,
      onMedicationToggled: _onMedicationToggled,
      onDoseToggled: _onDoseToggled,
    );
  }

  Widget _buildMedicineTab() {
    return const Center(
      child: Text('メモタブ - 実装中'),
    );
  }

  Widget _buildAlarmTab() {
    return const Center(
      child: Text('アラームタブ - 実装中'),
    );
  }

  Widget _buildStatsTab() {
    return const Center(
      child: Text('統計タブ - 実装中'),
    );
  }
}