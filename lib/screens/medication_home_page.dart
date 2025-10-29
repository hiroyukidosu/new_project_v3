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
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import '../utils/constants.dart';
import '../models/medication_memo.dart';
import '../models/medicine_data.dart';
import '../models/medication_info.dart';
import '../services/data_repository.dart';
import '../services/data_manager.dart';
import '../widgets/common_widgets.dart';
import '../widgets/trial_widgets.dart';
import '../widgets/memo_dialog.dart';

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
  
  // ✅ パフォーマンス最適化のための変数
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _pageSize = 20; // 1ページあたりの件数
  
  // ✅ メモリ管理のための変数
  static Box<MedicationMemo>? _memoBox;
  
  // ✅ メモボックスの取得
  static Future<Box<MedicationMemo>> get _getMemoBox async {
    _memoBox ??= await Hive.openBox<MedicationMemo>('medication_memos');
    return _memoBox!;
  }
  
  // ✅ メモの取得（ページネーション対応）
  static Future<List<MedicationMemo>> getMemos({
    int page = 0,
    int pageSize = _pageSize,
  }) async {
    final box = await _getMemoBox;
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, box.length);
    
    final memos = <MedicationMemo>[];
    for (int i = startIndex; i < endIndex; i++) {
      memos.add(box.getAt(i)!);
    }
    return memos;
  }
  
  // ✅ メモの検索
  static Future<List<MedicationMemo>> searchMemos(String keyword) async {
    final box = await _getMemoBox;
    return box.values.where((memo) => 
      memo.name.toLowerCase().contains(keyword.toLowerCase()) ||
      memo.notes.toLowerCase().contains(keyword.toLowerCase())
    ).toList();
  }
  
  // ✅ メモの保存
  static Future<void> saveMemo(MedicationMemo memo) async {
    final box = await _getMemoBox;
    await box.put(memo.id, memo);
  }
  
  // ✅ メモの削除
  static Future<void> deleteMemo(String id) async {
    final box = await _getMemoBox;
    await box.delete(id);
  }
  
  // ✅ メモの監視
  static Stream<List<MedicationMemo>> watchMemos() async* {
    final box = await _getMemoBox;
    yield box.values.toList();
  }
  
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
    _customDaysController.dispose();
    _customDaysFocusNode.dispose();
    _statsScrollController.dispose();
    _autoBackupTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _initializeApp() async {
    try {
      // アプリ初期化処理
      await _loadData();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      AppErrorHandler.handleError(e, null, context: 'アプリ初期化');
    }
  }
  
  Future<void> _loadData() async {
    // データ読み込み処理
    Logger.info('データ読み込み開始');
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('服用アラーム'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'カレンダー'),
            Tab(icon: Icon(Icons.medication), text: '服用メモ'),
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
  
  Widget _buildCalendarTab() {
    return const Center(
      child: Text('カレンダータブ'),
    );
  }
  
  Widget _buildMedicineTab() {
    return const Center(
      child: Text('服用メモタブ'),
    );
  }
  
  Widget _buildAlarmTab() {
    return const Center(
      child: Text('アラームタブ'),
    );
  }
  
  Widget _buildStatsTab() {
    return const Center(
      child: Text('統計タブ'),
    );
  }
}