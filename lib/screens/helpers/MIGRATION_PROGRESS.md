# home_page.dart 移行進捗

## ✅ 完了した移行

### 計算ロジック
- ✅ `_calculateDayMedicationStats()` → `MedicationStatsCalculator.calculateDayMedicationStats()`
- ✅ `_calculateAdherenceStats()` → `AdherenceCalculator.calculateCustomAdherence()`
- ✅ `_calculateCustomAdherence()` → `AdherenceCalculator.calculateCustomAdherence()`

### UIビルダー
- ✅ `_buildCalendarDay()` → `CalendarUIBuilderMixin.buildCalendarDay()`
- ✅ `_buildCalendarStyle()` → `CalendarUIBuilderMixin.buildCalendarStyle()`

### 状態管理
- ✅ `HomePageStateManager.hasDataChanged()` の使用開始

## 📋 現在の状態

- **ファイルサイズ**: 4,857行（元: 4,951行）
- **削減**: 94行（約2%削減）

## 🔄 次の移行タスク

### 優先度: 高

1. **メディケーションUIビルダーの統合**
   - `_buildMedicationMemoCheckbox()` を `MedicationUIBuilderMixin` に移行
   - `_buildMedicationRecords()` を `MedicationUIBuilderMixin` に移行

2. **イベントハンドラーの追加**
   - `_onDoseStatusChanged()` メソッドの実装確認と追加

### 優先度: 中

3. **タブビルダーの分離**
   - `_buildCalendarTab()` → `ui_builders/tabs/calendar_tab_builder.dart`
   - `_buildMedicineTab()` → `ui_builders/tabs/medicine_tab_builder.dart`
   - `_buildAlarmTab()` → `ui_builders/tabs/alarm_tab_builder.dart`
   - `_buildStatsTab()` → `ui_builders/tabs/stats_tab_builder.dart`

4. **データ操作のさらなる分離**
   - 各`_load*`メソッドの統合
   - 各`_save*`メソッドの統合

## ⚠️ 注意事項

- ミックスインのプロパティアクセサが正しく実装されているか確認
- 既存の機能が壊れていないかテスト
- 段階的に移行を進める

