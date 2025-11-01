# 移行ステップガイド

## 🎯 完了した作業

### Phase 1: 基盤構築 ✅
- [x] ProviderScopeの設定（main.dart）
- [x] リポジトリの初期化処理
- [x] 新しいページアーキテクチャの実装
- [x] 状態管理の実装（Riverpod）

### Phase 2: 新しいページの実装 ✅
- [x] CalendarPage - カレンダーページ
- [x] MedicinePage - 薬物管理ページ
- [x] AlarmPage - アラームページ
- [x] StatsPage - 統計ページ
- [x] IntegratedHomePage - 統合ホームページ

## 📋 次のステップ

### Step 1: IntegratedHomePageをアプリに統合

`medication_alarm_app.dart`を更新して、新しい`IntegratedHomePage`を使用：

```dart
// lib/screens/medication_alarm_app.dart
import '../pages/integrated_home_page.dart';

class MedicationAlarmApp extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...
      home: const IntegratedHomePage(), // 既存のMedicationHomePageから変更
      // ...
    );
  }
}
```

### Step 2: 既存コードとの段階的統合

#### オプションA: 完全置き換え（推奨）
- `home_page.dart`の使用を停止
- `IntegratedHomePage`に完全移行

#### オプションB: 並行運用
- 既存の`home_page.dart`を保持
- 新機能は`IntegratedHomePage`に追加
- 段階的に機能を移行

### Step 3: 既存機能の移行チェックリスト

#### カレンダータブ
- [ ] 既存の`calendar_tab.dart`の機能を`CalendarPage`に移植
- [ ] カレンダーイベント表示
- [ ] 日付色の変更機能
- [ ] 服用記録の表示

#### 薬物管理タブ
- [ ] 既存の`medicine_tab.dart`の機能を`MedicinePage`に移植
- [ ] メモの追加・編集・削除
- [ ] 服用チェック機能
- [ ] ページネーション

#### アラームタブ
- [ ] 既存の`alarm_tab.dart`の機能を`AlarmPage`に移植
- [ ] アラーム設定
- [ ] 通知管理

#### 統計タブ
- [ ] 既存の`stats_tab.dart`の機能を`StatsPage`に移植
- [ ] 遵守率計算
- [ ] グラフ表示

### Step 4: データ移行

既存のデータを新しいリポジトリに移行：

```dart
// 移行スクリプト例
Future<void> migrateData() async {
  // 既存のSharedPreferencesから読み込み
  final prefs = await SharedPreferences.getInstance();
  
  // 新しいリポジトリに保存
  final medicationRepo = MedicationRepository();
  await medicationRepo.initialize();
  // ... データ移行処理
}
```

### Step 5: テスト

1. **ユニットテスト**
   - 各UseCaseのテスト
   - リポジトリのテスト
   - 状態管理のテスト

2. **統合テスト**
   - ページ間の遷移
   - データの永続化
   - エラーハンドリング

3. **UIテスト**
   - 各ページの動作確認
   - 既存機能との互換性確認

## 🔧 トラブルシューティング

### 問題: リポジトリが初期化されない
**解決策**: `main.dart`の`_initializeRepositories()`が正しく実行されているか確認

### 問題: Providerが見つからない
**解決策**: `ProviderScope`が`MaterialApp`の外側にあることを確認

### 問題: データが表示されない
**解決策**: 
1. リポジトリの初期化を確認
2. 状態管理の`loadAll()`が呼ばれているか確認
3. 既存データの移行が必要か確認

## 📝 移行例

### 既存コード（Before）
```dart
// home_page.dart内
List<MedicationMemo> _medicationMemos = [];
await _loadMedicationMemos();
```

### 新コード（After）
```dart
// medicine_page.dart
final medicationState = ref.watch(medicationStateProvider);
// 自動的にデータが読み込まれます
```

## 🎉 移行完了後のメリット

1. **保守性向上**: 各機能が独立したファイルに分離
2. **テスト容易性**: UseCaseとリポジトリを個別にテスト可能
3. **再利用性**: UIコンポーネントを他ページで再利用可能
4. **拡張性**: 新機能追加が容易
5. **エラーハンドリング**: Result型による統一的なエラー処理

## 📚 参考資料

- [Riverpod公式ドキュメント](https://riverpod.dev/)
- `REFACTORING_GUIDE.md` - アーキテクチャの詳細
- 各ディレクトリのREADME（今後追加予定）

