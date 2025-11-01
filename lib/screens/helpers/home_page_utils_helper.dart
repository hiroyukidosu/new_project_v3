// ユーティリティヘルパー
import 'package:flutter/material.dart';

class HomePageUtilsHelper {
  // 空タイトル時の自動連番生成
  static String generateDefaultTitle(List<String> existingTitles) {
    const int maxCount = 999;
    int count = 1;
    while (count <= maxCount && existingTitles.contains('メモ$count')) {
      count++;
    }
    return 'メモ$count';
  }

  // 時間文字列をTimeOfDayに変換
  static TimeOfDay parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}
