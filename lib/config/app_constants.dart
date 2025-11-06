/// アプリケーション定数
/// アプリ全体で使用する定数値を定義します
class AppConstants {
  // アラーム関連の制限
  static const int maxAlarms = 100;
  static const int maxMemos = 500;
  static const int pageSize = 20;
  
  // 自動バックアップ関連
  static const Duration autoBackupTime = Duration(hours: 2);
  
  // UI関連
  static const double defaultCardElevation = 3.0;
  static const double defaultBorderRadius = 16.0;
  static const double defaultPadding = 12.0;
  
  // データ永続化関連
  static const int maxBackupHistory = 50; // 10年運用対応
  static const int debounceMilliseconds = 500;
  
  // 暗号化キーバックアップ関連
  static const Duration keyBackupInterval = Duration(days: 7); // 暗号化キー自動バックアップ間隔
  
  // パフォーマンス関連
  static const int maxDisplayedItems = 50;
  static const Duration cacheExpiration = Duration(minutes: 5);
  
  // バリデーション関連
  static const int minMedicationNameLength = 1;
  static const int maxMedicationNameLength = 100;
  
  // プライバシー関連
  static const Duration sessionTimeout = Duration(hours: 24);
  
  // エラー処理関連
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // 初期化関連
  static const Duration repositoryInitTimeout = Duration(seconds: 30); // リポジトリ初期化タイムアウト
}

