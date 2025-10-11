import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import '../utils/logger.dart';

// セキュアなトライアル検証サービス
class SecureTrialService {
  static const String _apiBaseUrl = 'https://your-api.com/api/v1';
  static const String _trialEndpoint = '/trial/verify';
  static const String _deviceEndpoint = '/device/register';
  
  // デバイス情報の取得
  static Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      } else {
        deviceId = 'unknown';
      }
      
      // デバイスIDをハッシュ化
      final bytes = utf8.encode(deviceId);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      Logger.error('デバイスID取得エラー', e);
      return 'error';
    }
  }
  
  // トライアル状態の検証
  static Future<TrialStatus> verifyTrial() async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == 'error') {
        return TrialStatus.error('デバイスIDの取得に失敗しました');
      }
      
      // サーバーに問い合わせ
      final response = await http.post(
        Uri.parse('$_apiBaseUrl$_trialEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MedicationApp/1.0.0',
        },
        body: jsonEncode({
          'deviceId': deviceId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TrialStatus.fromJson(data);
      } else {
        Logger.error('トライアル検証エラー: ${response.statusCode}');
        return TrialStatus.error('サーバーエラー: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('トライアル検証エラー', e);
      return TrialStatus.error('ネットワークエラー: $e');
    }
  }
  
  // デバイス登録
  static Future<bool> registerDevice() async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == 'error') {
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl$_deviceEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MedicationApp/1.0.0',
        },
        body: jsonEncode({
          'deviceId': deviceId,
          'platform': Platform.operatingSystem,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('デバイス登録成功');
        return true;
      } else {
        Logger.error('デバイス登録エラー: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('デバイス登録エラー', e);
      return false;
    }
  }
  
  // トライアル開始
  static Future<bool> startTrial() async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == 'error') {
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl$_trialEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MedicationApp/1.0.0',
        },
        body: jsonEncode({
          'deviceId': deviceId,
          'action': 'start',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        Logger.info('トライアル開始成功');
        return true;
      } else {
        Logger.error('トライアル開始エラー: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('トライアル開始エラー', e);
      return false;
    }
  }
  
  // トライアル延長（管理者用）
  static Future<bool> extendTrial({
    required String deviceId,
    required int days,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl$_trialEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MedicationApp/1.0.0',
          'Authorization': 'Bearer YOUR_ADMIN_TOKEN', // 実際のトークンに置き換え
        },
        body: jsonEncode({
          'deviceId': deviceId,
          'action': 'extend',
          'days': days,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        Logger.info('トライアル延長成功: ${days}日');
        return true;
      } else {
        Logger.error('トライアル延長エラー: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('トライアル延長エラー', e);
      return false;
    }
  }
  
  // オフライン時のフォールバック
  static Future<TrialStatus> getOfflineTrialStatus() async {
    try {
      // ローカルストレージから最後の検証結果を取得
      // 実装は既存のロジックを移植
      Logger.warning('オフライン時のトライアル状態取得');
      return TrialStatus.active(DateTime.now().add(const Duration(days: 7)));
    } catch (e) {
      Logger.error('オフライン状態取得エラー', e);
      return TrialStatus.error('オフライン状態の取得に失敗しました');
    }
  }
}

// トライアル状態クラス
class TrialStatus {
  final bool isActive;
  final bool isExpired;
  final DateTime? expiryDate;
  final String? errorMessage;
  final int remainingDays;
  
  const TrialStatus._({
    required this.isActive,
    required this.isExpired,
    this.expiryDate,
    this.errorMessage,
    required this.remainingDays,
  });
  
  // アクティブなトライアル
  factory TrialStatus.active(DateTime expiryDate) {
    final remainingDays = expiryDate.difference(DateTime.now()).inDays;
    return TrialStatus._(
      isActive: true,
      isExpired: false,
      expiryDate: expiryDate,
      remainingDays: remainingDays > 0 ? remainingDays : 0,
    );
  }
  
  // 期限切れのトライアル
  factory TrialStatus.expired() {
    return const TrialStatus._(
      isActive: false,
      isExpired: true,
      remainingDays: 0,
    );
  }
  
  // エラー状態
  factory TrialStatus.error(String message) {
    return TrialStatus._(
      isActive: false,
      isExpired: false,
      errorMessage: message,
      remainingDays: 0,
    );
  }
  
  // JSONから作成
  factory TrialStatus.fromJson(Map<String, dynamic> json) {
    final isActive = json['isActive'] as bool;
    final isExpired = json['isExpired'] as bool;
    final expiryDateStr = json['expiryDate'] as String?;
    final errorMessage = json['errorMessage'] as String?;
    final remainingDays = json['remainingDays'] as int? ?? 0;
    
    if (isActive && expiryDateStr != null) {
      return TrialStatus.active(DateTime.parse(expiryDateStr));
    } else if (isExpired) {
      return TrialStatus.expired();
    } else if (errorMessage != null) {
      return TrialStatus.error(errorMessage);
    } else {
      return TrialStatus.error('不明な状態');
    }
  }
  
  // JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'isExpired': isExpired,
      'expiryDate': expiryDate?.toIso8601String(),
      'errorMessage': errorMessage,
      'remainingDays': remainingDays,
    };
  }
  
  @override
  String toString() {
    if (isActive) {
      return 'TrialStatus(active, remaining: ${remainingDays}days)';
    } else if (isExpired) {
      return 'TrialStatus(expired)';
    } else {
      return 'TrialStatus(error: $errorMessage)';
    }
  }
}
