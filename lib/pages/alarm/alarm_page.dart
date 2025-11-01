import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/alarm_state.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_dialog.dart';

/// アラームページ
class AlarmPage extends ConsumerWidget {
  const AlarmPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmState = ref.watch(alarmStateProvider);
    
    // エラー表示
    if (alarmState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorDialog.show(
          context,
          message: alarmState.errorMessage!,
        );
      });
    }
    
    return LoadingOverlay(
      isLoading: alarmState.isLoading,
      message: '読み込み中...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('アラーム'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddAlarmDialog(context, ref),
            ),
          ],
        ),
        body: alarmState.alarmList.isEmpty
            ? _buildEmptyState(context)
            : _buildAlarmList(context, alarmState, ref),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'アラームが設定されていません',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddAlarmDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('アラームを追加'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAlarmList(
    BuildContext context,
    AlarmState state,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.alarmList.length,
      itemBuilder: (context, index) {
        final alarm = state.alarmList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ListTile(
            leading: Switch(
              value: alarm['enabled'] as bool? ?? false,
              onChanged: (value) {
                final updatedAlarm = Map<String, dynamic>.from(alarm);
                updatedAlarm['enabled'] = value;
                ref.read(alarmStateProvider.notifier).updateAlarm(index, updatedAlarm);
              },
            ),
            title: Text(alarm['name'] as String? ?? 'アラーム'),
            subtitle: Text(alarm['time'] as String? ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteAlarm(context, ref, index),
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _showAddAlarmDialog(BuildContext context, WidgetRef? ref) async {
    // TODO: アラーム追加ダイアログの実装
    if (ref != null) {
      // 一時的な実装
      ref.read(alarmStateProvider.notifier).addAlarm({
        'name': '新しいアラーム',
        'time': '09:00',
        'enabled': true,
      });
    }
  }
  
  Future<void> _confirmDeleteAlarm(BuildContext context, WidgetRef ref, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アラームを削除'),
        content: const Text('このアラームを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      ref.read(alarmStateProvider.notifier).deleteAlarm(index);
    }
  }
}

