# home_page.dart 分割計画

## 📊 現状分析

- **現在の行数**: 4,946行
- **目標行数**: 500行以下

## 🎯 分割戦略

### Phase 1: ヘルパーファイルの作成（完了 ✅）
- ✅ `home_page_data_operations.dart` - データ操作
- ✅ `home_page_dialogs.dart` - ダイアログ表示
- ✅ `home_page_event_handlers.dart` - イベントハンドラー

### Phase 2: さらに細分化（進行中）

#### 2.1 UIビルダーの分離
主要な`_build*`メソッド：
- `_buildCalendarTab()` → `ui_builders/calendar_builder.dart`
- `_buildMedicineTab()` → `ui_builders/medicine_builder.dart`
- `_buildAlarmTab()` → `ui_builders/alarm_builder.dart`
- `_buildStatsTab()` → `ui_builders/stats_builder.dart`
- `_buildCalendarDay()` → `ui_builders/calendar_day_builder.dart`
- `_buildMedicationRecords()` → `ui_builders/medication_records_builder.dart`
- `_buildMedicationMemoCheckbox()` → `ui_builders/memo_checkbox_builder.dart`
- `_buildMemoField()` → `ui_builders/memo_field_builder.dart`

#### 2.2 計算・ユーティリティの分離
- `_calculateAdherenceStats()` → `calculations/adherence_calculator.dart`
- `_calculateCustomAdherence()` → `calculations/adherence_calculator.dart`
- `_calculateDayMedicationStats()` → `calculations/day_stats_calculator.dart`
- `_normalizeDate()` → `utils/date_utils.dart`

#### 2.3 データ永続化の分離
既存の多くの`_load*`と`_save*`メソッド：
- これらは既に`home_page_data_operations.dart`に定義済み
- 段階的に移行を進める

## 🔄 実装アプローチ

### オプション1: ミックスイン方式（推奨）
```dart
mixin HomePageDataOperationsMixin on _MedicationHomePageState {
  Future<void> loadCurrentData() async { ... }
}
```

### オプション2: コンポジション方式
```dart
class _MedicationHomePageState {
  final _dataOperations = HomePageDataOperations();
  final _dialogs = HomePageDialogs();
}
```

### オプション3: 静的ヘルパー方式
```dart
class HomePageHelpers {
  static Future<void> loadData(_MedicationHomePageState state) async { ... }
}
```

## 📝 推奨事項

現在の実装では**オプション1（ミックスイン）**または**オプション3（静的ヘルパー）**を推奨：
- プライベートメンバーへのアクセスが容易
- 既存コードへの影響が最小限
- 段階的移行が可能

## 🚀 次のアクション

1. ミックスイン方式に変更
2. UIビルダーを個別ファイルに分離
3. 計算ロジックを分離
4. 段階的に元のメソッドを置き換え

