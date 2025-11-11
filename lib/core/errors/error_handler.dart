// lib/core/errors/error_handler.dart
// 統一的なエラーハンドリングクラス

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app_error.dart';
import '../../utils/logger.dart';

/// エラーハンドリングの結果
sealed class ErrorResult<T> {
  const ErrorResult();
}

/// 成功時の結果
class Success<T> extends ErrorResult<T> {
  final T value;
  const Success(this.value);
}

/// 失敗時の結果
class Failure<T> extends ErrorResult<T> {
  final AppError error;
  const Failure(this.error);
}

/// 統一的なエラーハンドラー
class ErrorHandler {
  /// エラーを捕捉してResult型に変換
  static Future<ErrorResult<T>> handle<T>({
    required Future<T> Function() action,
    AppError Function(Object error, StackTrace stackTrace)? onError,
    int maxRetries = 0,
    Duration? retryDelay,
    bool logError = true,
  }) async {
    int attempts = 0;
    while (attempts <= maxRetries) {
      try {
        final result = await action();
        return Success(result);
      } catch (e, stackTrace) {
        attempts++;
        
        // エラーログを記録
        if (logError) {
          Logger.error('エラー発生 (試行 $attempts/${maxRetries + 1})', e);
        }

        // Crashlyticsに記録
        if (Firebase.apps.isNotEmpty) {
          try {
            await FirebaseCrashlytics.instance.recordError(
              e,
              stackTrace,
              fatal: false,
            );
          } catch (_) {
            // Crashlytics記録失敗時は無視
          }
        }

        // デフォルトのエラー変換
        final appError = onError != null 
            ? onError(e, stackTrace)
            : _convertToAppError(e, stackTrace);
        
        // リトライ可能なエラーで、まだリトライ可能な場合
        if (appError is RetryableError && attempts <= maxRetries) {
          if (retryDelay != null) {
            await Future.delayed(retryDelay * attempts);
          }
          continue;
        }
        
        // リトライ不可能、またはリトライ回数超過
        return Failure(appError);
      }
    }
    
    // すべてのリトライが失敗した場合
    return Failure(const UnknownError(
      userMessage: '処理に失敗しました。しばらく待ってから再度お試しください。',
    ));
  }

  /// エラーをAppErrorに変換
  static AppError _convertToAppError(Object error, StackTrace stackTrace) {
    if (error is SocketException) {
      return NetworkError(
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    if (error is TimeoutException) {
      return TimeoutError(
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    if (error is HiveError) {
      return StorageError(
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    if (error is FormatException) {
      return ValidationError(
        userMessage: 'データ形式が不正です。',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    if (error is AppError) {
      return error;
    }
    
    // その他のエラー
    return UnknownError(
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// エラーメッセージをユーザーフレンドリーに変換
  static String getUserFriendlyMessage(AppError error) {
    return error.userMessage;
  }

  /// エラーがリトライ可能かどうかを判定
  static bool isRetryable(AppError error) {
    return error is RetryableError;
  }

  /// エラーをログに記録
  static Future<void> logError(AppError error) async {
    Logger.error('AppError: ${error.userMessage}', error.originalError);
    
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseCrashlytics.instance.log(error.debugInfo);
        if (error.originalError != null && error.stackTrace != null) {
          await FirebaseCrashlytics.instance.recordError(
            error.originalError!,
            error.stackTrace!,
            fatal: false,
          );
        }
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
    }
  }
}
