// Third-party package imports
import 'package:shared_preferences/shared_preferences.dart';

// トライアル期間管理サービス
class TrialService {
  static const String _trialStartTimeKey = 'trial_start_time';
  static const String _purchaseLinkKey = 'purchase_link';
  static const String _purchaseStatusKey = 'purchase_status'; // 購入状態を保存
  static const int _trialDurationMinutes = 7 * 24 * 60; // トライアル期間: 7日
  
  // 購入状態の列挙型
  static const String trialStatus = 'trial'; // トライアル中
  static const String expiredStatus = 'expired'; // 期限切れ
  static const String purchasedStatus = 'purchased'; // 購入済み
  
  // トライアル開始時刻を記録
  static Future<void> initializeTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_trialStartTimeKey)) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(_trialStartTimeKey, now);
      }
    } catch (e) {
    }
  }
  
  // 現在の購入状態を取得
  static Future<String> getPurchaseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = prefs.getString(_purchaseStatusKey);
      
      if (status == purchasedStatus) {
        return purchasedStatus; // 購入済み
      }
      
      // トライアル期間をチェック
      final startTime = prefs.getInt(_trialStartTimeKey);
      if (startTime == null) {
        await initializeTrial();
        return trialStatus; // トライアル開始
      }
      
      final start = DateTime.fromMillisecondsSinceEpoch(startTime);
      final now = DateTime.now();
      final difference = now.difference(start);
      
      if (difference.inMinutes >= _trialDurationMinutes) {
        return expiredStatus; // 期限切れ
      }
      
      return trialStatus; // トライアル中
    } catch (e) {
      return trialStatus;
    }
  }
  
  // 購入状態を設定
  static Future<void> setPurchaseStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_purchaseStatusKey, status);
    } catch (e) {
    }
  }
  
  // トライアル期間が終了しているかチェック（後方互換性のため残す）
  static Future<bool> isTrialExpired() async {
    final status = await getPurchaseStatus();
    return status == expiredStatus;
  }
  
  // 残り時間を取得（分単位）
  static Future<int> getRemainingMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTime = prefs.getInt(_trialStartTimeKey);
      if (startTime == null) return _trialDurationMinutes;
      
      final start = DateTime.fromMillisecondsSinceEpoch(startTime);
      final now = DateTime.now();
      final elapsed = now.difference(start).inMinutes;
      final remaining = _trialDurationMinutes - elapsed;
      
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }
  
  // 購入リンクを設定
  static Future<void> setPurchaseLink(String link) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_purchaseLinkKey, link);
    } catch (e) {
    }
  }
  
  // 購入リンクを取得
  static Future<String?> getPurchaseLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_purchaseLinkKey);
    } catch (e) {
      return null;
    }
  }
  
  // トライアル期間をリセット（開発・テスト用）
  static Future<void> resetTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_trialStartTimeKey);
    } catch (e) {
    }
  }
  
  // トライアル・購入状態の詳細情報を取得
  static Future<Map<String, dynamic>> getTrialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTime = prefs.getInt(_trialStartTimeKey);
      
      if (startTime == null) {
        await initializeTrial();
        return {
          'isExpired': false,
          'remainingMinutes': _trialDurationMinutes,
          'startTime': DateTime.now(),
          'status': 'trial_active'
        };
      }
      
      final start = DateTime.fromMillisecondsSinceEpoch(startTime);
      final now = DateTime.now();
      final elapsed = now.difference(start).inMinutes;
      final remaining = _trialDurationMinutes - elapsed;
      final isExpired = remaining <= 0;
      
      return {
        'isExpired': isExpired,
        'remainingMinutes': remaining > 0 ? remaining : 0,
        'startTime': start,
        'status': isExpired ? 'expired' : 'trial_active'
      };
    } catch (e) {
      return {
        'isExpired': false,
        'remainingMinutes': 0,
        'startTime': DateTime.now(),
        'status': 'error'
      };
    }
  }
  
  // トライアル状態をコンソールに出力（デバッグ用）
  static Future<void> printTrialStatus() async {
    await getTrialStatus();
  }
}
