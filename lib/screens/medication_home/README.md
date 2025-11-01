# MedicationHome リファクタリング構造

## 概要

このディレクトリは、Clean Architecture原則に基づいた新しい構造です。
現在は**将来の移行用として保持**されており、実際の運用では既存の`home_page.dart`を使用しています。

## 構造

```
medication_home/
├── controllers/          # 状態管理（ChangeNotifier）
│   ├── medication_home_controller.dart
│   ├── calendar_controller.dart
│   ├── medication_memo_controller.dart
│   ├── stats_controller.dart
│   └── backup_controller.dart
├── repositories/         # データアクセス層
│   ├── medication_repository.dart
│   ├── alarm_repository.dart
│   ├── calendar_repository.dart
│   ├── preference_repository.dart
│   └── backup_repository.dart
├── use_cases/           # ビジネスロジック
│   ├── medication/
│   ├── stats/
│   └── backup/
├── widgets/             # UIコンポーネント
│   └── tabs/
└── medication_home_page.dart  # メインページ（約150行）
```

## 現在の状態

### ✅ 完成済み
- Phase 1: Repository層 - 完了
- Phase 2: UseCase層 - 完了
- Phase 3: Controller層 - 完了
- Phase 4: UI層の基本構造 - 完了

### ⚠️ 未実装機能（TODO）
1. **メモ追加ダイアログ** (`medicine_tab_widget.dart`)
   - `MemoDialog`との統合が必要
   
2. **メモ編集機能** (`medicine_tab_widget.dart`)
   - `MemoDialog`を使用した編集機能
   
3. **カスタム遵守率ダイアログ** (`stats_tab_widget.dart`)
   - `CustomAdherenceDialog`との統合が必要
   
4. **バックアップダイアログ** (`medication_home_page.dart`)
   - `BackupDialog`との統合が必要
   
5. **カレンダー日のビルダー** (`calendar_tab_widget.dart`)
   - より詳細なカレンダー表示機能
   
6. **メモチェック回数取得機能** (`stats_tab_widget.dart`)
   - `getMedicationMemoCheckedCountForDate`の実装

## 使用方法

### 現状（安定性優先）
- **実際の運用**: `lib/screens/home_page.dart` を使用
- **この構造**: 将来の移行用として保持

### 将来の移行方法
1. 上記のTODO項目を全て実装
2. 既存の機能を完全に再現するまでテスト
3. `main.dart`で新しいページに切り替え

## メリット

### Clean Architectureの利点
- **分離された責任**: UI、ビジネスロジック、データアクセスが明確に分離
- **テスタビリティ**: 各層が独立してテスト可能
- **保守性**: 変更の影響範囲が限定的
- **再利用性**: UseCaseやRepositoryを他の画面でも利用可能

### コードサイズ削減
- 元の`home_page.dart`: 約4150行
- 新しい`medication_home_page.dart`: 約150行（約96%削減）

## 移行計画

段階的な移行を推奨：

1. **Phase 1**: TODO項目の実装
2. **Phase 2**: 既存機能の完全再現とテスト
3. **Phase 3**: 並行運用期間（両方をサポート）
4. **Phase 4**: 完全移行

## 注意事項

- ⚠️ 現在の状態では、新しい構造は**未完成**です
- ✅ 既存の`home_page.dart`は**完全に機能**しています
- 📝 移行前に必ず全機能をテストしてください

