// lib/screens/home/state/home_page_state_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medicine_data.dart';
import '../../../models/medication_info.dart';
import '../../../services/daily_memo_service.dart';
import '../../../utils/logger.dart';
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
import '../../helpers/calculations/adherence_calculator.dart';
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
      onStatusUpdate: (memoId, isChecked) {
        medicationMemoStatus[memoId] = isChecked;
        // 状態変更後に自動保存（デバウンス付き）
        _debouncedSave();
      },
      onDoseStatusUpdate: (memoId, doseIndex, isChecked) {
        if (selectedDay != null) {
          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
          weekdayMedicationDoseStatus.putIfAbsent(dateStr, () => {});
          weekdayMedicationDoseStatus[dateStr]!.putIfAbsent(memoId, () => {});
          weekdayMedicationDoseStatus[dateStr]![memoId]![doseIndex] = isChecked;
          // 状態変更後に自動保存（デバウンス付き）
          _debouncedSave();
        }
      },
    );

    memoEventHandler = MemoEventHandler(
      persistence: medicationDataPersistence,
      paginationManager: paginationManager,
      onMemoAdded: (memo) {
        medicationMemos.add(memo);
        paginationManager.setAllMemos(medicationMemos);
        // Notifierを更新して画面に通知（リストの長さを変更して通知）
        notifiers.medicationMemosNotifier.value = medicationMemos.length;
      },
      onMemoUpdated: (memo) {
        final index = medicationMemos.indexWhere((m) => m.id == memo.id);
        if (index != -1) {
          medicationMemos[index] = memo;
        }
        paginationManager.setAllMemos(medicationMemos);
        // Notifierを更新して画面に通知（リストの長さを変更して通知）
        notifiers.medicationMemosNotifier.value = medicationMemos.length;
      },
      onMemoDeleted: (memoId) {
        medicationMemos.removeWhere((memo) => memo.id == memoId);
        paginationManager.setAllMemos(medicationMemos);
        medicationMemoStatus.remove(memoId);
        weekdayMedicationStatus.remove(memoId);
        for (final dateStr in weekdayMedicationDoseStatus.keys) {
          weekdayMedicationDoseStatus[dateStr]?.remove(memoId);
        }
        // Notifierを更新して画面に通知（リストの長さを変更して通知）
        notifiers.medicationMemosNotifier.value = medicationMemos.length;
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

    // データ読み込み（非同期、メインスレッドをブロックしない）
    // クリティカルなデータのみ先に読み込み
    await _loadSavedData();
    
    // メモ読み込みはバックグラウンドで実行（UIをブロックしない）
    Future.microtask(() async {
      try {
        await _loadMedicationMemosWithRetry();
        paginationManager.setAllMemos(medicationMemos);
      } catch (e) {
        debugPrint('❌ メモ読み込みエラー（バックグラウンド）: $e');
      }
    });

    if (selectedDates.isEmpty) {
      selectedDates.add(_normalizeDate(DateTime.now()));
    }

    isInitialized = true;
    
    // 初期化完了を通知（データ保存を有効化）
    DataSyncManager.completeInitialization();
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

  /// 全データ読み込み（フレーム分散対応）
  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // クリティカルなデータのみ先に読み込み（UI表示に必要）
      await Future.wait([
        _loadMemoStatus(),
        _loadMedicationList(),
        _loadAlarmData(),
        _loadCalendarMarks(),
        _loadUserPreferences(),
      ], eagerError: false);
      
      // 非クリティカルなデータはバックグラウンドで読み込み
      Future.microtask(() async {
        try {
          await Future.wait([
            _loadMedicationData(),
            _loadDayColors(),
            _loadStatistics(),
            _loadWeekdayMedicationStatus(),
            _loadMedicationDoseStatus(),
            _loadAppSettings(),
          ], eagerError: false);
          
          // 選択日のメモを読み込む
          await _loadSelectedDayMemo();
          
          debugPrint('全データ読み込み完了');
        } catch (e) {
          debugPrint('非クリティカルデータ読み込みエラー: $e');
        }
      });
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
    try {
      final loadedStatus = await medicationDataPersistence.loadMedicationDoseStatus();
      weekdayMedicationDoseStatus = loadedStatus ?? {};
      debugPrint('✅ 服用回数別状態読み込み完了: ${weekdayMedicationDoseStatus.length}件の日付データ');
    } catch (e, stackTrace) {
      debugPrint('❌ 服用回数別状態読み込みエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      weekdayMedicationDoseStatus = {};
    }
  }

  /// アプリ設定読み込み
  Future<void> _loadAppSettings() async {
    // 実装は簡略化
  }

  /// 選択日のメモ読み込み（日付ベース）
  Future<void> _loadSelectedDayMemo() async {
    try {
      if (selectedDay != null) {
        // 日付ベースでメモを読み込む（yyyy-MM-dd形式）
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
        final savedMemo = await DailyMemoService.getMemo(dateStr);
        if (savedMemo.isNotEmpty) {
          memoController.text = savedMemo;
          notifiers.memoTextNotifier.value = savedMemo;
        } else {
          memoController.clear();
          notifiers.memoTextNotifier.value = '';
        }
      }
    } catch (e) {
      debugPrint('❌ 選択日メモ読み込みエラー: $e');
    }
  }

  /// 服用メモ読み込み（リトライ付き、アーカイブ処理も含む）
  Future<void> _loadMedicationMemosWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 服用メモ読み込み試行 $attempt/$maxRetries');
        
        medicationMemos = await medicationDataPersistence.loadMedicationMemos();
        paginationManager.setAllMemos(medicationMemos);
        // Notifierを更新して画面に通知（リストの長さを変更して通知）
        notifiers.medicationMemosNotifier.value = medicationMemos.length;
        
        // 初回読み込み時に古いメモをアーカイブ（バックグラウンドで実行）
        if (attempt == 1) {
          Future.microtask(() async {
            try {
              final archivedCount = await medicationDataPersistence.archiveOldMemos(keepYears: 2);
              if (archivedCount > 0) {
                debugPrint('✅ 古いメモをアーカイブ: ${archivedCount}件（バックグラウンド）');
                // アーカイブ後、メモリストを再読み込み
                medicationMemos = await medicationDataPersistence.loadMedicationMemos();
                paginationManager.setAllMemos(medicationMemos);
                // Notifierを更新して画面に通知（リストの長さを変更して通知）
                notifiers.medicationMemosNotifier.value = medicationMemos.length;
              }
            } catch (e) {
              debugPrint('⚠️ アーカイブ処理エラー: $e');
            }
          });
        }
        
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

  /// デバウンス付き保存（服用状況変更時の自動保存用）
  void _debouncedSave() {
    saveDebounceTimer?.cancel();
    saveDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final stopwatch = Stopwatch()..start();
      // まずデータを保存
      await saveAllData();
      // 服用状況変更後に遵守率を再計算（最新の状態を反映）
      // 注意: saveAllData()の後に呼ぶことで、最新のweekdayMedicationDoseStatusが反映される
      await updateAdherenceRates();
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('✅ デバウンス保存完了: 遵守率も更新済み (処理時間: ${stopwatch.elapsedMilliseconds}ms)');
      }
    });
  }

  /// 遵守率を更新（服用状況変更時に呼ばれる）
  Future<void> updateAdherenceRates() async {
    try {
      final stats = <String, double>{};
      // 最新の状態を取得（参照ではなく、現在の値を取得）
      final medicationData = Map<String, Map<String, MedicationInfo>>.from(this.medicationData);
      final medicationMemos = List<MedicationMemo>.from(this.medicationMemos);
      final weekdayStatus = Map<String, Map<String, bool>>.from(this.weekdayMedicationStatus);
      final memoStatus = Map<String, bool>.from(this.medicationMemoStatus);
      // 重要: weekdayMedicationDoseStatusは深いコピーを作成（最新の状態を確実に取得）
      final doseStatus = <String, Map<String, Map<int, bool>>>{};
      for (final dateEntry in this.weekdayMedicationDoseStatus.entries) {
        final dateMap = <String, Map<int, bool>>{};
        for (final memoEntry in dateEntry.value.entries) {
          dateMap[memoEntry.key] = Map<int, bool>.from(memoEntry.value);
        }
        doseStatus[dateEntry.key] = dateMap;
      }

      if (kDebugMode) {
        debugPrint('🔄 遵守率再計算開始: 服用回数別ステータス=${doseStatus.length}件の日付');
        // デバッグ: 服用回数別ステータスの内容を確認（最大5件）
        for (final dateEntry in doseStatus.entries.take(5)) {
          debugPrint('  📅 日付: ${dateEntry.key}, メモ数: ${dateEntry.value.length}');
          for (final memoEntry in dateEntry.value.entries) {
            final checkedCount = memoEntry.value.values.where((checked) => checked).length;
            if (checkedCount > 0) {
              debugPrint('    💊 メモID: ${memoEntry.key}, チェック済み: $checkedCount回');
            }
          }
        }
      }

      final stopwatch = Stopwatch()..start();
      for (final period in [7, 30, 90]) {
        final rate = AdherenceCalculator.calculateCustomAdherence(
          days: period,
          medicationData: medicationData,
          medicationMemos: medicationMemos,
          weekdayMedicationStatus: weekdayStatus,
          medicationMemoStatus: memoStatus,
          getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
            // 最新のweekdayMedicationDoseStatusを参照（カレンダーページのチェック状態を反映）
            final doseStatusForDate = doseStatus[dateStr]?[memoId];
            if (doseStatusForDate == null) {
              // データが存在しない場合は0を返す（チェックされていない）
              return 0;
            }
            // チェック済みの服用回数をカウント
            final checkedCount = doseStatusForDate.values.where((isChecked) => isChecked).length;
            return checkedCount;
          },
        );
        stats['${period}日'] = rate;
        if (kDebugMode) {
          debugPrint('📈 ${period}日間の遵守率: ${rate.toStringAsFixed(2)}%');
        }
      }
      stopwatch.stop();

      adherenceRates = stats;
      notifiers.adherenceRatesNotifier.value = stats;
      if (kDebugMode) {
        debugPrint('✅ 遵守率更新完了: ${stats.toString()} (計算時間: ${stopwatch.elapsedMilliseconds}ms)');
      }
    } catch (e, stackTrace) {
      // エラーは常にログに出力（本番環境でも重要）
      Logger.error('遵守率更新エラー', e, stackTrace: stackTrace);
      if (kDebugMode) {
        debugPrint('❌ 遵守率更新エラー: $e');
        debugPrint('スタックトレース: $stackTrace');
      }
    }
  }

  /// 全データ保存（アーカイブ処理も含む）
  Future<void> saveAllData() async {
    try {
      // 古いメモをアーカイブ（2年以上前のメモを自動アーカイブ）
      try {
        final archivedCount = await medicationDataPersistence.archiveOldMemos(keepYears: 2);
        if (archivedCount > 0) {
          debugPrint('✅ 古いメモをアーカイブ: ${archivedCount}件');
          // アーカイブ後、メモリストを再読み込み
          medicationMemos = await medicationDataPersistence.loadMedicationMemos();
          paginationManager.setAllMemos(medicationMemos);
        }
      } catch (e) {
        debugPrint('⚠️ アーカイブ処理エラー: $e');
        // アーカイブエラーは無視して続行
      }
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
      debugPrint('✅ 全データ保存完了（服用状況を含む）');
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

