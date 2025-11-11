# サプリ＆おくすりスケジュール管理帳 - アプリ構造・機能完全ドキュメント

## 📋 目次

1. [アプリ概要](#アプリ概要)
2. [アーキテクチャ](#アーキテクチャ)
3. [主要機能](#主要機能)
4. [データ構造](#データ構造)
5. [技術スタック](#技術スタック)
6. [ディレクトリ構造](#ディレクトリ構造)
7. [データフロー](#データフロー)
8. [パフォーマンス最適化](#パフォーマンス最適化)
9. [セキュリティ](#セキュリティ)
10. [10年運用対応](#10年運用対応)

---

## アプリ概要

### アプリ名
**サプリ＆おくすりスケジュール管理帳**

### バージョン
1.0.7+10

### 目的
24時間設定可能で確実に動作する服用アラームアプリ。薬物・サプリメントの服用管理、カレンダー表示、統計分析、バックアップ・復元機能を提供。

### 主要な特徴
- ✅ 24時間対応のアラーム機能
- ✅ カレンダーベースの服用記録管理
- ✅ 詳細な統計分析（遵守率、服用状況など）
- ✅ 手動バックアップ・復元機能
- ✅ 10年運用対応（データアーカイブ機能）
- ✅ オフライン動作（クラウド同期はオプション）

---

## アーキテクチャ

### アーキテクチャパターン
**Clean Architecture + Repository Pattern + State Management (Riverpod)**

### レイヤー構造

```
┌─────────────────────────────────────┐
│   Presentation Layer (UI)           │
│   - Screens                          │
│   - Widgets                          │
│   - Dialogs                          │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Application Layer                 │
│   - Controllers                      │
│   - Handlers                         │
│   - Use Cases                        │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Domain Layer                      │
│   - Models                           │
│   - Business Logic                   │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Data Layer                        │
│   - Repositories                    │
│   - Services                         │
│   - Persistence                      │
└─────────────────────────────────────┘
```

### 状態管理
- **Riverpod**: グローバル状態管理
- **ValueNotifier**: ローカル状態管理
- **StateManager**: ページ単位の状態管理

---

## 主要機能

### 1. 服用メモ管理機能

#### 機能概要
薬物・サプリメントの服用スケジュールを管理する機能。

#### 主要機能
- **メモの作成・編集・削除**
  - メモ名、種類（薬物/サプリメント）、服用量、メモ
  - 曜日指定（月〜日）
  - 1日の服用回数（1〜6回）
  - 色分け表示

- **服用記録**
  - 日付ごとの服用状況を記録
  - チェックボックスで服用済みをマーク
  - 服用時間の記録

- **メモ一覧表示**
  - ページネーション対応
  - 検索・フィルタリング機能
  - ソート機能（作成日、名前順など）

#### 実装ファイル
- `lib/models/medication_memo.dart`: データモデル
- `lib/repositories/medication_repository.dart`: データアクセス
- `lib/screens/home/controllers/medication_controller.dart`: コントローラー
- `lib/screens/home/handlers/memo_event_handler.dart`: イベントハンドラー

---

### 2. カレンダー機能

#### 機能概要
カレンダーベースで服用記録を視覚的に表示・管理する機能。

#### 主要機能
- **カレンダー表示**
  - `table_calendar`パッケージを使用
  - 月次・週次・日次表示
  - 服用記録のマーク表示

- **日付ごとのメモ**
  - 日付ごとにメモを保存
  - Hiveを使用した永続化
  - リアルタイム保存

- **日付色分け**
  - ユーザーが日付に色を設定可能
  - カスタムカラーピッカー
  - 色情報の永続化

- **選択日管理**
  - 選択した日付の服用記録を表示
  - 選択日のメモを表示・編集

#### 実装ファイル
- `lib/repositories/calendar_repository.dart`: カレンダーデータ管理
- `lib/screens/home/controllers/calendar_controller.dart`: カレンダーコントローラー
- `lib/screens/home/widgets/calendar_view.dart`: カレンダーUI
- `lib/services/daily_memo_service.dart`: 日付メモサービス

---

### 3. アラーム機能

#### 機能概要
24時間対応の服用アラーム機能。

#### 主要機能
- **アラーム設定**
  - アラーム名、時刻、繰り返し設定
  - 曜日指定（月〜日）
  - アラーム音の選択
  - 音量調整
  - バイブレーション設定

- **アラーム管理**
  - アラームの有効/無効切り替え
  - アラームの追加・編集・削除
  - アラーム一覧表示

- **通知機能**
  - ローカル通知（`flutter_local_notifications`）
  - アラーム音再生（`audioplayers`）
  - バイブレーション（`vibration`）
  - バックグラウンド動作対応

#### 実装ファイル
- `lib/repositories/alarm_repository.dart`: アラームデータ管理
- `lib/services/alarm_service.dart`: アラームサービス
- `lib/services/notification_service.dart`: 通知サービス
- `lib/screens/home/controllers/alarm_controller.dart`: アラームコントローラー

---

### 4. 統計分析機能

#### 機能概要
服用状況の統計分析と可視化機能。

#### 主要機能
- **遵守率計算**
  - 日別・週別・月別の遵守率
  - メモ別の遵守率
  - 全体の遵守率

- **グラフ表示**
  - `fl_chart`パッケージを使用
  - 円グラフ（服用状況の内訳）
  - 棒グラフ（期間別の遵守率）
  - 折れ線グラフ（推移）

- **統計データ**
  - 服用回数の統計
  - 服用時間の統計
  - カレンダーマークの統計

#### 実装ファイル
- `lib/screens/home/widgets/medication_stats_card.dart`: 統計カード
- `lib/screens/views/stats_view.dart`: 統計画面
- `lib/screens/helpers/home_page_stats_helper.dart`: 統計計算ヘルパー

---

### 5. バックアップ・復元機能

#### 機能概要
手動バックアップ・復元機能。

#### 主要機能
- **バックアップ作成**
  - 任意タイミングでデータを保存
  - バックアップ名の設定
  - 全データのエクスポート（JSON形式）
  - 暗号化対応

- **バックアップ復元**
  - バックアップ履歴から選択
  - データの完全復元
  - 復元前の確認ダイアログ
  - エラーハンドリング

- **バックアップ履歴**
  - バックアップ一覧表示
  - バックアップの削除
  - バックアップのプレビュー

#### バックアップ対象データ
- 服用メモ一覧（作成・変更・削除を含む）
- 服用記録（チェック状況、服用時間）
- カレンダーメモ（日付ごとのメモ）
- 日付色分け設定
- アラーム設定
- 遵守率データ

#### 実装ファイル
- `lib/repositories/backup_repository.dart`: バックアップデータ管理
- `lib/use_cases/backup/create_backup_use_case.dart`: バックアップ作成
- `lib/use_cases/backup/restore_backup_use_case.dart`: バックアップ復元
- `lib/screens/home/handlers/backup_handler.dart`: バックアップハンドラー
- `lib/services/backup_history_service.dart`: バックアップ履歴管理

---

### 6. 初期化・パフォーマンス最適化

#### 機能概要
段階的初期化とパフォーマンス最適化。

#### 主要機能
- **段階的初期化**
  - フェーズ1: 必須初期化（Hive、Adapter）
  - フェーズ2: 並列初期化（Repository）
  - フェーズ3: データ読み込み
  - フェーズ4: 遅延初期化（課金など）

- **パフォーマンス最適化**
  - 並列処理（`Future.wait`）
  - フレーム分散処理
  - バッチ処理
  - キャッシュ機能

- **スプラッシュスクリーン**
  - ネイティブスプラッシュスクリーン
  - カスタムスプラッシュスクリーン
  - 初期化進捗表示

#### 実装ファイル
- `lib/core/app_initializer.dart`: アプリ初期化
- `lib/widgets/splash_screen.dart`: スプラッシュスクリーン
- `lib/utils/performance_monitor.dart`: パフォーマンス監視

---

## データ構造

### 主要データモデル

#### 1. MedicationMemo（服用メモ）
```dart
class MedicationMemo {
  final String id;                    // 一意ID
  final String name;                  // メモ名
  final String type;                  // 種類（薬物/サプリメント）
  final String dosage;                // 服用量
  final String notes;                 // メモ
  final DateTime createdAt;           // 作成日時
  final DateTime? lastTaken;          // 最終服用日時
  final Color color;                  // 表示色
  final List<int> selectedWeekdays;   // 選択曜日（0=月曜日）
  final int dosageFrequency;         // 1日の服用回数（1-6回）
}
```

#### 2. MedicationInfo（服用情報）
```dart
class MedicationInfo {
  final bool isChecked;               // 服用済みフラグ
  final DateTime? takenTime;          // 服用時間
  final int doseIndex;                // 服用回数インデックス
}
```

#### 3. AlarmData（アラームデータ）
```dart
{
  'name': String,                     // アラーム名
  'time': String,                     // 時刻（HH:mm）
  'repeat': String,                   // 繰り返し設定
  'enabled': bool,                    // 有効/無効
  'alarmType': String,                // アラームタイプ
  'volume': int,                      // 音量（0-100）
  'message': String,                  // メッセージ
  'selectedDays': List<bool>,         // 選択曜日
}
```

### データ永続化

#### Hive（NoSQLデータベース）
- **medication_memos**: 服用メモ一覧
- **medication_data**: 服用記録（月次セグメンテーション）
- **daily_memos**: 日付ごとのメモ
- **alarm_data**: アラーム設定

#### SharedPreferences
- アプリ設定
- バックアップデータ（3重バックアップ）
- アラーム設定

#### 月次セグメンテーション
- **dose_status_YYYY-MM**: 服用ステータス（月単位）
- **weekday_status_YYYY-MM**: 曜日ステータス（月単位）
- **memo_enabled_YYYY-MM**: メモ有効化（月単位）

**目的**: 10年運用時のパフォーマンス最適化

---

## 技術スタック

### フレームワーク・言語
- **Flutter**: 3.10.0以上
- **Dart**: 3.0.0以上

### 主要パッケージ

#### データ管理
- `hive`: ^2.2.3 - NoSQLデータベース
- `hive_flutter`: ^1.1.0 - Hive Flutter統合
- `shared_preferences`: ^2.3.2 - キー値ストレージ

#### 状態管理
- `flutter_riverpod`: ^2.5.1 - 状態管理
- `riverpod_annotation`: ^2.3.5 - Riverpodアノテーション

#### UI
- `table_calendar`: ^3.0.9 - カレンダー表示
- `fl_chart`: ^0.66.0 - グラフ表示
- `expandable`: ^5.0.1 - 展開可能ウィジェット

#### 通知・アラーム
- `flutter_local_notifications`: ^17.2.3 - ローカル通知
- `alarm`: ^3.1.7 - アラーム機能
- `audioplayers`: ^6.4.0 - 音声再生
- `vibration`: ^2.1.0 - バイブレーション

#### 日付・時間
- `timezone`: ^0.9.2 - タイムゾーン管理
- `intl`: ^0.19.0 - 国際化・日付フォーマット

#### クラウド・認証
- `firebase_core`: ^2.32.0 - Firebase統合
- `firebase_auth`: ^4.15.3 - 認証
- `cloud_firestore`: ^4.13.6 - クラウドデータベース
- `firebase_crashlytics`: ^3.4.9 - クラッシュレポート

#### 課金
- `in_app_purchase`: ^3.1.13 - アプリ内課金

#### セキュリティ
- `flutter_secure_storage`: ^9.2.2 - セキュアストレージ

#### ユーティリティ
- `uuid`: ^4.5.1 - UUID生成
- `path_provider`: ^2.1.4 - パス取得
- `permission_handler`: ^11.4.0 - 権限管理
- `device_info_plus`: ^11.3.0 - デバイス情報

---

## ディレクトリ構造

```
lib/
├── main.dart                          # エントリーポイント
├── firebase_options.dart              # Firebase設定
│
├── core/                              # コア機能
│   └── app_initializer.dart          # アプリ初期化
│
├── models/                            # データモデル
│   ├── medication_memo.dart          # 服用メモモデル
│   ├── medication_info.dart          # 服用情報モデル
│   ├── medicine_data.dart            # 薬物データモデル
│   └── adapters/                     # Hive Adapter
│
├── repositories/                      # データアクセス層
│   ├── medication_repository.dart    # 服用メモリポジトリ
│   ├── calendar_repository.dart      # カレンダーリポジトリ
│   ├── alarm_repository.dart         # アラームリポジトリ
│   └── backup_repository.dart        # バックアップリポジトリ
│
├── services/                          # ビジネスロジック層
│   ├── alarm_service.dart            # アラームサービス
│   ├── notification_service.dart     # 通知サービス
│   ├── daily_memo_service.dart       # 日付メモサービス
│   ├── backup_history_service.dart   # バックアップ履歴
│   ├── in_app_purchase_service.dart  # 課金サービス
│   └── hive_service.dart             # Hiveサービス
│
├── use_cases/                        # ユースケース
│   └── backup/
│       ├── create_backup_use_case.dart
│       └── restore_backup_use_case.dart
│
├── screens/                           # UI層
│   ├── medication_alarm_app.dart     # ルートウィジェット
│   ├── home_page.dart                # ホームページ
│   │
│   ├── home/                          # ホームページ関連
│   │   ├── state/                     # 状態管理
│   │   │   ├── home_page_state_manager.dart
│   │   │   └── home_page_state_notifiers.dart
│   │   │
│   │   ├── controllers/               # コントローラー
│   │   │   ├── medication_controller.dart
│   │   │   ├── calendar_controller.dart
│   │   │   ├── alarm_controller.dart
│   │   │   └── backup_controller.dart
│   │   │
│   │   ├── handlers/                  # イベントハンドラー
│   │   │   ├── home_page_event_handler.dart
│   │   │   ├── memo_event_handler.dart
│   │   │   ├── medication_event_handler.dart
│   │   │   └── calendar_event_handler.dart
│   │   │
│   │   ├── persistence/               # 永続化
│   │   │   ├── medication_data_persistence.dart
│   │   │   ├── alarm_data_persistence.dart
│   │   │   └── snapshot_persistence.dart
│   │   │
│   │   ├── widgets/                   # UIウィジェット
│   │   │   ├── calendar_view.dart
│   │   │   ├── medication_record_list.dart
│   │   │   ├── day_memo_field_widget.dart
│   │   │   └── dialogs/
│   │   │       ├── backup_dialog.dart
│   │   │       ├── backup_history_dialog.dart
│   │   │       └── backup_preview_dialog.dart
│   │   │
│   │   └── initialization/            # 初期化
│   │       ├── home_page_initializer.dart
│   │       └── home_page_dependencies.dart
│   │
│   ├── views/                         # ビュー
│   │   ├── calendar_view.dart
│   │   ├── medicine_view.dart
│   │   ├── alarm_view.dart
│   │   └── stats_view.dart
│   │
│   └── helpers/                       # ヘルパー
│       ├── home_page_backup_helper.dart
│       ├── home_page_stats_helper.dart
│       └── data_operations.dart
│
├── widgets/                           # 共通ウィジェット
│   ├── splash_screen.dart            # スプラッシュスクリーン
│   └── tutorial_widgets.dart         # チュートリアル
│
└── utils/                             # ユーティリティ
    ├── performance_monitor.dart       # パフォーマンス監視
    ├── logger.dart                    # ロガー
    ├── locale_helper.dart             # ロケールヘルパー
    └── preferences_cache.dart         # 設定キャッシュ
```

---

## データフロー

### 1. 服用メモ作成フロー

```
ユーザー操作
    ↓
MedicationController.createMemo()
    ↓
MemoEventHandler.addMemo()
    ↓
MedicationRepository.saveMemo()
    ↓
Hive Box (medication_memos)
    ↓
MedicationDataPersistence.saveMedicationMemo()
    ↓
SharedPreferences (バックアップ)
    ↓
StateManager更新
    ↓
UI更新
```

### 2. アラーム設定フロー

```
ユーザー操作
    ↓
AlarmController.createAlarm()
    ↓
AlarmRepository.saveAlarm()
    ↓
AlarmService.scheduleAlarm()
    ↓
NotificationService.scheduleNotification()
    ↓
flutter_local_notifications
    ↓
システム通知
```

### 3. バックアップ作成フロー

```
ユーザー操作
    ↓
BackupHandler.createBackup()
    ↓
CreateBackupUseCase.execute()
    ↓
各Repositoryからデータ取得
    ↓
HomePageBackupHelper.createSafeBackupData()
    ↓
BackupRepository.createBackup()
    ↓
SharedPreferences (暗号化)
    ↓
BackupHistoryService.updateHistory()
```

### 4. データ読み込みフロー（起動時）

```
アプリ起動
    ↓
AppInitializer.initializeCriticalAndEssential()
    ↓
Hive初期化
    ↓
Repository初期化（並列）
    ↓
StateManager初期化
    ↓
MedicationDataPersistence.loadMedicationMemos()
    ↓
2年分のみフィルタリング
    ↓
StateManagerに反映
    ↓
UI表示
```

---

## パフォーマンス最適化

### 1. 段階的初期化
- **フェーズ1**: 必須初期化（Hive、Adapter） - 約150ms
- **フェーズ2**: 並列初期化（Repository） - 約1.6秒
- **フェーズ3**: データ読み込み - 約300ms
- **フェーズ4**: 遅延初期化（課金など） - バックグラウンド

### 2. データフィルタリング
- **服用メモ**: 2年分のみ読み込み（10年運用対応）
- **月次セグメンテーション**: 服用記録を月単位で分割

### 3. 並列処理
- Repository初期化を並列実行（`Future.wait`）
- フレーム分散処理（50件ずつ処理）

### 4. キャッシュ機能
- MedicationRepository: 5秒間のキャッシュ
- PreferencesCache: SharedPreferencesのキャッシュ

### 5. アーカイブ機能
- 2年以上前のメモを自動アーカイブ
- アーカイブボックスに移動（削除ではない）

### パフォーマンス指標
- **起動時間**: 約2.1秒（10年分データでも）
- **メモリ使用量**: 約3.6MB（2年分のみ読み込み）
- **フレームスキップ**: <100フレーム
- **Daveyエラー**: <800ms

---

## セキュリティ

### 1. データ暗号化
- バックアップデータの暗号化（`BackupUtils.encryptData`）
- セキュアストレージ（`flutter_secure_storage`）

### 2. エラーハンドリング
- Firebase Crashlyticsでエラー追跡
- ユーザー同意ベースのクラッシュレポート収集

### 3. データ保護
- 3重バックアップ（複数キーに保存）
- データバージョニング（マイグレーション対応）

---

## 10年運用対応

### 実装済み機能

#### 1. データフィルタリング
- 服用メモ: 2年分のみ読み込み
- 起動時の読み込み件数を80%削減

#### 2. 月次セグメンテーション
- 服用記録を月単位で分割保存
- 10年 = 120ヶ月分を効率的に管理

#### 3. アーカイブ機能
- 2年以上前のメモを自動アーカイブ
- アーカイブボックスに移動（削除ではない）
- 必要に応じて復元可能

#### 4. パフォーマンス最適化
- 並列処理で起動時間を短縮
- バッチ処理でフレーム分散
- キャッシュ機能で読み込み高速化

### 予想パフォーマンス（10年運用時）

| 項目 | 改善前 | 改善後 | 改善率 |
|------|--------|--------|--------|
| 起動時の読み込み件数 | 36,500件 | 7,300件 | -80% |
| メモリ使用量 | 約18MB | 約3.6MB | -80% |
| 起動時間 | 5-10秒 | 1-2秒 | -80% |

---

## 主要な設計パターン

### 1. Repository Pattern
- データアクセス層を抽象化
- テスト容易性の向上

### 2. Use Case Pattern
- ビジネスロジックの分離
- 再利用性の向上

### 3. State Management Pattern
- Riverpod + ValueNotifier
- 状態の一元管理

### 4. Event Handler Pattern
- イベント駆動型アーキテクチャ
- 疎結合な設計

---

## エラーハンドリング

### 1. エラーハンドリング戦略
- `try-catch`でエラーを捕捉
- Firebase Crashlyticsでエラー記録
- ユーザーフレンドリーなエラーメッセージ

### 2. リトライ機能
- データ読み込みのリトライ（最大3回）
- バックオフ戦略（指数バックオフ）

### 3. フォールバック機能
- Hive読み込み失敗時はSharedPreferencesから復元
- ネットワークエラー時のオフライン動作

---

## テスト戦略

### 1. ユニットテスト
- Repository層のテスト
- Use Case層のテスト

### 2. 統合テスト
- データフローのテスト
- バックアップ・復元のテスト

### 3. UIテスト
- ウィジェットテスト
- エンドツーエンドテスト

---

## 今後の拡張予定

### 1. クラウド同期
- Firebase Firestoreとの同期
- 複数デバイス間でのデータ同期

### 2. 通知改善
- リッチ通知
- アクション付き通知

### 3. 統計機能強化
- より詳細な分析
- エクスポート機能（CSV、PDF）

### 4. アクセシビリティ
- スクリーンリーダー対応
- フォントサイズ調整

---

## まとめ

このアプリは、**Clean Architecture**と**Repository Pattern**を採用した、スケーラブルで保守性の高い設計となっています。10年運用にも対応できるよう、パフォーマンス最適化とデータアーカイブ機能を実装しています。

主要な特徴:
- ✅ 段階的初期化による高速起動
- ✅ 並列処理によるパフォーマンス最適化
- ✅ 月次セグメンテーションによる大量データ対応
- ✅ アーカイブ機能による長期運用対応
- ✅ 完全なバックアップ・復元機能
- ✅ オフライン動作対応

---

**作成日**: 2025年1月
**バージョン**: 1.0.7+10
**対象プラットフォーム**: Android, iOS

