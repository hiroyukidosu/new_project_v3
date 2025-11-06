// lib/screens/helpers/ui_helpers.dart
// UIヘルパー関連の機能を集約

import 'package:flutter/material.dart';
import '../home/widgets/dialogs/warning_dialog.dart';
import '../../services/trial_service.dart';
import '../../widgets/trial_limit_dialog.dart';
import 'home_page_utils_helper.dart';
import '../../screens/home/state/home_page_state_manager.dart';

/// UIヘルパーを管理するクラス
/// home_page.dartからUIヘルパー関連メソッドを移動
class UIHelpers {
  final BuildContext context;
  final bool Function() onMountedCheck;
  final HomePageStateManager? stateManager;

  UIHelpers({
    required this.context,
    required this.onMountedCheck,
    required this.stateManager,
  });

  /// スナックバー表示
  void showSnackBar(String message) {
    if (!onMountedCheck()) return;
    try {
      const fontSize = 14.0;
      if (onMountedCheck()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ スナックバー表示エラー: $e');
    }
  }

  /// メモ詳細ダイアログ表示
  void showMemoDetailDialog(String medicationName, String memo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  const Icon(Icons.note, size: 24, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$medicationName のメモ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 20),
              // メモ内容
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Text(
                      memo,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // フッターボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 制限ダイアログ表示
  void showLimitDialog(String type) {
    const maxAlarms = 100;
    const maxMemos = 500;
    WarningDialog.showLimitDialog(
      context,
      type,
      type == 'アラーム' ? maxAlarms : maxMemos,
    );
  }

  /// 警告ダイアログ表示
  void showWarningDialog() {
    WarningDialog.show(
      context,
      title: '注意',
      message: '服用回数が多いため、\n医師の指示に従ってください',
      confirmText: '了解',
    );
  }

  /// トライアル状態表示ダイアログ
  Future<void> showTrialStatus() async {
    // PurchaseMixinに移動済み
    // 必要に応じて実装
  }

  /// デフォルトタイトル生成
  String generateDefaultTitle(List<String> existingTitles) {
    return HomePageUtilsHelper.generateDefaultTitle(existingTitles);
  }

  /// 時間文字列解析
  TimeOfDay parseTimeString(String timeStr) {
    return HomePageUtilsHelper.parseTimeString(timeStr);
  }

  /// メモ追加可能かチェック
  bool canAddMemo() {
    const maxMemos = 500;
    final memos = stateManager?.medicationMemos ?? [];
    return memos.length < maxMemos;
  }

  /// アラーム追加可能かチェック
  bool canAddAlarm() {
    const maxAlarms = 100;
    final alarms = stateManager?.alarmList ?? [];
    return alarms.length < maxAlarms;
  }

  /// トライアル制限チェック
  Future<bool> checkTrialLimit(String featureName) async {
    final isExpired = await TrialService.isTrialExpired();
    if (isExpired && onMountedCheck()) {
      showDialog(
        context: context,
        builder: (context) => TrialLimitDialog(featureName: featureName),
      );
      return true;
    }
    return false;
  }
}

