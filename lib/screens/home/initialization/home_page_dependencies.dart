// lib/screens/home/initialization/home_page_dependencies.dart
// ホームページの依存関係を集約管理

import 'package:flutter/material.dart';
import '../state/home_page_state_manager.dart';
import '../controllers/medication_controller.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/backup_controller.dart';
import '../controllers/alarm_controller.dart';
import '../../helpers/backup_operations.dart';
import '../../helpers/data_operations.dart';
import '../../helpers/medication_operations.dart';
import '../../helpers/calendar_operations.dart';
import '../../helpers/ui_helpers.dart';
import '../handlers/home_page_event_handler.dart';
import '../handlers/calendar_event_handler.dart';
import '../handlers/medication_event_handler.dart';
import '../handlers/memo_event_handler.dart';

/// ホームページの全依存関係を管理するクラス
class HomePageDependencies {
  final HomePageStateManager stateManager;
  final HomePageControllers controllers;
  final HomePageOperations operations;
  final HomePageHandlers handlers;
  final TabController tabController;
  
  HomePageDependencies({
    required this.stateManager,
    required this.controllers,
    required this.operations,
    required this.handlers,
    required this.tabController,
  });
  
  /// すべてのリソースを解放
  void dispose() {
    tabController.dispose();
    stateManager.dispose();
    controllers.dispose();
  }
}

/// コントローラーを集約管理するクラス
class HomePageControllers {
  final MedicationController medication;
  final CalendarController calendar;
  final BackupController backup;
  final AlarmController alarm;
  
  HomePageControllers({
    required this.medication,
    required this.calendar,
    required this.backup,
    required this.alarm,
  });
  
  void dispose() {
    // コントローラーはdisposeメソッドを持たないため、ここでは何もしない
    // 必要に応じて各コントローラーのクリーンアップを実装
  }
}

/// 操作クラスを集約管理するクラス
class HomePageOperations {
  final BackupOperations backup;
  final DataOperations data;
  final MedicationOperations medication;
  final CalendarOperations calendar;
  final UIHelpers ui;
  
  HomePageOperations({
    required this.backup,
    required this.data,
    required this.medication,
    required this.calendar,
    required this.ui,
  });
}

/// イベントハンドラーを集約管理するクラス
class HomePageHandlers {
  final HomePageEventHandler main;
  final CalendarEventHandler calendar;
  final MedicationEventHandler medication;
  final MemoEventHandler memo;
  
  HomePageHandlers({
    required this.main,
    required this.calendar,
    required this.medication,
    required this.memo,
  });
  
  /// PurchaseMixinを設定（後から設定）
  void setPurchaseMixin(dynamic purchaseMixin) {
    // HomePageEventHandlerはfinalなので、コンストラクタで設定済み
    // このメソッドは将来の拡張用
  }
}

