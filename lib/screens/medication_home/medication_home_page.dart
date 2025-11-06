// lib/screens/medication_home/medication_home_page.dart

import 'package:flutter/material.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';
import '../../models/medicine_data.dart';
import '../../../repositories/repository_manager.dart';
import '../repositories/preference_repository.dart'; // PreferenceRepositoryは別途管理
import '../controllers/medication_home_controller.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/medication_memo_controller.dart';
import '../controllers/stats_controller.dart';
import '../controllers/backup_controller.dart';
import 'widgets/tabs/calendar_tab_widget.dart';
import 'widgets/tabs/medicine_tab_widget.dart';
import 'widgets/tabs/alarm_tab_widget.dart';
import 'widgets/tabs/stats_tab_widget.dart';

/// メインのホームページ（簡素化版）
class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});

  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}

class _MedicationHomePageState extends State<MedicationHomePage>
    with TickerProviderStateMixin {
  // Controllers
  late MedicationHomeController _mainController;
  late CalendarController _calendarController;
  late MedicationMemoController _memoController;
  late StatsController _statsController;
  late BackupController _backupController;

  // UI Controllers
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Repositories初期化（RepositoryManager経由でシングルトン取得）
    final medicationRepo = RepositoryManager.medicationRepository;
    final alarmRepo = RepositoryManager.alarmRepository;
    final calendarRepo = RepositoryManager.calendarRepository;
    final backupRepo = RepositoryManager.backupRepository;
    
    // PreferenceRepositoryは別途管理（既存のコードを維持）
    final preferenceRepo = PreferenceRepository();
    
    // リポジトリがnullの場合のエラーハンドリング
    if (medicationRepo == null || alarmRepo == null || 
        calendarRepo == null || backupRepo == null) {
      throw Exception('リポジトリが初期化されていません。アプリを再起動してください。');
    }

    // Controllers初期化
    _mainController = MedicationHomeController(
      medicationRepo: medicationRepo,
      alarmRepo: alarmRepo,
      calendarRepo: calendarRepo,
      preferenceRepo: preferenceRepo,
      backupRepo: backupRepo,
    );

    _calendarController = CalendarController(
      repository: calendarRepo,
    );

    _memoController = MedicationMemoController(
      repository: medicationRepo,
    );

    _statsController = StatsController(
      preferenceRepo: preferenceRepo,
    );

    _backupController = BackupController(
      repository: backupRepo,
    );

    _tabController = TabController(length: 4, vsync: this);

    // データ読み込み
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _mainController.initialize(),
      _calendarController.initialize(),
      _memoController.initialize(),
      _statsController.initialize(),
      _backupController.initialize(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mainController.dispose();
    _calendarController.dispose();
    _memoController.dispose();
    _statsController.dispose();
    _backupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _mainController,
      builder: (context, _) {
        if (_mainController.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_mainController.error != null) {
          return Scaffold(
            body: Center(
              child: Text('エラー: ${_mainController.error}'),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(),
          body: TabBarView(
            controller: _tabController,
            children: [
              CalendarTabWidget(
                mainController: _mainController,
                calendarController: _calendarController,
              ),
              MedicineTabWidget(
                mainController: _mainController,
                memoController: _memoController,
              ),
              AlarmTabWidget(
                mainController: _mainController,
              ),
              StatsTabWidget(
                mainController: _mainController,
                statsController: _statsController,
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('サプリ＆おくすりスケジュール管理帳'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.calendar_month), text: 'カレンダー'),
          Tab(icon: Icon(Icons.medication), text: '服用メモ'),
          Tab(icon: Icon(Icons.alarm), text: 'アラーム'),
          Tab(icon: Icon(Icons.analytics), text: '統計'),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'backup') {
              _showBackupDialog();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('バックアップ'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBackupDialog() {
    // TODO: BackupDialogを使用
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バックアップ'),
        content: const Text('バックアップ機能は現在準備中です'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

