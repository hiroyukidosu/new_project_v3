# home_page.dart 分割分析レポート

## 📊 現在の状態

- **ファイルサイズ**: 4,732行
- **メソッド数**: 約150個（推定）
- **状態変数数**: 約50個（推定）

## 🎯 分割可能な箇所と削減見込み

### 1. ダイアログ関連（優先度: 高）

**対象ファイル**: `handlers/dialogs/` または `widgets/dialogs/`

#### 1.1 カスタム遵守率ダイアログ
- **メソッド**: `_showCustomAdherenceDialog()`
- **見込み削減**: 約80-100行
- **新規ファイル**: `widgets/dialogs/custom_adherence_dialog.dart`

#### 1.2 服用メモ編集ダイアログ
- **メソッド**: `_editMemo()`内のダイアログ構築部分
- **見込み削減**: 約150-200行
- **新規ファイル**: `widgets/dialogs/edit_memo_dialog.dart`

#### 1.3 服用メモ追加ダイアログ
- **メソッド**: `_addMemo()`内のダイアログ構築部分
- **見込み削減**: 約150-200行
- **新規ファイル**: `widgets/dialogs/add_memo_dialog.dart`

#### 1.4 警告ダイアログ
- **メソッド**: `_showWarningDialog()`, `_showLimitDialog()`
- **見込み削減**: 約30-50行
- **新規ファイル**: `widgets/dialogs/warning_dialog.dart`

**合計削減見込み**: 約410-550行

---

### 2. データ保存・読み込み処理（優先度: 高）

**対象ファイル**: `persistence/`（既存の拡張）

#### 2.1 スナップショット機能
- **メソッド**: `_saveSnapshotBeforeChange()`, `_saveSnapshot()`, `_restoreSnapshot()`
- **見込み削減**: 約100-150行
- **新規ファイル**: `persistence/snapshot_persistence.dart`

#### 2.2 カレンダーマーク更新
- **メソッド**: `_updateCalendarMarks()`
- **見込み削減**: 約50-80行
- **新規ファイル**: `persistence/calendar_mark_persistence.dart`

#### 2.3 データ統合保存
- **メソッド**: `_saveAllData()`, `_saveCurrentData()`
- **見込み削減**: 約80-100行
- **新規ファイル**: `persistence/data_sync_manager.dart`

**合計削減見込み**: 約230-330行

---

### 3. イベントハンドラー拡張（優先度: 中）

**対象ファイル**: `handlers/`（既存の拡張）

#### 3.1 メモイベントハンドラー
- **メソッド**: `_addMemo()`, `_editMemo()`, `_deleteMemo()`, `_markAsTaken()`
- **見込み削減**: 約300-400行
- **新規ファイル**: `handlers/memo_event_handler.dart`

#### 3.2 カレンダーイベントハンドラー拡張
- **メソッド**: `_onDaySelected()`, `_scrollToDayIfNeeded()`, `_scrollToBottom()`, `_scrollToTop()`
- **見込み削減**: 約100-150行
- **既存ファイル拡張**: `handlers/calendar_event_handler.dart`

#### 3.3 タブ切り替えハンドラー
- **メソッド**: `_onTabChanged()`, タブ関連の初期化
- **見込み削減**: 約50-80行
- **新規ファイル**: `handlers/tab_event_handler.dart`

**合計削減見込み**: 約450-630行

---

### 4. UIビルダーメソッド（優先度: 中）

**対象ファイル**: `widgets/`（既存の拡張）

#### 4.1 服用メモチェックボックス
- **メソッド**: `_buildMedicationMemoCheckbox()`
- **見込み削減**: 約150-200行
- **新規ファイル**: `widgets/medication_memo_checkbox.dart`（既存を拡張）

#### 4.2 カスタム遵守率カード
- **メソッド**: `_buildCustomAdherenceCard()`
- **見込み削減**: 約80-100行
- **新規ファイル**: `widgets/custom_adherence_card.dart`

#### 4.3 統計タブ構築
- **メソッド**: `_buildStatsTab()`内の詳細部分
- **見込み削減**: 約100-150行
- **新規ファイル**: `widgets/stats_tab_content.dart`

#### 4.4 アプリバー構築
- **メソッド**: `_buildAppBar()`
- **見込み削減**: 約50-80行
- **新規ファイル**: `widgets/home_app_bar.dart`

**合計削減見込み**: 約380-530行

---

### 5. バリデーション・チェック処理（優先度: 低）

**対象ファイル**: `business/`

#### 5.1 バリデーション管理
- **メソッド**: `_canAddMemo()`, `_canAddAlarm()`, 各種バリデーション
- **見込み削減**: 約50-80行
- **新規ファイル**: `business/validation_manager.dart`

#### 5.2 制限チェック
- **メソッド**: 上限チェック関連
- **見込み削減**: 約30-50行
- **既存ファイル拡張**: `business/validation_manager.dart`

**合計削減見込み**: 約80-130行

---

### 6. ヘルパーメソッド（優先度: 低）

**対象ファイル**: `business/helpers/`

#### 6.1 日付処理ヘルパー
- **メソッド**: `_normalizeDate()`, 日付フォーマット関連
- **見込み削減**: 約30-50行
- **新規ファイル**: `business/helpers/date_helper.dart`

#### 6.2 データ変換ヘルパー
- **メソッド**: データ変換関連の小さなメソッド
- **見込み削減**: 約50-80行
- **新規ファイル**: `business/helpers/data_converter.dart`

**合計削減見込み**: 約80-130行

---

### 7. 初期化処理（優先度: 低）

**対象ファイル**: `business/`

#### 7.1 初期化マネージャー
- **メソッド**: `initState()`内の初期化ロジック
- **見込み削減**: 約100-150行
- **新規ファイル**: `business/initialization_manager.dart`

**合計削減見込み**: 約100-150行

---

## 📈 総合削減見込み

### 優先度別削減見込み

| 優先度 | 削減見込み行数 | ファイル数 |
|--------|---------------|-----------|
| **高** | 640-880行 | 8ファイル |
| **中** | 830-1,160行 | 7ファイル |
| **低** | 260-410行 | 5ファイル |
| **合計** | **1,730-2,450行** | **20ファイル** |

### 最終的な見込み

- **現在**: 4,732行
- **削減後**: 約2,282-3,002行（約39-63%削減）
- **理想的な目標**: 約2,000-2,500行

---

## 🎯 推奨分割順序

### フェーズ1（優先度: 高）- 見込み削減: 640-880行

1. ✅ **ダイアログ関連の分離**（410-550行削減）
   - `widgets/dialogs/custom_adherence_dialog.dart`
   - `widgets/dialogs/edit_memo_dialog.dart`
   - `widgets/dialogs/add_memo_dialog.dart`
   - `widgets/dialogs/warning_dialog.dart`

2. ✅ **データ保存・読み込み処理の分離**（230-330行削減）
   - `persistence/snapshot_persistence.dart`
   - `persistence/calendar_mark_persistence.dart`
   - `persistence/data_sync_manager.dart`

### フェーズ2（優先度: 中）- 見込み削減: 830-1,160行

3. ✅ **イベントハンドラー拡張**（450-630行削減）
   - `handlers/memo_event_handler.dart`
   - `handlers/calendar_event_handler.dart`（拡張）
   - `handlers/tab_event_handler.dart`

4. ✅ **UIビルダーメソッドの分離**（380-530行削減）
   - `widgets/medication_memo_checkbox.dart`
   - `widgets/custom_adherence_card.dart`
   - `widgets/stats_tab_content.dart`
   - `widgets/home_app_bar.dart`

### フェーズ3（優先度: 低）- 見込み削減: 260-410行

5. ✅ **バリデーション・チェック処理**（80-130行削減）
   - `business/validation_manager.dart`

6. ✅ **ヘルパーメソッド**（80-130行削減）
   - `business/helpers/date_helper.dart`
   - `business/helpers/data_converter.dart`

7. ✅ **初期化処理**（100-150行削減）
   - `business/initialization_manager.dart`

---

## 💡 実装の注意点

1. **依存関係の管理**: 新しいファイル間の依存関係を明確にする
2. **テスト容易性**: 各クラスが独立してテスト可能にする
3. **パフォーマンス**: 不要な再構築を避ける
4. **後方互換性**: 既存の機能を損なわないようにする

---

## 📝 次のステップ

1. **フェーズ1の実装**を開始（ダイアログ関連の分離）
2. **テスト**を実行して動作確認
3. **リンターエラー**の確認と修正
4. **ドキュメント**の更新

---

作成日: 2024年
最終更新: 現在

