import 'package:flutter/material.dart';

/// 通知タイプの列挙型
/// 音、バイブレーション、サイレント、緊急の4種類
enum NotificationType {
  sound('音', Icons.volume_up),
  vibration('バイブレーション', Icons.vibration),
  silent('サイレント', Icons.notifications_off),
  urgent('緊急', Icons.priority_high);
  
  const NotificationType(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// 音のタイプの列挙型
/// デフォルト、優しい音、緊急音、クラシック音の4種類
enum SoundType {
  defaultSound('デフォルト', 'default_sound'),
  gentle('優しい音', 'gentle_sound'),
  urgent('緊急音', 'urgent_sound'),
  classic('クラシック音', 'classic_sound');
  
  const SoundType(this.displayName, this.soundFile);
  final String displayName;
  final String soundFile;
}

