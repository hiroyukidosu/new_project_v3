// Crashlytics同意制御サービス
// ユーザーの同意に基づいてCrashlytics収集を制御します

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app_preferences.dart';
import '../utils/logger.dart';

/// Crashlytics同意制御サービス
/// GDPR等のプライバシー規制に準拠した同意管理を提供します
class CrashlyticsConsentService {
  static const String _consentKey = 'crashlytics_consent';
  static const String _consentDateKey = 'crashlytics_consent_date';
  static const String _consentVersionKey = 'crashlytics_consent_version';
  static const int _currentConsentVersion = 1;
  
  /// 同意状態の取得
  static bool? getConsent() {
    return AppPreferences.getBool(_consentKey);
  }
  
  /// 同意の設定
  static Future<void> setConsent(bool consent) async {
    try {
      await AppPreferences.saveBool(_consentKey, consent);
      await AppPreferences.saveString(_consentDateKey, DateTime.now().toIso8601String());
      await AppPreferences.saveInt(_consentVersionKey, _currentConsentVersion);
      
      // Crashlytics収集を即座に反映
      await updateCrashlyticsCollection(consent);
      
      Logger.info('Crashlytics同意設定: $consent');
    } catch (e) {
      Logger.error('Crashlytics同意設定エラー', e);
    }
  }
  
  /// Crashlytics収集の更新
  static Future<void> updateCrashlyticsCollection(bool? consent) async {
    try {
      // リリースビルドかつ同意がある場合のみ有効化
      final shouldEnable = kReleaseMode && (consent == true);
      
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(shouldEnable);
      
      if (kDebugMode) {
        debugPrint('Crashlytics収集状態: ${shouldEnable ? '有効' : '無効'}');
      }
    } catch (e) {
      Logger.error('Crashlytics収集更新エラー', e);
    }
  }
  
  /// 初期化時の同意状態の適用
  static Future<void> initializeConsent() async {
    try {
      final consent = getConsent();
      await updateCrashlyticsCollection(consent);
      
      Logger.debug('Crashlytics同意状態を初期化: $consent');
    } catch (e) {
      Logger.error('Crashlytics同意初期化エラー', e);
    }
  }
  
  /// 同意が未設定かどうかを確認
  static bool isConsentUndefined() {
    return getConsent() == null;
  }
  
  /// 同意日時の取得
  static DateTime? getConsentDate() {
    try {
      final dateStr = AppPreferences.getString(_consentDateKey);
      if (dateStr != null) {
        return DateTime.parse(dateStr);
      }
      return null;
    } catch (e) {
      Logger.error('同意日時取得エラー', e);
      return null;
    }
  }
  
  /// 同意バージョンの取得
  static int? getConsentVersion() {
    return AppPreferences.getInt(_consentVersionKey);
  }
  
  /// 同意のリセット（再同意を求める場合）
  static Future<void> resetConsent() async {
    try {
      await AppPreferences.remove(_consentKey);
      await AppPreferences.remove(_consentDateKey);
      await AppPreferences.remove(_consentVersionKey);
      
      // Crashlytics収集を無効化
      await updateCrashlyticsCollection(false);
      
      Logger.info('Crashlytics同意をリセットしました');
    } catch (e) {
      Logger.error('Crashlytics同意リセットエラー', e);
    }
  }
  
  /// 同意状態の詳細情報を取得
  static Future<Map<String, dynamic>> getConsentInfo() async {
    try {
      final consent = getConsent();
      final consentDate = getConsentDate();
      final consentVersion = getConsentVersion();
      
      return {
        'consent': consent,
        'consentDate': consentDate?.toIso8601String(),
        'consentVersion': consentVersion,
        'currentVersion': _currentConsentVersion,
        'isUndefined': consent == null,
        'isOutdated': consentVersion != null && consentVersion < _currentConsentVersion,
        'isEnabled': kReleaseMode && consent == true,
      };
    } catch (e) {
      Logger.error('同意情報取得エラー', e);
      return {
        'consent': null,
        'error': e.toString(),
      };
    }
  }
}

