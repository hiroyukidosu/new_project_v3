# 次のフェーズ - 分割作業の継続

## ✅ 完了した作業

### Phase 1: 基盤構築
- ✅ 新しいヘルパーファイルの作成
- ✅ 計算ロジックの分離（MedicationStatsCalculator, AdherenceCalculator）
- ✅ UIビルダーミックスインの追加
- ✅ 状態管理ヘルパーの追加

### Phase 2: 基本統合
- ✅ `_calculateDayMedicationStats()` → MedicationStatsCalculator使用
- ✅ `_calculateAdherenceStats()` → AdherenceCalculator使用
- ✅ `_calculateCustomAdherence()` → AdherenceCalculator使用
- ✅ `_buildCalendarDay()` → CalendarUIBuilderMixin使用
- ✅ `_buildCalendarStyle()` → CalendarUIBuilderMixin使用
- ✅ `_onDoseStatusChanged()`メソッドの実装

## 📊 現在の状態

- **ファイルサイズ**: 4,882行（元: 4,951行）
- **削減**: 69行（約1.4%削減）
- **リンターエラー**: なし

## 🔄 次のフェーズ

### Phase 3: 複雑なUIビルダーの分割

#### 3.1 メディケーションメモチェックボックスの分割
現在の`_buildMedicationMemoCheckbox()`は非常に複雑（約250行）で、以下の機能を含みます：
- メモ選択状態の管理
- 服用回数別のチェックボックス
- 詳細なスタイリング
- スナップショット保存機能

**分割戦略**:
1. 基本UI部分を`medication_ui_builder.dart`に移動
2. 状態管理部分を別のヘルパーに分離
3. イベントハンドラーを`event_handlers`に移動

#### 3.2 服用記録リストの分割
`_buildMedicationRecords()`も複雑で、以下の機能を含みます：
- ヘッダー表示
- メモ選択機能
- スクロール可能なリスト

**分割戦略**:
1. ヘッダー部分を独立したウィジェットに
2. リスト部分を独立したウィジェットに
3. 状態管理を分離

### Phase 4: タブビルダーの完全分離

#### 4.1 タブビルダーファイルの作成
- `ui_builders/tabs/calendar_tab_builder.dart`
- `ui_builders/tabs/medicine_tab_builder.dart`
- `ui_builders/tabs/alarm_tab_builder.dart`
- `ui_builders/tabs/stats_tab_builder.dart`

#### 4.2 各タブの分離
各タブビルダーは独立したクラスとして実装：
```dart
class CalendarTabBuilder {
  Widget build({
    required DateTime focusedDay,
    required DateTime? selectedDay,
    // ... その他のパラメータ
  });
}
```

### Phase 5: データ操作のさらなる統合

#### 5.1 データローダーの統合
- `data_operations/loaders/medication_loader.dart`
- `data_operations/loaders/calendar_loader.dart`
- `data_operations/loaders/alarm_loader.dart`

#### 5.2 データセーバーの統合
- `data_operations/savers/medication_saver.dart`
- `data_operations/savers/calendar_saver.dart`
- `data_operations/savers/alarm_saver.dart`

## 🎯 推奨アプローチ

### オプション1: 段階的移行（推奨）
1. まず複雑なUIビルダーを部分的なヘルパーに分割
2. 既存のメソッドを段階的に置き換え
3. テストしながら進行

### オプション2: 新ページへの完全移行
1. 新しい`pages/`ディレクトリの実装を完成
2. 既存の`home_page.dart`を段階的に置き換え
3. 最終的に`home_page.dart`を削除

## 📝 注意事項

- 既存の複雑な実装を無理に変更しない
- 段階的な移行を重視
- テストを各ステップで実行
- バックアップを取ってから作業

