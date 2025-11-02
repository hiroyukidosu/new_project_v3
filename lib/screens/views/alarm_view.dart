// AlarmView
// アラームタブ - 完全独立化

import 'package:flutter/material.dart';
import '../../services/trial_service.dart';
import '../../simple_alarm_app.dart';
import '../../widgets/trial_limit_dialog.dart';

/// アラームビュー
class AlarmView extends StatelessWidget {
  final Key alarmTabKey;

  const AlarmView({
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'アラーム機能は有料版でのみ利用できます',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => TrialLimitDialog(featureName: 'アラーム'),
                    );
                  },
                  child: const Text('詳細を見る'),
                ),
              ],
            ),
          );
        }
        
        return SimpleAlarmApp(key: alarmTabKey);
      },
    );
  }
}

