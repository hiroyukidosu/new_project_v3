# データ永続化機能 - 使い方ガイド

## 📋 概要

`DataPersistence`クラスは、アプリ再起動後のデータ消失問題を完全に解決するための包括的なデータ保存・読み込み機能を提供します。

## 🎯 主な機能

### 1. 動的薬リスト（_addedMedications）の保存・読み込み
- **4重バックアップ**: 複数のキーにデータを保存
- **フォールバック機能**: 1つのバックアップが失敗しても他のバックアップから復元
- **JSON配列形式**: 従来方式とJSON配列形式の両方でバックアップ

### 2. アラームリスト（_alarmList）の保存・読み込み
- **3重バックアップ**: 複数のキーにデータを保存
- **個別キー保存**: 各アラームを個別に保存
- **曜日データ**: 曜日選択状態も個別に保存

## 💻 使い方

### main.dartでの使用例

#### 1. インポート
```dart
import 'package:new_project_v3/utils/data_persistence.dart';
```

#### 2. 動的薬リストの保存

既存の`_saveMedicationList()`メソッドを以下のように置き換えます：

```dart
// ✅ 改善版：動的薬リスト保存
Future<void> _saveMedicationList() async {
  await DataPersistence.saveMedicationList(_addedMedications);
}
```

#### 3. 動的薬リストの読み込み

既存の`_loadMedicationList()`メソッドを以下のように置き換えます：

```dart
// ✅ 改善版：動的薬リスト読み込み
Future<void> _loadMedicationList() async {
  final loadedMedications = await DataPersistence.loadMedicationList();
  setState(() {
    _addedMedications = loadedMedications;
  });
}
```

#### 4. アラームデータの保存

既存の`_saveAlarmData()`メソッドを以下のように置き換えます：

```dart
// ✅ 改善版：アラームデータ保存
Future<void> _saveAlarmData() async {
  await DataPersistence.saveAlarmData(_alarmList, _alarmSettings);
}
```

#### 5. アラームデータの読み込み

既存の`_loadAlarmData()`メソッドを以下のように置き換えます：

```dart
// ✅ 改善版：アラームデータ読み込み
Future<void> _loadAlarmData() async {
  final alarmData = await DataPersistence.loadAlarmData();
  setState(() {
    _alarmList = alarmData['alarmList'] as List<Map<String, dynamic>>;
    _alarmSettings = alarmData['alarmSettings'] as Map<String, dynamic>;
  });
}
```

## 🔍 動作の詳細

### 保存時の動作

1. **動的薬リスト**:
   - `medicationList` (メイン)
   - `medicationList_backup` (バックアップ1)
   - `medicationList_backup2` (バックアップ2)
   - `medicationList_backup3` (バックアップ3)
   - `medicationList_array` (配列形式)
   - `medicationList_array_backup` (配列形式バックアップ)
   - `medicationList_count` (件数)
   - `medicationList_count_backup` (件数バックアップ)

2. **アラームリスト**:
   - `alarm_list_json` (JSON配列)
   - `alarm_list_json_backup` (バックアップ1)
   - `alarm_list_json_backup2` (バックアップ2)
   - `alarm_0`, `alarm_1`, ... (個別アラーム)
   - `alarm_0_backup`, `alarm_1_backup`, ... (個別バックアップ)
   - `alarm_0_day_0`, `alarm_0_day_1`, ... (曜日データ)
   - `alarm_count` (件数)
   - `alarm_settings` (設定)

### 読み込み時の動作

1. **優先順位**:
   - メインキーから読み込み試行
   - 失敗した場合、バックアップ1から試行
   - 失敗した場合、バックアップ2から試行
   - 全て失敗した場合、配列形式/個別キーから試行

2. **エラーハンドリング**:
   - 各ステップでエラーが発生しても次のバックアップにフォールバック
   - 全てのバックアップが失敗しても空のリストを返す（クラッシュしない）

## 🛡️ 信頼性

- **多重バックアップ**: データ消失のリスクを最小化
- **フォールバック機構**: 1つのバックアップが壊れても復元可能
- **エラーハンドリング**: 例外が発生してもアプリがクラッシュしない
- **デバッグログ**: 詳細なログで問題を追跡可能

## ✅ メリット

1. **データ消失防止**: 4重バックアップでデータを確実に保護
2. **アプリ再起動対応**: アプリを閉じても開いてもデータが残る
3. **自動復元**: フォールバック機能で自動的に最適なバックアップから復元
4. **パフォーマンス**: Future.waitで並列保存により高速化
5. **保守性**: 1つのクラスで管理するため保守が容易

## 🔧 トラブルシューティング

### データが保存されない場合
- デバッグログを確認: `💾 動的薬リスト保存開始...` → `✅ 動的薬リスト保存完了`
- エラーログを確認: `❌ 動的薬リスト保存エラー`

### データが読み込まれない場合
- デバッグログを確認: `📖 動的薬リスト読み込み開始...` → `✅ 動的薬リスト読み込み完了`
- フォールバックログを確認: `⚠️ 動的薬リストが見つかりません`

## 📝 注意事項

- この機能を使う前に、既存の保存・読み込み機能をバックアップしてください
- 既存のキー名と競合しないように注意してください
- デバッグログを有効にして動作を確認してください

