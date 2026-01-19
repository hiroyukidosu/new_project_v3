import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリ内課金サービス
/// 製品ID hirochaso980 を使用した課金処理を行う
class InAppPurchaseService {
  static const String _productId = 'hirochaso980';
  static const String _purchaseStatusKey = 'purchase_status';
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 製品情報を取得
  static Future<ProductDetails?> getProductDetails() async {
    try {
      // アプリ内課金が利用可能か確認
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('アプリ内課金が利用できません');
        return null;
      }
      
      final Set<String> productIds = {_productId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('製品IDが見つかりません: ${response.notFoundIDs}');
          debugPrint('Google Play Consoleで製品ID $_productId が登録されているか確認してください');
        }
        return null;
      }
      
      if (response.productDetails.isNotEmpty) {
        final product = response.productDetails.first;
        if (kDebugMode) {
          debugPrint('製品情報取得成功: ${product.title} - ${product.price}');
        }
        return product;
      }
      
      if (kDebugMode) {
        debugPrint('製品情報が取得できません');
      }
      return null;
    } catch (e) {
      debugPrint('製品情報取得エラー: $e');
      return null;
    }
  }
  
  // 製品を購入
  static Future<bool> purchaseProduct() async {
    try {
      // アプリ内課金が利用可能か確認
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('アプリ内課金が利用できません');
        return false;
      }
      
      final ProductDetails? product = await getProductDetails();
      if (product == null) {
        if (kDebugMode) {
          debugPrint('製品情報が取得できません');
          debugPrint('Google Play Consoleで製品ID $_productId が正しく設定されているか確認してください');
        }
        return false;
      }
      
      if (kDebugMode) {
        debugPrint('購入を開始します: ${product.title} - ${product.price}');
      }
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (kDebugMode) {
        if (success) {
          debugPrint('購入リクエストを送信しました');
        } else {
          debugPrint('購入リクエストに失敗しました');
        }
      }
      
      return success;
    } catch (e) {
      debugPrint('購入エラー: $e');
      return false;
    }
  }
  
  // 購入リスナーを開始
  static void startPurchaseListener(Function(bool success, String? error) onPurchaseResult) {
    _subscription?.cancel();
    _subscription = _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      for (var purchaseDetails in purchaseDetailsList) {
        _handlePurchaseUpdate(purchaseDetails, onPurchaseResult);
      }
    });
  }
  
  // 購入更新を処理
  static void _handlePurchaseUpdate(PurchaseDetails purchaseDetails, Function(bool success, String? error) onPurchaseResult) {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      if (kDebugMode) {
        debugPrint('購入成功: ${purchaseDetails.productID}');
      }
      // 購入状態を保存
      // TrialService.setPurchaseStatus(TrialService.purchasedStatus);
      onPurchaseResult(true, '製品の購入が正常に完了しました。');
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      if (kDebugMode) {
        debugPrint('購入エラー: ${purchaseDetails.error}');
      }
      onPurchaseResult(false, purchaseDetails.error?.message ?? '購入に失敗しました');
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      if (kDebugMode) {
        debugPrint('購入キャンセル');
      }
      onPurchaseResult(false, '購入がキャンセルされました');
    }
    
    // 購入完了を通知
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }
  
  // 購入状態を確認
  static Future<bool> isPurchased() async {
    try {
      // final status = await TrialService.getPurchaseStatus();
      // return status == TrialService.purchasedStatus;
      return false; // 仮実装
    } catch (e) {
      debugPrint('購入状態確認エラー: $e');
      return false;
    }
  }
  
  // 購入履歴を復元
  static Future<void> restorePurchases() async {
    try {
      // アプリ内課金が利用可能か確認
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('アプリ内課金が利用できません');
        return;
      }
      
      if (kDebugMode) {
        debugPrint('購入履歴の復元を開始します');
      }
      await _inAppPurchase.restorePurchases();
      
      // 購入履歴復元リスナーを設定
      _subscription?.cancel();
      _subscription = _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
        for (var purchaseDetails in purchaseDetailsList) {
          if (purchaseDetails.status == PurchaseStatus.purchased) {
            if (kDebugMode) {
              debugPrint('購入履歴復元成功: ${purchaseDetails.productID}');
            }
            // 購入状態を保存
            // TrialService.setPurchaseStatus(TrialService.purchasedStatus);
          }
        }
      });
    } catch (e) {
      debugPrint('購入履歴復元エラー: $e');
    }
  }
  
  // リソースを解放
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
