// AlarmTab
// アラームタブ

import 'package:flutter/material.dart';
import '../../services/trial_service.dart';
import '../../simple_alarm_app.dart';

/// アラームタブ
/// アラーム機能を表示
class AlarmTab extends StatelessWidget {
  final Key alarmTabKey;

  const AlarmTab({
    super.key,
    required this.alarmTabKey,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: TrialService.isTrialExpired(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final isExpired = snapshot.data ?? false;
        
        if (isExpired) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.orange),
                  SizedBox(height: 24),
                  Text(
                    'トライアル期間が終了しました',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'アラーム機能は制限されています',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await TrialService.getPurchaseLink();
                      // リンクを開く処理（後で実装）
                    },
                    icon: Icon(Icons.shopping_cart),
                    label: Text('👉 機能解除はこちら'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return KeyedSubtree(
          key: alarmTabKey,
          child: const SimpleAlarmApp(),
        );
      },
    );
  }
}

