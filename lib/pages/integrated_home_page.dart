import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medication_state.dart';
import '../providers/calendar_state.dart';
import '../providers/alarm_state.dart';
import 'calendar/calendar_page.dart';
import 'medicine/medicine_page.dart';
import 'alarm/alarm_page.dart';
import 'stats/stats_page.dart';

/// 統合ホームページ
/// 既存のタブ実装と新しいページアーキテクチャの統合
class IntegratedHomePage extends ConsumerStatefulWidget {
  const IntegratedHomePage({super.key});
  
  @override
  ConsumerState<IntegratedHomePage> createState() => _IntegratedHomePageState();
}

class _IntegratedHomePageState extends ConsumerState<IntegratedHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // 初期化時にデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }
  
  Future<void> _initializeData() async {
    // 各状態管理からデータを読み込み
    ref.read(medicationStateProvider.notifier).loadAll();
    ref.read(calendarStateProvider.notifier).loadAll();
    ref.read(alarmStateProvider.notifier).loadAll();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サプリ＆おくすりスケジュール管理帳'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'カレンダー'),
            Tab(icon: Icon(Icons.medication), text: '薬物'),
            Tab(icon: Icon(Icons.alarm), text: 'アラーム'),
            Tab(icon: Icon(Icons.bar_chart), text: '統計'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 新しいカレンダーページを使用
          const CalendarPage(),
          
          // 新しい薬物管理ページを使用
          const MedicinePage(),
          
          // アラームページ
          const AlarmPage(),
          
          // 統計ページ
          const StatsPage(),
        ],
      ),
    );
  }
  
}

