// lib/screens/home/initialization/home_page_initializer.dart
// ホームページの初期化ロジックを集約

import 'package:flutter/material.dart';
import 'dart:async';
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
      onDataRestored: (restored) {
        // データ復元後の処理は各メソッド内で実行済み
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

