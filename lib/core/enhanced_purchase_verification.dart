import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/logger.dart';

/// 強化された課金検証機能 - サーバー側検証とセキュリティ強化
class EnhancedPurchaseVerification {
  static const String _serverApiUrl = 'https://your-api.com/api/purchase'; // 実際のAPIエンドポイント
  static const String _googlePlayApiUrl = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
  static const Duration _verificationTimeout = Duration(seconds: 30);
  
  /// サーバー側での課金検証
  static Future<PurchaseVerificationResult> verifyPurchaseServerSide({
    required String purchaseToken,
    required String productId,
    required String packageName,
  }) async {
    try {
      Logger.info('サーバー側課金検証開始: $productId');
      
      // デバイス情報の取得
      final deviceInfo = await _getDeviceInfo();
      
      // サーバーへの検証リクエスト
      final response = await http.post(
        Uri.parse('$_serverApiUrl/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getServerToken()}',
        },
        body: jsonEncode({
          'purchaseToken': purchaseToken,
          'productId': productId,
          'packageName': packageName,
          'deviceInfo': deviceInfo,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(_verificationTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final isValid = data['isValid'] as bool? ?? false;
        final purchaseData = data['purchaseData'] as Map<String, dynamic>?;
        
        Logger.info('サーバー側課金検証完了: $productId - $isValid');
        
        return PurchaseVerificationResult(
          isValid: isValid,
          purchaseData: purchaseData,
          verificationMethod: 'server',
          timestamp: DateTime.now(),
        );
      } else {
        Logger.warning('サーバー側課金検証エラー: ${response.statusCode}');
        return PurchaseVerificationResult(
          isValid: false,
          error: 'Server verification failed: ${response.statusCode}',
          verificationMethod: 'server',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      Logger.error('サーバー側課金検証エラー', e);
      return PurchaseVerificationResult(
        isValid: false,
        error: e.toString(),
        verificationMethod: 'server',
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Google Play Developer APIでの直接検証
  static Future<PurchaseVerificationResult> verifyPurchaseGooglePlay({
    required String purchaseToken,
    required String productId,
    required String packageName,
  }) async {
    try {
      Logger.info('Google Play API検証開始: $productId');
      
      // Google Play Developer APIでの検証
      final response = await http.get(
        Uri.parse('$_googlePlayApiUrl/applications/$packageName/purchases/products/$productId/tokens/$purchaseToken'),
        headers: {
          'Authorization': 'Bearer ${await _getGooglePlayToken()}',
        },
      ).timeout(_verificationTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final purchaseState = data['purchaseState'] as int? ?? 0;
        final isValid = purchaseState == 0; // 0 = 購入済み
        
        Logger.info('Google Play API検証完了: $productId - $isValid');
        
        return PurchaseVerificationResult(
          isValid: isValid,
          purchaseData: data,
          verificationMethod: 'google_play',
          timestamp: DateTime.now(),
        );
      } else {
        Logger.warning('Google Play API検証エラー: ${response.statusCode}');
        return PurchaseVerificationResult(
          isValid: false,
          error: 'Google Play verification failed: ${response.statusCode}',
          verificationMethod: 'google_play',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      Logger.error('Google Play API検証エラー', e);
      return PurchaseVerificationResult(
        isValid: false,
        error: e.toString(),
        verificationMethod: 'google_play',
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// 複数の検証方法による総合検証
  static Future<PurchaseVerificationResult> verifyPurchaseComprehensive({
    required String purchaseToken,
    required String productId,
    required String packageName,
  }) async {
    try {
      Logger.info('総合課金検証開始: $productId');
      
      final results = <PurchaseVerificationResult>[];
      
      // サーバー側検証
      try {
        final serverResult = await verifyPurchaseServerSide(
          purchaseToken: purchaseToken,
          productId: productId,
          packageName: packageName,
        );
        results.add(serverResult);
      } catch (e) {
        Logger.warning('サーバー側検証エラー: $e');
      }
      
      // Google Play API検証
      try {
        final googlePlayResult = await verifyPurchaseGooglePlay(
          purchaseToken: purchaseToken,
          productId: productId,
          packageName: packageName,
        );
        results.add(googlePlayResult);
      } catch (e) {
        Logger.warning('Google Play API検証エラー: $e');
      }
      
      // 結果の統合
      final validResults = results.where((r) => r.isValid).toList();
      final invalidResults = results.where((r) => !r.isValid).toList();
      
      final isComprehensiveValid = validResults.isNotEmpty && 
          (validResults.length >= 2 || results.length == 1);
      
      Logger.info('総合課金検証完了: $productId - $isComprehensiveValid (${validResults.length}/${results.length})');
      
      return PurchaseVerificationResult(
        isValid: isComprehensiveValid,
        purchaseData: validResults.isNotEmpty ? validResults.first.purchaseData : null,
        verificationMethod: 'comprehensive',
        timestamp: DateTime.now(),
        subResults: results,
      );
    } catch (e) {
      Logger.error('総合課金検証エラー', e);
      return PurchaseVerificationResult(
        isValid: false,
        error: e.toString(),
        verificationMethod: 'comprehensive',
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// デバイス情報の取得
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'deviceId': androidInfo.id,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'deviceId': iosInfo.identifierForVendor,
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
        };
      } else {
        return {
          'platform': 'unknown',
          'deviceId': 'unknown',
        };
      }
    } catch (e) {
      Logger.error('デバイス情報取得エラー', e);
      return {
        'platform': 'unknown',
        'deviceId': 'unknown',
        'error': e.toString(),
      };
    }
  }
  
  /// サーバートークンの取得
  static Future<String> _getServerToken() async {
    // 実際の実装では、セキュアな方法でトークンを取得
    return 'your_server_token_here';
  }
  
  /// Google Playトークンの取得
  static Future<String> _getGooglePlayToken() async {
    // 実際の実装では、Google Play Consoleで設定したサービスアカウントのトークンを取得
    return 'your_google_play_token_here';
  }
}

/// 課金検証結果
class PurchaseVerificationResult {
  final bool isValid;
  final Map<String, dynamic>? purchaseData;
  final String? error;
  final String verificationMethod;
  final DateTime timestamp;
  final List<PurchaseVerificationResult>? subResults;
  
  const PurchaseVerificationResult({
    required this.isValid,
    this.purchaseData,
    this.error,
    required this.verificationMethod,
    required this.timestamp,
    this.subResults,
  });
  
  @override
  String toString() {
    return 'PurchaseVerificationResult(isValid: $isValid, method: $verificationMethod, error: $error)';
  }
}

/// セキュアな課金状態管理
class SecurePurchaseStateManager {
  static const String _purchaseStateKey = 'secure_purchase_state';
  static const String _verificationHistoryKey = 'purchase_verification_history';
  
  /// セキュアな課金状態の保存
  static Future<void> savePurchaseState({
    required String productId,
    required bool isPurchased,
    required PurchaseVerificationResult verificationResult,
  }) async {
    try {
      final state = {
        'productId': productId,
        'isPurchased': isPurchased,
        'verificationResult': {
          'isValid': verificationResult.isValid,
          'verificationMethod': verificationResult.verificationMethod,
          'timestamp': verificationResult.timestamp.toIso8601String(),
          'error': verificationResult.error,
        },
        'lastVerified': DateTime.now().toIso8601String(),
      };
      
      // 暗号化して保存
      await SecureStorageManager.saveSecureJson(_purchaseStateKey, state);
      
      // 検証履歴の保存
      await _saveVerificationHistory(productId, verificationResult);
      
      Logger.info('セキュアな課金状態保存完了: $productId');
    } catch (e) {
      Logger.error('セキュアな課金状態保存エラー: $productId', e);
    }
  }
  
  /// セキュアな課金状態の読み込み
  static Future<Map<String, dynamic>?> loadPurchaseState() async {
    try {
      final state = await SecureStorageManager.loadSecureJson(_purchaseStateKey);
      if (state != null) {
        Logger.debug('セキュアな課金状態読み込み完了');
      }
      return state;
    } catch (e) {
      Logger.error('セキュアな課金状態読み込みエラー', e);
      return null;
    }
  }
  
  /// 検証履歴の保存
  static Future<void> _saveVerificationHistory(String productId, PurchaseVerificationResult result) async {
    try {
      final history = await SecureStorageManager.loadSecureJson(_verificationHistoryKey) ?? {};
      final productHistory = (history[productId] as List<dynamic>?) ?? [];
      
      productHistory.add({
        'timestamp': result.timestamp.toIso8601String(),
        'isValid': result.isValid,
        'verificationMethod': result.verificationMethod,
        'error': result.error,
      });
      
      // 最新10件のみ保持
      if (productHistory.length > 10) {
        productHistory.removeRange(0, productHistory.length - 10);
      }
      
      history[productId] = productHistory;
      await SecureStorageManager.saveSecureJson(_verificationHistoryKey, history);
      
      Logger.debug('検証履歴保存完了: $productId');
    } catch (e) {
      Logger.error('検証履歴保存エラー: $productId', e);
    }
  }
  
  /// 検証履歴の取得
  static Future<List<Map<String, dynamic>>> getVerificationHistory(String productId) async {
    try {
      final history = await SecureStorageManager.loadSecureJson(_verificationHistoryKey) ?? {};
      final productHistory = (history[productId] as List<dynamic>?) ?? [];
      return productHistory.cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.error('検証履歴取得エラー: $productId', e);
      return [];
    }
  }
  
  /// 課金状態の検証
  static Future<bool> isPurchasedSecurely(String productId) async {
    try {
      final state = await loadPurchaseState();
      if (state == null) {
        Logger.warning('課金状態が見つかりません: $productId');
        return false;
      }
      
      final isPurchased = state['isPurchased'] as bool? ?? false;
      final lastVerified = DateTime.tryParse(state['lastVerified'] as String? ?? '');
      
      // 検証が古い場合は再検証が必要
      if (lastVerified != null && DateTime.now().difference(lastVerified).inDays > 7) {
        Logger.warning('課金状態の検証が古いです: $productId');
        return false;
      }
      
      Logger.debug('セキュアな課金状態確認: $productId - $isPurchased');
      return isPurchased;
    } catch (e) {
      Logger.error('セキュアな課金状態確認エラー: $productId', e);
      return false;
    }
  }
  
  /// 課金状態のクリア
  static Future<void> clearPurchaseState() async {
    try {
      await SecureStorageManager.deleteSecure(_purchaseStateKey);
      await SecureStorageManager.deleteSecure(_verificationHistoryKey);
      Logger.info('課金状態クリア完了');
    } catch (e) {
      Logger.error('課金状態クリアエラー', e);
    }
  }
}

/// 課金検証の監視
class PurchaseVerificationMonitor {
  static final List<PurchaseVerificationResult> _verificationHistory = [];
  static final Map<String, DateTime> _lastVerificationTimes = {};
  
  /// 検証結果の記録
  static void recordVerificationResult(String productId, PurchaseVerificationResult result) {
    _verificationHistory.add(result);
    _lastVerificationTimes[productId] = result.timestamp;
    
    // 履歴の制限（最新100件のみ保持）
    if (_verificationHistory.length > 100) {
      _verificationHistory.removeAt(0);
    }
    
    Logger.debug('検証結果記録: $productId - ${result.isValid}');
  }
  
  /// 検証頻度のチェック
  static bool shouldVerifyAgain(String productId, {Duration cooldown = const Duration(hours: 1)}) {
    final lastVerification = _lastVerificationTimes[productId];
    if (lastVerification == null) {
      return true;
    }
    
    final timeSinceLastVerification = DateTime.now().difference(lastVerification);
    return timeSinceLastVerification.compareTo(cooldown) > 0;
  }
  
  /// 検証統計の取得
  static Map<String, dynamic> getVerificationStats() {
    final totalVerifications = _verificationHistory.length;
    final successfulVerifications = _verificationHistory.where((r) => r.isValid).length;
    final failedVerifications = totalVerifications - successfulVerifications;
    
    return {
      'totalVerifications': totalVerifications,
      'successfulVerifications': successfulVerifications,
      'failedVerifications': failedVerifications,
      'successRate': totalVerifications > 0 ? (successfulVerifications / totalVerifications * 100).round() : 0,
      'lastVerificationTimes': Map.from(_lastVerificationTimes),
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _verificationHistory.clear();
    _lastVerificationTimes.clear();
    Logger.info('検証統計クリア完了');
  }
}
