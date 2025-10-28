// Flutter core imports
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Local imports
import 'logger.dart';

// 高速化：エラーハンドリング強化
class AppErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    // エラーログを出力
    Logger.error('エラー発生', error);
    
    // ユーザーフレンドリーなエラーメッセージを生成
    final userMessage = _getUserFriendlyMessage(error);
    
    // Firebase Crashlyticsに送信（初期化済みの場合）
    try {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
    } catch (e) {
      // Crashlyticsが利用できない場合は無視
    }
    
    // デバッグ環境でのみ詳細ログを出力
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
    
    return '予期しないエラーが発生しました。アプリを再起動してください';
  }
}