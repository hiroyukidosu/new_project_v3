// MedicationHomePage
// メインホーム画面 - タブバーで各機能にアクセスします

// Dart core imports
import 'dart:async';
import 'dart:convert';

// Flutter core imports
import 'package:flutter/material.dart';

// Third-party package imports
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Local imports
import '../models/medication_memo.dart';
import '../models/medicine_data.dart';
import '../models/medication_info.dart';
import '../services/app_preferences.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../services/trial_service.dart';
import '../services/in_app_purchase_service.dart';
import 'mixins/purchase_mixin.dart';
import '../widgets/memo_dialog.dart';
import '../widgets/trial_limit_dialog.dart';
import '../utils/logger.dart';
import 'tabs/alarm_tab.dart';
import 'tabs/medicine_tab.dart';
import 'tabs/stats_tab.dart';
import 'views/calendar_view.dart';
import 'views/medicine_view.dart';
import 'views/alarm_view.dart';
import 'views/stats_view.dart';
// import 'tabs/calendar_tab.dart'; // CalendarViewに置き換え済み
import 'helpers/home_page_data_helper.dart';
import 'helpers/home_page_alarm_helper.dart';
import 'helpers/home_page_backup_helper.dart';
import 'helpers/home_page_stats_helper.dart';
import 'helpers/home_page_utils_helper.dart';
// TODO: これらのファイルは将来の移行用です。現在はprivateクラスへの参照によりエラーが発生するため、コメントアウトします。
// import 'helpers/home_page_data_operations.dart';
// import 'helpers/home_page_dialogs.dart';
// import 'helpers/home_page_event_handlers.dart';
// import 'helpers/home_page_ui_builders.dart';
import 'helpers/calculations/medication_stats_calculator.dart';
import 'helpers/calculations/adherence_calculator.dart';
import 'helpers/ui_builders/calendar_ui_builder.dart';
import 'helpers/ui_builders/medication_ui_builder.dart';
// import 'helpers/state_management/home_page_state_manager.dart'; // 重複インポート削除
// 新しい分割構造のインポート
import 'home/persistence/medication_data_persistence.dart';
import 'home/persistence/alarm_data_persistence.dart';
import 'home/handlers/calendar_event_handler.dart';
import 'home/handlers/medication_event_handler.dart';
import 'home/handlers/memo_event_handler.dart';
import 'home/business/calendar_marker_manager.dart';
import 'home/business/pagination_manager.dart';
import 'home/state/home_page_state_notifiers.dart';
import 'home/widgets/medication_item_widgets.dart';
import 'home/widgets/expanded_medication_memo_checkbox.dart';
import 'home/widgets/day_memo_field_widget.dart';
import 'home/widgets/day_medication_records_widget.dart';
import 'home/widgets/day_color_picker_dialog.dart';
import 'home/widgets/dialogs/custom_adherence_dialog.dart';
import 'home/widgets/dialogs/warning_dialog.dart';
import 'home/widgets/dialogs/backup_dialog.dart';
import 'home/widgets/dialogs/backup_history_dialog.dart';
import 'home/widgets/dialogs/backup_preview_dialog.dart';
import 'home/handlers/backup_handler.dart';
import 'home/persistence/snapshot_persistence.dart';
import 'home/persistence/data_sync_manager.dart';
import 'home/state/home_page_state_manager.dart';
import 'home/controllers/medication_controller.dart';
import 'home/controllers/calendar_controller.dart';
import 'home/controllers/backup_controller.dart';
import 'home/controllers/alarm_controller.dart';
import 'home/helpers/data_persistence_helper.dart';
import 'helpers/backup_operations.dart';
import 'helpers/data_operations.dart';
import 'helpers/medication_operations.dart';
import 'helpers/calendar_operations.dart';
import 'helpers/ui_helpers.dart';
import 'home/widgets/home_app_bar_menu.dart';
import 'home/widgets/home_tab_bar_view.dart';
import 'home/handlers/home_page_event_handler.dart';
import 'home/initialization/home_page_initializer.dart';
import 'home/initialization/home_page_dependencies.dart';
import '../services/daily_memo_service.dart';

class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});
  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}
class _MedicationHomePageState extends State<MedicationHomePage> 
    with TickerProviderStateMixin, PurchaseMixin,
         CalendarUIBuilderMixin, MedicationUIBuilderMixin {
  
  // CalendarUIBuilderMixinで必要なプロパティ（依存関係経由）
  @override
  List<MedicationMemo> get medicationMemos => _dependencies?.stateManager.medicationMemos ?? [];
  
  @override
  Map<String, Map<String, MedicationInfo>> get medicationData => _dependencies?.stateManager.medicationData ?? {};
  
  @override
  Map<String, Color> get dayColors => _dependencies?.stateManager.dayColors ?? {};
  
  // MedicationUIBuilderMixinで必要なプロパティ（依存関係経由）
  @override
  Map<String, bool> get medicationMemoStatus => _dependencies?.stateManager.medicationMemoStatus ?? {};
  
  @override
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus => _dependencies?.stateManager.weekdayMedicationDoseStatus ?? {};
  
  @override
  DateTime? get selectedDay => _dependencies?.stateManager.selectedDay;
  
  @override
  void Function(String, int, bool) get onDoseStatusChanged => _onDoseStatusChanged;
  
  /// 服用回数のステータスを変更
  void _onDoseStatusChanged(String memoId, int doseIndex, bool isChecked) async {
    if (_dependencies == null) return;
    
    final selectedDay = _dependencies!.stateManager.selectedDay;
    if (selectedDay == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    
    // 変更前スナップショット
    await _dependencies!.operations.backup.saveSnapshotBeforeChange('服用回数変更_${memoId}_${doseIndex + 1}回目_$dateStr');
    
    setState(() {
      _dependencies!.stateManager.weekdayMedicationDoseStatus.putIfAbsent(dateStr, () => {});
      _dependencies!.stateManager.weekdayMedicationDoseStatus[dateStr]!.putIfAbsent(memoId, () => {});
      _dependencies!.stateManager.weekdayMedicationDoseStatus[dateStr]![memoId]![doseIndex] = isChecked;
      _dependencies!.stateManager.weekdayMedicationStatusChanged = true;
    });
    
    // データを保存
    await _dependencies!.stateManager.saveAllData();
    
    // 統計を再計算（チェック状況が反映されるように）
    await _calculateAdherenceStats();
  }
  
  @override
  void Function(MedicationMemo) get onEditMemo => _editMemo;
  
  @override
  void Function(String) get onDeleteMemo => _deleteMemo;
  
  @override
  void Function(MedicationMemo) get onMarkAsTaken => _markAsTaken;
  late TabController _tabController;
  
  // 注意: 以下の状態変数はStateManagerに移動済み
  // DateTime _focusedDay, DateTime? _selectedDay, Set<DateTime> _selectedDates,
  // List<Map<String, dynamic>> _addedMedications, Map<String, Map<String, MedicationInfo>> _medicationData,
  // Map<String, double> _adherenceRates, List<MedicineData> _medicines, List<MedicationMemo> _medicationMemos
  // これらは _stateManager 経由でアクセス
  Timer? _debounce;
  Timer? _saveDebounceTimer; // ✅ 修正：保存用デバウンスタイマーを追加
  StreamSubscription<List<PurchaseDetails>>? _subscription; // ✅ 修正：StreamSubscriptionを追加
  
  // ✅ 修正：変更フラグ変数を追加
  bool _medicationMemoStatusChanged = false;
  
  // アラームタブのキー（強制再構築用）
  Key _alarmTabKey = UniqueKey();
  
  // 注意: _statsScrollControllerはStateManagerに移動済み
  
  // ✅ 任意の日数の遵守率機能用の変数
  double? _customAdherenceResult;
  int? _customDaysResult;
  final TextEditingController _customDaysController = TextEditingController();
  final FocusNode _customDaysFocusNode = FocusNode();
  
  
  // ✅ 手動復元機能のための変数
  DateTime? _lastOperationTime;
  
  // ✅ 自動バックアップ機能はサービスに移動済み（変数削除）
 
  // ✅ 修正：データキーの統一とバージョン管理
  static const String _medicationMemosKey = 'medication_memos_v2';
  static const String _medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String _weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String _addedMedicationsKey = 'added_medications_v2';
  
  // バックアップキー
  static const String _backupSuffix = '_backup';

  // 注意: 以下の状態変数はStateManagerに移動済み
  // _memoController, _memoFocusNode, _isMemoFocused, _memoSnapshotSaved,
  // _memoTextNotifier, _dayColorsNotifier, _weekdayMedicationStatus, _weekdayMedicationDoseStatus,
  // _medicationMemoStatus, _isMemoSelected, _selectedMemo, _alarmList, _alarmSettings,
  // _isAtTop, _lastScrollPosition, _calendarScrollController, _medicationHistoryScrollController,
  // _medicationPageController, _currentMedicationPage, _calendarBottomKey, _isScrollBatonPassActive,
  // _lastAlarmCheckLog, _dayColors
  // これらは _stateManager 経由でアクセス
  
  
  
  // 依存関係を集約管理（Phase 1: 初期化ロジック分離）
  HomePageDependencies? _dependencies;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }
  
  /// 非同期初期化（Phase 1: 初期化ロジック分離）
  Future<void> _initializeAsync() async {
    try {
      // 日メモHive初期化＆SPからの一括移行（初回のみ）
      await DailyMemoService.initialize();
      final dependencies = await HomePageInitializer.initialize(
        context,
        this,
        () {
              if (mounted) setState(() {});
            },
        (key) {
          _alarmTabKey = key;
              if (mounted) setState(() {});
            },
        () async => await _updateMedicineInputsForSelectedDate(),
        () async => await _loadMemoForSelectedDate(),
        () async => await _calculateAdherenceStats(),
        () => _updateCalendarMarks(),
        () => mounted,
        (message) => _showSnackBar(message),
        () async => await _saveAllData(),
        _lastOperationTime,
        this, // PurchaseMixinを渡す（thisはPurchaseMixinを実装している）
      );
      
      if (mounted) {
        setState(() => _dependencies = dependencies);
      }
      } catch (e) {
        debugPrint('❌ 初期化エラー: $e');
        if (mounted) setState(() {});
      }
  }
  
  // 注意: _loadSavedData()は削除（StateManager.init()で実行済み）
  
  // 完全移行: 依存関係経由でデータ保存
  Future<void> _saveAllData() async {
    await _dependencies?.operations.data.saveAllData();
  }
  
  // 操作後5分以内の手動復元機能（依存関係経由）
  Future<void> _showManualRestoreDialog() async {
    await _dependencies?.handlers.main.showManualRestoreDialog();
  }
  
  // 手動復元を実行（依存関係経由）
  Future<void> _performManualRestore() async {
    await _dependencies?.operations.backup.performManualRestore();
  }
  
  // 注意: 以下のメソッドは削除（StateManager.init()で実行済み、またはAlarmTabで管理）
  // _loadAllData, _validateAndUpdateUI, _loadMedicationData, _loadMedicationList,
  // _loadAlarmData, _reRegisterAlarms, _registerSingleAlarm
  
  // アラーム操作（依存関係経由）
  Future<void> addAlarm(Map<String, dynamic> alarm) async {
    await _dependencies?.controllers.alarm.addAlarm(alarm);
    if (mounted) setState(() {});
  }
  
  Future<void> removeAlarm(int index) async {
    await _dependencies?.controllers.alarm.removeAlarm(index);
  }
  
  Future<void> updateAlarm(int index, Map<String, dynamic> updatedAlarm) async {
    await _dependencies?.controllers.alarm.updateAlarm(index, updatedAlarm);
  }
  
  Future<void> toggleAlarm(int index) async {
    await _dependencies?.controllers.alarm.toggleAlarm(index);
  }
  
  // アラームデータの整合性チェック（依存関係経由）
  Future<void> _checkAlarmDataIntegrity() async {
    await _dependencies?.controllers.alarm.checkAlarmDataIntegrity();
  }
  
  Future<void> _saveMedicationDoseStatus() async {
    await _dependencies?.operations.data.saveMedicationDoseStatus();
  }
  
  // 注意: 以下のメソッドは削除（StateManager.init()で実行済み）
  // _loadMedicationDoseStatus, _loadAppSettings, _setupControllerListeners,
  // _initializeAsync, _loadHeavyData
  
  @override
  void dispose() {
    // Phase 1: 依存関係のクリーンアップを統合
    _dependencies?.dispose();
    
    // タイマーとStreamSubscriptionのクリーンアップ
    _debounce?.cancel();
    _debounce = null;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    _subscription?.cancel();
    _subscription = null;
    
    // 動的薬リストのリスナー解放
    final addedMeds = _dependencies?.stateManager.addedMedications ?? [];
    for (final medication in addedMeds) {
      if (medication.containsKey('controller')) {
        (medication['controller'] as TextEditingController?)?.dispose();
      }
    }
    
    // カスタムコントローラーのクリーンアップ
    _customDaysController.dispose();
    _customDaysFocusNode.dispose();
    
    // 購入サービスのクリーンアップ（Hiveはアプリケーションレベルで管理）
    InAppPurchaseService.dispose();
    
    super.dispose();
  }
  DateTime _normalizeDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);
  
  /// 遵守率統計を計算（依存関係経由）
  Future<void> _calculateAdherenceStats() async {
    await _dependencies?.operations.calendar.calculateAdherenceStats();
  }
  
  // 完全移行: 依存関係経由でデータ保存（簡素化）
  void _saveCurrentDataDebounced() {
    _dependencies?.operations.data.saveCurrentDataDebounced();
  }

  // 完全移行: 依存関係経由でデータ保存
  void _saveCurrentData() async {
    await _dependencies?.operations.data.saveCurrentData();
  }
  
  // 動的薬リストの保存
  Future<void> _saveAddedMedications() async {
    await _dependencies?.operations.data.saveAddedMedications();
  }
  
  // 服用メモの状態保存
  Future<void> _saveMedicationMemoStatus() async {
    await _dependencies?.operations.data.saveMedicationMemoStatus();
  }
  
  // 曜日設定薬の状態保存
  Future<void> _saveWeekdayMedicationStatus() async {
    await _dependencies?.operations.data.saveWeekdayMedicationStatus();
  }
  
  // 完全移行: 依存関係経由でデータ読み込み
  Future<void> _loadCurrentData() async {
    await _dependencies?.operations.data.loadCurrentData();
  }
  
  Future<void> _loadMemo() async {
    await _dependencies?.operations.data.loadMemo();
  }
  
  Future<void> _updateMedicineInputsForSelectedDate() async {
    await _dependencies?.operations.data.updateMedicineInputsForSelectedDate();
  }

  Future<void> _loadMemoForSelectedDate() async {
    await _dependencies?.operations.data.loadMemoForSelectedDate();
  }


  // 注意: 以下のメソッドは削除（StateManagerで実行済み）
  // _loadMedicationMemos, _loadMemosFromSharedPreferences, _backupMemosToSharedPreferences,
  // _saveMedicationMemoWithBackup, _deleteMedicationMemoWithBackup,
  // _loadMedicationMemosWithRetry, _restoreMedicationMemosFromBackup

  void _showSnackBar(String message) async {
    _dependencies?.handlers.main.showSnackBar(message);
  }




  // 注意: _buildCalendarTab()は削除。直接CalendarViewを使用

  // 注意: カレンダー関連のビルダーメソッドはCalendarViewに移動済み
  // 以下はMixinで必要なため保持（StateManager経由）
  @override
  Map<String, int> Function(DateTime) get calculateDayMedicationStats => (DateTime day) {
    if (_dependencies == null) return {'total': 0, 'taken': 0};
    return MedicationStatsCalculator.calculateDayMedicationStats(
      day: day,
      medicationData: _dependencies!.stateManager.medicationData,
      medicationMemos: _dependencies!.stateManager.medicationMemos,
      getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
        final doseStatus = _dependencies!.stateManager.weekdayMedicationDoseStatus[dateStr]?[memoId];
        if (doseStatus == null) return 0;
        return doseStatus.values.where((isChecked) => isChecked).length;
      },
    );
  };

  @override
  int Function(String, String) get getMedicationMemoCheckedCountForDate => (String memoId, String dateStr) {
    if (_dependencies == null) return 0;
    final doseStatus = _dependencies!.stateManager.weekdayMedicationDoseStatus[dateStr]?[memoId];
    if (doseStatus == null) return 0;
    return doseStatus.values.where((isChecked) => isChecked).length;
  };

  // 注意: カレンダー関連メソッドはCalendarViewに移動済み
  // _changeDayColor, _buildMedicationRecords, _getMedicationListLength, _buildMedicationItem,
  // _buildNoMedicationMessage, _buildMedicationMemoCheckbox

  // メモ詳細ダイアログを表示（EventHandler経由）
  void _showMemoDetailDialog(BuildContext context, String medicationName, String memo) {
    _dependencies?.handlers.main.showMemoDetailDialog(medicationName, memo);
  }

  // ページネーション機能（PaginationManagerを使用）
  final ScrollController _memoScrollController = ScrollController();
  
  // 注意: _memoBox, _getMemoBoxは削除（StateManagerで管理済み）
  


  // ページネーション機能の実装（PaginationManagerを使用）
  Future<void> _loadMoreMemos() async {
    // PaginationManagerはStateManagerで管理されているため、ここでは削除
    // 必要に応じて_dependencies経由でアクセス
  }
  
  // スクロール監視の初期化
  void _initializeScrollListener() {
    _memoScrollController.addListener(() {
      if (_memoScrollController.position.pixels >= 
          _memoScrollController.position.maxScrollExtent * 0.8) {
        _loadMoreMemos();
      }
    });
  }
  
  // メモ制限チェック（依存関係経由）
  bool _canAddMemo() {
    return _dependencies?.operations.ui.canAddMemo() ?? false;
  }
  
  // 制限ダイアログ表示（依存関係経由）
  void _showLimitDialog(String type) {
    _dependencies?.handlers.main.showLimitDialog(type);
  }

  // 注意: 以下のメソッドは削除（MedicationOperationsに移動済み）
  // _addToTakenMedications, _removeFromTakenMedications, _updateMedicationMemoStatus
  
  // データ保存メソッド（依存関係経由）
  Future<void> _saveMedicationData() async {
    await _dependencies?.operations.data.saveMedicationData();
  }
  
  // メモの状態を読み込み（依存関係経由）
  Future<void> _loadMemoStatus() async {
    await _dependencies?.operations.data.loadMemoStatus();
        if (mounted) {
    setState(() {
            // 保存された値があればそれを使う
          });
        }
  }
  
  // アプリ再起動時のデータ表示を確実にする（簡略化）
  Future<void> _ensureDataDisplayOnRestart() async {
    if (_dependencies == null) return;
    final memos = _dependencies!.stateManager.medicationMemos;
    final status = _dependencies!.stateManager.medicationMemoStatus;
    for (final memo in memos) {
      status.putIfAbsent(memo.id, () => false);
    }
    _dependencies!.stateManager.medicationMemoStatus = status;
    if (mounted) setState(() {});
  }


  // 注意: _buildAddedMedicationRecordはCalendarViewに移動済み（削除済み）

  /// 服用メモタブを構築（完全移行）
  // 注意: _buildMedicineTab(), _buildAlarmTab(), _buildStatsTab()は削除。直接ビューを使用
  // 注意: 統計関連のメソッドはStatsViewに移動済み
  // _buildCustomAdherenceCard, _showCustomAdherenceDialog, _calculateCustomAdherence,
  // _buildAdherenceChart, _buildMedicationUsageChart は削除
  /// メモ追加（依存関係経由）
  void _addMemo() {
    _dependencies?.controllers.medication.addMemo();
  }
  
  /// メモ編集（依存関係経由）
  void _editMemo(MedicationMemo memo) {
    _dependencies?.controllers.medication.editMemo(memo);
  }
  
  /// 服用済みにマーク（依存関係経由）
  Future<void> _markAsTaken(MedicationMemo memo) async {
    await _dependencies?.controllers.medication.markAsTaken(memo);
  }
  
  /// メモ削除（依存関係経由）
  Future<void> _deleteMemo(String id) async {
    await _dependencies?.controllers.medication.deleteMemo(id);
  }

  // 注意: _generateDefaultTitle, _parseTimeStringは削除（ヘルパーを直接使用）


  // 注意: 以下のメソッドは削除（MedicationOperationsに移動済み）
  // _getMedicationsForSelectedDay, _getWeekdayMedicationStatus, _updateWeekdayMedicationStatus

  // 注意: _buildWeekdayMedicationRecordは削除（CalendarViewに移動済み）


  void _addMedicationToTimeSlot(String medicationName) {
    _saveSnapshotBeforeChange('薬追加_$medicationName');
    _dependencies?.operations.medication.addMedicationToTimeSlot(
      medicationName,
      (titles) => HomePageUtilsHelper.generateDefaultTitle(titles),
      _showLimitDialog,
      _showSnackBar,
      _saveCurrentDataDebounced,
    );
  }

  /// カレンダーマークを更新（依存関係経由）
  void _updateCalendarMarks() {
    _dependencies?.operations.calendar.updateCalendarMarks();
  }

  // 軽量化された統計計算メソッド
  Map<String, int> _calculateMedicationStats() {
    if (_dependencies == null) return {'total': 0, 'taken': 0};
    
    final selectedDay = _dependencies!.stateManager.selectedDay;
    if (selectedDay == null) return {'total': 0, 'taken': 0};
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    final addedMeds = _dependencies!.stateManager.addedMedications;
    totalMedications += addedMeds.length;
    takenMedications += addedMeds.where((med) => med['isChecked'] == true).length;
    
    // 服用メモの統計（軽量化）
    final weekday = selectedDay.weekday % 7;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final memos = _dependencies!.stateManager.medicationMemos;
    final status = _dependencies!.stateManager.medicationMemoStatus;
    
    for (final memo in memos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications++;
        if (status[memo.id] == true) {
          takenMedications++;
        }
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  // 注意: _buildMedicationStats と _buildMemoField はCalendarViewに移動済み

  Future<void> _saveMemo() async {
    try {
      if (_dependencies == null) return;
      final selectedDay = _dependencies!.stateManager.selectedDay;
      final memoController = _dependencies!.stateManager.memoController;
      if (selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
        await DailyMemoService.setMemo(dateStr, memoController?.text ?? '');
      }
    } catch (e) {
    }
  }
  
  void _completeMemo() {
    if (_dependencies == null) return;
    final memoController = _dependencies!.stateManager.memoController;
    setState(() {
      _dependencies!.stateManager.isMemoFocused = false;
      _dependencies!.stateManager.memoSnapshotSaved = false;
    });
    // カーソルの選択を外す
    FocusScope.of(context).unfocus();
    _saveMemo().then((_) {
      if (memoController.text.isNotEmpty) {
        _showSnackBar('メモを保存しました');
      } else {
        _showSnackBar('メモをクリアしました');
      }
    });
  }

  // 注意: _showTrialStatus, _showPurchaseLinkDialog, _startPurchaseは削除（EventHandler経由で直接Mixin呼び出し）
  
  // 警告ダイアログを表示（EventHandler経由）
  void _showWarningDialog(BuildContext context) {
    _dependencies?.handlers.main.showWarningDialog();
  }

  // ✅ バックアップ機能を実装（簡略化）
  Future<void> _showBackupDialog() async {
    await _dependencies?.operations.backup.showBackupDialog();
  }

  // ✅ 直前の変更が存在するか（スナップショット有無）
  Future<bool> _hasUndoAvailable() async {
    return await _dependencies?.operations.backup.hasUndoAvailable() ?? false;
  }

  // ✅ 変更前スナップショット保存
  Future<void> _saveSnapshotBeforeChange(String operationType) async {
    await _dependencies?.operations.backup.saveSnapshotBeforeChange(operationType);
  }

  // ✅ 1つ前の状態に復元（最新スナップショットから）
  Future<void> _undoLastChange() async {
    await _dependencies?.operations.backup.undoLastChange();
  }


  // ✅ 手動バックアップ作成機能
  Future<void> _createManualBackup() async {
    await _dependencies?.operations.backup.createManualBackup();
  }

  // ✅ 型安全なバックアップデータ作成
  Future<Map<String, dynamic>> _createSafeBackupData(String backupName) async {
    return await _dependencies?.operations.backup.createSafeBackupData(backupName) ?? {};
  }

  // ✅ 安全なJSONエンコード（エラーハンドリング）
  Future<String> _safeJsonEncode(Map<String, dynamic> data) async {
    return await _dependencies?.operations.backup.safeJsonEncode(data) ?? '';
  }

  // ✅ 非同期暗号化
  Future<String> _encryptDataAsync(String data) async {
    return await _dependencies?.operations.backup.encryptDataAsync(data) ?? '';
  }






  // ✅ バックアップ履歴の更新（サービスに移動）
  Future<void> _updateBackupHistory(String backupName, String backupKey, {String type = 'manual'}) async {
    await _dependencies?.operations.backup.updateBackupHistory(backupName, backupKey, type: type);
  }

  // ✅ バックアップ履歴表示機能（強化版）
  Future<void> _showBackupHistory() async {
    await _dependencies?.operations.backup.showBackupHistory();
  }

  // ✅ バックアッププレビュー機能（簡略化）
  Future<void> _previewBackup(String backupKey) async {
    await _dependencies?.operations.backup.previewBackup(backupKey);
  }

  // ✅ バックアップ復元機能（最適化版）
  Future<void> _restoreBackup(String backupKey) async {
    await _dependencies?.operations.backup.restoreBackup(backupKey);
  }

  // ✅ バックアップ削除機能
  Future<void> _deleteBackup(String backupKey, int index) async {
    await _dependencies?.operations.backup.deleteBackup(backupKey, index);
  }





  /// メインビルドメソッド
  /// TODO: 完全移行後は、このメソッドを最小限のUIフレーム（Scaffold + TabBar + TabBarViewのみ）に削減
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // キーボード表示時のオーバーフローを防止
      appBar: AppBar(
          title: const Text(
            'サプリ＆おくすりスケジュール管理帳',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          titleSpacing: 0,
          actions: [
            HomeAppBarMenu(
              onPurchaseStatus: () => _dependencies?.handlers.main.showTrialStatus(),
              onPurchaseLink: () => _dependencies?.handlers.main.showPurchaseLinkDialog(),
              onBackup: () => _dependencies?.handlers.main.showBackupDialog(),
            ),
          ],
          bottom: _dependencies == null
              ? null
              : TabBar(
                  controller: _dependencies!.tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.calendar_month), text: 'カレンダー'),
              Tab(icon: Icon(Icons.medication), text: '服用メモ'),
              Tab(icon: Icon(Icons.alarm), text: 'アラーム'),
              Tab(icon: Icon(Icons.analytics), text: '統計'),
            ],
          ),
        ),
        body: _dependencies == null
            ? const Center(child: CircularProgressIndicator())
            : HomeTabBarView(
                stateManager: _dependencies!.stateManager,
                tabController: _dependencies!.tabController,
                onEditMemo: _editMemo,
                onDeleteMemo: _deleteMemo,
                onMarkAsTaken: _markAsTaken,
                onShowMemoDetailDialog: (context, name, notes) => _dependencies!.handlers.main.showMemoDetailDialog(name, notes),
                onShowWarningDialog: () => _dependencies!.handlers.main.showWarningDialog(),
                onCalculateAdherenceStats: () async {
                  // 遵守率を再計算（服用状況変更時に呼ばれる）
                  if (_dependencies != null) {
                    await _dependencies!.stateManager.updateAdherenceRates();
                  }
                },
            ),
      // 注意: FloatingActionButtonは各View（特にMedicineView）で個別に処理
      floatingActionButton: null,
    );
  }







}
