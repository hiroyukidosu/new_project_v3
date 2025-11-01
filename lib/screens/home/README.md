# Homeページ分割構造

このディレクトリは、`home_page.dart`の分割によって作成されたファイル群です。

## ディレクトリ構造

```
lib/screens/home/
├── state/
│   ├── home_page_state.dart          # 状態管理クラス
│   └── home_page_state_notifiers.dart # Notifierクラス
├── persistence/
│   ├── medication_data_persistence.dart # メディケーションデータ永続化
│   └── alarm_data_persistence.dart     # アラームデータ永続化
├── handlers/
│   ├── calendar_event_handler.dart     # カレンダーイベント処理
│   └── medication_event_handler.dart   # メディケーションイベント処理
├── business/
│   └── calendar_marker_manager.dart   # カレンダーマーカー管理
└── README.md
```

## 各ファイルの役割

### State (状態管理)

#### `home_page_state.dart`
- ホームページの全状態を管理するクラス
- `copyWith`メソッドで状態の更新をサポート

#### `home_page_state_notifiers.dart`
- `ValueNotifier`を使用したリアクティブな状態管理
- UI更新の最適化に使用

### Persistence (データ永続化)

#### `medication_data_persistence.dart`
- 服用メモデータの保存・読み込み
- HiveとSharedPreferencesを使用した3重バックアップ
- メモステータス、曜日別ステータス、服用回数別ステータスの管理

#### `alarm_data_persistence.dart`
- アラームデータの保存・読み込み
- CRUD操作を提供

### Handlers (イベント処理)

#### `calendar_event_handler.dart`
- カレンダー関連のイベント処理
- 日付選択、色変更、マーク更新など

#### `medication_event_handler.dart`
- メディケーション関連のイベント処理
- メモの追加・削除・更新、チェック状態の変更など

### Business (ビジネスロジック)

#### `calendar_marker_manager.dart`
- カレンダーマーカーの管理
- イベント表示の生成
- 日別統計の計算

## 使用方法

### 1. 状態管理の使用

```dart
final state = HomePageState(
  focusedDay: DateTime.now(),
  medicationMemos: [],
);

// 状態の更新
final newState = state.copyWith(
  selectedDay: DateTime.now(),
);
```

### 2. データ永続化の使用

```dart
final persistence = MedicationDataPersistence();

// メモの読み込み
final memos = await persistence.loadMedicationMemos();

// メモの保存
await persistence.saveMedicationMemo(memo);
```

### 3. イベントハンドラーの使用

```dart
final handler = CalendarEventHandler(
  persistence: persistence,
  onStateUpdate: (day) => setState(() => _selectedDay = day),
  onDayColorUpdate: (key, color) => setState(() => _dayColors[key] = color),
);

// 日付選択イベント
handler.onDaySelected(DateTime.now(), _selectedDay);
```

## 次のステップ

1. UIコンポーネントの分離（widgets/）
2. メインページ（medication_home_page.dart）のリファクタリング
3. 各コンポーネントの統合

## 注意事項

- この構造は段階的に実装されています
- 既存のコードとの互換性を保ちながら移行します
- 各ファイルは単一責任の原則に従って作成されています

