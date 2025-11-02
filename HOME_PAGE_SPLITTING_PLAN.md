# home_page.dart 分割計画

## 現在の状況
- **総行数**: 2,128行
- **メソッド数**: 約70個のprivateメソッド
- **主な機能領域**: バックアップ、データ操作、メモ操作、UI構築、初期化

## 分割案と削減見込み

### 1. バックアップ関連機能 → `home/helpers/backup_operations.dart`
**移動対象メソッド:**
- `_showBackupDialog()` (30行)
- `_hasUndoAvailable()` (18行)
- `_saveSnapshotBeforeChange()` (18行)
- `_undoLastChange()` (135行) - 大きなメソッド
- `_createManualBackup()` (36行)
- `_createSafeBackupData()` (16行)
- `_safeJsonEncode()` (3行)
- `_encryptDataAsync()` (3行)
- `_updateBackupHistory()` (3行)
- `_showBackupHistory()` (18行)
- `_previewBackup()` (13行)
- `_restoreBackup()` (3行)
- `_deleteBackup()` (3行)
- `_showManualRestoreDialog()` (70行)
- `_performManualRestore()` (43行)

**削減見込み**: **約350-400行**
- メソッド本体 + コメント + 空行

---

### 2. データ読み込み・保存関連 → `home/helpers/data_operations.dart`
**移動対象メソッド:**
- `_saveAllData()` (10行)
- `_saveCurrentDataDebounced()` (12行)
- `_saveCurrentData()` (7行)
- `_saveAddedMedications()` (28行)
- `_saveMedicationMemoStatus()` (7行)
- `_saveWeekdayMedicationStatus()` (7行)
- `_loadCurrentData()` (18行)
- `_loadMedicationMemoStatus()` (36行) - コメント含む
- `_loadWeekdayMedicationStatus()` (5行)
- `_loadMemo()` (11行)
- `_loadMedicationMemos()` (5行)
- `_loadMemosFromSharedPreferences()` (38行)
- `_backupMemosToSharedPreferences()` (24行)
- `_saveMedicationMemoWithBackup()` (8行)
- `_deleteMedicationMemoWithBackup()` (8行)
- `_loadMedicationMemosWithRetry()` (5行)
- `_restoreMedicationMemosFromBackup()` (3行)
- `_saveMedicationData()` (3行)
- `_loadMemoStatus()` (37行)
- `_saveMedicationDoseStatus()` (3行)
- `_saveDayColors()` (7行) - 残りの方
- `_saveCalendarMarks()`, `_loadCalendarMarks()`, `_saveUserPreferences()`, `_loadUserPreferences()`, `_loadDayColors()`, `_saveStatistics()`, `_loadStatistics()`, `_saveAppSettings()` (各3-5行、コメントのみのもの多数)

**削減見込み**: **約250-300行**
- 実装メソッド + コメントのみのメソッド削除

---

### 3. メモ操作・ヘルパー関連 → `home/helpers/medication_operations.dart`
**移動対象メソッド:**
- `_addMemo()` (3行) - 既にコントローラー経由
- `_editMemo()` (3行)
- `_markAsTaken()` (3行)
- `_deleteMemo()` (3行)
- `_showMemoDetailDialog()` (77行) - 大きなUIメソッド
- `_buildMedicationMemoCheckbox()` (46行)
- `_addToTakenMedications()` (42行)
- `_removeFromTakenMedications()` (24行)
- `_updateMedicationMemoStatus()` (8行)
- `_onDoseStatusChanged()` (19行)
- `_generateDefaultTitle()` (3行)
- `_parseTimeString()` (3行)
- `_getMedicationsForSelectedDay()` (8行)
- `_getWeekdayMedicationStatus()` (7行)
- `_updateWeekdayMedicationStatus()` (9行)
- `_getMedicationMemoStatus()` (3行)
- `_getMedicationMemoStatusForSelectedDay()` (7行)
- `_getMedicationMemoDoseStatusForSelectedDay()` (7行)
- `_getMedicationMemoCheckedCountForSelectedDay()` (11行)
- `_ensureDataDisplayOnRestart()` (11行)
- `_getMedicationRecordCount()` (4行)
- `_getEventsForDay()` (47行) - 空の実装だが残存

**削減見込み**: **約300-350行**
- メソッド実装 + UI構築メソッド

---

### 4. カレンダー・統計・UI関連 → `home/helpers/calendar_operations.dart`
**移動対象メソッド:**
- `_updateMedicineInputsForSelectedDate()` (26行)
- `_loadMemoForSelectedDate()` (17行)
- `_onDaySelected()` (3行) - 空実装
- `_addMedicationToTimeSlot()` (50行)
- `_updateCalendarMarks()` (31行)
- `_calculateMedicationStats()` (29行)
- `_saveMemo()` (11行)
- `_completeMemo()` (22行)
- `_calculateAdherenceStats()` (36行)
- `_buildWeekdayMedicationRecord()` (52行) - UIメソッド
- `_buildAddedMedicationRecordDeprecated()` (79行) - 非推奨だが残存
- `calculateDayMedicationStats` getter (13行)
- `getMedicationMemoCheckedCountForDate` getter (7行)
- `_normalizeDate()` (1行)
- `_getEventsForDay()` (47行) - 実装は空だが構造あり

**削減見込み**: **約350-400行**
- カレンダー操作 + 統計計算 + UI構築

---

### 5. アプリ内課金・ダイアログ関連 → `home/helpers/ui_helpers.dart`
**移動対象メソッド:**
- `_showTrialStatus()` (3行) - Mixin経由
- `_showWarningDialog()` (19行)
- `_showPurchaseLinkDialog()` (3行) - Mixin経由
- `_startPurchase()` (3行) - Mixin経由
- `_showSnackBar()` (20行)
- `_showLimitDialog()` (6行)
- `_loadMoreMemos()` (22行)
- `_initializeScrollListener()` (11行)
- `_canAddMemo()` (4行)

**削減見込み**: **約80-100行**

---

### 6. アラーム操作（既にコントローラー経由） → 削除可能
**削除対象:**
- `addAlarm()`, `removeAlarm()`, `updateAlarm()`, `toggleAlarm()` (各4行)
- `_checkAlarmDataIntegrity()` (3行)

**削減見込み**: **約20行**
- 既にコントローラーで処理されているため削除可能

---

### 7. 空実装・非推奨メソッドの削除
**削除対象:**
- `_saveCalendarMarks()`, `_loadCalendarMarks()` (コメントのみ)
- `_saveUserPreferences()`, `_loadUserPreferences()` (コメントのみ)
- `_loadDayColors()` (コメントのみ)
- `_saveStatistics()`, `_loadStatistics()` (コメントのみ)
- `_saveAppSettings()` (コメントのみ)
- `_loadMedicationMemoStatus()` (コメントのみ)
- `_loadWeekdayMedicationStatus()` (コメントのみ)
- `_loadMedicationMemos()` (コメントのみ)
- `_loadMedicationMemosWithRetry()` (コメントのみ)
- `_restoreMedicationMemosFromBackup()` (コメントのみ)
- `_onDaySelected()` (空実装)

**削減見込み**: **約100-120行**
- コメントのみのメソッドを削除

---

### 8. コメント・空行の整理
**削減見込み**: **約50-80行**
- 長いコメントブロック
- 不要な空行

---

## 削減見込みの合計

| カテゴリ | 削減見込み行数 |
|---------|--------------|
| バックアップ関連 | 350-400行 |
| データ読み込み・保存 | 250-300行 |
| メモ操作・ヘルパー | 300-350行 |
| カレンダー・統計・UI | 350-400行 |
| UIヘルパー | 80-100行 |
| アラーム操作 | 20行 |
| 空実装・非推奨削除 | 100-120行 |
| コメント・空行整理 | 50-80行 |
| **合計** | **1,500-1,770行** |

## 分割後の想定

### 分割後の`home_page.dart`
- **残存行数**: 約350-600行
- **主な内容**:
  - クラス定義・プロパティ
  - `initState()`, `dispose()`
  - `build()`メソッド（UIフレームのみ）
  - コントローラー呼び出し
  - Mixin実装

### 新規作成ファイル
1. `home/helpers/backup_operations.dart` (約350-400行)
2. `home/helpers/data_operations.dart` (約250-300行)
3. `home/helpers/medication_operations.dart` (約300-350行)
4. `home/helpers/calendar_operations.dart` (約350-400行)
5. `home/helpers/ui_helpers.dart` (約80-100行)

**合計新規ファイル**: 約1,330-1,550行

## メリット
1. **可読性向上**: 各ファイルが明確な責務を持つ
2. **保守性向上**: 機能ごとに分離され、変更影響範囲が明確
3. **テスト容易性**: 各ヘルパーファイルを個別にテスト可能
4. **再利用性**: 他の画面でも同じヘルパーを利用可能

## 注意点
- 既存のコントローラー（MedicationController等）との重複を避ける
- StateManagerへの依存を維持
- 既存のHelperクラスとの統合を検討

