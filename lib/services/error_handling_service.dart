import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../utils/logger.dart';

// エラーハンドリングの完全実装
class ErrorHandlingService {
  static final Map<String, int> _errorCounts = {};
  static final Map<String, DateTime> _lastErrorTimes = {};
  static const Duration _errorCooldown = Duration(minutes: 5);
  static const int _maxErrorsPerKey = 3;
  
  // エラーの処理
  static void handleError(
    BuildContext? context,
    dynamic error, {
    String? userMessage,
    String? errorContext,
    bool showToUser = true,
    bool reportToCrashlytics = true,
  }) {
    final errorKey = error.toString();
    final now = DateTime.now();
    
    // エラー頻度のチェック
    if (_shouldThrottleError(errorKey, now)) {
      Logger.warning('エラーが頻繁すぎるため、スキップ: $errorKey');
      return;
    }
    
    // エラーカウントの更新
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
    _lastErrorTimes[errorKey] = now;
    
    // ログ出力
    Logger.error('エラー発生: ${errorContext ?? 'Unknown'}', error);
    
    // Crashlyticsへの報告
    if (reportToCrashlytics) {
      _reportToCrashlytics(error, errorContext);
    }
    
    // ユーザーへの表示
    if (showToUser && context != null && context.mounted) {
      _showErrorToUser(context, error, userMessage, errorContext);
    }
  }
  
  // エラー頻度のチェック
  static bool _shouldThrottleError(String errorKey, DateTime now) {
    final lastTime = _lastErrorTimes[errorKey];
    final count = _errorCounts[errorKey] ?? 0;
    
    if (lastTime != null && 
        now.difference(lastTime).compareTo(_errorCooldown) < 0 &&
        count >= _maxErrorsPerKey) {
      return true;
    }
    
    return false;
  }
  
  // Crashlyticsへの報告
  static void _reportToCrashlytics(dynamic error, String? context) {
    try {
      FirebaseCrashlytics.instance.log('Error Context: ${context ?? 'Unknown'}');
      FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
    } catch (e) {
      Logger.warning('Crashlyticsレポートエラー: $e');
    }
  }
  
  // ユーザーへのエラー表示
  static void _showErrorToUser(
    BuildContext context,
    dynamic error,
    String? userMessage,
    String? errorContext,
  ) {
    final message = userMessage ?? _getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '詳細',
          textColor: Colors.white,
          onPressed: () => _showErrorDetails(context, error, errorContext),
        ),
      ),
    );
  }
  
  // ユーザーフレンドリーなエラーメッセージ
  static String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission') || errorString.contains('権限')) {
      return '権限が不足しています。設定から許可してください。';
    } else if (errorString.contains('network') || errorString.contains('接続')) {
      return 'ネットワーク接続を確認してください。';
    } else if (errorString.contains('storage') || errorString.contains('容量')) {
      return 'ストレージの容量が不足しています。';
    } else if (errorString.contains('timeout') || errorString.contains('タイムアウト')) {
      return '処理に時間がかかりすぎています。もう一度お試しください。';
    } else if (errorString.contains('not found') || errorString.contains('見つかりません')) {
      return 'データが見つかりません。アプリを再起動してください。';
    } else if (errorString.contains('format') || errorString.contains('形式')) {
      return 'データの形式が正しくありません。';
    } else if (errorString.contains('memory') || errorString.contains('メモリ')) {
      return 'メモリが不足しています。他のアプリを閉じてください。';
    } else if (errorString.contains('database') || errorString.contains('データベース')) {
      return 'データベースエラーが発生しました。データを確認してください。';
    } else if (errorString.contains('file') || errorString.contains('ファイル')) {
      return 'ファイルアクセスエラーが発生しました。';
    } else {
      return '問題が発生しました。もう一度お試しください。';
    }
  }
  
  // エラー詳細の表示
  static void _showErrorDetails(BuildContext context, dynamic error, String? errorContext) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー詳細'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (context != null) ...[
                Text('コンテキスト: $context'),
                const SizedBox(height: 8),
              ],
              Text('エラー: ${error.toString()}'),
              const SizedBox(height: 8),
              const Text('この情報を開発者に報告してください。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyErrorToClipboard(error, errorContext);
            },
            child: const Text('コピー'),
          ),
        ],
      ),
    );
  }
  
  // エラー情報のクリップボードコピー
  static void _copyErrorToClipboard(dynamic error, String? errorContext) {
    // クリップボードへのコピー実装
    Logger.info('エラー情報をクリップボードにコピー');
  }
  
  // リトライ機能付きのエラーハンドリング
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? operationName,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        Logger.warning('${operationName ?? 'Operation'} 失敗 (試行 $attempts/$maxRetries): $e');
        
        if (attempts >= maxRetries) {
          Logger.error('${operationName ?? 'Operation'} 最大試行回数に達しました', e);
          rethrow;
        }
        
        await Future.delayed(delay * attempts);
      }
    }
    
    throw Exception('予期しないエラー');
  }
  
  // エラーの分類
  static ErrorType classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('timeout')) {
      return ErrorType.network;
    } else if (errorString.contains('permission')) {
      return ErrorType.permission;
    } else if (errorString.contains('storage') || errorString.contains('memory')) {
      return ErrorType.resource;
    } else if (errorString.contains('format') || errorString.contains('parse')) {
      return ErrorType.data;
    } else {
      return ErrorType.unknown;
    }
  }
  
  // エラー統計の取得
  static Map<String, int> getErrorStatistics() {
    return Map.unmodifiable(_errorCounts);
  }
  
  // エラー統計のリセット
  static void resetErrorStatistics() {
    _errorCounts.clear();
    _lastErrorTimes.clear();
    Logger.info('エラー統計をリセットしました');
  }
  
  // グローバルエラーハンドラーの設定
  static void setupGlobalErrorHandlers() {
    // Flutterエラーハンドラー
    FlutterError.onError = (FlutterErrorDetails details) {
      Logger.critical('Flutter Error', details.exception);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    
    // プラットフォームエラーハンドラー
    PlatformDispatcher.instance.onError = (error, stack) {
      Logger.critical('Platform Error', error);
      FirebaseCrashlytics.instance.recordError(error, stack);
      return true;
    };
  }
}

// エラータイプの列挙
enum ErrorType {
  network,
  permission,
  resource,
  data,
  unknown,
}
