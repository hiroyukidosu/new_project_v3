// lib/widgets/notification_settings_dialog.dart
// 通知設定ダイアログ

import 'package:flutter/material.dart';

/// 通知設定ダイアログ
class NotificationSettingsDialog extends StatefulWidget {
  final String selectedNotificationType;
  final String selectedAlarmSound;
  final String selectedNotificationSound;
  final int notificationVolume;
  final Function({
    required String selectedNotificationType,
    required String selectedAlarmSound,
    required String selectedNotificationSound,
    required int notificationVolume,
  }) onSave;

  const NotificationSettingsDialog({
    super.key,
    required this.selectedNotificationType,
    required this.selectedAlarmSound,
    required this.selectedNotificationSound,
    required this.notificationVolume,
    required this.onSave,
  });

  @override
  State<NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> {
  late String _selectedNotificationType;
  late String _selectedAlarmSound;
  late String _selectedNotificationSound;
  late int _notificationVolume;

  @override
  void initState() {
    super.initState();
    _selectedNotificationType = widget.selectedNotificationType;
    _selectedAlarmSound = widget.selectedAlarmSound;
    _selectedNotificationSound = widget.selectedNotificationSound;
    _notificationVolume = widget.notificationVolume;
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('通知設定'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 通知タイプ選択
              const Text('通知タイプ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedNotificationType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'sound', child: Text('🔊 音')),
                  DropdownMenuItem(value: 'sound_vibration', child: Text('🔊📳 音+バイブ')),
                  DropdownMenuItem(value: 'vibration', child: Text('📳 バイブ')),
                  DropdownMenuItem(value: 'silent', child: Text('🔇 サイレント')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedNotificationType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // アラーム音選択
              const Text('アラーム音', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAlarmSound,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'default', child: Text('🔔 デフォルト音')),
                  DropdownMenuItem(value: 'gentle', child: Text('🌸 優しい音')),
                  DropdownMenuItem(value: 'urgent', child: Text('⚠️ 緊急音')),
                  DropdownMenuItem(value: 'classic', child: Text('🎵 クラシック')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAlarmSound = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 通知音選択
              const Text('通知音', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedNotificationSound,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'single_notification', child: Text('🔔 単発通知')),
                  DropdownMenuItem(value: 'loop_notification', child: Text('🔄 ループ通知')),
                  DropdownMenuItem(value: 'short_loop', child: Text('⏰ 短いループ')),
                  DropdownMenuItem(value: 'long_loop', child: Text('📢 長いループ')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedNotificationSound = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 音量設定
              const Text('音量', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('0%'),
                  Expanded(
                    child: Slider(
                      value: _notificationVolume.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() {
                          _notificationVolume = value.round();
                        });
                      },
                    ),
                  ),
                  Text('${_notificationVolume}%'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSave(
                selectedNotificationType: _selectedNotificationType,
                selectedAlarmSound: _selectedAlarmSound,
                selectedNotificationSound: _selectedNotificationSound,
                notificationVolume: _notificationVolume,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('通知設定を保存しました')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

