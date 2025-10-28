// Dart core imports
import 'dart:async';

// Flutter core imports
import 'package:flutter/material.dart';

// Local imports
import '../services/trial_service.dart';

// トライアル制限警告ダイアログ
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

// トライアル期間メッセージ表示画面
class TrialMessageScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const TrialMessageScreen({super.key, required this.onComplete});
  @override
  State<TrialMessageScreen> createState() => _TrialMessageScreenState();
}

class _TrialMessageScreenState extends State<TrialMessageScreen> {
  @override
  void initState() {
    super.initState();
    // 5秒後に自動的にメインページに遷移
    Timer(const Duration(seconds: 5), () {
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // アイコン
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              // メッセージ
              const Text(
                '本日から7日間、すべての機能を無料でご利用いただけます。',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '※無料期間終了後は一部機能に制限がかかります。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // ローディングインジケーター
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
