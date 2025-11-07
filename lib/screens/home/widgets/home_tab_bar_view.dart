// lib/screens/home/widgets/home_tab_bar_view.dart
// TabBarViewのコンテンツを分離

import 'package:flutter/material.dart';
import '../../../models/medication_memo.dart';
import '../../views/calendar_view.dart';
import '../../views/medicine_view.dart';
import '../../views/alarm_view.dart';
import '../../views/stats_view.dart';
import '../../home/state/home_page_state_manager.dart';

/// TabBarViewのコンテンツウィジェット
class HomeTabBarView extends StatelessWidget {
  final HomePageStateManager? stateManager;
  final TabController tabController;
  final void Function(MedicationMemo) onEditMemo;
  final void Function(String) onDeleteMemo;
  final void Function(MedicationMemo) onMarkAsTaken;
  final void Function(BuildContext, String, String) onShowMemoDetailDialog;
  final VoidCallback onShowWarningDialog;
  final Future<void> Function()? onCalculateAdherenceStats;

  const HomeTabBarView({
    super.key,
    required this.stateManager,
    required this.tabController,
    required this.onEditMemo,
    required this.onDeleteMemo,
    required this.onMarkAsTaken,
    required this.onShowMemoDetailDialog,
    required this.onShowWarningDialog,
    this.onCalculateAdherenceStats,
  });

  @override
  Widget build(BuildContext context) {
    if (stateManager?.isInitialized ?? false) {
      return TabBarView(
        controller: tabController,
        children: [
          // カレンダータブ
          _buildCalendarTab(context),
          // 服用メモタブ
          _buildMedicineTab(),
          // アラームタブ
          _buildAlarmTab(),
          // 統計タブ
          _buildStatsTab(),
        ],
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('アプリを初期化中...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
  }

  Widget _buildCalendarTab(BuildContext context) {
    if (stateManager != null) {
      return CalendarView(
        stateManager: stateManager!,
        onEditMemo: onEditMemo,
        onDeleteMemo: onDeleteMemo,
        onShowMemoDetailDialog: (name, notes) => onShowMemoDetailDialog(context, name, notes),
        onShowWarningDialog: onShowWarningDialog,
        onCalculateAdherenceStats: onCalculateAdherenceStats,
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildMedicineTab() {
    if (stateManager != null) {
      return MedicineView(
        stateManager: stateManager!,
        onEditMemo: onEditMemo,
        onDeleteMemo: onDeleteMemo,
        onMarkAsTaken: onMarkAsTaken,
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildAlarmTab() {
    if (stateManager != null) {
      return AlarmView(alarmTabKey: stateManager!.alarmTabKey);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildStatsTab() {
    if (stateManager != null) {
      return StatsView(stateManager: stateManager!);
    }
    return const Center(child: CircularProgressIndicator());
  }
}

