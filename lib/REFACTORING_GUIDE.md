# リファクタリングガイド

## 📋 実装完了項目

### 1. 設定ファイル（config/）
- ✅ `app_constants.dart` - アプリケーション定数
- ✅ `storage_keys.dart` - ストレージキー定数

### 2. コアユーティリティ（core/）
- ✅ `result.dart` - 結果型（Success/Error）

### 3. リポジトリレイヤー（repositories/）
- ✅ `medication_repository.dart` - メディケーション関連データ管理
- ✅ `calendar_repository.dart` - カレンダー関連データ管理
- ✅ `backup_repository.dart` - バックアップ関連データ管理
- ✅ `alarm_repository.dart` - アラーム関連データ管理

### 4. UseCaseレイヤー（use_cases/）
- ✅ `medication/add_medication_use_case.dart` - メディケーション追加
- ✅ `medication/edit_medication_use_case.dart` - メディケーション編集
- ✅ `medication/delete_medication_use_case.dart` - メディケーション削除
- ✅ `backup/create_backup_use_case.dart` - バックアップ作成
- ✅ `backup/restore_backup_use_case.dart` - バックアップ復元
- ✅ `stats/calculate_adherence_use_case.dart` - 遵守率計算

### 5. 状態管理（providers/）
- ✅ `medication_state.dart` - メディケーション状態管理（Riverpod）
- ✅ `calendar_state.dart` - カレンダー状態管理（Riverpod）
- ✅ `alarm_state.dart` - アラーム状態管理（Riverpod）

### 6. UIコンポーネント（widgets/）
- ✅ `calendar/calendar_day_cell.dart` - カレンダー日付セル
- ✅ `medication/medication_record_card.dart` - 服用記録カード
- ✅ `medication/medication_memo_checkbox.dart` - 服用メモチェックボックス
- ✅ `stats/adherence_chart_card.dart` - 遵守率グラフカード
- ✅ `common/loading_overlay.dart` - ローディングオーバーレイ
- ✅ `common/error_dialog.dart` - エラーダイアログ

### 7. ページ（pages/）
- ✅ `calendar/calendar_page.dart` - カレンダーページ
- ✅ `medicine/medicine_page.dart` - 薬物管理ページ

## 🔄 移行手順

### Phase 1: 既存コードへの統合

1. **リポジトリの初期化**
   ```dart
   // main.dart または AppModule で
   await MedicationRepository().initialize();
   await CalendarRepository().initialize();
   await BackupRepository().initialize();
   await AlarmRepository().initialize();
   ```

2. **Providerの設定**
   ```dart
   // main.dart
   void main() {
     runApp(
       const ProviderScope(
         child: MedicationAlarmApp(),
       ),
     );
   }
   ```

3. **既存のhome_page.dartからの移行**
   - 状態変数をProviderに移行
   - UIコンポーネントを新しいウィジェットに置き換え
   - UseCaseを使用してビジネスロジックを実行

### Phase 2: 段階的置き換え

1. **カレンダータブの置き換え**
   - `CalendarPage`を使用
   - 既存のカレンダー実装を段階的に置き換え

2. **薬物管理タブの置き換え**
   - `MedicinePage`を使用
   - 既存のメディケーション管理機能を移行

3. **アラーム・統計タブの追加**
   - 同様のパターンで実装

## 📁 推奨ファイル構造

```
lib/
├── config/
│   ├── app_constants.dart
│   └── storage_keys.dart
├── core/
│   └── result.dart
├── models/
│   └── medication_memo.dart
├── repositories/
│   ├── medication_repository.dart
│   ├── calendar_repository.dart
│   ├── backup_repository.dart
│   └── alarm_repository.dart
├── providers/
│   ├── medication_state.dart
│   ├── calendar_state.dart
│   └── alarm_state.dart
├── use_cases/
│   ├── medication/
│   ├── backup/
│   └── stats/
├── pages/
│   ├── calendar/
│   ├── medicine/
│   ├── alarm/
│   └── stats/
├── widgets/
│   ├── calendar/
│   ├── medication/
│   ├── stats/
│   └── common/
└── main.dart
```

## 🎯 次のステップ

1. **依存性注入の実装**
   - GetItまたはRiverpodのDIパターンを使用

2. **エラーハンドリングの統一**
   - Result型を使用した一貫したエラー処理

3. **テストの追加**
   - 各レイヤーに対するユニットテスト
   - 統合テストの実装

4. **パフォーマンス最適化**
   - 不要な再ビルドの防止
   - メモ化の適切な使用

