import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

/// アプリ内課金サービス
/// プレミアム機能の購入を管理する
class InAppPurchaseService {
  static const String _productId = 'premium_upgrade';
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  static Future<ProductDetails?> getProductDetails() async {
    try {
      final isAvailable = await InAppPurchase.instance.isAvailable();
      if (!isAvailable) {
        debugPrint('アプリ内課金が利用できません');
        return null;
      }

      final response = await InAppPurchase.instance.queryProductDetails({_productId});
      if (response.error != null) {
        debugPrint('商品詳細取得エラー: ${response.error}');
        return null;
      }

      if (response.productDetails.isNotEmpty) {
        return response.productDetails.first;
      }

      return null;
    } catch (e) {
      debugPrint('商品詳細取得エラー: $e');
      return null;
    }
  }

  static Future<bool> purchaseProduct() async {
    try {
      final productDetails = await getProductDetails();
      if (productDetails == null) {
        debugPrint('商品詳細が取得できません');
        return false;
      }

      final purchaseParam = PurchaseParam(productDetails: productDetails);
      final result = await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

      if (result) {
        debugPrint('購入処理を開始しました');
        return true;
      } else {
        debugPrint('購入処理の開始に失敗しました');
        return false;
      }
    } catch (e) {
      debugPrint('購入エラー: $e');
      return false;
    }
  }

  static void startPurchaseListener(Function(bool success, String? error) onPurchaseResult) {
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchaseDetailsList) {
        for (final purchaseDetails in purchaseDetailsList) {
          _handlePurchaseUpdate(purchaseDetails, onPurchaseResult);
        }
      },
    );
  }

  static void _handlePurchaseUpdate(PurchaseDetails purchaseDetails, Function(bool success, String? error) onPurchaseResult) {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      debugPrint('購入完了: ${purchaseDetails.productID}');
      onPurchaseResult(true, null);
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint('購入エラー: ${purchaseDetails.error}');
      onPurchaseResult(false, purchaseDetails.error?.message);
    } else if (purchaseDetails.status == PurchaseStatus.pending) {
      debugPrint('購入処理中...');
    }
  }

  static Future<bool> isPurchased() async {
    try {
      final pastPurchases = await InAppPurchase.instance.restorePurchases();
      return pastPurchases.any((purchase) => purchase.productID == _productId);
    } catch (e) {
      debugPrint('購入状態確認エラー: $e');
      return false;
    }
  }

  static Future<void> restorePurchases() async {
    try {
      await InAppPurchase.instance.restorePurchases();
      debugPrint('購入履歴を復元しました');
    } catch (e) {
      debugPrint('購入履歴復元エラー: $e');
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
