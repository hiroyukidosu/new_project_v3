# Widgets ディレクトリ

このディレクトリには、ホームページで使用されるUIコンポーネントが含まれています。

## ファイル一覧

### 1. calendar_view.dart
- **説明**: カレンダー表示専用のウィジェット
- **機能**:
  - 日付選択
  - イベント表示
  - カレンダースタイルのカスタマイズ

### 2. medication_record_list.dart
- **説明**: 服用記録リストを表示するウィジェット
- **機能**:
  - 服用記録の一覧表示
  - メモ選択機能
  - 追加された薬の表示

### 3. medication_stats_card.dart
- **説明**: 服用統計を表示するカードウィジェット
- **機能**:
  - 総数、服用済み、未服用の表示
  - 進捗バーの表示
  - 遵守率の計算と表示

### 4. memo_field.dart
- **説明**: メモ入力欄ウィジェット
- **機能**:
  - テキスト入力
  - フォーカス状態の管理
  - 保存機能

## 使用方法

### CalendarView

```dart
CalendarView(
  focusedDay: DateTime.now(),
  selectedDay: _selectedDay,
  onDaySelected: (day, selected) => setState(() => _selectedDay = day),
  // ... その他のパラメータ
)
```

### MedicationRecordList

```dart
MedicationRecordList(
  selectedDay: _selectedDay,
  medicationMemos: _medicationMemos,
  onMemoTap: (memo) => _selectMemo(memo),
  // ... その他のパラメータ
)
```

### MedicationStatsCard

```dart
MedicationStatsCard(
  selectedDay: _selectedDay,
  stats: {'total': 10, 'taken': 8},
)
```

### MemoField

```dart
MemoField(
  initialValue: _memoText,
  onChanged: (value) => _memoText = value,
  onSaved: () => _saveMemo(),
)
```

## 設計方針

- **再利用性**: 他の画面でも使用可能なように設計
- **単一責任**: 各ウィジェットは1つの機能のみを持つ
- **カスタマイズ性**: 必要に応じてパラメータで動作を変更可能
