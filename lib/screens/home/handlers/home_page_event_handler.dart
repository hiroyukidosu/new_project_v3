// lib/screens/home/handlers/home_page_event_handler.dart
// home_page.dartのイベントハンドラーを集約

import 'package:flutter/material.dart';
import '../../../models/medication_memo.dart';
import '../../helpers/ui_helpers.dart';
import '../../helpers/backup_operations.dart';
import '../../mixins/purchase_mixin.dart';

/// HomePageのイベントハンドラーを管理するクラス
/// UI操作やコールバックを一元管理
class HomePageEventHandler {
  final BuildContext context;
  final UIHelpers? uiHelpers;
  final BackupOperations? backupOperations;
  final PurchaseMixin? purchaseMixin;

  HomePageEventHandler({
    required this.context,
    this.uiHelpers,
    this.backupOperations,
    this.purchaseMixin,
  });

  /// トライアル状態表示
  Future<void> showTrialStatus() async {
    await purchaseMixin?.showTrialStatus();
  }

  /// 購入リンクダイアログ表示
  Future<void> showPurchaseLinkDialog() async {
    await purchaseMixin?.showPurchaseLinkDialog();
  }

  /// バックアップダイアログ表示
  Future<void> showBackupDialog() async {
    await backupOperations?.showBackupDialog();
  }

  /// 警告ダイアログ表示
  void showWarningDialog() {
    uiHelpers?.showWarningDialog();
  }

  /// メモ詳細ダイアログ表示
  void showMemoDetailDialog(String medicationName, String memo) {
    uiHelpers?.showMemoDetailDialog(medicationName, memo);
  }

  /// 制限ダイアログ表示
  void showLimitDialog(String type) {
    uiHelpers?.showLimitDialog(type);
  }

  /// スナックバー表示
  void showSnackBar(String message) {
    uiHelpers?.showSnackBar(message);
  }

  /// 手動復元ダイアログ表示
  Future<void> showManualRestoreDialog() async {
    await backupOperations?.showManualRestoreDialog();
  }
}

