// lib/screens/home/state/home_page_state_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../../helpers/calendar_operations.dart';
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
  bool _isSaving = false; // 保存中フラグ（重複保存防止）
  DateTime? _lastSaveTime; // 最後の保存時刻

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

    // デフォルト値の設定（データが読み込めなかった場合のフォールバック）
    if (selectedDates.isEmpty) {
      selectedDates.add(_normalizeDate(DateTime.now()));
    }
    if (medicationMemoStatus.isEmpty) {
      medicationMemoStatus = {};
    }
    if (addedMedications.isEmpty) {
      addedMedications = [];
    }
    if (dayColors.isEmpty) {
      dayColors = {};
    }
    
    // すぐに初期化完了フラグを立てる（UI表示を可能にする）
    // データ読み込みは非同期で実行し、完了後に更新
    isInitialized = true;
    debugPrint('✅ 初期化完了（最小限の初期化）');
    
    // データ読み込みは非同期で実行（init()の完了をブロックしない）
    _startAsyncDataLoading();
  }
  
  /// 非同期データ読み込みを開始（init()の完了をブロックしない）
  void _startAsyncDataLoading() {
    // Phase 1: 必須データ読み込み（UI表示に必要）
    // 非同期で実行し、完了後にデータを更新
    Future.microtask(() async {
      try {
        await _loadEssentialData().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⚠️ 必須データ読み込みタイムアウト（5秒）- デフォルト値で継続');
          },
        );
      } catch (e) {
        debugPrint('⚠️ 必須データ読み込みエラー: $e（アプリは継続します）');
      }
    });

    // Phase 2以降: メモ読み込みとその他のデータ読み込みは非同期で実行
    Future.microtask(() async {
      try {
        // メモ読み込み（リトライ付き、タイムアウト付き）
        await _loadMedicationMemosWithRetry().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⚠️ メモ読み込みタイムアウト（10秒）');
            medicationMemos = [];
            paginationManager.setAllMemos(medicationMemos);
          },
        );
        paginationManager.setAllMemos(medicationMemos);
        debugPrint('✅ メモ読み込み完了: ${medicationMemos.length}件');
      } catch (e) {
        debugPrint('⚠️ メモ読み込みエラー: $e（アプリは継続します）');
        // エラー時も空のリストで初期化
        medicationMemos = [];
        paginationManager.setAllMemos(medicationMemos);
      }
    });

    // Phase 2以降: 重要データと遅延データの読み込み（非ブロッキング）
    _loadSavedData();
  }

  /// データ読み込み（段階的初期化で最適化）
  /// 注意: Phase 1は既にinit()で実行済み
  Future<void> _loadSavedData() async {
    try {
      // Phase 2: 重要データを並列読み込み（非ブロッキング）
      Future.microtask(() async {
        try {
          await _loadImportantData();
        } catch (e) {
          debugPrint('重要データ読み込みエラー: $e');
        }
      });
      
      // Phase 3: 統計データなどは遅延読み込み（バックグラウンド）
      Future.microtask(() async {
        try {
          await Future.delayed(const Duration(milliseconds: 500)); // UI表示を優先
          await _loadDeferredData();
        } catch (e) {
          debugPrint('遅延データ読み込みエラー: $e');
        }
      });
    } catch (e) {
      debugPrint('データ読み込みエラー: $e');
    }
  }

  /// Phase 1: 必須データ読み込み（UI表示に必要）
  /// 最小限のデータのみを読み込んで、UIを早期に表示
  /// エラーが発生しても処理を継続
  Future<void> _loadEssentialData() async {
    try {
      // 並列読み込みで高速化（独立したデータ）
      // 各処理に個別のエラーハンドリングを追加
      await Future.wait([
        _loadMemoStatus().catchError((e) {
          debugPrint('⚠️ メモ状態読み込みエラー: $e');
          medicationMemoStatus = {};
        }),
        _loadMedicationList().catchError((e) {
          debugPrint('⚠️ 薬リスト読み込みエラー: $e');
          addedMedications = [];
        }),
        _loadCalendarMarks().catchError((e) {
          debugPrint('⚠️ カレンダーマーク読み込みエラー: $e');
          if (selectedDates.isEmpty) {
            selectedDates.add(_normalizeDate(DateTime.now()));
          }
        }),
        _loadDayColors().catchError((e) {
          debugPrint('⚠️ 日付色読み込みエラー: $e');
          dayColors = {};
        }),
      ], eagerError: false); // エラーが発生しても他の処理を継続
      
      debugPrint('✅ 必須データ読み込み完了');
    } catch (e) {
      debugPrint('必須データ読み込みエラー: $e（デフォルト値で継続）');
    }
  }

  /// Phase 2: 重要データ読み込み（アプリ機能に必要）
  /// アラーム、設定など、アプリの主要機能に必要なデータ
  Future<void> _loadImportantData() async {
    try {
      // 並列読み込みで高速化
      await Future.wait([
        _loadAlarmData(),
        _loadUserPreferences(),
        _loadAppSettings(),
        _loadMedicationData(), // 選択日のデータ
      ]);
      
      debugPrint('✅ 重要データ読み込み完了');
    } catch (e) {
      debugPrint('重要データ読み込みエラー: $e');
    }
  }

  /// Phase 3: 遅延データ読み込み（統計・分析データ）
  /// 遵守率計算など、重い処理は後で実行
  Future<void> _loadDeferredData() async {
    try {
      // 重要: 服用回数別ステータスを統計データより先に読み込む（遵守率計算に必要）
      await _loadMedicationDoseStatus();
      
      // 服用回数別ステータス読み込み後に統計を読み込み（その後、_loadMedicationDoseStatus内で再計算される）
      await _loadStatistics();
      
      debugPrint('✅ 遅延データ読み込み完了');
    } catch (e) {
      debugPrint('遅延データ読み込みエラー: $e');
    }
  }

  /// 全データ読み込み（後方互換性のため残す）
  /// 注意: 通常は段階的読み込みを使用
  Future<void> _loadAllData() async {
    try {
      await _loadEssentialData();
      await _loadImportantData();
      await _loadDeferredData();
      
      debugPrint('全データ読み込み完了');
    } catch (e) {
      debugPrint('全データ読み込みエラー: $e');
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
  /// 注意: 服用回数別ステータス読み込み後に実行される（_loadMedicationDoseStatus内で再計算されるため、ここでは初期値のみ読み込む）
  Future<void> _loadStatistics() async {
    adherenceRates = await HomePageDataHelper.loadStatistics();
    // 初期値として設定（_loadMedicationDoseStatus内で再計算される）
    notifiers.adherenceRatesNotifier.value = Map<String, double>.from(adherenceRates);
  }

  /// 服用回数別状態読み込み
  Future<void> _loadMedicationDoseStatus() async {
    try {
      final loaded = await medicationDataPersistence.loadMedicationDoseStatus();
      weekdayMedicationDoseStatus = loaded ?? {};
      debugPrint('服用回数別ステータス読み込み: ${weekdayMedicationDoseStatus.length}日分のデータ');
      if (weekdayMedicationDoseStatus.isNotEmpty) {
        final sampleDate = weekdayMedicationDoseStatus.keys.first;
        final sampleMemos = weekdayMedicationDoseStatus[sampleDate]?.length ?? 0;
        debugPrint('サンプル日付($sampleDate): $sampleMemos件のメモ');
        // サンプルデータの詳細をログ出力
        final sampleMemoId = weekdayMedicationDoseStatus[sampleDate]?.keys.first;
        if (sampleMemoId != null) {
          final sampleDoseStatus = weekdayMedicationDoseStatus[sampleDate]?[sampleMemoId];
          debugPrint('サンプルメモ($sampleMemoId)のチェック状態: $sampleDoseStatus');
        }
      } else {
        debugPrint('⚠️ 服用回数別ステータスが空です');
      }
      
      // 服用回数別ステータス読み込み後、遵守率統計を再計算（服用完了率を反映）
      await _recalculateAdherenceStats();
    } catch (e, stackTrace) {
      debugPrint('服用回数別ステータス読み込みエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      weekdayMedicationDoseStatus = {};
    }
  }
  
  /// 遵守率統計を再計算（服用完了率を反映）（完全再構築版 - 徹底的に作り直し）
  Future<void> _recalculateAdherenceStats() async {
    try {
      debugPrint('========================================');
      debugPrint('遵守率統計再計算開始（完全再構築版）');
      debugPrint('服用回数別ステータス: ${weekdayMedicationDoseStatus.length}日分');
      if (weekdayMedicationDoseStatus.isNotEmpty) {
        final sampleDate = weekdayMedicationDoseStatus.keys.first;
        final sampleMemos = weekdayMedicationDoseStatus[sampleDate]?.length ?? 0;
        debugPrint('サンプル日付: $sampleDate, メモ数: $sampleMemos');
      }
      debugPrint('========================================');
      
      // CalendarOperationsを使用して遵守率統計を計算
      final calendarOps = CalendarOperations(
        stateManager: this,
        onMountedCheck: () => true,
        onStateChanged: () {
          // UI更新は不要（ValueNotifierが自動的に更新する）
        },
      );
      await calendarOps.calculateAdherenceStats();
      
      debugPrint('========================================');
      debugPrint('遵守率統計再計算完了');
      debugPrint('遵守率データ: $adherenceRates');
      debugPrint('Notifier値: ${notifiers.adherenceRatesNotifier.value}');
      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('❌ 遵守率統計再計算エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
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

  /// 全データ保存（完全再構築版 - 徹底的に作り直し）
  /// 保存後に遵守率統計を再計算して、グラフに反映させる
  /// 重複保存防止とデバウンス処理を追加
  Future<void> saveAllData({bool force = false}) async {
    // 既に保存中の場合はスキップ（重複保存防止）
    if (_isSaving && !force) {
      debugPrint('⚠️ 保存処理が既に実行中のため、スキップします');
      return;
    }
    
    // 最後の保存から1秒以内の場合はスキップ（デバウンス）
    if (!force && _lastSaveTime != null) {
      final timeSinceLastSave = DateTime.now().difference(_lastSaveTime!);
      if (timeSinceLastSave.inMilliseconds < 1000) {
        debugPrint('⚠️ 最後の保存から${timeSinceLastSave.inMilliseconds}msしか経過していないため、スキップします');
        return;
      }
    }
    
    _isSaving = true;
    try {
      // メモテキストを確実に取得（memoTextNotifierとmemoControllerの両方を確認）
      final memoText = notifiers.memoTextNotifier.value.isNotEmpty
          ? notifiers.memoTextNotifier.value
          : memoController.text;

      debugPrint('========================================');
      debugPrint('全データ保存開始（完全再構築版）');
      debugPrint('服用回数別ステータス: ${weekdayMedicationDoseStatus.length}日分');
      if (weekdayMedicationDoseStatus.isNotEmpty) {
        final sampleDate = weekdayMedicationDoseStatus.keys.first;
        final sampleMemos = weekdayMedicationDoseStatus[sampleDate]?.length ?? 0;
        debugPrint('サンプル日付: $sampleDate, メモ数: $sampleMemos');
      }
      debugPrint('========================================');
      
      // 重い処理をバックグラウンドで実行（computeは使えないため、Future.microtaskで非同期実行）
      await Future.microtask(() async {
        await dataSyncManager.saveAllData(
          medicationMemos: medicationMemos,
          medicationMemoStatus: medicationMemoStatus,
          weekdayMedicationStatus: weekdayMedicationStatus,
          weekdayMedicationDoseStatus: weekdayMedicationDoseStatus,
          addedMedications: addedMedications,
          alarmList: alarmList,
          dayColors: dayColors,
          selectedDay: selectedDay,
          memoText: memoText,
          adherenceRates: adherenceRates,
        );
      });
      
      debugPrint('全データ保存完了');
      
      // 重要：データ保存後に遵守率統計を再計算（グラフに反映させる）
      debugPrint('遵守率統計を再計算します...');
      await _recalculateAdherenceStats();
      
      _lastSaveTime = DateTime.now();
      debugPrint('全データ保存と遵守率統計再計算完了');
    } catch (e, stackTrace) {
      debugPrint('❌ データ保存エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    } finally {
      _isSaving = false;
    }
  }

  /// 日付正規化
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// バックアップデータ作成
  Future<Map<String, dynamic>> _createSafeBackupData(String label) async {
    try {
      // Colorオブジェクトをint値に変換（シリアライズ可能にする）
      final dayColorsSerialized = <String, int>{};
      dayColors.forEach((key, color) {
        dayColorsSerialized[key] = color.value;
      });
      
      // addedMedications内のColorオブジェクトも変換
      final addedMedicationsSerialized = addedMedications.map((med) {
        final medCopy = Map<String, dynamic>.from(med);
        if (medCopy['color'] is Color) {
          medCopy['color'] = (medCopy['color'] as Color).value;
        }
        return medCopy;
      }).toList();
      
      return {
        'medicationMemos': medicationMemos.map((m) => m.toJson()).toList(),
        'medicationMemoStatus': medicationMemoStatus,
        'weekdayMedicationStatus': weekdayMedicationStatus,
        'weekdayMedicationDoseStatus': weekdayMedicationDoseStatus,
        'addedMedications': addedMedicationsSerialized,
        'dayColors': dayColorsSerialized,
        'adherenceRates': adherenceRates,
        'label': label,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      debugPrint('バックアップデータ作成エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      // エラー時はdayColorsとaddedMedicationsのColorを除外して保存
      try {
        final addedMedicationsWithoutColor = addedMedications.map((med) {
          final medCopy = Map<String, dynamic>.from(med);
          medCopy.remove('color'); // Colorオブジェクトを削除
          return medCopy;
        }).toList();
        
        return {
          'medicationMemos': medicationMemos.map((m) => m.toJson()).toList(),
          'medicationMemoStatus': medicationMemoStatus,
          'weekdayMedicationStatus': weekdayMedicationStatus,
          'weekdayMedicationDoseStatus': weekdayMedicationDoseStatus,
          'addedMedications': addedMedicationsWithoutColor,
          'adherenceRates': adherenceRates,
          'label': label,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } catch (e2) {
        debugPrint('フォールバックバックアップデータ作成もエラー: $e2');
        // 最小限のデータのみ返す
        return {
          'medicationMemos': medicationMemos.map((m) => m.toJson()).toList(),
          'medicationMemoStatus': medicationMemoStatus,
          'adherenceRates': adherenceRates,
          'label': label,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
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

