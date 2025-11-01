# home_page.dart ファイル分割サマリー

## 📊 現在の状況

- **元の行数**: 4,946行
- **分割後の目標**: 各ファイル200-500行程度

## ✅ 作成したヘルパーファイル

### 1. `home_page_data_operations.dart`
- **目的**: データのロード・保存操作を分離
- **メソッド**:
  - `loadCurrentData()` - 現在のデータ読み込み
  - `loadMedicationMemoStatus()` - 服用メモ状態読み込み
  - `loadWeekdayMedicationStatus()` - 曜日メディケーション状態読み込み
  - `loadMemo()` - メモ読み込み
  - `saveMedicationMemoStatus()` - 服用メモ状態保存
  - `saveWeekdayMedicationStatus()` - 曜日メディケーション状態保存
  - `saveAddedMedications()` - 追加メディケーション保存
  - `saveCalendarMarks()` / `loadCalendarMarks()` - カレンダーマーク
  - `saveDayColors()` / `loadDayColors()` - 日付色

### 2. `home_page_dialogs.dart`
- **目的**: ダイアログ表示メソッドを分離
- **メソッド**:
  - `showColorPickerDialog()` - カラーピッカーダイアログ
  - `showCustomAdherenceDialog()` - カスタム遵守率ダイアログ
  - `showWarningDialog()` - 警告ダイアログ

### 3. `home_page_event_handlers.dart`
- **目的**: イベントハンドラーメソッドを分離
- **メソッド**:
  - `onDaySelected()` - 日付選択イベント
  - `onScrollToTop()` - スクロール上端
  - `onScrollToBottom()` - スクロール下端
  - `_normalizeDate()` - 日付正規化

## 🔄 実装方針

### 段階的移行アプローチ

1. **Phase 1（完了）**: ヘルパーファイルの作成と拡張メソッドの定義
2. **Phase 2（進行中）**: 既存メソッドを段階的にヘルパーへ移行
3. **Phase 3（将来）**: 完全にヘルパークラスに移行し、元のメソッドを削除

### 注意事項

- プライベートメンバー（`_`で始まる変数）へのアクセス制限のため、
  現時点では元の実装を保持し、段階的に移行
- 拡張メソッドは将来的に完全移行のための準備として機能
- 後方互換性を保つため、既存のメソッド名を維持

## 📝 次のステップ

### UIビルダーの分離
- `_buildCalendarTab()` → `home_page_ui_builders.dart`
- `_buildMedicineTab()` → `home_page_ui_builders.dart`
- `_buildAlarmTab()` → `home_page_ui_builders.dart`
- `_buildStatsTab()` → `home_page_ui_builders.dart`
- その他の`_build*`メソッド

### 計算・ユーティリティの分離
- `_calculateAdherenceStats()` → `home_page_calculations.dart`
- `_calculateCustomAdherence()` → `home_page_calculations.dart`
- その他の計算メソッド

## 🎯 目標

最終的に`home_page.dart`を以下のような構造に：
- メインクラス定義（100-200行）
- 状態変数定義（100-200行）
- ライフサイクルメソッド（100-200行）
- ヘルパークラスへの委譲（最小限）

合計: 500行以下を目標

