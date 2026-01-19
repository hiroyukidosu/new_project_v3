import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// トライアルメッセージ画面
/// トライアル期間の制限を表示する
class TrialMessageScreen extends StatefulWidget {
  const TrialMessageScreen({super.key});

  @override
  State<TrialMessageScreen> createState() => _TrialMessageScreenState();
}

class _TrialMessageScreenState extends State<TrialMessageScreen> {
  bool _isLoading = true;
  int _remainingMinutes = 0;
  bool _isTrialExpired = false;

  @override
  void initState() {
    super.initState();
    _loadTrialStatus();
  }

  Future<void> _loadTrialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trialStartTimeStr = prefs.getString('trial_start_time');
      
      if (trialStartTimeStr != null) {
        final trialStartTime = DateTime.parse(trialStartTimeStr);
        final difference = DateTime.now().difference(trialStartTime);
        final remaining = 1440 - difference.inMinutes; // 24時間 = 1440分
        
        setState(() {
          _remainingMinutes = remaining > 0 ? remaining : 0;
          _isTrialExpired = remaining <= 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isTrialExpired ? Icons.access_time_filled : Icons.timer,
                size: 80,
                color: _isTrialExpired ? Colors.red : Colors.orange,
              ),
              const SizedBox(height: 32),
              Text(
                _isTrialExpired ? 'トライアル期間が終了しました' : 'トライアル期間中',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!_isTrialExpired) ...[
                Text(
                  '残り時間: ${_formatTime(_remainingMinutes)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'トライアル期間中は以下の機能をご利用いただけます：',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Column(
                  children: [
                    _FeatureItem(
                      icon: Icons.medication,
                      text: '薬の登録と管理',
                    ),
                    _FeatureItem(
                      icon: Icons.calendar_today,
                      text: 'カレンダー表示',
                    ),
                    _FeatureItem(
                      icon: Icons.alarm,
                      text: 'アラーム設定',
                    ),
                    _FeatureItem(
                      icon: Icons.bar_chart,
                      text: '統計情報',
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'トライアル期間が終了しました。\n続けてご利用いただくには、プレミアム版へのアップグレードが必要です。',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isTrialExpired ? _upgradeToPremium : _continueTrial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTrialExpired ? Colors.blue : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isTrialExpired ? 'プレミアム版にアップグレード' : '続行',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!_isTrialExpired) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _upgradeToPremium,
                  child: const Text('今すぐアップグレード'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}時間${mins}分';
    } else {
      return '${mins}分';
    }
  }

  void _continueTrial() {
    Navigator.of(context).pop();
  }

  void _upgradeToPremium() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアム版'),
        content: const Text('プレミアム版では以下の機能をご利用いただけます：\n\n• 無制限の薬の登録\n• 高度な統計機能\n• バックアップと復元\n• 広告なし'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // アップグレード処理
            },
            child: const Text('アップグレード'),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

/// トライアル制限ダイアログ
/// 特定の機能が制限されていることを表示する
class TrialLimitDialog extends StatelessWidget {
  final String featureName;

  const TrialLimitDialog({
    super.key,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('機能制限'),
      content: Text('$featureName機能はプレミアム版でのみご利用いただけます。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // アップグレード処理
          },
          child: const Text('アップグレード'),
        ),
      ],
    );
  }
}
