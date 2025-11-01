# ページディレクトリ

このディレクトリには、新しいアーキテクチャに基づくページ実装が含まれています。

## 📁 ディレクトリ構造

```
pages/
├── calendar/
│   └── calendar_page.dart      # カレンダーページ
├── medicine/
│   └── medicine_page.dart       # 薬物管理ページ
├── alarm/
│   └── alarm_page.dart          # アラームページ
├── stats/
│   └── stats_page.dart          # 統計ページ
└── integrated_home_page.dart    # 統合ホームページ（タブ管理）
```

## 🔄 既存コードからの移行

### CalendarTab → CalendarPage
既存の`screens/tabs/calendar_tab.dart`から`pages/calendar/calendar_page.dart`への移行：
- 状態管理をRiverpodに移行
- リポジトリパターンを使用
- UIコンポーネントを細分化

### MedicineTab → MedicinePage
既存の`screens/tabs/medicine_tab.dart`から`pages/medicine/medicine_page.dart`への移行：
- UseCaseパターンでビジネスロジックを分離
- 状態管理をProviderに移行

## 🎯 使用方法

### 統合ホームページを使用

```dart
import 'pages/integrated_home_page.dart';

// MaterialAppのhomeに設定
home: const IntegratedHomePage(),
```

### 個別のページを使用

```dart
import 'pages/calendar/calendar_page.dart';
import 'pages/medicine/medicine_page.dart';

// 個別に使用することも可能
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const CalendarPage(),
));
```

## 🔄 段階的移行

1. **Phase 1**: `IntegratedHomePage`を既存の`MedicationHomePage`と並行運用
2. **Phase 2**: 機能ごとに段階的に移行
3. **Phase 3**: 既存コードの完全置き換え

詳細は`MIGRATION_STEPS.md`を参照してください。

