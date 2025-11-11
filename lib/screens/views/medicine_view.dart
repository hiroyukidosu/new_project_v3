// MedicineView
// 服用メモタブ - 完全独立化（StateManagerに直接依存）

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../home/state/home_page_state_manager.dart';
import '../home/business/pagination_manager.dart';
import '../../widgets/memo_dialog.dart';
import '../../services/trial_service.dart';
import '../../widgets/trial_limit_dialog.dart';

/// 服用メモビュー
/// StateManagerに完全依存し、コールバック関数は親から受け取る
class MedicineView extends StatefulWidget {
  final HomePageStateManager stateManager;
  final void Function(MedicationMemo)? onEditMemo;
  final void Function(String)? onDeleteMemo;
  final void Function(MedicationMemo)? onMarkAsTaken;

  const MedicineView({
    super.key,
    required this.stateManager,
    this.onEditMemo,
    this.onDeleteMemo,
    this.onMarkAsTaken,
  });

  @override
  State<MedicineView> createState() => _MedicineViewState();
}

class _MedicineViewState extends State<MedicineView> {
  @override
  void initState() {
    super.initState();
    // メモリストの変更を監視
    widget.stateManager.notifiers.medicationMemosNotifier.addListener(_onMemosChanged);
  }

  @override
  void dispose() {
    widget.stateManager.notifiers.medicationMemosNotifier.removeListener(_onMemosChanged);
    super.dispose();
  }

  void _onMemosChanged() {
    if (mounted) {
      setState(() {
        // メモリストが変更されたので画面を更新
      });
    }
  }

  /// メモ追加
  Future<void> _addMemo(BuildContext context) async {
    final isExpired = await TrialService.isTrialExpired();
    if (isExpired) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => TrialLimitDialog(featureName: '服用メモ'),
      );
      return;
    }

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => MemoDialog(
        existingMemos: widget.stateManager.medicationMemos,
        onMemoAdded: (memo) async {
          await widget.stateManager.memoEventHandler.addMemo(
            memo,
            widget.stateManager.medicationMemos,
            500, // maxMemos
            () async => await widget.stateManager.saveAllData(),
          );
          // メモ追加後に画面を更新
          if (mounted) {
            setState(() {
              // 状態を更新して画面を再構築
            });
          }
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
    // ダイアログが閉じられた後も画面を更新
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.stateManager.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // ValueListenableBuilderでメモリストの変更を監視
    return ValueListenableBuilder<int>(
      valueListenable: widget.stateManager.notifiers.medicationMemosNotifier,
      builder: (context, _, __) {
        final memos = widget.stateManager.paginationManager.displayedMemos;
        final hasMore = widget.stateManager.paginationManager.hasMore;
        final currentPage = widget.stateManager.paginationManager.currentPage;
        final totalMemos = widget.stateManager.medicationMemos.length;
        final totalPages = (totalMemos / widget.stateManager.paginationManager.pageSize).ceil();
        
        return _buildContent(context, memos, hasMore, currentPage, totalMemos, totalPages);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<MedicationMemo> memos,
    bool hasMore,
    int currentPage,
    int totalMemos,
    int totalPages,
  ) {

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade600,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medication, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '服用メモ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (totalPages > 1)
                            Text(
                              'ページ ${currentPage + 1} / $totalPages',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.add_circle, color: Colors.white, size: 24),
                      ),
                      onPressed: () => _addMemo(context),
                      tooltip: 'メモを追加',
                    ),
                  ],
                ),
              ),
              // メモリスト
              Expanded(
                child: memos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '服用メモがありません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _addMemo(context),
                            icon: const Icon(Icons.add),
                            label: const Text('メモを追加'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: widget.stateManager.medicationHistoryScrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: memos.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= memos.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.stateManager.paginationManager.loadNextPage();
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                                child: const Text('次のページを読み込む'),
                              ),
                            ),
                          );
                        }
                        final memo = memos[index];
                        return _buildMemoCard(context, memo);
                      },
                    ),
              ),
              // ページネーションコントロール
              if (totalPages > 1)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: currentPage > 0
                            ? () {
                                widget.stateManager.paginationManager.goToPage(currentPage - 1);
                                if (mounted) {
                                  setState(() {});
                                }
                              }
                            : null,
                      ),
                      Text('${currentPage + 1} / $totalPages'),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: hasMore
                            ? () {
                                widget.stateManager.paginationManager.loadNextPage();
                                if (mounted) {
                                  setState(() {});
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addMemo(context),
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMemoCard(BuildContext context, MedicationMemo memo) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // アイコンと名前を上に配置
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: memo.color,
                  radius: 24,
                  child: Icon(
                    memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memo.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: memo.type == 'サプリメント'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: memo.type == 'サプリメント'
                                ? Colors.green.withOpacity(0.3)
                                : Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          memo.type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : (memo.type == 'サプリメント' ? Colors.green : Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // アクションボタンを右上に配置
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    // トライアル制限チェック
                    final isExpired = await TrialService.isTrialExpired();
                    if (isExpired) {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (context) => TrialLimitDialog(featureName: '服用メモ'),
                      );
                      return;
                    }
                    switch (value) {
                      case 'taken':
                        if (widget.onMarkAsTaken != null) widget.onMarkAsTaken!(memo);
                        break;
                      case 'edit':
                        if (widget.onEditMemo != null) widget.onEditMemo!(memo);
                        break;
                      case 'delete':
                        if (widget.onDeleteMemo != null) widget.onDeleteMemo!(memo.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'taken',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('服用記録'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('編集'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('削除'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 詳細情報を下に配置
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 服用回数情報
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.repeat, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '服用回数: ${memo.dosageFrequency}回',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      if (memo.dosageFrequency >= 6) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange, size: 24),
                                    SizedBox(width: 8),
                                    Text('服用回数が多い'),
                                  ],
                                ),
                                content: const Text(
                                  '服用回数が多いため医師の指示に従ってください',
                                  style: TextStyle(fontSize: 16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('了解'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Icon(Icons.warning, size: 16, color: Colors.orange),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (memo.dosage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.straighten, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '用量: ${memo.dosage}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                if (memo.dosage.isNotEmpty) const SizedBox(height: 10),
                if (memo.notes.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            memo.notes,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (memo.notes.isNotEmpty) const SizedBox(height: 10),
                // 曜日未設定の警告表示
                if (memo.selectedWeekdays.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.15),
                          Colors.orange.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                size: 28,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⚠️ 服用スケジュール未設定',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '曜日を設定してください',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'メモを編集して「服用スケジュール」から(毎日、曜日)を選択してください',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (memo.selectedWeekdays.isEmpty) const SizedBox(height: 10),
                if (memo.lastTaken != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          '最後の服用:\n${DateFormat('yyyy/MM/dd HH:mm').format(memo.lastTaken!)}',
                          style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

