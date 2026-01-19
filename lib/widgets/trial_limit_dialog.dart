// トライアル制限ダイアログ
// トライアル期間終了後に機能制限をユーザーに通知し、購入を促すダイアログです

import 'package:flutter/material.dart';
import '../services/trial_service.dart';

/// トライアル制限ダイアログ
/// トライアル期間終了後に機能制限をユーザーに通知し、購入を促すダイアログ
class TrialLimitDialog extends StatelessWidget {
  final String featureName;
  
  const TrialLimitDialog({super.key, required this.featureName});
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 鍵アイコンとメッセージ
          Row(
            children: [
              Icon(Icons.lock, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'トライアル期間が終了しました。\n現在、以下の機能が制限されています：',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildRestrictionItem('すべてのメモ（服用メモ含む）', '追加・入力ができません'),
          _buildRestrictionItem('アラーム機能', '使用できません'),
          _buildRestrictionItem('統計機能', '閲覧できません'),
          _buildRestrictionItem('カレンダー', '当日以外の閲覧ができません'),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '機能を継続してご利用いただくには、\n購入が必要です。',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('閉じる'),
        ),
        ElevatedButton(
          onPressed: () async {
            await TrialService.getPurchaseLink();
            // リンクを開く処理（後で実装）
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text('👉 機能解除はこちら'),
        ),
      ],
    );
  }
  
  Widget _buildRestrictionItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.block, color: Colors.red, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

