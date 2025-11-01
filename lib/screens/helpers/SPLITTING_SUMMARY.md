# home_page.dart 分割サマリー

## 📊 現在の状態

- **元のファイル**: `home_page.dart` - 4,951行
- **目標**: 500行以下まで削減

## ✅ 作成されたヘルパーファイル

### 1. UIビルダー (`ui_builders/`)
| ファイル | 行数 | 説明 |
|---------|------|------|
| `calendar_ui_builder.dart` | ~170行 | カレンダー関連UI構築 |
| `medication_ui_builder.dart` | ~150行 | メディケーション関連UI構築 |

### 2. 計算ロジック (`calculations/`)
| ファイル | 行数 | 説明 |
|---------|------|------|
| `medication_stats_calculator.dart` | ~100行 | メディケーション統計計算 |
| `adherence_calculator.dart` | ~130行 | 遵守率計算ロジック |

### 3. 状態管理 (`state_management/`)
| ファイル | 行数 | 説明 |
|---------|------|------|
| `home_page_state_manager.dart` | ~40行 | 状態管理ヘルパー |

### 4. 既存ヘルパー
- `home_page_data_operations.dart` - データ操作
- `home_page_dialogs.dart` - ダイアログ表示
- `home_page_event_handlers.dart` - イベントハンドラー
- `home_page_stats_helper.dart` - 統計ヘルパー
- `home_page_alarm_helper.dart` - アラームヘルパー
- `home_page_backup_helper.dart` - バックアップヘルパー
- `home_page_data_helper.dart` - データヘルパー
- `home_page_utils_helper.dart` - ユーティリティヘルパー
- `home_page_ui_builders.dart` - UIビルダーヘルパー

## 🎯 分割の効果

### 削減見込み
- UIビルダー分離: ~300行削減
- 計算ロジック分離: ~400行削減
- 合計見込み削減: ~700行

### 残り見込み行数
- 現在: 4,951行
- 削減後: ~4,250行（さらに分割が必要）

## 📋 次のステップ

### Phase 3: さらなる分割（推奨）

1. **タブビルダーの分離**
   - `_buildCalendarTab()` → `ui_builders/tabs/calendar_tab_builder.dart`
   - `_buildMedicineTab()` → `ui_builders/tabs/medicine_tab_builder.dart`
   - `_buildAlarmTab()` → `ui_builders/tabs/alarm_tab_builder.dart`
   - `_buildStatsTab()` → `ui_builders/tabs/stats_tab_builder.dart`

2. **データ操作のさらなる分離**
   - 各`_load*`メソッド → `data_operations/loaders/`
   - 各`_save*`メソッド → `data_operations/savers/`

3. **イベントハンドラーの分離**
   - カレンダーイベント → `event_handlers/calendar_handlers.dart`
   - メディケーションイベント → `event_handlers/medication_handlers.dart`
   - アラームイベント → `event_handlers/alarm_handlers.dart`

## 💡 使用例

```dart
// home_page.dartでの使用例
import 'helpers/ui_builders/calendar_ui_builder.dart';
import 'helpers/calculations/medication_stats_calculator.dart';
import 'helpers/calculations/adherence_calculator.dart';

class _MedicationHomePageState extends State<MedicationHomePage>
    with TickerProviderStateMixin,
         PurchaseMixin,
         CalendarUIBuilderMixin {
  
  // 統計計算の例
  Map<String, int> _calculateDayStats(DateTime day) {
    return MedicationStatsCalculator.calculateDayMedicationStats(
      day: day,
      medicationData: _medicationData,
      medicationMemos: _medicationMemos,
      getMedicationMemoCheckedCountForDate: _getMedicationMemoCheckedCountForDate,
    );
  }
  
  // 遵守率計算の例
  double _calculateAdherence(int days) {
    return AdherenceCalculator.calculateCustomAdherence(
      days: days,
      medicationData: _medicationData,
      medicationMemos: _medicationMemos,
      weekdayMedicationStatus: _weekdayMedicationStatus,
      medicationMemoStatus: _medicationMemoStatus,
      getMedicationMemoCheckedCountForDate: _getMedicationMemoCheckedCountForDate,
    );
  }
}
```

## 🚀 移行計画

1. **Phase 1**: 新しいヘルパーファイルの作成 ✅
2. **Phase 2**: `home_page.dart`での使用開始（段階的）
3. **Phase 3**: 既存メソッドの置き換え
4. **Phase 4**: 不要コードの削除
5. **Phase 5**: さらなる分割（必要に応じて）

## ⚠️ 注意事項

- プライベートメンバーへのアクセスが必要な場合は、ミックスイン方式を推奨
- 段階的な移行を推奨（一度にすべてを変更しない）
- 各ステップでテストを実行
- バックアップを取ってから作業開始

