// Dart core imports
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

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
import '../models/medication_info.dart';
import '../models/medicine_data.dart';
import '../models/medication_memo.dart';
import '../models/medicine_data_adapter.dart';
import '../models/medication_memo_adapter.dart';
import '../models/medication_info_adapter.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../services/in_app_purchase_service.dart';
import '../services/trial_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../widgets/trial_widgets.dart';
import '../widgets/tutorial_widgets.dart';

/// メインのホームページ
/// カレンダー、服用メモ、統計、設定のタブを持つメインページ
class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});
  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}
class _MedicationHomePageState extends State<MedicationHomePage> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _selectedDates = <DateTime>{};
  // ✅ カレンダーメモ用の変数
  Map<String, String> _calendarMemos = {};
  // 動的に追加される薬のリスト
  List<Map<String, dynamic>> _addedMedications = [];
  late TabController _tabController;
  bool _notificationError = false;
  bool _isInitialized = false;
  bool _isAlarmPlaying = false;
  bool _isLoading = false; // ✅ 修正：ローディング状態を追加
  Map<String, Map<String, MedicationInfo>> _medicationData = {};
  Map<String, double> _adherenceRates = {};
  List<MedicineData> _medicines = [];
  List<MedicationMemo> _medicationMemos = [];
  Timer? _debounce;
  Timer? _saveDebounceTimer; // ✅ 修正：保存用デバウンスタイマーを追加
  StreamSubscription<List<PurchaseDetails>>? _subscription; // ✅ 修正：StreamSubscriptionを追加
  
  // ✅ 修正：変更フラグ変数を追加
  bool _medicationMemoStatusChanged = false;

  bool _weekdayMedicationStatusChanged = false;
  bool _addedMedicationsChanged = false;
 
  
  // ✅ アラームタブのキー（強制再構築用）
  Key _alarmTabKey = UniqueKey();
  
  // ✅ 統計タブ用のScrollController
  final ScrollController _statsScrollController = ScrollController();
  
  // ✅ 任意の日数の遵守率機能用の変数
  double? _customAdherenceResult;
  int? _customDaysResult;
  final TextEditingController _customDaysController = TextEditingController();
  final FocusNode _customDaysFocusNode = FocusNode();
  
  
  // ✅ 手動復元機能のための変数
  DateTime? _lastOperationTime;
  
  // ✅ 自動バックアップ機能のための変数
  Timer? _autoBackupTimer;
  bool _autoBackupEnabled = true;

  // ✅ 修正：データキーの統一とバージョン管理
  static const String _medicationMemosKey = 'medication_memos_v2';
  static const String _medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String _weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String _addedMedicationsKey = 'added_medications_v2';
  
  // バックアップキー
  static const String _backupSuffix = '_backup';

  
  // メモ用の状態変数
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();
  bool _isMemoFocused = false;
  bool _memoSnapshotSaved = false; // メモ変更時のスナップショット保存フラグ
  // ✅ 部分更新用のValueNotifier
  final ValueNotifier<String> _memoTextNotifier = ValueNotifier<String>('');
  final ValueNotifier<Map<String, Color>> _dayColorsNotifier = ValueNotifier<Map<String, Color>>({});
  
  
  // 曜日設定された薬の服用状況を管理
  Map<String, Map<String, bool>> _weekdayMedicationStatus = {};
  
  // 服用回数別の服用状況を管理（日付 -> メモID -> 回数インデックス -> 服用済み）
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
  
  // 服用記録ページめくり用のコントローラー
  late PageController _medicationPageController;
  int _currentMedicationPage = 0;
  
  // カレンダー下の位置を取得するためのGlobalKey
  final GlobalKey _calendarBottomKey = GlobalKey();
  
  // スクロールバトンタッチ用の変数
  bool _isScrollBatonPassActive = false;
  
  // ログ制御用の変数
  DateTime _lastAlarmCheckLog = DateTime.now();
  
  // カレンダー色変更用の変数
  Map<String, Color> _dayColors = {};
  static const Duration _logInterval = Duration(seconds: 30); // 30秒間隔でログ出力
  
  // ログ出力を制限するヘルパーメソッド
  bool _shouldLog() {
    final now = DateTime.now();
    if (now.difference(_lastAlarmCheckLog).inSeconds >= _logInterval.inSeconds) {
      _lastAlarmCheckLog = now;
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _medicationPageController = PageController();
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _medicationPageController.dispose();
    _debounce?.cancel();
    _saveDebounceTimer?.cancel();
    _subscription?.cancel();
    _autoBackupTimer?.cancel();
    _memoController.dispose();
    _memoFocusNode.dispose();
    _customDaysController.dispose();
    _customDaysFocusNode.dispose();
    _calendarScrollController.dispose();
    _medicationHistoryScrollController.dispose();
    _statsScrollController.dispose();
    _memoTextNotifier.dispose();
    _dayColorsNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    if (_isInitialized) return;
    
    try {
      setState(() => _isLoading = true);
      
      // ロケール初期化
      await _initializeLocale();
      
      // データ読み込み
      await _loadAllData();
      
      // 通知設定
      await _setupNotifications();
      
      // アプリ内課金設定
      await _setupInAppPurchase();
      
      // 自動バックアップ設定
      _setupAutoBackup();
      
      setState(() => _isInitialized = true);
    } catch (e) {
      Logger.error('アプリ初期化エラー', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('ja_JP', null);
    } catch (e) {
      Logger.error('ロケール初期化エラー', e);
    }
  }

  Future<void> _loadAllData() async {
    try {
      await Future.wait([
        _loadMedicationData(),
        _loadMedicines(),
        _loadAdherenceStats(),
        _loadMedicationMemos(),
        _loadAlarms(),
        _loadSettings(),
      ]);
    } catch (e) {
      Logger.error('データ読み込みエラー', e);
    }
  }

  Future<void> _loadMedicationData() async {
    try {
      final data = await MedicationService.loadMedicationData();
      if (mounted) {
        setState(() => _medicationData = data);
      }
    } catch (e) {
      Logger.error('服用データ読み込みエラー', e);
    }
  }

  Future<void> _loadMedicines() async {
    try {
      final medicines = await MedicationService.loadMedicines();
      if (mounted) {
        setState(() => _medicines = medicines);
      }
    } catch (e) {
      Logger.error('薬データ読み込みエラー', e);
    }
  }

  Future<void> _loadAdherenceStats() async {
    try {
      final stats = await MedicationService.loadAdherenceStats();
      if (mounted) {
        setState(() => _adherenceRates = stats);
      }
    } catch (e) {
      Logger.error('遵守率データ読み込みエラー', e);
    }
  }

  Future<void> _loadMedicationMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memosJson = prefs.getString(_medicationMemosKey);
      if (memosJson != null) {
        final List<dynamic> memosList = jsonDecode(memosJson);
        final memos = memosList.map((json) => MedicationMemo.fromJson(json)).toList();
        if (mounted) {
          setState(() => _medicationMemos = memos);
        }
      }
    } catch (e) {
      Logger.error('服用メモ読み込みエラー', e);
    }
  }

  Future<void> _loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString('alarm_list');
      if (alarmsJson != null) {
        final List<dynamic> alarmsList = jsonDecode(alarmsJson);
        if (mounted) {
          setState(() => _alarmList = List<Map<String, dynamic>>.from(alarmsList));
        }
      }
    } catch (e) {
      Logger.error('アラーム読み込みエラー', e);
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await MedicationService.loadSettings();
      if (mounted) {
        setState(() => _alarmSettings = Map<String, dynamic>.from(settings));
      }
    } catch (e) {
      Logger.error('設定読み込みエラー', e);
    }
  }

  Future<void> _setupNotifications() async {
    try {
      final initialized = await NotificationService.initialize();
      if (!initialized) {
        setState(() => _notificationError = true);
      }
    } catch (e) {
      Logger.error('通知設定エラー', e);
      setState(() => _notificationError = true);
    }
  }

  Future<void> _setupInAppPurchase() async {
    try {
      InAppPurchaseService.startPurchaseListener((success, error) {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      Logger.error('アプリ内課金設定エラー', e);
    }
  }

  void _setupAutoBackup() {
    _autoBackupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (_autoBackupEnabled) {
        _saveAllData();
      }
    });
  }

  Future<void> _saveAllData() async {
    try {
      await Future.wait([
        _saveMedicationData(),
        _saveMedicines(),
        _saveAdherenceStats(),
        _saveMedicationMemos(),
        _saveAlarms(),
        _saveSettings(),
      ]);
    } catch (e) {
      Logger.error('データ保存エラー', e);
    }
  }

  Future<void> _saveMedicationData() async {
    try {
      await MedicationService.saveMedicationData(_medicationData);
    } catch (e) {
      Logger.error('服用データ保存エラー', e);
    }
  }

  Future<void> _saveMedicines() async {
    try {
      for (final medicine in _medicines) {
        await MedicationService.saveMedicine(medicine);
      }
    } catch (e) {
      Logger.error('薬データ保存エラー', e);
    }
  }

  Future<void> _saveAdherenceStats() async {
    try {
      await MedicationService.saveAdherenceStats(_adherenceRates);
    } catch (e) {
      Logger.error('遵守率データ保存エラー', e);
    }
  }

  Future<void> _saveMedicationMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memosJson = jsonEncode(_medicationMemos.map((memo) => memo.toJson()).toList());
      await prefs.setString(_medicationMemosKey, memosJson);
    } catch (e) {
      Logger.error('服用メモ保存エラー', e);
    }
  }

  Future<void> _saveAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = jsonEncode(_alarmList);
      await prefs.setString('alarm_list', alarmsJson);
    } catch (e) {
      Logger.error('アラーム保存エラー', e);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await MedicationService.saveSettings(_alarmSettings);
    } catch (e) {
      Logger.error('設定保存エラー', e);
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
        title: const Text('服薬管理アプリ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'カレンダー'),
            Tab(icon: Icon(Icons.medication), text: '服用メモ'),
            Tab(icon: Icon(Icons.alarm), text: 'アラーム'),
            Tab(icon: Icon(Icons.analytics), text: '統計'),
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

  Widget _buildCalendarTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TableCalendar<dynamic>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              final dateStr = DateFormat('yyyy-MM-dd').format(day);
              return _medicationData[dateStr]?.keys.toList() ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null) _buildSelectedDayInfo(),
        ],
      ),
    );
  }

  Widget _buildSelectedDayInfo() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final dayData = _medicationData[dateStr];
    
    if (dayData == null || dayData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('この日は服用記録がありません'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('M月d日').format(_selectedDay!)}の服用記録',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...dayData.entries.map((entry) => ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value.medicine),
              trailing: Checkbox(
                value: entry.value.checked,
                onChanged: (value) {
                  setState(() {
                    _medicationData[dateStr]![entry.key] = MedicationInfo(
                      checked: value ?? false,
                      medicine: entry.value.medicine,
                      actualTime: value == true ? DateTime.now() : null,
                      notes: entry.value.notes,
                      sideEffects: entry.value.sideEffects,
                    );
                  });
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _showAddMedicineDialog,
            child: const Text('薬を追加'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _medicines.length,
              itemBuilder: (context, index) {
                final medicine = _medicines[index];
                return Card(
                  child: ListTile(
                    title: Text(medicine.name),
                    subtitle: Text(medicine.dosage),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteMedicine(medicine),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _addAlarm,
            child: const Text('アラームを追加'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _alarmList.length,
              itemBuilder: (context, index) {
                final alarm = _alarmList[index];
                return Card(
                  child: ListTile(
                    title: Text(alarm['name'] ?? 'アラーム'),
                    subtitle: Text(alarm['time'] ?? ''),
                    trailing: Switch(
                      value: alarm['enabled'] ?? false,
                      onChanged: (value) {
                        setState(() {
                          alarm['enabled'] = value;
                        });
                        _saveAlarms();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '服用遵守率',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (_adherenceRates.isNotEmpty)
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: _adherenceRates.entries.map((entry) {
                    return PieChartSectionData(
                      color: entry.key == 'adherent' ? Colors.green : Colors.red,
                      value: entry.value,
                      title: '${entry.key}: ${entry.value.toStringAsFixed(1)}%',
                    );
                  }).toList(),
                ),
              ),
            )
          else
            const Text('データがありません'),
        ],
      ),
    );
  }

  void _showAddMedicineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('薬を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: '薬の名前'),
              onChanged: (value) {
                // 薬の名前を保存
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: '用量'),
              onChanged: (value) {
                // 用量を保存
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 薬を追加する処理
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _deleteMedicine(MedicineData medicine) {
    setState(() {
      _medicines.remove(medicine);
    });
    _saveMedicines();
  }

  void _addAlarm() {
    setState(() {
      _alarmList.add({
        'name': '新しいアラーム',
        'time': '09:00',
        'enabled': true,
      });
    });
    _saveAlarms();
  }
}