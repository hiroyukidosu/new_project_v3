import 'package:shared_preferences/shared_preferences.dart';

/// トライアル期間管理サービス
/// 7日間のトライアル期間の管理を行う
class TrialService {
  static const String _trialStartTimeKey = 'trial_start_time';
  static const String _purchaseLinkKey = 'purchase_link';
  static const String _purchaseStatusKey = 'purchase_status'; // 購入状態を保存
  /// トライアル期間: 7日間（分単位）
  /// 7日 × 24時間 × 60分 = 10,080分
  static const int _trialDurationMinutes = 7 * 24 * 60;
  static const Set<String> _restrictedFeatureKeys = {
    // 期限切れ時に制限対象となる機能キー（現在は制限なし）
  };
  
  // 購入状態の定数
  static const String trialStatus = 'trial'; // トライアル中
  static const String expiredStatus = 'expired'; // 期限切れ
  static const String purchasedStatus = 'purchased'; // 購入済み
  
  // トライアル開始時刻を初期化
  static Future<void> initializeTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_trialStartTimeKey)) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(_trialStartTimeKey, now);
      }
    } catch (e) {
      // エラー処理
    }
  }

  /// トライアル期間をリセット（新しい開始時刻を設定）
  /// トライアル期間切れの状態から再開したい場合に使用
  static Future<void> resetTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_trialStartTimeKey, now);
      
      // 購入状態が期限切れの場合は、トライアル中に戻す
      final currentStatus = prefs.getString(_purchaseStatusKey);
      if (currentStatus == expiredStatus) {
        await prefs.remove(_purchaseStatusKey);
      }
    } catch (e) {
      // エラー処理
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
      
      // トライアル期間を確認
      final startTime = prefs.getInt(_trialStartTimeKey);
      if (startTime == null) {
        await initializeTrial();
        return trialStatus;
      }
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMinutes = (now - startTime) ~/ (1000 * 60);
      
      if (elapsedMinutes >= _trialDurationMinutes) {
        return expiredStatus; // 期限切れ
      }
      
      return trialStatus; // トライアル中
    } catch (e) {
      return trialStatus; // エラー時はトライアル中とする
    }
  }
  
  // 購入状態を設定
  static Future<void> setPurchaseStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_purchaseStatusKey, status);
    } catch (e) {
      // エラー処理
    }
  }
  
  // トライアル期限切れかを確認
  static Future<bool> isTrialExpired() async {
    final status = await getPurchaseStatus();
    return status == expiredStatus;
  }
  
  // 購入済みかを確認
  static Future<bool> isPurchased() async {
    final status = await getPurchaseStatus();
    return status == purchasedStatus;
  }

  // 機能が使用可能か（トライアル期限切れ時は特定機能のみ制限）
  static Future<bool> isFeatureAllowed(String featureKey) async {
    try {
      if (await isPurchased()) return true;
      final expired = await isTrialExpired();
      if (!expired) return true;
      return !_restrictedFeatureKeys.contains(featureKey);
    } catch (_) {
      return true; // エラー時はブロックしない
    }
  }
  
  // 購入リンクを設定
  static Future<void> setPurchaseLink(String link) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_purchaseLinkKey, link);
    } catch (e) {
      // エラー処理
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
  
  // 残りトライアル時間を取得（分）
  static Future<int> getRemainingTrialMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTime = prefs.getInt(_trialStartTimeKey);
      
      if (startTime == null) {
        await initializeTrial();
        return _trialDurationMinutes;
      }
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMinutes = (now - startTime) ~/ (1000 * 60);
      final remaining = _trialDurationMinutes - elapsedMinutes;
      
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return _trialDurationMinutes;
    }
  }
}
