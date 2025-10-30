import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'logger.dart';

/// デバッグ用ログ関数
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// アプリケーションエラーハンドラー
class AppErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    // ログ出力
    Logger.error('エラー発生', error);
    
    // ユーザーフレンドリーなメッセージを取得
    final userMessage = _getUserFriendlyMessage(error);
    
    // Firebase Crashlyticsに送信（非同期なのでエラーを無視）
    try {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
    } catch (e) {
      // Crashlyticsのエラーは無視
    }
    
    // デバッグモードでのエラーログ
    if (kDebugMode) {
      debugPrint('エラー詳細: $error');
      if (stackTrace != null) {
        debugPrint('スタックトレース: $stackTrace');
      }
    }
  }
  
  static String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'ネットワーク接続を確認してください';
    }
    
    if (errorString.contains('permission') || errorString.contains('権限')) {
      return '必要な権限が許可されていません';
    }
    
    if (errorString.contains('storage') || errorString.contains('保存')) {
      return 'データの保存に失敗しました';
    }
    
    if (errorString.contains('load') || errorString.contains('読み込み')) {
      return 'データの読み込みに失敗しました';
    }
    
    return '予期しないエラーが発生しました。しばらく待ってから再試行してください';
  }
}

/// エラーサービスクラス
class ErrorService {
  static void handle(BuildContext? context, dynamic error, {String? userMessage}) {
    Logger.error('エラー発生', error);
    
    try {
      FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
    } catch (e) {
      Logger.warning('Crashlytics記録エラー: $e');
    }
    
    if (context != null && context.mounted) {
      final message = userMessage ?? _getUserFriendlyMessage(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '再試行',
            textColor: Colors.white,
            onPressed: () => _retry(context),
          ),
        ),
      );
    }
  }
  
  static void _retry(BuildContext context) {
    // 再試行処理（必要に応じて実装）
    Logger.info('再試行ボタンが押されました');
  }
  
  // ユーザーフレンドリーなエラーメッセージを取得
  static String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission') || errorString.contains('権限')) {
      return '必要な権限が許可されていません。設定を確認してください。';
    } else if (errorString.contains('network') || errorString.contains('接続')) {
      return 'ネットワーク接続を確認してください。';
    } else if (errorString.contains('storage') || errorString.contains('記憶')) {
      return 'ストレージの容量が不足しています。';
    } else if (errorString.contains('timeout') || errorString.contains('タイムアウト')) {
      return 'タイムアウトが発生しました。しばらく待ってから再試行してください。';
    } else if (errorString.contains('not found') || errorString.contains('見つかりません')) {
      return 'データが見つかりません。もう一度お試しください。';
    } else if (errorString.contains('format') || errorString.contains('形式')) {
      return 'データの形式が正しくありません。';
    } else if (errorString.contains('memory') || errorString.contains('メモリ')) {
      return 'メモリが不足しています。アプリを再起動してください。';
    } else {
      return '予期しないエラーが発生しました。しばらく待ってから再試行してください。';
    }
  }
  
  static void showUserFriendlyError(BuildContext context, String errorContext, dynamic error) {
    final message = _getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '詳細',
          textColor: Colors.white,
          onPressed: () => _showErrorDetails(context, errorContext, error),
        ),
      ),
    );
  }
  
  static void _showErrorDetails(BuildContext context, String errorContext, dynamic error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー詳細'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('コンテキスト: $errorContext'),
            const SizedBox(height: 8),
            Text('エラー: ${error.toString()}'),
            const SizedBox(height: 8),
            const Text('開発者に連絡してください。', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
