import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

/// ロケール関連のヘルパー
/// 
/// LocaleDataExceptionエラーを防ぐための安全な初期化
class LocaleHelper {
  static bool _isInitialized = false;
  static String _currentLocale = 'ja_JP';
  
  /// ロケールが初期化済みかチェック
  static bool get isInitialized => _isInitialized;
  
  /// 現在のロケールを取得
  static String get currentLocale => _currentLocale;
  
  /// 安全なロケール初期化
  static Future<bool> initializeLocale([String? locale]) async {
    if (_isInitialized) {
      return true;
    }
    
    final targetLocale = locale ?? 'ja_JP';
    
    try {
      await initializeDateFormatting(targetLocale, null);
      _currentLocale = targetLocale;
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('ロケール初期化成功: $targetLocale');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ロケール初期化エラー ($targetLocale): $e');
      }
      
      // フォールバック: 英語で初期化を試行
      if (targetLocale != 'en_US') {
        try {
          await initializeDateFormatting('en_US', null);
          _currentLocale = 'en_US';
          _isInitialized = true;
          
          if (kDebugMode) {
            debugPrint('フォールバックロケール初期化成功: en_US');
          }
          
          return true;
        } catch (e2) {
          if (kDebugMode) {
            debugPrint('フォールバックロケール初期化も失敗: $e2');
          }
        }
      }
    }
    
    return false;
  }
  
  /// ロケール初期化をリセット
  static void reset() {
    _isInitialized = false;
    _currentLocale = 'ja_JP';
  }
  
  /// 利用可能なロケール一覧
  static const List<String> availableLocales = [
    'ja_JP',
    'en_US',
    'en_GB',
  ];
  
  /// ロケールが利用可能かチェック
  static bool isLocaleAvailable(String locale) {
    return availableLocales.contains(locale);
  }
  
  /// 安全なロケール取得
  static String getSafeLocale(String preferredLocale) {
    if (isLocaleAvailable(preferredLocale)) {
      return preferredLocale;
    }
    
    // フォールバック順序
    for (final fallback in ['ja_JP', 'en_US', 'en_GB']) {
      if (isLocaleAvailable(fallback)) {
        return fallback;
      }
    }
    
    return 'en_US'; // 最終フォールバック
  }
}