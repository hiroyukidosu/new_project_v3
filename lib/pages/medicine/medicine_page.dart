import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/medication_state.dart';
import '../../widgets/medication/medication_memo_checkbox.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_dialog.dart';
import '../../widgets/memo_dialog.dart';

/// 薬物管理ページ
class MedicinePage extends ConsumerWidget {
  const MedicinePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationState = ref.watch(medicationStateProvider);
    
    // エラー表示
    if (medicationState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorDialog.show(
          context,
          message: medicationState.errorMessage!,
        );
      });
    }
    
    return LoadingOverlay(
      isLoading: medicationState.isLoading,
      message: '読み込み中...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('薬物管理'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddMemoDialog(context, ref),
            ),
          ],
        ),
        body: medicationState.medicationMemos.isEmpty
            ? _buildEmptyState(context)
            : _buildMemoList(context, medicationState, ref),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '薬物が登録されていません',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddMemoDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('薬物を追加'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMemoList(
    BuildContext context,
    MedicationState state,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.medicationMemos.length,
      itemBuilder: (context, index) {
        final memo = state.medicationMemos[index];
        final dateKey = _getDateKey(DateTime.now());
        final doseStatus = <String, Map<int, bool>>{
          dateKey: state.medicationMemoStatus.map((key, value) {
            if (key.startsWith('${memo.id}_')) {
              final parts = key.split('_');
              if (parts.length > 2) {
                final doseIndex = int.tryParse(parts[parts.length - 1]);
                if (doseIndex != null) {
                  return MapEntry(memo.id, {doseIndex: value});
                }
              }
            }
            return MapEntry(memo.id, {});
          })[memo.id] ?? {},
        };
        
        return MedicationMemoCheckbox(
          memo: memo,
          doseStatus: doseStatus,
          onDoseStatusChanged: (memoId, doseIndex, isChecked) {
            ref.read(medicationStateProvider.notifier).updateMemoStatus(
              '${memoId}_${_getDateKey(DateTime.now())}_$doseIndex',
              isChecked,
            );
          },
        );
      },
    );
  }
  
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  Future<void> _showAddMemoDialog(BuildContext context, WidgetRef? ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const MemoDialog(),
    );
    
    if (result != null && ref != null) {
      // メモを追加する処理は既存のMemoDialogと統合が必要
      // ここでは例として示しています
    }
  }
}

