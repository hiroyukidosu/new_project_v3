// lib/widgets/current_time_card.dart
// 現在時刻表示カード

import 'package:flutter/material.dart';

/// 現在時刻表示カード
class CurrentTimeCard extends StatelessWidget {
  final String currentTime;
  final String currentDate;
  final bool isAlarmEnabled;
  final ValueChanged<bool> onAlarmEnabledChanged;
  final VoidCallback onStopAlarm;
  final bool isAlarmPlaying;

  const CurrentTimeCard({
    super.key,
    required this.currentTime,
    required this.currentDate,
    required this.isAlarmEnabled,
    required this.onAlarmEnabledChanged,
    required this.onStopAlarm,
    required this.isAlarmPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            currentTime,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentDate,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          // アラーム有効/無効トグル
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAlarmEnabled ? Icons.alarm : Icons.alarm_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAlarmEnabled ? 'アラーム有効' : 'アラーム無効',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: isAlarmEnabled,
                onChanged: onAlarmEnabledChanged,
                activeColor: Colors.white,
                activeTrackColor: Colors.white70,
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white30,
              ),
            ],
          ),
          // アラーム停止ボタン（再生中の場合のみ表示）
          if (isAlarmPlaying) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onStopAlarm,
              icon: const Icon(Icons.stop, color: Colors.white, size: 18),
              label: const Text(
                'アラーム停止',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

