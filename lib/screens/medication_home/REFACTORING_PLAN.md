# MedicationHomePage リファクタリング全体設計書

## 📊 1. 現状分析

### 1.1 現在のファイル構成

```
lib/screens/
├── home_page.dart (4,153行) ⚠️ 巨大ファイル
│
├── home/                       ✅ 既存の分割済みファイル
│   ├── persistence/
│   │   ├── medication_data_persistence.dart
│   │   ├── alarm_data_persistence.dart
│   │   ├── snapshot_persistence.dart
│   │   └── data_sync_manager.dart
│   ├── handlers/
│   │   ├── calendar_event_handler.dart
│   │   ├── medication_event_handler.dart
│   │   ├── memo_event_handler.dart
│   │   └── backup_handler.dart
│   ├── business/
│   │   ├── calendar_marker_manager.dart
│   │   ├── medication_calculator.dart
│   │   └── pagination_manager.dart
│   ├── state/
│   │   ├── home_page_state.dart
│   │   └── home_page_state_notifiers.dart
│   └── widgets/
│       ├── calendar_view.dart
│       ├── medication_record_list.dart
│       ├── medication_stats_card.dart
│       ├── memo_field.dart
│       ├── medication_item_widgets.dart
│       └── dialogs/
│           ├── backup_dialog.dart
│           ├── backup_history_dialog.dart
│           ├── backup_preview_dialog.dart
│           ├── custom_adherence_dialog.dart
│           └── warning_dialog.dart
│
└── helpers/                    ⚠️ ヘルパー関数群（統合対象）
    ├── home_page_backup_helper.dart
    ├── home_page_data_helper.dart
    ├── home_page_alarm_helper.dart
    ├── home_page_stats_helper.dart
    └── home_page_utils_helper.dart
```

### 1.2 現状の問題点

| 問題 | 詳細 | 影響度 | 優先度 |
|------|------|--------|--------|
| **巨大なStatefulWidget** | 4,153行の単一ファイル | 🔴 高 | P0 |
| **状態変数の過多** | 約50個の状態変数が密結合 | 🔴 高 | P0 |
| **責務の混在** | UI/ロジック/データアクセスが同一ファイル | 🔴 高 | P0 |
| **テストの困難さ** | ビジネスロジックとUIが分離不可 | 🟡 中 | P1 |
| **コード重複** | helper/handler/persistenceに機能重複 | 🟡 中 | P1 |
| **依存関係の混乱** | 循環参照のリスク | 🟢 低 | P2 |

### 1.3 既存分割の状況

✅ **既に分割済み（活用できる）**
- データ永続化層（`persistence/`）
- イベントハンドラー層（`handlers/`）
- ビジネスロジック層（`business/`）
- UIウィジェット層（`widgets/`）

⚠️ **統合が必要**
- `helpers/`配下の関数群をRepository/UseCaseに統合
- 重複機能の統合（例：バックアップ処理がhelperとhandlerに分散）

---

## 🏗️ 2. 目標アーキテクチャ

### 2.1 Clean Architecture 層構造

```
┌─────────────────────────────────────────┐
│   Presentation Layer (UI)               │
│   - medication_home_page.dart (200行)   │
│   - widgets/ (既存維持)                 │
│   - StatefulWidget → StatelessWidget化 │
└─────────────┬───────────────────────────┘
              │ depends on
┌─────────────▼───────────────────────────┐
│   Application Layer (Controllers)       │
│   - MedicationHomeController            │
│   - CalendarController                  │
│   - MedicationMemoController            │
│   - StatsController                     │
│   - BackupController                    │
└─────────────┬───────────────────────────┘
              │ depends on
┌─────────────▼───────────────────────────┐
│   Domain Layer (Business Logic)         │
│   - Use Cases                          │
│   - Calculators                         │
│   - Models/State                        │
└─────────────┬───────────────────────────┘
              │ depends on
┌─────────────▼───────────────────────────┐
│   Data Layer (Repositories)             │
│   - MedicationRepository                │
│   - AlarmRepository                     │
│   - BackupRepository                    │
│   - CalendarRepository                  │
└─────────────────────────────────────────┘
```

### 2.2 依存関係の原則

**✅ 許可される依存**
- UI → Controller
- Controller → Repository / UseCase
- Repository → DataSource
- UseCase → Repository

**❌ 禁止される依存**
- Repository → Controller
- UI → Repository (直接アクセス禁止)
- DataSource → Repository

---

## 📁 3. 詳細なファイル構成

### 3.1 最終的なディレクトリ構造

```
lib/screens/medication_home/
│
├── medication_home_page.dart                    # エントリーポイント（200行以下目標）
│
├── controllers/                                 # Application Layer
│   ├── medication_home_controller.dart          # メインController（状態統合）
│   ├── calendar_controller.dart                 # カレンダー専用
│   ├── medication_memo_controller.dart          # 服用メモ専用
│   ├── alarm_controller.dart                    # アラーム専用
│   ├── stats_controller.dart                    # 統計計算専用
│   └── backup_controller.dart                   # バックアップ専用
│
├── repositories/                                # Data Layer（既存persistence/を統合）
│   ├── medication_repository.dart               # 服用メモデータ
│   │   └── (既存: medication_data_persistence.dart を統合)
│   ├── alarm_repository.dart                    # アラームデータ
│   │   └── (既存: alarm_data_persistence.dart を統合)
│   ├── calendar_repository.dart                 # カレンダーデータ
│   ├── backup_repository.dart                   # バックアップデータ
│   │   └── (既存: backup_handler.dart を統合)
│   └── preference_repository.dart               # 設定データ
│       └── (既存: data_sync_manager.dart を統合)
│
├── use_cases/                                   # Domain Layer
│   ├── medication/
│   │   ├── add_medication_memo_use_case.dart
│   │   ├── edit_medication_memo_use_case.dart
│   │   ├── delete_medication_memo_use_case.dart
│   │   └── mark_as_taken_use_case.dart
│   ├── calendar/
│   │   ├── update_calendar_marker_use_case.dart
│   │   └── calculate_day_stats_use_case.dart
│   ├── stats/
│   │   ├── calculate_adherence_use_case.dart    # (既存: adherence_calculator.dart を統合)
│   │   └── calculate_custom_adherence_use_case.dart
│   └── backup/
│       ├── create_backup_use_case.dart
│       ├── restore_backup_use_case.dart
│       └── delete_backup_use_case.dart
│
├── models/                                      # Domain Layer
│   ├── medication_home_state.dart               # 統合状態モデル
│   │   └── (既存: home_page_state.dart を拡張)
│   ├── calendar_state.dart                      # カレンダー状態
│   ├── medication_state.dart                    # 服用メモ状態
│   └── stats_state.dart                         # 統計状態
│
├── widgets/                                     # Presentation Layer（既存維持＋拡張）
│   ├── tabs/
│   │   ├── calendar_tab_widget.dart            # (既存: calendar_tab.dart)
│   │   ├── medicine_tab_widget.dart            # (既存: medicine_tab.dart)
│   │   ├── alarm_tab_widget.dart               # (既存: alarm_tab.dart)
│   │   └── stats_tab_widget.dart               # (既存: stats_tab.dart)
│   │
│   ├── calendar/
│   │   ├── calendar_view.dart                   # (既存)
│   │   ├── calendar_day_cell.dart              # 新規作成
│   │   └── calendar_legend.dart                # 新規作成
│   │
│   ├── medication/
│   │   ├── medication_record_list.dart         # (既存)
│   │   ├── medication_item_widgets.dart        # (既存)
│   │   └── medication_stats_card.dart          # (既存)
│   │
│   └── dialogs/                                # (既存維持)
│       ├── backup_dialog.dart
│       ├── backup_history_dialog.dart
│       ├── backup_preview_dialog.dart
│       ├── custom_adherence_dialog.dart
│       └── warning_dialog.dart
│
└── utils/                                       # 共通ユーティリティ
    ├── date_utils.dart                          # 日付処理
    ├── validation_utils.dart                   # バリデーション
    └── format_utils.dart                        # フォーマット
```

### 3.2 既存ファイルの統合マッピング

| 既存ファイル | 統合先 | 移行方法 |
|------------|--------|---------|
| `home/persistence/medication_data_persistence.dart` | `repositories/medication_repository.dart` | メソッドをRepositoryパターンに統一 |
| `home/persistence/alarm_data_persistence.dart` | `repositories/alarm_repository.dart` | そのまま移行 |
| `home/persistence/data_sync_manager.dart` | `repositories/preference_repository.dart` | 設定関連を統合 |
| `home/handlers/calendar_event_handler.dart` | `controllers/calendar_controller.dart` | ChangeNotifierに変換 |
| `home/handlers/medication_event_handler.dart` | `controllers/medication_memo_controller.dart` | ChangeNotifierに変換 |
| `home/handlers/memo_event_handler.dart` | `use_cases/medication/*_use_case.dart` | UseCaseパターンに分割 |
| `home/handlers/backup_handler.dart` | `controllers/backup_controller.dart` + `repositories/backup_repository.dart` | 責務を分離 |
| `home/business/medication_calculator.dart` | `use_cases/stats/calculate_adherence_use_case.dart` | UseCaseパターンに変換 |
| `home/business/pagination_manager.dart` | `repositories/medication_repository.dart` | ページネーション機能として統合 |
| `helpers/home_page_backup_helper.dart` | `repositories/backup_repository.dart` | 機能を統合 |
| `helpers/home_page_data_helper.dart` | `repositories/` 各Repository | 機能別に分散 |
| `helpers/home_page_stats_helper.dart` | `use_cases/stats/` | UseCaseに変換 |

---

## 🎯 4. 段階的移行計画（5 Phases）

### Phase 1: Repository層の統合・構築（Week 1）

**目標**: データアクセス層を統一し、既存のpersistence/handlerを統合

**タスク一覧**
1. ✅ `MedicationRepository`作成（既存`MedicationDataPersistence`を吸収）
2. ✅ `AlarmRepository`作成（既存`AlarmDataPersistence`を吸収）
3. ✅ `BackupRepository`作成（既存`BackupHandler`のデータ部分を統合）
4. ✅ `CalendarRepository`作成（新規）
5. ✅ `PreferenceRepository`作成（既存`DataSyncManager`を統合）
6. ✅ 既存のhelper関数を各Repositoryに分散
7. ✅ 単体テスト作成（各Repository）

**成果物例**

```dart
// repositories/medication_repository.dart
class MedicationRepository {
  final MedicationDataPersistence _persistence; // 既存クラスを利用
  
  Future<List<MedicationMemo>> loadMemos() async {
    return await _persistence.loadMedicationMemos();
  }
  
  Future<void> saveMemo(MedicationMemo memo) async {
    await _persistence.saveMedicationMemo(memo);
  }
  
  Future<void> deleteMemo(String id) async {
    await _persistence.deleteMedicationMemo(id);
  }
  
  Future<Map<String, bool>> loadMemoStatus() async {
    return await _persistence.loadMedicationMemoStatus();
  }
}
```

**リスク対策**
- 既存のPersistenceクラスとの互換性: アダプターパターンで段階的移行
- データ移行: 旧データ形式との互換性を保証

---

### Phase 2: UseCase層の構築（Week 2）

**目標**: ビジネスロジックを再利用可能なUseCaseに分離

**タスク一覧**
1. ✅ `AddMedicationMemoUseCase`作成（既存`MemoEventHandler.addMemo`を統合）
2. ✅ `EditMedicationMemoUseCase`作成
3. ✅ `DeleteMedicationMemoUseCase`作成
4. ✅ `MarkAsTakenUseCase`作成
5. ✅ `CalculateAdherenceUseCase`作成（既存`AdherenceCalculator`を統合）
6. ✅ `CalculateCustomAdherenceUseCase`作成
7. ✅ `CreateBackupUseCase`作成
8. ✅ `RestoreBackupUseCase`作成

**成果物例**

```dart
// use_cases/medication/add_medication_memo_use_case.dart
class AddMedicationMemoUseCase {
  final MedicationRepository _repository;
  
  AddMedicationMemoUseCase(this._repository);
  
  Future<Result<MedicationMemo>> execute({
    required MedicationMemo memo,
    required List<MedicationMemo> existingMemos,
    required int maxMemos,
  }) async {
    // バリデーション
    if (existingMemos.length >= maxMemos) {
      return Result.failure('メモは最大$maxMemos件まで設定できます');
    }
    
    // タイトル自動生成
    final title = memo.name.trim().isEmpty 
        ? _generateDefaultTitle(existingMemos)
        : memo.name;
    
    final memoToSave = memo.copyWith(name: title);
    
    // 保存
    await _repository.saveMemo(memoToSave);
    
    return Result.success(memoToSave);
  }
  
  String _generateDefaultTitle(List<MedicationMemo> existing) {
    // 実装
  }
}
```

---

### Phase 3: Controller層の構築（Week 3）

**目標**: 状態管理をUIから分離し、ChangeNotifierで統一

**タスク一覧**
1. ✅ `MedicationHomeController`作成（メイン状態管理）
2. ✅ `CalendarController`作成（既存`CalendarEventHandler`を統合）
3. ✅ `MedicationMemoController`作成（既存`MedicationEventHandler`を統合）
4. ✅ `StatsController`作成（統計計算の状態管理）
5. ✅ `BackupController`作成（既存`BackupHandler`のUI部分を統合）
6. ✅ 状態管理を`ChangeNotifier`に統一
7. ✅ メモリリーク検証

**成果物例**

```dart
// controllers/medication_home_controller.dart
class MedicationHomeController extends ChangeNotifier {
  final MedicationRepository _medicationRepo;
  final AlarmRepository _alarmRepo;
  final CalendarRepository _calendarRepo;
  
  // 状態
  DateTime? _selectedDay;
  List<MedicationMemo> _memos = [];
  Map<String, Color> _dayColors = {};
  bool _isLoading = false;
  String? _error;
  
  // ゲッター
  DateTime? get selectedDay => _selectedDay;
  List<MedicationMemo> get memos => _memos;
  Map<String, Color> get dayColors => _dayColors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 初期化
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _memos = await _medicationRepo.loadMemos();
      _dayColors = await _calendarRepo.loadDayColors();
      _error = null;
    } catch (e) {
      _error = 'データ読み込みに失敗しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 日付選択
  void selectDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }
  
  // メモ追加
  Future<void> addMemo(MedicationMemo memo) async {
    final useCase = AddMedicationMemoUseCase(_medicationRepo);
    final result = await useCase.execute(
      memo: memo,
      existingMemos: _memos,
      maxMemos: 1000,
    );
    
    result.when(
      success: (savedMemo) {
        _memos.add(savedMemo);
        notifyListeners();
      },
      failure: (error) {
        _error = error;
        notifyListeners();
      },
    );
  }
}
```

**マイグレーション例**

```dart
// Before (State内)
void _addMemo() {
  setState(() {
    _medicationMemos.add(memo);
  });
  _saveMedicationMemoWithBackup(memo);
}

// After (Controller使用)
void _addMemo() {
  _controller.addMemo(memo); // Controllerに委譲
}
```

---

### Phase 4: UI層の簡素化（Week 4）

**目標**: StatefulWidgetを薄くし、Controller経由で状態管理

**タスク一覧**
1. ✅ `medication_home_page.dart`を200行以下に削減
2. ✅ 各タブをStatelessWidgetに変換
3. ✅ Controllerとの接続を`ListenableBuilder`で実装
4. ✅ 不要なMixinを削除
5. ✅ 状態変数をControllerに移動

**成果物例**

```dart
// medication_home_page.dart (簡素化版 - 200行以下目標)
class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});
  
  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}

class _MedicationHomePageState extends State<MedicationHomePage> 
    with TickerProviderStateMixin {
  late MedicationHomeController _controller;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    
    // Repository初期化
    final medicationRepo = MedicationRepository();
    final alarmRepo = AlarmRepository();
    final calendarRepo = CalendarRepository();
    final backupRepo = BackupRepository();
    
    // Controller初期化
    _controller = MedicationHomeController(
      medicationRepo: medicationRepo,
      alarmRepo: alarmRepo,
      calendarRepo: calendarRepo,
      backupRepo: backupRepo,
    );
    
    _tabController = TabController(length: 4, vsync: this);
    
    // データ読み込み
    _controller.initialize();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (_controller.error != null) {
          return Scaffold(
            body: Center(
              child: Text('エラー: ${_controller.error}'),
            ),
          );
        }
        
        return Scaffold(
          appBar: _buildAppBar(),
          body: TabBarView(
            controller: _tabController,
            children: [
              CalendarTabWidget(controller: _controller),
              MedicineTabWidget(controller: _controller),
              AlarmTabWidget(controller: _controller),
              StatsTabWidget(controller: _controller),
            ],
          ),
        );
      },
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('サプリ＆おくすりスケジュール管理帳'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.calendar_month), text: 'カレンダー'),
          Tab(icon: Icon(Icons.medication), text: '服用メモ'),
          Tab(icon: Icon(Icons.alarm), text: 'アラーム'),
          Tab(icon: Icon(Icons.analytics), text: '統計'),
        ],
      ),
      actions: [
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.backup),
                  SizedBox(width: 8),
                  Text('バックアップ'),
                ],
              ),
              onTap: () => _controller.showBackupDialog(context),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

### Phase 5: テストとリファクタリング（Week 5）

**目標**: 品質保証と最終調整

**タスク一覧**
1. ✅ 単体テスト（Repository: 80%カバレッジ目標）
2. ✅ 単体テスト（UseCase: 100%カバレッジ目標）
3. ✅ 単体テスト（Controller: 60%カバレッジ目標）
4. ✅ 統合テスト（主要フロー）
5. ✅ パフォーマンステスト
6. ✅ 不要コードの削除
7. ✅ ドキュメント整備

**テストサンプル**

```dart
// test/repositories/medication_repository_test.dart
void main() {
  group('MedicationRepository', () {
    late MedicationRepository repository;
    late MockMedicationDataPersistence mockPersistence;
    
    setUp(() {
      mockPersistence = MockMedicationDataPersistence();
      repository = MedicationRepository(mockPersistence);
    });
    
    test('メモを保存して読み込める', () async {
      final memo = MedicationMemo(id: '1', name: 'テスト薬');
      
      when(() => mockPersistence.saveMedicationMemo(memo))
          .thenAnswer((_) async => Future.value());
      when(() => mockPersistence.loadMedicationMemos())
          .thenAnswer((_) async => [memo]);
      
      await repository.saveMemo(memo);
      final loaded = await repository.loadMemos();
      
      expect(loaded.length, 1);
      expect(loaded.first.name, 'テスト薬');
      verify(() => mockPersistence.saveMedicationMemo(memo)).called(1);
    });
    
    test('メモ削除時にエラーハンドリング', () async {
      when(() => mockPersistence.deleteMedicationMemo('invalid'))
          .thenThrow(Exception('削除失敗'));
      
      expect(
        () => repository.deleteMemo('invalid'),
        throwsException,
      );
    });
  });
}
```

---

## 🔧 5. 実装ガイドライン

### 5.1 命名規則

| 要素 | 命名規則 | 例 |
|------|---------|-----|
| Controller | `XxxController` | `MedicationHomeController` |
| Repository | `XxxRepository` | `MedicationRepository` |
| UseCase | `VerbNounUseCase` | `AddMedicationMemoUseCase` |
| Model | `XxxState`, `XxxModel` | `MedicationHomeState` |
| Widget | `XxxWidget` | `CalendarTabWidget` |

### 5.2 エラーハンドリング戦略

```dart
// Result型を使用（既存: lib/core/result.dart を活用）
class Result<T> {
  final T? data;
  final String? error;
  
  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
  
  bool get isSuccess => error == null;
  bool get isFailure => error != null;
  
  R when<R>({
    required R Function(T) success,
    required R Function(String) failure,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return failure(error!);
    }
  }
}

// Repository層
class MedicationRepository {
  Future<Result<List<MedicationMemo>>> loadMemos() async {
    try {
      final memos = await _persistence.loadMedicationMemos();
      return Result.success(memos);
    } on HiveError catch (e) {
      Logger.error('Hiveエラー', e);
      // フォールバック
      final backup = await _loadFromBackup();
      if (backup != null) {
        return Result.success(backup);
      }
      return Result.failure('データ読み込みに失敗しました');
    } catch (e) {
      Logger.error('予期しないエラー', e);
      return Result.failure('予期しないエラーが発生しました: $e');
    }
  }
}

// Controller層
class MedicationHomeController extends ChangeNotifier {
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    final result = await _repository.loadMemos();
    
    result.when(
      success: (memos) {
        _memos = memos;
        _error = null;
      },
      failure: (error) {
        _error = error;
        _memos = [];
      },
    );
    
    _isLoading = false;
    notifyListeners();
  }
}

// UI層
ListenableBuilder(
  listenable: _controller,
  builder: (context, _) {
    if (_controller.isLoading) {
      return const CircularProgressIndicator();
    }
    
    if (_controller.error != null) {
      return ErrorWidget(message: _controller.error!);
    }
    
    return SuccessWidget(data: _controller.memos);
  },
)
```

### 5.3 非同期処理のベストプラクティス

```dart
// ❌ 悪い例：非同期処理をsetState内で実行
setState(() {
  _loadData(); // 非同期なのでsetStateが先に終わる
});

// ✅ 良い例：非同期処理完了後にsetState
await _loadData();
setState(() {
  // 状態更新
});

// ✅ さらに良い例：Controllerで管理
_controller.loadData(); // Controller内でnotifyListeners()
```

---

## 📈 6. マイグレーション前後の比較

### 6.1 コード行数の変化

| ファイル/ディレクトリ | Before | After | 削減率 |
|---------------------|--------|-------|--------|
| `medication_home_page.dart` | 4,153行 | 200行 | **95%削減** |
| Controllers (合計) | 0行 | 800行 | - |
| Repositories (合計) | 600行 | 600行 | 統合 |
| UseCases (合計) | 400行 | 500行 | 拡張 |
| **合計** | **5,153行** | **2,100行** | **59%削減** |

### 6.2 テスタビリティの向上

```dart
// Before: テスト不可能（Widgetに密結合）
class _MedicationHomePageState extends State {
  void _calculateAdherence() {
    // UIと密結合したビジネスロジック
    // setState, BuildContext に依存
  }
}

// After: 単体テスト可能
class CalculateAdherenceUseCase {
  double execute({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> memos,
  }) {
    // Pure Function（副作用なし）
    // テスト可能
  }
}

// テスト
test('30日間の遵守率計算', () {
  final useCase = CalculateAdherenceUseCase();
  final result = useCase.execute(
    days: 30,
    medicationData: mockData,
    memos: mockMemos,
  );
  expect(result, closeTo(85.5, 0.1));
});
```

---

## 🚨 7. リスク管理

### 7.1 主要リスクと対策

| リスク | 影響度 | 対策 |
|--------|--------|------|
| **既存機能の破壊** | 🔴 高 | ・段階的移行<br>・並行実行期間を設定<br>・Rollback計画 |
| **パフォーマンス劣化** | 🟡 中 | ・ベンチマークテスト<br>・Profilerで計測<br>・キャッシュ戦略の見直し |
| **開発期間の超過** | 🟡 中 | ・週次レビュー<br>・優先度調整<br>・MVP（最小機能）でのリリース |
| **チーム学習コスト** | 🟢 低 | ・ドキュメント整備<br>・ペアプロ実施<br>・コードレビューで知識共有 |

### 7.2 Rollback計画

```dart
// フィーチャーフラグでの切り替え
class FeatureFlags {
  static const bool useNewArchitecture = true; // 段階的に切り替え
}

// エントリーポイント
Widget build(BuildContext context) {
  if (FeatureFlags.useNewArchitecture) {
    return NewMedicationHomePage(); // 新アーキテクチャ
  } else {
    return LegacyMedicationHomePage(); // 旧アーキテクチャ（既存）
  }
}
```

---

## ✅ 8. 完了基準（Definition of Done）

### Phase 1 (Repository層)
- [ ] 全Repositoryクラスが作成済み
- [ ] 既存Persistence/H ANDLERとの統合完了
- [ ] 単体テストカバレッジ80%以上
- [ ] 既存機能との互換性確認
- [ ] コードレビュー完了

### Phase 2 (UseCase層)
- [ ] 全UseCaseクラスが作成済み
- [ ] 既存Calculator/Handlerとの統合完了
- [ ] 単体テストカバレッジ100%
- [ ] ドキュメント整備完了

### Phase 3 (Controller層)
- [ ] 全Controllerクラスが作成済み
- [ ] 状態管理がChangeNotifierに統一
- [ ] メモリリーク検証完了
- [ ] パフォーマンステスト合格

### Phase 4 (UI層簡素化)
- [ ] `medication_home_page.dart`が200行以下
- [ ] Mixinの使用が0個
- [ ] ウィジェットツリーの深さ5階層以内
- [ ] UI動作確認完了

### Phase 5 (テスト)
- [ ] 全体カバレッジ70%以上
- [ ] パフォーマンス基準クリア（起動3秒以内）
- [ ] 不要コード削除完了
- [ ] リリース準備完了

---

## 📚 9. 参考資料

### 推奨読書
- Flutter Architecture Samples
- Clean Architecture in Flutter
- Provider + ChangeNotifier Best Practices

### コーディング規約
- Effective Dart
- Flutter Style Guide

---

## 🎉 10. 期待される効果

### 開発効率の向上
- **新機能追加時間**: 50%削減（適切な層に追加するだけ）
- **バグ修正時間**: 60%削減（責務が明確）
- **コードレビュー時間**: 40%削減（ファイルが小さい）

### 品質向上
- **テストカバレッジ**: 20% → 70%
- **バグ発生率**: 30%削減
- **技術的負債**: 大幅削減

### チーム協業
- **並行開発**: 複数人が同時に異なる層を編集可能
- **オンボーディング**: 新メンバーが理解しやすい
- **属人化解消**: 層ごとに責任者を分散

---

## 🚀 次のステップ

1. **Phase 1開始**: Repository層の統合・構築
2. **既存コード確認**: 統合対象ファイルの詳細確認
3. **テスト環境整備**: Mock/Test用のセットアップ
4. **ドキュメント作成**: API仕様書の作成

---

**作成日**: 2024年
**最終更新**: 現在
**ステータス**: 📋 計画作成完了 - Phase 1準備中

