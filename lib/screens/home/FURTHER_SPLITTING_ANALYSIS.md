# home_page.dart さらなる分割分析レポート

## 現在のファイルサイズ
- **現在**: 4,533行
- **目標**: 200行以下（最終目標）
- **削減必要**: 約4,333行

---

## 分割候補と削減見込み（優先度順）

### 🔴 優先度：高（すぐに分離すべきもの）

#### 1. **バックアップ機能群** - 約650-800行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_showBackupDialog()` | 85行 | `widgets/dialogs/backup_dialog.dart` | バックアップメインダイアログ |
| `_createManualBackup()` | 100行 | `handlers/backup_handler.dart` | 手動バックアップ作成 |
| `_performBackup()` | 120行 | `handlers/backup_handler.dart` | バックアップ実行 |
| `_showBackupHistory()` | 142行 | `widgets/dialogs/backup_history_dialog.dart` | バックアップ履歴表示 |
| `_previewBackup()` | 48行 | `widgets/dialogs/backup_preview_dialog.dart` | バックアッププレビュー |
| `_restoreBackup()` | 68行 | `handlers/backup_handler.dart` | バックアップ復元 |
| `_deleteBackup()` | 198行 | `handlers/backup_handler.dart` | バックアップ削除 |
| `_restoreDataAsync()` | 52行 | `handlers/backup_handler.dart` | データ復元処理 |
| `_updateBackupHistory()` | 3行 | `handlers/backup_handler.dart` | 履歴更新 |

**合計削減**: 約816行

---

#### 2. **データ永続化メソッド群（残存）** - 約350-450行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_loadSavedData()` | 37行 | `persistence/data_loader.dart` | データ読み込み統合 |
| `_saveAllData()` | 60行 | `persistence/data_saver.dart` | データ保存統合（DataSyncManagerと統合可能） |
| `_loadAllData()` | 47行 | `persistence/data_loader.dart` | 全データ読み込み |
| `_loadMedicationData()` | 18行 | `persistence/data_loader.dart` | 服用データ読み込み |
| `_loadMedicationList()` | 7行 | `persistence/data_loader.dart` | 薬品リスト読み込み |
| `_loadAlarmData()` | 6行 | `persistence/data_loader.dart` | アラームデータ読み込み |
| `_loadCalendarMarks()` | 5行 | `persistence/data_loader.dart` | カレンダーマーク読み込み |
| `_loadStatistics()` | 5行 | `persistence/data_loader.dart` | 統計データ読み込み |
| `_saveMedicationData()` | 53行 | `persistence/data_saver.dart` | 服用データ保存 |
| `_saveMedicationList()` | 30行 | `persistence/data_saver.dart` | 薬品リスト保存 |
| `_saveAdditionalBackup()` | 23行 | `persistence/data_saver.dart` | 追加バックアップ |
| `_saveToSharedPreferences()` | 15行 | `persistence/data_saver.dart` | SharedPreferences保存 |
| `_saveMemoStatus()` | 19行 | `persistence/data_saver.dart` | メモ状態保存 |
| `_loadMemoStatus()` | 35行 | `persistence/data_loader.dart` | メモ状態読み込み |
| `_saveCalendarMarks()` | 5行 | `persistence/data_saver.dart` | カレンダーマーク保存 |
| `_saveStatistics()` | 5行 | `persistence/data_saver.dart` | 統計データ保存 |
| `_validateAndUpdateUI()` | 37行 | `persistence/data_validator.dart` | データ検証 |
| `_validateDataIntegrity()` | 5行 | `persistence/data_validator.dart` | データ整合性チェック |

**合計削減**: 約413行

---

#### 3. **ダイアログメソッド群** - 約250-300行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_showColorPickerDialog()` | 67行 | `widgets/dialogs/color_picker_dialog.dart` | 色選択ダイアログ |
| `_showMemoDetailDialog()` | 74行 | `widgets/dialogs/memo_detail_dialog.dart` | メモ詳細ダイアログ |
| `_showManualRestoreDialog()` | 70行 | `widgets/dialogs/manual_restore_dialog.dart` | 手動復元ダイアログ |

**合計削減**: 約211行

---

### 🟡 優先度：中（次に分離すべきもの）

#### 4. **アラーム関連メソッド群** - 約200-250行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_reRegisterAlarms()` | 13行 | `handlers/alarm_handler.dart` | アラーム再登録 |
| `_registerSingleAlarm()` | 98行 | `handlers/alarm_handler.dart` | 単一アラーム登録 |
| `_validateAlarmData()` | 5行 | `handlers/alarm_handler.dart` | アラームデータ検証 |
| `_checkAlarmDataIntegrity()` | 31行 | `handlers/alarm_handler.dart` | アラーム整合性チェック |

**合計削減**: 約147行

---

#### 5. **タブビルダーメソッド群** - 約150-200行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_buildCalendarTab()` | 34行 | `widgets/tabs/calendar_tab_content.dart` | カレンダータブ |
| `_buildMedicineTab()` | 11行 | `widgets/tabs/medicine_tab_content.dart` | 薬品タブ |
| `_buildAlarmTab()` | 5行 | `widgets/tabs/alarm_tab_content.dart` | アラームタブ |
| `_buildStatsTab()` | 17行 | `widgets/tabs/stats_tab_content.dart` | 統計タブ |

**合計削減**: 約67行

---

#### 6. **統計関連UIメソッド群** - 約150-200行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_buildCustomAdherenceCard()` | 90行 | `widgets/stats/custom_adherence_card.dart` | カスタム遵守率カード |
| `_showCustomAdherenceDialog()` | 10行 | `widgets/dialogs/custom_adherence_dialog.dart` | （既存） |
| `_calculateCustomAdherence()` | 38行 | `business/statistics_calculator.dart` | カスタム遵守率計算 |

**合計削減**: 約138行

---

### 🟢 優先度：低（最終的に分離すべきもの）

#### 7. **メモフィールド関連** - 約200-250行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_buildMemoField()` | 187行 | `widgets/memo_field.dart` | （既存だが実装を完全に移動） |
| `_saveMemo()` | 9行 | `persistence/memo_persistence.dart` | メモ保存 |
| `_completeMemo()` | 15行 | `handlers/memo_handler.dart` | メモ完了処理 |

**合計削減**: 約211行

---

#### 8. **メモチェックボックスUI** - 約260行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_buildMedicationMemoCheckbox()` | 260行 | `widgets/medication_memo_checkbox.dart` | メモチェックボックス（大規模） |

**合計削減**: 約260行

---

#### 9. **その他のUIビルダー** - 約150-200行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_buildAddedMedicationRecord()` | 76行 | `widgets/medication_item_widgets.dart` | （既存だが統合） |
| `_buildWeekdayMedicationRecord()` | 52行 | `widgets/medication_item_widgets.dart` | （既存だが統合） |
| `_buildMedicationRecords()` | 259行 | `widgets/medication_record_list.dart` | （既存だが統合） |
| `_buildMedicationItem()` | 42行 | `widgets/medication_item_widgets.dart` | （既存だが統合） |

**合計削減**: 約429行（既存ウィジェットに統合済みの可能性）

---

#### 10. **ユーティリティメソッド** - 約100-150行削減見込み
| メソッド名 | 行数 | 新規ファイル | 備考 |
|-----------|------|-------------|------|
| `_updateCalendarForSelectedDate()` | 8行 | `handlers/calendar_handler.dart` | （既存に統合可能） |
| `_updateMedicationMemoDisplay()` | 8行 | `handlers/medication_handler.dart` | （既存に統合可能） |
| `_updateCalendarMarks()` | 165行 | `business/calendar_marker_manager.dart` | （既存に統合可能） |
| `_updateMedicineInputsForSelectedDate()` | 31行 | `handlers/medication_handler.dart` | （既存に統合可能） |
| `_loadMemoForSelectedDate()` | 18行 | `handlers/memo_handler.dart` | （既存に統合可能） |
| `_onScrollToTop()` | 6行 | `widgets/common/scroll_helpers.dart` | スクロールヘルパー |
| `_onScrollToBottom()` | 10行 | `widgets/common/scroll_helpers.dart` | スクロールヘルパー |
| `_showTopNavigationHint()` | 10行 | `widgets/common/hint_widgets.dart` | ヒント表示 |

**合計削減**: 約256行

---

## 総合削減見込み

### 優先度別

| 優先度 | 削減見込み行数 | ファイル数 |
|--------|---------------|-----------|
| **高** | 1,480行 | 約15ファイル |
| **中** | 545行 | 約10ファイル |
| **低** | 1,156行 | 約12ファイル |
| **合計** | **3,181行** | **約37ファイル** |

---

## 削減後の見込みファイルサイズ

- 現在の `home_page.dart` 行数: **4,533行**
- 削減見込み: **3,181行**
- 削減後の目標行数: 約 **1,352行**（最終目標200行にはまだ遠いが、大幅な改善）

---

## 推奨される分割順序

### フェーズ1: 高優先度（即座に実施）
1. バックアップ機能群の分離（約816行削減）
2. データ永続化メソッド群の残存分離（約413行削減）
3. ダイアログメソッド群の分離（約211行削減）

**フェーズ1合計**: 約1,440行削減

### フェーズ2: 中優先度
4. アラーム関連メソッド群の分離（約147行削減）
5. タブビルダーメソッド群の分離（約67行削減）
6. 統計関連UIメソッド群の分離（約138行削減）

**フェーズ2合計**: 約352行削減

### フェーズ3: 低優先度
7. メモフィールド関連の完全分離（約211行削減）
8. メモチェックボックスUIの分離（約260行削減）
9. その他のUIビルダーの統合（約429行削減）
10. ユーティリティメソッドの統合（約256行削減）

**フェーズ3合計**: 約1,156行削減

---

## 最終目標達成のための追加提案

目標200行以下を達成するには、さらに以下を検討：

1. **状態管理の完全分離**
   - すべての状態変数を`home_page_state.dart`に移動
   - 状態更新ロジックを`state_notifier`に移動

2. **イベントハンドラーの拡張**
   - すべてのイベント処理を既存のハンドラーに統合

3. **UIビルダーの完全分離**
   - すべての`_build*`メソッドを専用ウィジェットに移動

4. **ライフサイクル管理の分離**
   - `initState`, `dispose`, `didChangeAppLifecycleState`を専用クラスに移動

---

作成日: 2024年
最終更新: 現在

