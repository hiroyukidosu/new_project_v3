// 購入・トライアル関連機能のMixin
// home_page.dartから購入・トライアル関連の機能を分離

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/trial_service.dart';
import '../../services/in_app_purchase_service.dart';

/// 購入・トライアル関連機能のMixin
mixin PurchaseMixin<T extends StatefulWidget> on State<T> {
  // トライアル状態表示ダイアログ
  Future<void> showTrialStatus() async {
    final status = await TrialService.getPurchaseStatus();
    final remainingMinutes = await TrialService.getRemainingTrialMinutes();
    
    if (!mounted) return;
    
    // 状態に応じたアイコンと色を設定
    IconData statusIcon;
    Color statusColor;
    String statusText;
    
    switch (status) {
      case TrialService.trialStatus:
        statusIcon = Icons.timer;
        statusColor = Colors.blue;
        statusText = 'トライアル中';
        break;
      case TrialService.expiredStatus:
        statusIcon = Icons.warning;
        statusColor = Colors.red;
        statusText = '期限切れ';
        break;
      case TrialService.purchasedStatus:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = '購入済み';
        break;
      default:
        statusIcon = Icons.timer;
        statusColor = Colors.blue;
        statusText = 'トライアル中';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 12),
            const Text('購入状態'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('現在の状態', statusText, statusColor),
            if (status == TrialService.trialStatus) ...[
              const SizedBox(height: 12),
              _buildStatusRow('残り時間', 
                    '${(remainingMinutes / (24 * 60)).ceil()}日',
                    Colors.orange),
            ],
            if (status == TrialService.expiredStatus) ...[
              const SizedBox(height: 12),
              _buildStatusRow('期限', '7日間終了', Colors.red),
            ],
            if (status == TrialService.purchasedStatus) ...[
              const SizedBox(height: 12),
              _buildStatusRow('有効期限', '無制限', Colors.green),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          if (status == TrialService.expiredStatus)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await showPurchaseLinkDialog();
              },
              child: const Text('購入する'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // アプリ内課金ダイアログを表示
  Future<void> showPurchaseLinkDialog() async {
    if (!mounted) return;
    
    // 商品情報を取得
    final ProductDetails? product = await InAppPurchaseService.getProductDetails();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.green),
            SizedBox(width: 12),
            Text('アプリ内課金'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品情報表示
              if (product != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shopping_bag, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'プレミアム機能',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '商品名: ${product.title}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '説明: ${product.description}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '価格: ${product.price}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 機能説明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'プレミアム機能',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '購入後は以下の機能が無制限で使用できます：',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Text('• メモの追加・編集'),
                    Text('• アラーム機能'),
                    Text('• 統計機能'),
                    Text('• カレンダー機能'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 購入ボタン
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'アプリ内課金で購入',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: product != null ? () async {
                        Navigator.of(context).pop();
                        await startPurchase(product);
                      } : null,
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(product != null ? '${product.price}で購入' : '商品情報を取得中...'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await InAppPurchaseService.restorePurchases();
                        
                        // 購入履歴復元の結果を確認
                        final isPurchased = await InAppPurchaseService.isPurchased();
                        if (isPurchased) {
                          // 購入履歴が復元された場合の特別なメッセージ
                          if (mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(Icons.restore, color: Colors.blue, size: 32),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('購入履歴復元'),
                                          Text('完了！'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                content: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '商品購入後、期限が無期限になりました！',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '過去の購入履歴が復元され、プレミアム機能が有効になりました。',
                                      style: TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('ありがとうございます！'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('購入履歴が見つかりませんでした')),
                            );
                          }
                        }
                      },
                      child: const Text('購入履歴を復元'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  // 購入を開始
  Future<void> startPurchase(ProductDetails product) async {
    // 購入結果の監視を開始
    InAppPurchaseService.startPurchaseListener((success, error) {
      if (success) {
        // 購入成功時の特別なメッセージを表示
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 12),
                  Text('購入完了！'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '商品購入後、期限が無期限になりました！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '🎉 プレミアム機能が有効になりました！',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• メモの追加・編集\n• アラーム機能\n• 統計機能\n• カレンダー機能',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('ありがとうございます！'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('購入に失敗しました: ${error ?? "不明なエラー"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
    
    // 購入を開始
    final success = await InAppPurchaseService.purchaseProduct();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('購入の開始に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

