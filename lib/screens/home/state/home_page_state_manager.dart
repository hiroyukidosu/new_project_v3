// lib/screens/home/state/home_page_state_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medicine_data.dart';
import '../../../models/medication_info.dart';
import '../persistence/medication_data_persistence.dart';
import '../persistence/alarm_data_persistence.dart';
import '../persistence/snapshot_persistence.dart';
import '../persistence/data_sync_manager.dart';
import '../handlers/calendar_event_handler.dart';
import '../handlers/medication_event_handler.dart';
import '../handlers/memo_event_handler.dart';
import '../handlers/backup_handler.dart';
import '../business/pagination_manager.dart';
import 'home_page_state_notifiers.dart';
import '../../helpers/home_page_data_helper.dart';
import '../../helpers/home_page_alarm_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ホームページの状態を集中管理するクラス
class HomePageStateManager {
  final BuildContext context;

  // ValueNotifier群（状態管理）
  final HomePageStateNotifiers notifiers = HomePageStateNotifiers();

  // 基本状態
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  final Set<DateTime> selectedDates = <DateTime>{};
  bool isInitialized = false;
  bool isLoading = false;
  bool notificationError = false;
  bool isAlarmPlaying = false;

  // データ状態
  List<MedicationMemo> medicationMemos = [];
  List<Map<String, dynamic>> addedMedications = [];
  List<MedicineData> medicines = [];
  Map<String, Map<String, MedicationInfo>> medicationData = {};
  Map<String, double> adherenceRates = {};
  
  // アラームデータ
  List<Map<String, dynamic>> alarmList = [];
  Map<String, dynamic> alarmSettings = {};

  // 服用状況管理
  Map<String, bool> medicationMemoStatus = {};
  Map<String, Map<String, bool>> weekdayMedicationStatus = {};
  Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus = {};

  // カレンダー状態
  Map<String, Color> dayColors = {};

  // メモ選択状態
  bool isMemoSelected = false;
  MedicationMemo? selectedMemo;
  bool isMemoFocused = false;
  bool memoSnapshotSaved = false;

  // メモコントローラー
  final TextEditingController memoController = TextEditingController();
  final FocusNode memoFocusNode = FocusNode();

  // 統計タブ用
  double? customAdherenceResult;
  int? customDaysResult;
  final TextEditingController customDaysController = TextEditingController();
  final FocusNode customDaysFocusNode = FocusNode();

  // ScrollController
  final ScrollController calendarScrollController = ScrollController();
  final ScrollController statsScrollController = ScrollController();
  final ScrollController medicationHistoryScrollController = ScrollController();

  // ページコントローラー
  late PageController medicationPageController;
  int currentMedicationPage = 0;

  // その他の状態
  Key alarmTabKey = UniqueKey();
  bool medicationMemoStatusChanged = false;
  bool weekdayMedicationStatusChanged = false;
  bool addedMedicationsChanged = false;
  bool isAtTop = false;
  double lastScrollPosition = 0.0;
  bool isScrollBatonPassActive = false;
  DateTime? lastOperationTime;
  DateTime lastAlarmCheckLog = DateTime.now();
  Timer? debounce;
  Timer? saveDebounceTimer;

  // サービス・ハンドラー（依存性注入）
  late MedicationDataPersistence medicationDataPersistence;
  late AlarmDataPersistence alarmDataPersistence;
  late CalendarEventHandler calendarEventHandler;
  late MedicationEventHandler medicationEventHandler;
  late MemoEventHandler memoEventHandler;
  late PaginationManager paginationManager;
  late SnapshotPersistence snapshotPersistence;
  late DataSyncManager dataSyncManager;
  late BackupHandler backupHandler;

  HomePageStateManager(this.context);

  /// 初期化処理
  Future<void> init() async {
    // サービス・ハンドラーの初期化
    medicationDataPersistence = MedicationDataPersistence();
    alarmDataPersistence = AlarmDataPersistence();
    notifiers.memoTextNotifier.value = '';
    notifiers.dayColorsNotifier.value = {};
    paginationManager = PaginationManager();
    snapshotPersistence = SnapshotPersistence();
    dataSyncManager = DataSyncManager(
      medicationPersistence: medicationDataPersistence,
      alarmPersistence: alarmDataPersistence,
    );

    // イベントハンドラーの初期化
    calendarEventHandler = CalendarEventHandler(
      persistence: medicationDataPersistence,
      onStateUpdate: (day) => selectedDay = day,
      onDayColorUpdate: (key, color) => dayColors[key] = color,
    );

    medicationEventHandler = MedicationEventHandler(
      persistence: medicationDataPersistence,
      onStatusUpdate: (memoId, isChecked) => medicationMemoStatus[memoId] = isChecked,
      onDoseStatusUpdate: (memoId, doseIndex, isChecked) {
        if (selectedDay != null) {
          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
          weekdayMedicationDoseStatus.putIfAbsent(dateStr, () => {});
          weekdayMedicationDoseStatus[dateStr]!.putIfAbsent(memoId, () => {});
          weekdayMedicationDoseStatus[dateStr]![memoId]![doseIndex] = isChecked;
        }
      },
    );

    memoEventHandler = MemoEventHandler(
      persistence: medicationDataPersistence,
      paginationManager: paginationManager,
      onMemoAdded: (memo) {
        medicationMemos.add(memo);
        paginationManager.setAllMemos(medicationMemos);
      },
      onMemoUpdated: (memo) {
        final index = medicationMemos.indexWhere((m) => m.id == memo.id);
        if (index != -1) {
          medicationMemos[index] = memo;
        }
        paginationManager.setAllMemos(medicationMemos);
      },
      onMemoDeleted: (memoId) {
        medicationMemos.removeWhere((memo) => memo.id == memoId);
        paginationManager.setAllMemos(medicationMemos);
        medicationMemoStatus.remove(memoId);
        weekdayMedicationStatus.remove(memoId);
        for (final dateStr in weekdayMedicationDoseStatus.keys) {
          weekdayMedicationDoseStatus[dateStr]?.remove(memoId);
        }
      },
      onShowSnackBar: (message) {
        // SnackBar表示は呼び出し側で実装
      },
      onSaveSnapshotBeforeChange: (operationType) async {
        await snapshotPersistence.saveSnapshotBeforeChange(
          operationType,
          () => _createSafeBackupData('変更前_$operationType'),
        );
      },
      saveMedicationMemo: (memo) async {
        await medicationDataPersistence.saveMedicationMemo(memo);
      },
    );

    backupHandler = BackupHandler(
      onDataRestored: (data) async {
        // データ復元処理は呼び出し側で実装
      },
      onShowSnackBar: (message) {
        // SnackBar表示は呼び出し側で実装
      },
      onMountedCheck: () => true,
      createBackupData: (String label) async => _createSafeBackupData(label),
    );

    // PageControllerを初期化
    medicationPageController = PageController(viewportFraction: 1.0);

    // 初期値設定
    if (selectedDay == null) {
      selectedDay = DateTime.now();
    }
    notifiers.selectedDayNotifier.value = selectedDay;
    notifiers.focusedDayNotifier.value = focusedDay;

    // データ読み込み（非同期）
    await _loadSavedData();
    await _loadMedicationMemosWithRetry();
    paginationManager.setAllMemos(medicationMemos);

    if (selectedDates.isEmpty) {
      selectedDates.add(_normalizeDate(DateTime.now()));
    }

    isInitialized = true;
  }

  /// データ読み込み
  Future<void> _loadSavedData() async {
    try {
      await _loadAllData();
    } catch (e, stackTrace) {
      debugPrint('データ読み込みエラー: $e');
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('データ読み込みエラー: _loadSavedData');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
    }
  }

  /// 全データ読み込み
  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await _loadMemoStatus();
      await _loadMedicationList();
      await _loadAlarmData();
      await _loadCalendarMarks();
      await _loadUserPreferences();
      await _loadMedicationData();
      await _loadDayColors();
      await _loadStatistics();
      await _loadWeekdayMedicationStatus();
      await _loadMedicationDoseStatus();
      await _loadAppSettings();
      
      debugPrint('全データ読み込み完了');
    } catch (e, stackTrace) {
      debugPrint('全データ読み込みエラー: $e');
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('全データ読み込みエラー: _loadAllData');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
    }
  }

  /// メモ状態読み込み
  Future<void> _loadMemoStatus() async {
    medicationMemoStatus = await medicationDataPersistence.loadMedicationMemoStatus();
  }

  /// 薬リスト読み込み
  Future<void> _loadMedicationList() async {
    addedMedications.clear();
    addedMedications.addAll(await HomePageDataHelper.loadMedicationList());
  }

  /// アラームデータ読み込み
  Future<void> _loadAlarmData() async {
    alarmList = await HomePageAlarmHelper.loadAlarmData();
  }

  /// カレンダーマーク読み込み
  Future<void> _loadCalendarMarks() async {
    selectedDates.clear();
    selectedDates.addAll(await HomePageDataHelper.loadCalendarMarks(_normalizeDate));
  }

  /// ユーザー設定読み込み
  Future<void> _loadUserPreferences() async {
    final prefs = await HomePageDataHelper.loadUserPreferences();
    final selectedDayStr = prefs['selectedDay'];
    if (selectedDayStr != null && selectedDayStr is String) {
      selectedDay = DateTime.parse(selectedDayStr);
      notifiers.selectedDayNotifier.value = selectedDay;
    }
    final isMemoSelectedValue = prefs['isMemoSelected'];
    final isAlarmPlayingValue = prefs['isAlarmPlaying'];
    isMemoSelected = isMemoSelectedValue is bool ? isMemoSelectedValue : (isMemoSelectedValue == true);
    isAlarmPlaying = isAlarmPlayingValue is bool ? isAlarmPlayingValue : (isAlarmPlayingValue == true);
  }

  /// 服用データ読み込み
  Future<void> _loadMedicationData() async {
    // 実装は簡略化（実際はDataSyncManagerを使用）
    medicationData = {};
  }

  /// 日別色設定読み込み
  Future<void> _loadDayColors() async {
    dayColors = await HomePageDataHelper.loadDayColors();
    notifiers.dayColorsNotifier.value = Map<String, Color>.from(dayColors);
  }

  /// 統計データ読み込み
  Future<void> _loadStatistics() async {
    adherenceRates = await HomePageDataHelper.loadStatistics();
    notifiers.adherenceRatesNotifier.value = Map<String, double>.from(adherenceRates);
  }

  /// 曜日別服用状態読み込み
  Future<void> _loadWeekdayMedicationStatus() async {
    try {
      // 月別キー形式から日付文字列キー形式に変換
      final monthlyData = await medicationDataPersistence.loadWeekdayMedicationStatus();
      weekdayMedicationStatus = {};
      
      // 月別データを日付文字列キー形式に変換
      // monthlyData: Map<月別キー, Map<日付文字列, Map<メモID, bool>>>
      for (final monthlyEntry in monthlyData.entries) {
        // monthlyEntry.key は "weekday_status_YYYY-MM" 形式（月別キー）
        // monthlyEntry.value は Map<日付文字列, Map<メモID, bool>>
        final weekdaysData = monthlyEntry.value;
        
        for (final dateEntry in weekdaysData.entries) {
          final dateStr = dateEntry.key;
          final memoStatusMap = dateEntry.value; // Map<メモID, bool>
          
          weekdayMedicationStatus.putIfAbsent(dateStr, () => {});
          weekdayMedicationStatus[dateStr]!.addAll(memoStatusMap);
        }
      }
      
      debugPrint('✅ 曜日別服用状態読み込み完了: ${weekdayMedicationStatus.length}件の日付データ');
    } catch (e, stackTrace) {
      debugPrint('❌ 曜日別服用状態読み込みエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      weekdayMedicationStatus = {};
    }
  }

  /// 服用回数別状態読み込み
  Future<void> _loadMedicationDoseStatus() async {
    weekdayMedicationDoseStatus = await medicationDataPersistence.loadMedicationDoseStatus() ?? {};
  }

  /// アプリ設定読み込み
  Future<void> _loadAppSettings() async {
    // 実装は簡略化
  }

  /// 服用メモ読み込み（リトライ付き）
  Future<void> _loadMedicationMemosWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 服用メモ読み込み試行 $attempt/$maxRetries');
        
        medicationMemos = await medicationDataPersistence.loadMedicationMemos();
        
        if (medicationMemos.isNotEmpty || attempt == maxRetries) {
          debugPrint('✅ 服用メモ読み込み成功: ${medicationMemos.length}件（試行$attempt回目）');
          return;
        }
        
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      } catch (e) {
        debugPrint('❌ 服用メモ読み込みエラー（試行$attempt回目）: $e');
        if (attempt == maxRetries) {
          debugPrint('❌ 最大試行回数に達しました');
        } else {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
  }

  /// 全データ保存
  Future<void> saveAllData() async {
    try {
      await dataSyncManager.saveAllData(
        medicationMemos: medicationMemos,
        medicationMemoStatus: medicationMemoStatus,
        weekdayMedicationStatus: weekdayMedicationStatus,
        weekdayMedicationDoseStatus: weekdayMedicationDoseStatus,
        addedMedications: addedMedications,
        alarmList: alarmList,
        dayColors: dayColors,
        selectedDay: selectedDay,
        memoText: memoController.text,
        adherenceRates: adherenceRates,
      );
    } catch (e) {
      debugPrint('データ保存エラー: $e');
    }
  }

  /// 日付正規化
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// バックアップデータ作成
  Future<Map<String, dynamic>> _createSafeBackupData(String label) async {
    try {
      return {
        'medicationMemos': medicationMemos.map((m) => m.toJson()).toList(),
        'medicationMemoStatus': medicationMemoStatus,
        'weekdayMedicationStatus': weekdayMedicationStatus,
        'weekdayMedicationDoseStatus': weekdayMedicationDoseStatus,
        'addedMedications': addedMedications,
        'dayColors': dayColors.map((k, v) => MapEntry(k, v.value)), // Colorをint値に変換
        'adherenceRates': adherenceRates,
        'label': label,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('バックアップデータ作成エラー: $e');
      // エラー時はdayColorsを除外して保存
      return {
        'medicationMemos': medicationMemos.map((m) => m.toJson()).toList(),
        'medicationMemoStatus': medicationMemoStatus,
        'weekdayMedicationStatus': weekdayMedicationStatus,
        'weekdayMedicationDoseStatus': weekdayMedicationDoseStatus,
        'addedMedications': addedMedications,
        'adherenceRates': adherenceRates,
        'label': label,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// メモ追加
  void addMemo(BuildContext context) {
    // TODO: MemoDialogを表示する処理を実装
    // 現在は呼び出し側で実装（後で完全移行）
  }

  /// 破棄処理
  void dispose() {
    debounce?.cancel();
    saveDebounceTimer?.cancel();
    memoController.dispose();
    memoFocusNode.dispose();
    customDaysController.dispose();
    customDaysFocusNode.dispose();
    calendarScrollController.dispose();
    statsScrollController.dispose();
    medicationHistoryScrollController.dispose();
    medicationPageController.dispose();
    notifiers.dispose();
  }
}

