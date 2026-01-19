# 🔍 無限ループの原因候補（怪しい処理リスト）

## 🚨 最優先で確認すべき問題

### 1. **StatisticsProvider._recalculateAllStatistics() の166行目**
```dart
_notifyListenersWithTracking('計算開始'); // ← これが怪しい！
```
**問題**: 計算開始時に`notifyListeners()`を呼ぶと、`Selector`が反応して再ビルドされる。
**影響**: 再ビルドのたびに何かがトリガーされる可能性がある。

### 2. **StatisticsPage._onMedicationDataChanged() の42行目**
```dart
medicationProvider.addListener(_onMedicationDataChanged);
```
**問題**: `MedicationProvider`の`notifyListeners()`が呼ばれるたびに、このリスナーが反応する。
**影響**: `StatisticsProvider`の`notifyListeners()`が間接的に`MedicationProvider`を更新している可能性。

### 3. **MedicationProvider._notifySafely() の144行目**
```dart
notifyListeners(); // ← これが_onMedicationDataChangedをトリガー
```
**問題**: `_notifySafely()`が呼ばれると、`_onMedicationDataChanged`が反応する。
**影響**: これが`scheduleRecalculation()`を呼び、再計算が始まる。

### 4. **StatisticsProvider._recalculateAllStatistics() の162行目**
```dart
_medicationProvider!.setUpdateFlag(true);
```
**問題**: フラグを設定しても、既にリスナーが登録されている場合は反応する可能性がある。
**影響**: フラグ設定のタイミングが遅い可能性。

### 5. **Selectorのbuilder内での処理**
```dart
builder: (context, data, _) {
  // builderが呼ばれるたびに何かが起こる可能性
}
```
**問題**: `builder`が呼ばれるたびに、内部で何かがトリガーされる可能性。

## 🔄 無限ループの可能性がある連鎖

### パターン1: notifyListeners() → Selector → 再ビルド → 何かがトリガー
```
StatisticsProvider.notifyListeners()
  ↓
Selectorが反応
  ↓
builderが呼ばれる
  ↓
何かがトリガーされる？
```

### パターン2: MedicationProvider.notifyListeners() → リスナー → scheduleRecalculation()
```
MedicationProvider.notifyListeners()
  ↓
_onMedicationDataChanged()が呼ばれる
  ↓
scheduleRecalculation()が呼ばれる
  ↓
_recalculateAllStatistics()が呼ばれる
  ↓
notifyListeners()が呼ばれる
  ↓
（間接的にMedicationProviderが更新される？）
```

### パターン3: 計算開始通知 → Selector → 再ビルド → リスナー反応
```
_recalculateAllStatistics()開始
  ↓
_notifyListenersWithTracking('計算開始')
  ↓
Selectorが反応
  ↓
再ビルド
  ↓
_onMedicationDataChangedが呼ばれる？
```

## 🛠️ 修正すべき箇所

1. **計算開始時の通知を削除**: `_notifyListenersWithTracking('計算開始')`を削除
2. **リスナーの登録タイミングを変更**: `initState`ではなく、別のタイミングで登録
3. **MedicationProviderの通知を完全に抑制**: 計算中は一切通知しない
4. **Selectorのbuilder内で何も実行しない**: 純粋にUIの表示のみ
