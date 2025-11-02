# MedicationHomePage リファクタリング分割案（調整版）

## 📊 現状分析

### 現在の状態（2024年時点）

- **ファイルサイズ**: 948行（目標: 200行以下）
- **既存分割状況**: 
  - ✅ Controllers: 4つ（medication, calendar, backup, alarm）
  - ✅ Handlers: 5つ（calendar_event, medication_event, memo_event, backup, home_page_event）
  - ✅ Operations: 5つ（backup, data, medication, calendar, ui）
  - ✅ Widgets: 多数（home_app_bar_menu, home_tab_bar_view等）
  - ✅ State: home_page_state_manager, home_page_state_notifiers
  - ✅ Mixins: 3つ（PurchaseMixin, CalendarUIBuilderMixin, MedicationUIBuilderMixin）

### 残っている問題

1. **初期化ロジックの分散**: `initState()`に約200行の初期化コード
2. **コールバックメソッド**: 多数のプライベートメソッドが残存
3. **依存関係管理**: 各クラスの初期化順序が複雑
4. **Mixinの肥大化**: 各Mixinがまだ大きい可能性

---

## 🎯 分割戦略（調整版）

### Phase 1: 初期化ロジックの分離（最優先）

#### `lib/screens/home/initialization/home_page_initializer.dart`（新規: 150行）

```dart
class HomePageInitializer {
  static Future<HomePageDependencies> initialize(
    BuildContext context,
    TickerProvider vsync,
  ) async {
    // 1. StateManagerの初期化
    final stateManager = HomePageStateManager(context);
    await stateManager.init();
    
    // 2. Controllersの初期化（StateManager依存）
    final controllers = _initializeControllers(stateManager);
    
    // 3. Operationsの初期化（StateManager + Controllers依存）
    final operations = _initializeOperations(stateManager, controllers);
    
    // 4. Handlersの初期化（すべて依存）
    final handlers = _initializeHandlers(
      stateManager,
      controllers,
      operations,
      context,
    );
    
    return HomePageDependencies(
      stateManager: stateManager,
      controllers: controllers,
      operations: operations,
      handlers: handlers,
      tabController: TabController(length: 4, vsync: vsync),
    );
  }
  
  static HomePageControllers _initializeControllers(
    HomePageStateManager stateManager,
  ) {
    return HomePageControllers(
      medication: MedicationController(stateManager: stateManager),
      calendar: CalendarController(stateManager: stateManager),
      backup: BackupController(stateManager: stateManager),
      alarm: AlarmController(stateManager: stateManager),
    );
  }
  
  static HomePageOperations _initializeOperations(
    HomePageStateManager stateManager,
    HomePageControllers controllers,
  ) {
    return HomePageOperations(
      backup: BackupOperations(stateManager: stateManager),
      data: DataOperations(stateManager: stateManager),
      medication: MedicationOperations(
        stateManager: stateManager,
        controller: controllers.medication,
      ),
      calendar: CalendarOperations(
        stateManager: stateManager,
        controller: controllers.calendar,
      ),
      ui: UIHelpers(stateManager: stateManager),
    );
  }
  
  static HomePageHandlers _initializeHandlers(
    HomePageStateManager stateManager,
    HomePageControllers controllers,
    HomePageOperations operations,
    BuildContext context,
  ) {
    return HomePageHandlers(
      main: HomePageEventHandler(
        stateManager: stateManager,
        operations: operations,
      ),
      calendar: CalendarEventHandler(
        stateManager: stateManager,
        controller: controllers.calendar,
      ),
      medication: MedicationEventHandler(
        stateManager: stateManager,
        controller: controllers.medication,
      ),
      memo: MemoEventHandler(
        stateManager: stateManager,
        controller: controllers.medication,
      ),
    );
  }
}
```

#### `lib/screens/home/initialization/home_page_dependencies.dart`（新規: 80行）

```dart
class HomePageDependencies {
  final HomePageStateManager stateManager;
  final HomePageControllers controllers;
  final HomePageOperations operations;
  final HomePageHandlers handlers;
  final TabController tabController;
  
  HomePageDependencies({
    required this.stateManager,
    required this.controllers,
    required this.operations,
    required this.handlers,
    required this.tabController,
  });
  
  void dispose() {
    tabController.dispose();
    stateManager.dispose();
    controllers.dispose();
    // handlersとoperationsは通常dispose不要
  }
}
```

---

### Phase 2: コントローラー・操作・ハンドラーの統合クラス

#### `lib/screens/home/controllers/home_page_controllers.dart`（新規: 100行）

```dart
class HomePageControllers {
  final MedicationController medication;
  final CalendarController calendar;
  final BackupController backup;
  final AlarmController alarm;
  
  HomePageControllers({
    required this.medication,
    required this.calendar,
    required this.backup,
    required this.alarm,
  });
  
  void dispose() {
    medication.dispose();
    calendar.dispose();
    backup.dispose();
    alarm.dispose();
  }
}
```

#### `lib/screens/home/operations/home_page_operations.dart`（新規: 100行）

```dart
class HomePageOperations {
  final BackupOperations backup;
  final DataOperations data;
  final MedicationOperations medication;
  final CalendarOperations calendar;
  final UIHelpers ui;
  
  HomePageOperations({
    required this.backup,
    required this.data,
    required this.medication,
    required this.calendar,
    required this.ui,
  });
}
```

#### `lib/screens/home/handlers/home_page_handlers.dart`（新規: 100行）

```dart
class HomePageHandlers {
  final HomePageEventHandler main;
  final CalendarEventHandler calendar;
  final MedicationEventHandler medication;
  final MemoEventHandler memo;
  
  HomePageHandlers({
    required this.main,
    required this.calendar,
    required this.medication,
    required this.memo,
  });
}
```

---

### Phase 3: コールバック・型定義の整理

#### `lib/screens/home/types/home_page_callbacks.dart`（新規: 50行）

```dart
// コールバック型定義
typedef OnStateChanged = void Function();
typedef OnDoseStatusChanged = void Function(String memoId, int doseIndex, bool isChecked);
typedef OnEditMemo = void Function(MedicationMemo memo);
typedef OnDeleteMemo = void Function(String memoId);
typedef OnMarkAsTaken = Future<void> Function(MedicationMemo memo);
typedef OnShowSnackBar = void Function(String message);
typedef OnShowMemoDetailDialog = void Function(BuildContext context, String name, String notes);
typedef OnShowWarningDialog = void Function();

// 設定型定義
class HomePageSettings {
  final bool isAlarmEnabled;
  final String selectedNotificationType;
  // その他設定...
}
```

#### `lib/screens/home/types/home_page_constants.dart`（新規: 50行）

```dart
class HomePageConstants {
  // データキー
  static const String medicationMemosKey = 'medication_memos_v2';
  static const String medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String addedMedicationsKey = 'added_medications_v2';
  static const String backupSuffix = '_backup';
  
  // UI定数
  static const int tabCount = 4;
  static const Duration debounceDuration = Duration(milliseconds: 500);
  
  // その他定数...
}
```

---

### Phase 4: Mixinの再編成（オプション）

既存のMixinが大きい場合は分割:

#### `lib/screens/home/mixins/`

```
- purchase_handler_mixin.dart (PurchaseMixinを分割)
- calendar_ui_mixin.dart (CalendarUIBuilderMixinのUI部分)
- calendar_logic_mixin.dart (CalendarUIBuilderMixinのロジック部分)
- medication_ui_mixin.dart (MedicationUIBuilderMixinのUI部分)
- medication_logic_mixin.dart (MedicationUIBuilderMixinのロジック部分)
```

---

## 📁 最終的なファイル構成

```
lib/screens/
├── home_page.dart (200行以下) ← 目標
│
├── home/
│   ├── initialization/ ← 新規
│   │   ├── home_page_initializer.dart (150行)
│   │   └── home_page_dependencies.dart (80行)
│   │
│   ├── controllers/
│   │   ├── home_page_controllers.dart (100行) ← 新規
│   │   ├── medication_controller.dart (既存)
│   │   ├── calendar_controller.dart (既存)
│   │   ├── backup_controller.dart (既存)
│   │   └── alarm_controller.dart (既存)
│   │
│   ├── operations/
│   │   ├── home_page_operations.dart (100行) ← 新規
│   │   ├── backup_operations.dart (既存)
│   │   ├── data_operations.dart (既存)
│   │   ├── medication_operations.dart (既存)
│   │   ├── calendar_operations.dart (既存)
│   │   └── ui_helpers.dart (既存)
│   │
│   ├── handlers/
│   │   ├── home_page_handlers.dart (100行) ← 新規
│   │   ├── home_page_event_handler.dart (既存)
│   │   ├── calendar_event_handler.dart (既存)
│   │   ├── medication_event_handler.dart (既存)
│   │   ├── memo_event_handler.dart (既存)
│   │   └── backup_handler.dart (既存)
│   │
│   ├── types/ ← 新規
│   │   ├── home_page_callbacks.dart (50行)
│   │   └── home_page_constants.dart (50行)
│   │
│   ├── mixins/
│   │   ├── purchase_mixin.dart (既存、必要に応じて分割)
│   │   ├── calendar_ui_builder_mixin.dart (既存、必要に応じて分割)
│   │   └── medication_ui_builder_mixin.dart (既存、必要に応じて分割)
│   │
│   ├── state/
│   │   ├── home_page_state_manager.dart (既存)
│   │   └── home_page_state_notifiers.dart (既存)
│   │
│   └── widgets/
│       ├── home_app_bar_menu.dart (既存)
│       ├── home_tab_bar_view.dart (既存)
│       └── ... (その他既存Widget)
```

---

## 🔧 リファクタリング手順（段階的）

### Phase 1: 初期化ロジックの分離（優先度: 高）

**目標**: `initState()`を30行以下に削減

1. ✅ `home_page_initializer.dart`を作成
2. ✅ `home_page_dependencies.dart`を作成
3. ✅ `initState()`の初期化ロジックを移動
4. ✅ 動作確認

**期待される削減**: 約200行 → 約30行（170行削減）

---

### Phase 2: コントローラー・操作・ハンドラーの統合（優先度: 中）

**目標**: 依存関係の明確化

1. ✅ `home_page_controllers.dart`を作成
2. ✅ `home_page_operations.dart`を作成
3. ✅ `home_page_handlers.dart`を作成
4. ✅ 参照を統合クラス経由に変更
5. ✅ 動作確認

**期待される削減**: 約50行（可読性向上）

---

### Phase 3: コールバック・定数の整理（優先度: 低）

**目標**: 型安全性と定数管理の向上

1. ✅ `home_page_callbacks.dart`を作成
2. ✅ `home_page_constants.dart`を作成
3. ✅ 型定義と定数を移動
4. ✅ 動作確認

**期待される削減**: 約30行（保守性向上）

---

### Phase 4: メインファイルの最終調整（優先度: 高）

**目標**: `home_page.dart`を200行以下に削減

1. ✅ 残存するプライベートメソッドを適切なクラスに移動
2. ✅ 不要なコメント・TODOを削除
3. ✅ UIフレームのみ残す
4. ✅ 最終動作確認

**期待される削減**: 約200行

---

## ✅ 最終的な`home_page.dart`の構造（目標）

```dart
// home_page.dart (約200行以下)

class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});
  
  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}

class _MedicationHomePageState extends State<MedicationHomePage> 
    with TickerProviderStateMixin,
         PurchaseMixin,
         CalendarUIBuilderMixin,
         MedicationUIBuilderMixin {
  
  HomePageDependencies? _dependencies;
  
  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }
  
  Future<void> _initializeAsync() async {
    final dependencies = await HomePageInitializer.initialize(
      context,
      this,
    );
    if (mounted) {
      setState(() => _dependencies = dependencies);
    }
  }
  
  @override
  void dispose() {
    _dependencies?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_dependencies == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Mixin経由で必要なプロパティを取得
    _setupMixinProperties();
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: HomeTabBarView(
        stateManager: _dependencies!.stateManager,
        tabController: _dependencies!.tabController,
        onEditMemo: _dependencies!.controllers.medication.editMemo,
        onDeleteMemo: _dependencies!.controllers.medication.deleteMemo,
        onMarkAsTaken: _dependencies!.controllers.medication.markAsTaken,
        onShowMemoDetailDialog: _dependencies!.handlers.main.showMemoDetailDialog,
        onShowWarningDialog: _dependencies!.handlers.main.showWarningDialog,
      ),
    );
  }
  
  void _setupMixinProperties() {
    // MixinがStateManager経由でデータにアクセスできるように設定
    // （既存の実装を維持）
  }
  
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('サプリ＆おくすりスケジュール管理帳'),
      centerTitle: true,
      actions: [
        HomeAppBarMenu(
          onPurchaseStatus: _dependencies!.handlers.main.showTrialStatus,
          onPurchaseLink: _dependencies!.handlers.main.showPurchaseLinkDialog,
          onBackup: _dependencies!.handlers.main.showBackupDialog,
        ),
      ],
      bottom: TabBar(
        controller: _dependencies!.tabController,
        tabs: const [
          Tab(icon: Icon(Icons.calendar_month), text: 'カレンダー'),
          Tab(icon: Icon(Icons.medication), text: '服用メモ'),
          Tab(icon: Icon(Icons.alarm), text: 'アラーム'),
          Tab(icon: Icon(Icons.analytics), text: '統計'),
        ],
      ),
    );
  }
}
```

---

## 📊 期待される効果

| 項目 | 現在 | 目標 |
|------|------|------|
| `home_page.dart`の行数 | 948行 | 200行以下 |
| 初期化ロジックの行数 | 約200行 | 約30行 |
| ファイル分割数 | - | +5ファイル（初期化関連） |
| 依存関係の明確性 | 低 | 高 |
| テスト容易性 | 中 | 高 |

---

## 🚨 注意点

1. **段階的リファクタリング**: Phaseごとに動作確認
2. **既存機能の維持**: 分割中も機能を完全に保持
3. **Mixinとの整合性**: Mixinのプロパティアクセスを維持
4. **非同期初期化**: StateManagerの非同期初期化を考慮

---

## ✅ 承認チェックリスト

- [ ] Phase 1: 初期化ロジックの分離
- [ ] Phase 2: コントローラー・操作・ハンドラーの統合
- [ ] Phase 3: コールバック・定数の整理
- [ ] Phase 4: メインファイルの最終調整
- [ ] 動作確認（全機能テスト）
- [ ] コードレビュー

---

この分割案は、既存の構造を最大限に活用しつつ、`home_page.dart`を200行以下に削減することを目標としています。

