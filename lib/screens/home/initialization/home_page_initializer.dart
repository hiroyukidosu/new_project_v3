// lib/screens/home/initialization/home_page_initializer.dart
// ホームページの初期化ロジックを集約

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/home_page_state_manager.dart';
import '../persistence/medication_data_persistence.dart';
import '../persistence/alarm_data_persistence.dart';
import '../persistence/snapshot_persistence.dart';
import '../persistence/data_sync_manager.dart';
import '../handlers/backup_handler.dart';
import '../helpers/data_persistence_helper.dart';
import '../../helpers/home_page_backup_helper.dart';
import '../controllers/medication_controller.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/backup_controller.dart';
import '../controllers/alarm_controller.dart';
import '../../helpers/backup_operations.dart';
import '../../helpers/data_operations.dart';
import '../../helpers/medication_operations.dart';
import '../../helpers/calendar_operations.dart';
import '../../helpers/ui_helpers.dart';
import '../handlers/calendar_event_handler.dart';
import '../handlers/medication_event_handler.dart';
import '../handlers/memo_event_handler.dart';
import '../business/pagination_manager.dart';
import 'package:intl/intl.dart';
import '../handlers/home_page_event_handler.dart';
import '../../../models/medication_info.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medicine_data.dart';
import '../../../services/daily_memo_service.dart';
import 'home_page_dependencies.dart';

/// ホームページの初期化を管理するクラス
class HomePageInitializer {
  /// ホームページの全依存関係を初期化
  static Future<HomePageDependencies> initialize(
    BuildContext context,
    TickerProvider vsync,
    VoidCallback onStateChanged,
    Function(UniqueKey) onAlarmTabKeyChanged,
    Future<void> Function() onUpdateMedicineInputsForSelectedDate,
    Future<void> Function() onLoadMemoForSelectedDate,
    Future<void> Function() onCalculateAdherenceStats,
    void Function() onUpdateCalendarMarks,
    bool Function() onMountedCheck,
    Function(String) onShowSnackBar,
    Future<void> Function() onSaveAllData,
    DateTime? lastOperationTime,
    dynamic purchaseMixin, // PurchaseMixinを追加
  ) async {
    // 1. StateManagerの初期化
    final stateManager = HomePageStateManager(context);
    
    // 2. 永続化クラスの初期化
    final medicationDataPersistence = MedicationDataPersistence();
    final alarmDataPersistence = AlarmDataPersistence();
    final snapshotPersistence = SnapshotPersistence();
    final dataSyncManager = DataSyncManager(
      medicationPersistence: medicationDataPersistence,
      alarmPersistence: alarmDataPersistence,
    );
    
    // 3. バックアップハンドラーの初期化
    final backupHandler = BackupHandler(
      onMountedCheck: onMountedCheck,
      onShowSnackBar: onShowSnackBar,
      onAlarmTabKeyChanged: onAlarmTabKeyChanged,
      onUpdateMedicineInputsForSelectedDate: onUpdateMedicineInputsForSelectedDate,
      onLoadMemoForSelectedDate: onLoadMemoForSelectedDate,
      onCalculateAdherenceStats: onCalculateAdherenceStats,
      onUpdateCalendarMarks: onUpdateCalendarMarks,
      onDataRestored: (restored) async {
        // StateManagerにデータを反映
        try {
          // メモを復元（服用メモ一覧の変更・作成・削除を反映）
          // RestoreBackupUseCaseで既にHiveに保存されているので、MedicationDataPersistenceから再読み込み
          try {
            // MedicationDataPersistenceから最新のメモを取得（復元後の状態を反映）
            // 少し待機してから読み込む（Hiveの書き込み完了を待つ）
            await Future.delayed(const Duration(milliseconds: 100));
            final restoredMemos = await medicationDataPersistence.loadMedicationMemos();
            
            // StateManagerに反映
            stateManager.medicationMemos = restoredMemos;
            
            // PaginationManagerにも反映（メモ一覧の表示に必要）
            if (stateManager.paginationManager != null) {
              stateManager.paginationManager!.setAllMemos(stateManager.medicationMemos);
            }
            
            debugPrint('✅ 服用メモ復元完了: ${stateManager.medicationMemos.length}件（MedicationDataPersistenceから再読み込み）');
          } catch (e) {
            debugPrint('⚠️ 服用メモ復元エラー: $e');
            // フォールバック: バックアップデータから直接復元
            final restoredMemos = restored['restoredMemos'] as List? ?? [];
            final memosList = restoredMemos.map((json) {
              return MedicationMemo.fromJson(json as Map<String, dynamic>);
            }).toList();
            
            stateManager.medicationMemos = memosList;
            await medicationDataPersistence.saveMedicationMemos(stateManager.medicationMemos);
            
            if (stateManager.paginationManager != null) {
              stateManager.paginationManager!.setAllMemos(stateManager.medicationMemos);
            }
            
            debugPrint('✅ 服用メモ復元完了（フォールバック）: ${stateManager.medicationMemos.length}件');
          }
          
          // medicinesを復元（MedicineData）
          final restoredMedicines = restored['restoredMedicines'] as List? ?? [];
          if (restoredMedicines.isNotEmpty) {
            try {
              stateManager.medicines = restoredMedicines.map((json) {
                return MedicineData.fromJson(json as Map<String, dynamic>);
              }).toList();
            } catch (e) {
              debugPrint('⚠️ medicines復元エラー: $e');
            }
          }
          
          // 追加された薬を復元
          final restoredAddedMeds = restored['restoredAddedMedications'] as List? ?? [];
          stateManager.addedMedications = restoredAddedMeds.cast<Map<String, dynamic>>();
          
          // メディケーションデータを復元
          final restoredMedicationData = restored['restoredMedicationData'] as Map<String, Map<String, dynamic>>? ?? {};
          stateManager.medicationData = restoredMedicationData.map((dateKey, dayData) {
            return MapEntry(
              dateKey,
              dayData.map((medKey, medInfo) {
                return MapEntry(medKey, MedicationInfo.fromJson(medInfo));
              }),
            );
          });
          
          // 曜日メディケーションステータスを復元
          final restoredWeekdayStatus = restored['restoredWeekdayStatus'] as Map<String, Map<String, bool>>? ?? {};
          stateManager.weekdayMedicationStatus = restoredWeekdayStatus;
          
          // 服用ステータスを復元
          final restoredWeekdayDoseStatus = restored['restoredWeekdayDoseStatus'] as Map<String, Map<String, Map<int, bool>>>? ?? {};
          stateManager.weekdayMedicationDoseStatus = restoredWeekdayDoseStatus;
          
          // メモステータスを復元
          final restoredMemoStatus = restored['restoredMemoStatus'] as Map<String, bool>? ?? {};
          stateManager.medicationMemoStatus = restoredMemoStatus;
          
          // 日付色を復元
          final restoredDayColors = restored['restoredDayColors'] as Map<String, Color>? ?? {};
          stateManager.dayColors = restoredDayColors;
          
          // アラームリストを復元
          final restoredAlarmList = restored['restoredAlarmList'] as List? ?? [];
          stateManager.alarmList = restoredAlarmList.cast<Map<String, dynamic>>();
          
          // アラーム設定を復元
          final restoredAlarmSettings = restored['restoredAlarmSettings'] as Map<String, dynamic>? ?? {};
          stateManager.alarmSettings = restoredAlarmSettings;
          
          // 遵守率を復元
          final restoredAdherenceRates = restored['restoredAdherenceRates'] as Map<String, double>? ?? {};
          stateManager.adherenceRates = restoredAdherenceRates;
          
          // Notifierを更新
          stateManager.notifiers.dayColorsNotifier.value = Map<String, Color>.from(stateManager.dayColors);
          
          // メモフィールドを再同期（選択日のメモを読み込む）
          if (stateManager.selectedDay != null) {
            final dateStr = DateFormat('yyyy-MM-dd').format(stateManager.selectedDay!);
            try {
              final memo = await DailyMemoService.getMemo(dateStr);
              stateManager.memoController.text = memo;
              stateManager.notifiers.memoTextNotifier.value = memo;
            } catch (e) {
              debugPrint('⚠️ メモ読み込みエラー: $e');
            }
          }
          
          // データを永続化（メモは既に保存済み）
          
          // メモステータスを保存
          await medicationDataPersistence.saveMedicationMemoStatus(stateManager.medicationMemoStatus);
          
          // 曜日ステータスを保存
          await medicationDataPersistence.saveWeekdayMedicationStatus(stateManager.weekdayMedicationStatus);
          
          // 服用ステータスを保存
          await medicationDataPersistence.saveMedicationDoseStatus(stateManager.weekdayMedicationDoseStatus);
          
          // アラームデータを永続化
          await alarmDataPersistence.saveAlarmData(stateManager.alarmList);
          
          // アラーム設定はSharedPreferencesに直接保存
          if (stateManager.alarmSettings.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('alarm_settings', jsonEncode(stateManager.alarmSettings));
          }
          
          // UIを完全に更新
          if (onMountedCheck()) {
            // アラームタブキーを更新（再構築のため）
            onAlarmTabKeyChanged(UniqueKey());
            
            // カレンダーと入力を再評価
            await onUpdateMedicineInputsForSelectedDate();
            await onLoadMemoForSelectedDate();
            
            // 統計の再計算
            await onCalculateAdherenceStats();
            
            // 服用記録の表示を強制更新
            onUpdateCalendarMarks();
            
            // 状態変更を通知
            onStateChanged();
          }
          
          debugPrint('✅ バックアップ復元完了: メモ${stateManager.medicationMemos.length}件、アラーム${stateManager.alarmList.length}件');
        } catch (e, stackTrace) {
          debugPrint('❌ バックアップ復元エラー: $e');
          // Crashlyticsに記録
          try {
            await FirebaseCrashlytics.instance.log('バックアップ復元エラー: onDataRestored');
            await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
          } catch (_) {
            // Crashlytics記録失敗時は無視
          }
        }
      },
      createBackupData: (label) async {
        if (stateManager.isInitialized) {
          return HomePageBackupHelper.createSafeBackupData(
            backupName: label,
            medicationMemos: stateManager.medicationMemos,
            addedMedications: stateManager.addedMedications,
            medicines: stateManager.medicines,
            medicationData: stateManager.medicationData,
            weekdayMedicationStatus: stateManager.weekdayMedicationStatus,
            weekdayMedicationDoseStatus: stateManager.weekdayMedicationDoseStatus,
            medicationMemoStatus: stateManager.medicationMemoStatus,
            dayColors: stateManager.dayColors,
            alarmList: stateManager.alarmList,
            alarmSettings: stateManager.alarmSettings,
            adherenceRates: stateManager.adherenceRates,
          );
        }
        return {};
      },
    );
    
    // 4. StateManagerの非同期初期化
    await stateManager.init();
    
    // 5. コントローラーの初期化（StateManager依存）
    final controllers = _initializeControllers(
      stateManager,
      context,
      snapshotPersistence,
      backupHandler,
      onStateChanged,
      onShowSnackBar,
    );
    
    // 6. データ永続化ヘルパーの初期化
    final dataPersistenceHelper = DataPersistenceHelper(
      stateManager: stateManager,
      medicationDataPersistence: medicationDataPersistence,
    );
    
    // 7. Operationsクラスの初期化（StateManager + Controllers依存）
    final operations = _initializeOperations(
      stateManager,
      controllers,
      context,
      snapshotPersistence,
      backupHandler,
      medicationDataPersistence,
      dataPersistenceHelper,
      onAlarmTabKeyChanged,
      onUpdateMedicineInputsForSelectedDate,
      onLoadMemoForSelectedDate,
      onCalculateAdherenceStats,
      onUpdateCalendarMarks,
      onMountedCheck,
      onSaveAllData,
      lastOperationTime,
    );
    
    // 8. イベントハンドラーの初期化
    final handlers = _initializeHandlers(
      stateManager,
      operations,
      context,
      controllers,
      medicationDataPersistence,
      snapshotPersistence,
      onMountedCheck,
      onStateChanged,
      onShowSnackBar,
      purchaseMixin, // PurchaseMixinを渡す
    );
    
    // 9. TabControllerの作成
    final tabController = TabController(length: 4, vsync: vsync);
    tabController.addListener(() {
      if (onMountedCheck()) {
        onStateChanged();
      }
    });
    
    return HomePageDependencies(
      stateManager: stateManager,
      controllers: controllers,
      operations: operations,
      handlers: handlers,
      tabController: tabController,
    );
  }
  
  /// コントローラーを初期化
  static HomePageControllers _initializeControllers(
    HomePageStateManager stateManager,
    BuildContext context,
    SnapshotPersistence snapshotPersistence,
    BackupHandler backupHandler,
    VoidCallback onStateChanged,
    Function(String) onShowSnackBar,
  ) {
    return HomePageControllers(
      medication: MedicationController(
        stateManager: stateManager,
        context: context,
        snapshotPersistence: snapshotPersistence,
        onStateChanged: onStateChanged,
      ),
      calendar: CalendarController(
        stateManager: stateManager,
        snapshotPersistence: snapshotPersistence,
        onStateChanged: onStateChanged,
      ),
      backup: BackupController(
        stateManager: stateManager,
        backupHandler: backupHandler,
        context: context,
        showSnackBar: onShowSnackBar,
      ),
      alarm: AlarmController(
        stateManager: stateManager,
        snapshotPersistence: snapshotPersistence,
        onStateChanged: onStateChanged,
      ),
    );
  }
  
  /// Operationsクラスを初期化
  static HomePageOperations _initializeOperations(
    HomePageStateManager stateManager,
    HomePageControllers controllers,
    BuildContext context,
    SnapshotPersistence snapshotPersistence,
    BackupHandler backupHandler,
    MedicationDataPersistence medicationDataPersistence,
    DataPersistenceHelper dataPersistenceHelper,
    Function(UniqueKey) onAlarmTabKeyChanged,
    Future<void> Function() onUpdateMedicineInputsForSelectedDate,
    Future<void> Function() onLoadMemoForSelectedDate,
    Future<void> Function() onCalculateAdherenceStats,
    void Function() onUpdateCalendarMarks,
    bool Function() onMountedCheck,
    Future<void> Function() onSaveAllData,
    DateTime? lastOperationTime,
  ) {
    return HomePageOperations(
      backup: BackupOperations(
        context: context,
        stateManager: stateManager,
        snapshotPersistence: snapshotPersistence,
        backupHandler: backupHandler,
        lastOperationTime: lastOperationTime,
        onAlarmTabKeyChanged: onAlarmTabKeyChanged,
        onUpdateMedicineInputsForSelectedDate: onUpdateMedicineInputsForSelectedDate,
        onLoadMemoForSelectedDate: onLoadMemoForSelectedDate,
        onCalculateAdherenceStats: onCalculateAdherenceStats,
        onUpdateCalendarMarks: onUpdateCalendarMarks,
        onMountedCheck: onMountedCheck,
      ),
      data: DataOperations(
        stateManager: stateManager,
        dataPersistenceHelper: dataPersistenceHelper,
        medicationDataPersistence: medicationDataPersistence,
        getSaveDebounceTimer: () => null, // Stateクラスで管理
        setSaveDebounceTimer: (_) {}, // Stateクラスで管理
        getLastOperationTime: () => lastOperationTime,
        setLastOperationTime: (_) {}, // Stateクラスで管理
      ),
      medication: MedicationOperations(
        stateManager: stateManager,
        medicationController: controllers.medication,
        medicationDataPersistence: medicationDataPersistence,
        onSaveAllData: onSaveAllData,
        onStateChanged: () {
          if (onMountedCheck()) {
            // Stateクラスで管理
          }
        },
        onUpdateCalendarMarks: onUpdateCalendarMarks,
      ),
      calendar: CalendarOperations(
        stateManager: stateManager,
        onMountedCheck: onMountedCheck,
        onStateChanged: () {
          if (onMountedCheck()) {
            // Stateクラスで管理
          }
        },
      ),
      ui: UIHelpers(
        context: context,
        onMountedCheck: onMountedCheck,
        stateManager: stateManager,
      ),
    );
  }
  
  /// イベントハンドラーを初期化
  static HomePageHandlers _initializeHandlers(
    HomePageStateManager stateManager,
    HomePageOperations operations,
    BuildContext context,
    HomePageControllers controllers,
    MedicationDataPersistence medicationDataPersistence,
    SnapshotPersistence snapshotPersistence,
    bool Function() onMountedCheck,
    VoidCallback onStateChanged,
    Function(String) onShowSnackBar,
    dynamic purchaseMixin, // PurchaseMixinを追加
  ) {
    return HomePageHandlers(
      main: HomePageEventHandler(
        context: context,
        uiHelpers: operations.ui,
        backupOperations: operations.backup,
        purchaseMixin: purchaseMixin, // PurchaseMixinを設定
      ),
      calendar: CalendarEventHandler(
        persistence: medicationDataPersistence,
        onStateUpdate: (day) {
          if (onMountedCheck()) {
            stateManager.selectedDay = day;
          }
        },
        onDayColorUpdate: (dateStr, color) {
          if (onMountedCheck()) {
            stateManager.dayColors[dateStr] = color;
          }
        },
      ),
      medication: MedicationEventHandler(
        persistence: medicationDataPersistence,
        onStatusUpdate: (memoId, isChecked) {
          if (onMountedCheck()) {
            stateManager.medicationMemoStatus[memoId] = isChecked;
          }
        },
        onDoseStatusUpdate: (memoId, doseIndex, isChecked) {
          if (onMountedCheck()) {
            final dateStr = DateFormat('yyyy-MM-dd').format(stateManager.selectedDay ?? DateTime.now());
            stateManager.weekdayMedicationDoseStatus.putIfAbsent(dateStr, () => <String, Map<int, bool>>{});
            stateManager.weekdayMedicationDoseStatus[dateStr]!.putIfAbsent(memoId, () => <int, bool>{});
            stateManager.weekdayMedicationDoseStatus[dateStr]![memoId]![doseIndex] = isChecked;
          }
        },
      ),
      memo: MemoEventHandler(
        persistence: medicationDataPersistence,
        paginationManager: PaginationManager(),
        onMemoAdded: (memo) {
          if (onMountedCheck()) {
            stateManager.medicationMemos.add(memo);
            onStateChanged();
          }
        },
        onMemoUpdated: (memo) {
          if (onMountedCheck()) {
            final index = stateManager.medicationMemos.indexWhere((m) => m.id == memo.id);
            if (index != -1) {
              stateManager.medicationMemos[index] = memo;
              onStateChanged();
            }
          }
        },
        onMemoDeleted: (memoId) {
          if (onMountedCheck()) {
            stateManager.medicationMemos.removeWhere((m) => m.id == memoId);
            onStateChanged();
          }
        },
        onShowSnackBar: onShowSnackBar,
        onSaveSnapshotBeforeChange: (type) async {
          await snapshotPersistence.saveSnapshotBeforeChange(type, () async => {});
        },
        saveMedicationMemo: (memo) async {
          await medicationDataPersistence.saveMedicationMemo(memo);
        },
      ),
    );
  }
}

