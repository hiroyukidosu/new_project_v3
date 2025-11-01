// lib/screens/home/state/home_page_state_notifiers.dart

import 'package:flutter/material.dart';

/// ホームページの状態を管理するNotifierクラス
class HomePageStateNotifiers {
  /// メモテキストのNotifier
  final ValueNotifier<String> memoTextNotifier = ValueNotifier<String>('');
  
  /// 日付色のNotifier
  final ValueNotifier<Map<String, Color>> dayColorsNotifier = ValueNotifier<Map<String, Color>>({});
  
  /// 選択された日付のNotifier
  final ValueNotifier<DateTime?> selectedDayNotifier = ValueNotifier<DateTime?>(null);
  
  /// フォーカスされた日付のNotifier
  final ValueNotifier<DateTime> focusedDayNotifier = ValueNotifier<DateTime>(DateTime.now());
  
  /// メモ選択状態のNotifier
  final ValueNotifier<bool> isMemoSelectedNotifier = ValueNotifier<bool>(false);
  
  /// タブインデックスのNotifier
  final ValueNotifier<int> currentTabIndexNotifier = ValueNotifier<int>(0);
  
  /// 統計結果のNotifier
  final ValueNotifier<Map<String, double>> adherenceRatesNotifier = ValueNotifier<Map<String, double>>({});
  
  /// カスタム遵守率結果のNotifier
  final ValueNotifier<double?> customAdherenceResultNotifier = ValueNotifier<double?>(null);
  
  /// すべてのNotifierを破棄
  void dispose() {
    memoTextNotifier.dispose();
    dayColorsNotifier.dispose();
    selectedDayNotifier.dispose();
    focusedDayNotifier.dispose();
    isMemoSelectedNotifier.dispose();
    currentTabIndexNotifier.dispose();
    adherenceRatesNotifier.dispose();
    customAdherenceResultNotifier.dispose();
  }
}

