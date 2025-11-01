# home_page.dart 分割ガイド

## 📁 作成されたヘルパーファイル

### UIビルダー (`ui_builders/`)
- ✅ `calendar_ui_builder.dart` - カレンダー関連のUI構築
  - `buildCalendarDay()` - カレンダー日付セルの構築
  - `buildCalendarStyle()` - カレンダースタイルの構築

- ✅ `medication_ui_builder.dart` - メディケーション関連のUI構築
  - `buildMedicationMemoCheckbox()` - メモチェックボックスの構築
  - `buildMedicationRecords()` - 服用記録リストの構築

### 計算ロジック (`calculations/`)
- ✅ `medication_stats_calculator.dart` - メディケーション統計計算
  - `calculateDayMedicationStats()` - 日別統計
  - `calculateSelectedDayStats()` - 選択日統計
  - `getMedicationMemoCheckedCount()` - チェック数取得

- ✅ `adherence_calculator.dart` - 遵守率計算
  - `calculateCustomAdherence()` - カスタム遵守率
  - `calculatePeriodAdherence()` - 期間別遵守率
  - `calculateMemoAdherence()` - メモ別遵守率

### 状態管理 (`state_management/`)
- ✅ `home_page_state_manager.dart` - 状態管理ヘルパー
  - `hasDataChanged()` - データ変更チェック
  - `resetChangeFlags()` - 変更フラグリセット

## 🔄 使用方法

### オプション1: ミックスイン方式（推奨）

```dart
class _MedicationHomePageState extends State<MedicationHomePage>
    with TickerProviderStateMixin,
         PurchaseMixin,
         CalendarUIBuilderMixin,
         MedicationUIBuilderMixin {
  
  // ミックスインで必要な変数をプロパティとして公開
  @override
  List<MedicationMemo> get medicationMemos => _medicationMemos;
  
  // 使用例
  Widget _buildCalendarDay(DateTime day) {
    return buildCalendarDay(day); // ミックスインのメソッドを使用
  }
}
```

### オプション2: 静的ヘルパー方式

```dart
// 統計計算の例
final stats = MedicationStatsCalculator.calculateDayMedicationStats(
  day: selectedDay,
  medicationData: _medicationData,
  medicationMemos: _medicationMemos,
  getMedicationMemoCheckedCountForDate: _getMedicationMemoCheckedCountForDate,
);

// 遵守率計算の例
final adherenceRate = AdherenceCalculator.calculateCustomAdherence(
  days: 30,
  medicationData: _medicationData,
  medicationMemos: _medicationMemos,
  weekdayMedicationStatus: _weekdayMedicationStatus,
  medicationMemoStatus: _medicationMemoStatus,
  getMedicationMemoCheckedCountForDate: _getMedicationMemoCheckedCountForDate,
);
```

## 📋 移行手順

1. **段階的移行**
   - まず1つのメソッドを新しいヘルパーに移行
   - 動作確認後、次のメソッドへ

2. **テスト**
   - 各移行ステップでテストを実行
   - エラーが発生した場合は即座にロールバック

3. **完了確認**
   - すべての機能が正常に動作することを確認
   - パフォーマンステストを実行

## 🎯 次のステップ

1. `home_page.dart`で新しいヘルパーをインポート
2. 既存のメソッドを段階的に置き換え
3. 不要になったコードを削除
4. ファイルサイズを確認（目標: 500行以下）

