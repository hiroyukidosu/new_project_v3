# エラーハンドリング

アプリケーション全体で統一的なエラーハンドリングを提供します。

## 使用方法

### 基本的な使用方法

```dart
import 'package:medication_alarm_app/core/errors/error_handler.dart';
import 'package:medication_alarm_app/core/errors/app_error.dart';

// エラーハンドリング付きで処理を実行
final result = await ErrorHandler.handle(
  action: () async {
    // 処理を実行
    return await someOperation();
  },
  maxRetries: 2,
  retryDelay: const Duration(milliseconds: 500),
);

// 結果を処理
switch (result) {
  case Success(:final value):
    // 成功時の処理
    print('成功: $value');
  case Failure(:final error):
    // 失敗時の処理
    print('エラー: ${error.userMessage}');
}
```

### エラーダイアログの表示

```dart
import 'package:medication_alarm_app/core/widgets/error_dialog.dart';

await ErrorDialog.show(
  context: context,
  error: error,
  onRetry: () {
    // 再試行処理
  },
);
```

### エラースナックバーの表示

```dart
import 'package:medication_alarm_app/core/widgets/error_snackbar.dart';

ErrorSnackBar.show(
  context: context,
  error: error,
  onRetry: () {
    // 再試行処理
  },
);
```

### ヘルパークラスの使用

```dart
import 'package:medication_alarm_app/core/errors/error_helper.dart';

// エラー結果を処理してユーザーに表示
await ErrorHelper.handleErrorResult(
  context: context,
  result: result,
  onRetry: () {
    // 再試行処理
  },
  showDialog: false, // true でダイアログ、false でスナックバー
);
```

## エラータイプ

- **NetworkError**: ネットワーク接続エラー（リトライ可能）
- **StorageError**: データ保存/読み込みエラー（リトライ可能）
- **TimeoutError**: タイムアウトエラー（リトライ可能）
- **ValidationError**: 入力値検証エラー（リトライ不可能）
- **PermissionError**: 権限エラー（リトライ不可能）
- **UnknownError**: 不明なエラー（リトライ不可能）

## リトライ機能

リトライ可能なエラー（NetworkError、StorageError、TimeoutError）は自動的にリトライされます。

```dart
final result = await ErrorHandler.handle(
  action: () async {
    return await networkRequest();
  },
  maxRetries: 3, // 最大3回リトライ
  retryDelay: const Duration(seconds: 1), // リトライ間隔
);
```

