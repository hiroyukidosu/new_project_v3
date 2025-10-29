// Flutter core imports
import 'package:flutter/material.dart';

// ✅ 修正：統一された定数管理
class AppConstants {
  // アニメーション時間
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // デバウンス時間
  static const Duration debounceDelay = Duration(seconds: 2);
  static const Duration shortDebounceDelay = Duration(milliseconds: 500);
  
  // ログ間隔
  static const Duration logInterval = Duration(seconds: 30);
  
  // データキー
  static const String medicationMemosKey = 'medication_memos_v2';
  static const String medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String addedMedicationsKey = 'added_medications_v2';
  static const String backupSuffix = '_backup';
  
  // カレンダー関連定数
  static const String calendarMarksKey = 'calendar_marks';
  static const Duration calendarScrollAnimationDuration = Duration(milliseconds: 300);
  static const double calendarScrollSensitivity = 3.0;
  static const double calendarScrollVelocityThreshold = 300.0;
}

// ✅ 修正：統一されたUI定数（マジックナンバー削減）
class AppDimensions {
  // 高さ
  static const double listMaxHeight = 250.0;
  static const double listMaxHeightExpanded = 500.0;
  static const double calendarMaxHeight = 600.0;
  static const double dialogMaxHeight = 0.8;
  static const double dialogMinHeight = 0.4;
  
  // パディング
  static const EdgeInsets standardPadding = EdgeInsets.all(16);
  static const EdgeInsets smallPadding = EdgeInsets.all(8);
  static const EdgeInsets largePadding = EdgeInsets.all(24);
  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets dialogPadding = EdgeInsets.all(20);
  static const EdgeInsets listPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  
  // マージン
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 10, horizontal: 4);
  static const EdgeInsets sectionMargin = EdgeInsets.only(bottom: 16);
  
  // ボーダー半径
  static const double standardBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double dialogBorderRadius = 16.0;
  static const double buttonBorderRadius = 8.0;
  
  // アイコンサイズ
  static const double smallIcon = 16.0;
  static const double mediumIcon = 20.0;
  static const double largeIcon = 24.0;
  static const double extraLargeIcon = 32.0;
  
  // フォントサイズ
  static const double smallText = 11.0;
  static const double mediumText = 14.0;
  static const double largeText = 16.0;
  static const double titleText = 18.0;
  static const double headerText = 24.0;
  
  // スペーシング
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 12.0;
  static const double extraLargeSpacing = 16.0;
  
  // ボタンサイズ
  static const double buttonHeight = 48.0;
  static const double smallButtonHeight = 32.0;
  static const double largeButtonHeight = 56.0;
  
  // アニメーション時間
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration standardAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // デバウンス時間
  static const Duration shortDebounce = Duration(milliseconds: 500);
  static const Duration standardDebounce = Duration(seconds: 2);
  static const Duration longDebounce = Duration(seconds: 5);
  
  // キャッシュ時間
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const Duration logInterval = Duration(seconds: 30);
}