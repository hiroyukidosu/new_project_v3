# HomePage完全移行：コード削減分析

## 現在の状態

### ファイルサイズ
- **現在**: 3,840行
- **目標**: 約150行（最小限のUIフレーム）

### 削減予定: 約3,690行（96.1%削減）

---

## カテゴリ別削減分析

### 1. 状態変数（約200行 → 0行）
**削減**: 200行

削除できる変数群：
- `_focusedDay`, `_selectedDay`, `_selectedDates`
- `_medicationMemos`, `_medicationData`, `_adherenceRates`
- `_medicationMemoStatus`, `_weekdayMedicationStatus`
- `_weekdayMedicationDoseStatus`, `_addedMedications`
- `_dayColors`, `_alarmList`, `_alarmSettings`
- 各種Controller（`_memoController`, `_customDaysController`など）
- 各種ScrollController
- 各種Notifier

**移行先**: `HomePageStateManager`

---

### 2. データ読み込みメソッド（約800行 → 0行）
**削減**: 800行

削除できるメソッド：
- `_loadSavedData()` (約30行)
- `_loadAllData()` (約50行)
- `_loadMedicationData()` (約20行)
- `_loadMedicationList()` (約50行)
- `_loadAlarmData()` (約20行)
- `_loadMedicationMemos()` (約50行)
- `_loadMedicationMemosWithRetry()` (約100行)
- `_loadMedicationMemoStatus()` (約30行)
- `_loadWeekdayMedicationStatus()` (約30行)
- `_loadMemoStatus()` (約50行)
- `_loadCalendarMarks()` (約20行)
- `_loadUserPreferences()` (約30行)
- `_loadDayColors()` (約20行)
- `_loadStatistics()` (約20行)
- `_loadMedicationDoseStatus()` (約20行)
- `_loadAppSettings()` (約10行)
- `_loadCurrentData()` (約30行)
- `_loadMemo()` (約20行)
- `_loadMemoForSelectedDate()` (約30行)
- `_updateMedicineInputsForSelectedDate()` (約30行)
- `_restoreMedicationMemosFromBackup()` (約70行)
- `_initializeAsync()` (約25行)
- `_loadHeavyData()` (約25行)
- `_reRegisterAlarms()` (約50行)
- `_registerSingleAlarm()` (約100行)
- その他検証・テストメソッド (約150行)

**移行先**: `HomePageStateManager.init()` / `persistence/`クラス

---

### 3. データ保存メソッド（約600行 → 0行）
**削減**: 600行

削除できるメソッド：
- `_saveAllData()` (約40行)
- `_saveCurrentData()` (約50行)
- `_saveCurrentDataDebounced()` (約10行)
- `_saveMedicationData()` (約60行)
- `_saveMedicationList()` (約50行)
- `_saveMedicationMemoStatus()` (約30行)
- `_saveWeekdayMedicationStatus()` (約30行)
- `_saveMedicationDoseStatus()` (約20行)
- `_saveAddedMedications()` (約30行)
- `_saveCalendarMarks()` (約20行)
- `_saveUserPreferences()` (約30行)
- `_saveDayColors()` (約20行)
- `_saveStatistics()` (約20行)
- `_saveAppSettings()` (約20行)
- `_saveMemo()` (約30行)
- `_saveMemoStatus()` (約40行)
- `_saveToSharedPreferences()` (約30行)
- `_saveAdditionalBackup()` (約30行)
- `_saveAlarmData()` (約10行)
- `_saveMedicationMemoWithBackup()` (約30行)
- `_backupMemosToSharedPreferences()` (約30行)
- その他バックアップ関連 (約150行)

**移行先**: `HomePageStateManager.saveAllData()` / `persistence/`クラス

---

### 4. UIビルダーメソッド（約1,200行 → 0行）
**削減**: 1,200行

削除できるメソッド：
- `_buildCalendarTab()` (約50行) → `tabs/calendar_tab.dart`に移行済み
- `_buildMedicineTab()` (約30行) → `tabs/medicine_tab.dart`に移行済み
- `_buildStatsTab()` (約40行) → `tabs/stats_tab.dart`に移行済み
- `_buildAlarmTab()` (約10行) → `tabs/alarm_tab.dart`に移行済み
- `_buildCalendarDay()` (約10行) → `helpers/ui_builders/`に移行済み
- `_buildCalendarStyle()` (約50行) → `helpers/ui_builders/`に移行済み
- `_buildMemoField()` (約100行) → `home/widgets/memo_field.dart`に移行済み
- `_buildMedicationStats()` (約100行) → `home/widgets/medication_stats_card.dart`に移行済み
- `_buildMedicationRecords()` (約150行) → `home/widgets/medication_record_list.dart`に移行済み
- `_buildMedicationItem()` (約80行) → `home/widgets/medication_item_widgets.dart`に移行済み
- `_buildMedicationMemoCheckbox()` (約100行) → `home/widgets/expanded_medication_memo_checkbox.dart`に移行済み
- `_buildNoMedicationMessage()` (約20行) → `home/widgets/`に移行済み
- `_buildAddedMedicationRecord()` (約150行) → `home/widgets/`に移行済み
- `_buildAdherenceChart()` (約10行) → `helpers/home_page_stats_helper.dart`に移行済み
- `_buildMedicationUsageChart()` (約20行) → `helpers/home_page_stats_helper.dart`に移行済み
- `_getEventsForDay()` (約200行) → `helpers/ui_builders/`に移行
- その他UI関連 (約200行)

**移行先**: 既に各ウィジェットファイルに分割済み

---

### 5. イベントハンドラー（約400行 → 0行）
**削減**: 400行

削除できるメソッド：
- `_onDaySelected()` (約80行) → `home/handlers/calendar_event_handler.dart`に移行
- `_onDoseStatusChanged()` (約20行) → `home/handlers/medication_event_handler.dart`に移行
- `_changeDayColor()` (約30行) → `home/handlers/calendar_event_handler.dart`に移行
- `_addMemo()` (約20行) → タブ側で直接`StateManager`を使用
- `_editMemo()` (約30行) → タブ側で直接`StateManager`を使用
- `_deleteMemo()` (約30行) → タブ側で直接`StateManager`を使用
- `_markAsTaken()` (約30行) → タブ側で直接`StateManager`を使用
- `_showColorPickerDialog()` (約70行) → `home/widgets/day_color_picker_dialog.dart`に移行済み
- `_showMemoDetailDialog()` (約80行) → `home/widgets/dialogs/`に移行
- `_showWarningDialog()` (約20行) → `home/widgets/dialogs/warning_dialog.dart`に移行済み
- `_showCustomAdherenceDialog()` (約70行) → `home/widgets/dialogs/custom_adherence_dialog.dart`に移行済み
- その他ダイアログ (約50行)

**移行先**: `home/handlers/` / タブ側で直接`StateManager`使用

---

### 6. バックアップ関連（約300行 → 0行）
**削減**: 300行

削除できるメソッド：
- `_createSafeBackupData()` (約20行) → `HomePageBackupHelper`に移行済み
- `_safeJsonEncode()` (約10行) → `HomePageBackupHelper`に移行済み
- `_encryptDataAsync()` (約10行) → `HomePageBackupHelper`に移行済み
- `_showBackupDialog()` (約50行) → `home/widgets/dialogs/backup_dialog.dart`に移行済み
- `_showBackupHistory()` (約30行) → `home/widgets/dialogs/backup_history_dialog.dart`に移行済み
- `_previewBackup()` (約30行) → `home/widgets/dialogs/backup_preview_dialog.dart`に移行済み
- `_restoreBackup()` (約20行) → `home/handlers/backup_handler.dart`に移行済み
- `_deleteBackup()` (約10行) → `home/handlers/backup_handler.dart`に移行済み
- `_createManualBackup()` (約60行) → `home/handlers/backup_handler.dart`に移行済み
- `_showManualRestoreDialog()` (約70行) → `home/handlers/backup_handler.dart`に移行
- `_performManualRestore()` (約60行) → `home/handlers/backup_handler.dart`に移行
- `_updateBackupHistory()` (約10行) → `home/handlers/backup_handler.dart`に移行済み

**移行先**: 既に`home/handlers/backup_handler.dart`とダイアログに分割済み

---

### 7. ビジネスロジック（約200行 → 0行）
**削減**: 200行

削除できるメソッド：
- `_calculateDayMedicationStats()` (約20行) → `helpers/calculations/medication_stats_calculator.dart`に移行済み
- `_calculateAdherenceStats()` (約30行) → `home/business/`に移行
- `_calculateCustomAdherence()` (約40行) → `helpers/calculations/adherence_calculator.dart`に移行済み
- `_getMedicationMemoCheckedCountForDate()` (約10行) → `home/business/medication_calculator.dart`に移行
- `_getMedicationMemoCheckedCountForSelectedDay()` (約20行) → `home/business/medication_calculator.dart`に移行
- `_getMedicationMemoDoseStatusForSelectedDay()` (約20行) → `home/business/medication_calculator.dart`に移行
- `_getMedicationMemoStatusForSelectedDay()` (約20行) → `home/business/medication_calculator.dart`に移行
- `_getMedicationMemoStatus()` (約10行) → `home/business/medication_calculator.dart`に移行
- `_getMedicationsForSelectedDay()` (約30行) → `home/business/calendar_marker_manager.dart`に移行

**移行先**: `helpers/calculations/` / `home/business/`

---

### 8. ヘルパーメソッド（約150行 → 0行）
**削減**: 150行

削除できるメソッド：
- `_normalizeDate()` (約5行) → `HomePageStateManager`に移行済み
- `_getMedicationListLength()` (約10行) → `home/business/pagination_manager.dart`に移行
- `_updateCalendarMarks()` (約30行) → `home/business/calendar_marker_manager.dart`に移行
- `_showSnackBar()` (約30行) → 共通ヘルパーに移行
- `_setupControllerListeners()` (約10行) → 削除可能
- `_initializeScrollListener()` (約20行) → タブ側で管理
- `_canAddMemo()` (約10行) → `home/business/`に移行
- `_showLimitDialog()` (約20行) → `home/widgets/dialogs/warning_dialog.dart`に移行済み
- `_addToTakenMedications()` (約40行) → `home/handlers/medication_event_handler.dart`に移行
- `_removeFromTakenMedications()` (約30行) → `home/handlers/medication_event_handler.dart`に移行
- `_updateMedicationMemoStatus()` (約15行) → `home/handlers/medication_event_handler.dart`に移行
- その他ユーティリティ (約20行)

**移行先**: 各ハンドラー/ビジネスロジック/ヘルパー

---

### 9. 検証・テストメソッド（約200行 → 0行）
**削減**: 200行

削除できるメソッド：
- `_validateAndUpdateUI()` (約40行)
- `_finalDataDisplayCheck()` (約20行)
- `_validateDataIntegrity()` (約30行)
- `_updateCalendarForSelectedDate()` (約10行)
- `_updateMedicationMemoDisplay()` (約10行)
- `_testDataPersistence()` (約30行)
- `_validateAlarmData()` (約20行)
- `_checkAlarmDataIntegrity()` (約40行)
- その他 (約0行)

**移行先**: 削除またはテストファイルに移動

---

### 10. initState/dispose（約150行 → 約30行）
**削減**: 120行

現在の`initState`: 約150行
完全移行後: 約30行（StateManagerの初期化のみ）

現在の`dispose`: 約50行
完全移行後: 約10行（StateManagerのクリーンアップのみ）

---

### 11. buildメソッド（約200行 → 約80行）
**削減**: 120行

現在の`build`: 約200行
完全移行後: 約80行（Scaffold + TabBar + TabBarViewのみ）

---

## 総合削減見積もり

| カテゴリ | 現在 | 完全移行後 | 削減数 |
|---------|------|-----------|--------|
| 状態変数 | 200行 | 0行 | **200行** |
| データ読み込み | 800行 | 0行 | **800行** |
| データ保存 | 600行 | 0行 | **600行** |
| UIビルダー | 1,200行 | 0行 | **1,200行** |
| イベントハンドラー | 400行 | 0行 | **400行** |
| バックアップ関連 | 300行 | 0行 | **300行** |
| ビジネスロジック | 200行 | 0行 | **200行** |
| ヘルパーメソッド | 150行 | 0行 | **150行** |
| 検証・テスト | 200行 | 0行 | **200行** |
| initState/dispose | 200行 | 40行 | **160行** |
| buildメソッド | 200行 | 80行 | **120行** |
| その他（コメント等） | 190行 | 30行 | **160行** |
| **合計** | **3,840行** | **150行** | **3,690行** |

---

## 削減率

- **削減行数**: 3,690行
- **削減率**: **96.1%**
- **残存行数**: 150行（最小限のUIフレーム）

---

## 完全移行後のhome_page.dart構造

```dart
// 約150行の最小限のUIフレーム

class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});
  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}

class _MedicationHomePageState extends State<MedicationHomePage> 
    with TickerProviderStateMixin, PurchaseMixin {
  
  late final TabController _tabController;
  late final HomePageStateManager _stateManager;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _stateManager = HomePageStateManager(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _stateManager.init();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _stateManager.isInitialized
          ? TabBarView(
              controller: _tabController,
              children: [
                CalendarTab(stateManager: _stateManager),
                MedicineTab(stateManager: _stateManager),
                AlarmTab(stateManager: _stateManager),
                StatsTab(stateManager: _stateManager),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () => _stateManager.addMemo(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('サプリ＆おくすりスケジュール管理帳'),
      actions: [_buildMenu()],
      bottom: TabBar(controller: _tabController, tabs: _tabs),
    );
  }

  Widget _buildMenu() { /* メニュー */ }
  
  final List<Tab> _tabs = [ /* タブ定義 */ ];
}
```

---

## メリット

1. **保守性**: バグ修正が1ファイルで完結
2. **可読性**: 1ファイル150行以下で理解しやすい
3. **テスト**: 計算ロジックは単体テスト可能
4. **再利用**: ウィジェットを別画面でも使用可能
5. **コラボ**: 複数人で並行開発可能

---

## 結論

完全移行により、**3,840行 → 150行**（**96.1%削減**）を実現できます。

これにより、`home_page.dart`は最小限のUIフレームとなり、すべてのロジックは適切に分割されたファイルに配置されます。

