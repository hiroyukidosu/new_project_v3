import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// 高度なメモリリーク対策 - 完全なリソース解放
class MemoryLeakPreventionAdvanced {
  static final Map<String, List<TextEditingController>> _controllerGroups = {};
  static final Map<String, List<FocusNode>> _focusNodeGroups = {};
  static final Map<String, List<StreamSubscription>> _subscriptionGroups = {};
  static final Map<String, List<Timer>> _timerGroups = {};
  static final Map<String, List<AnimationController>> _animationGroups = {};
  static final Map<String, List<ScrollController>> _scrollGroups = {};
  static final Map<String, List<ValueNotifier>> _valueNotifierGroups = {};
  static final Map<String, List<ChangeNotifier>> _changeNotifierGroups = {};
  
  /// コントローラーの登録
  static void registerController(String groupId, TextEditingController controller) {
    _controllerGroups.putIfAbsent(groupId, () => []).add(controller);
    Logger.debug('コントローラー登録: $groupId');
  }
  
  /// フォーカスノードの登録
  static void registerFocusNode(String groupId, FocusNode focusNode) {
    _focusNodeGroups.putIfAbsent(groupId, () => []).add(focusNode);
    Logger.debug('フォーカスノード登録: $groupId');
  }
  
  /// ストリームサブスクリプションの登録
  static void registerSubscription(String groupId, StreamSubscription subscription) {
    _subscriptionGroups.putIfAbsent(groupId, () => []).add(subscription);
    Logger.debug('ストリームサブスクリプション登録: $groupId');
  }
  
  /// タイマーの登録
  static void registerTimer(String groupId, Timer timer) {
    _timerGroups.putIfAbsent(groupId, () => []).add(timer);
    Logger.debug('タイマー登録: $groupId');
  }
  
  /// アニメーションコントローラーの登録
  static void registerAnimationController(String groupId, AnimationController controller) {
    _animationGroups.putIfAbsent(groupId, () => []).add(controller);
    Logger.debug('アニメーションコントローラー登録: $groupId');
  }
  
  /// スクロールコントローラーの登録
  static void registerScrollController(String groupId, ScrollController controller) {
    _scrollGroups.putIfAbsent(groupId, () => []).add(controller);
    Logger.debug('スクロールコントローラー登録: $groupId');
  }
  
  /// バリューノーティファイアの登録
  static void registerValueNotifier(String groupId, ValueNotifier notifier) {
    _valueNotifierGroups.putIfAbsent(groupId, () => []).add(notifier);
    Logger.debug('バリューノーティファイア登録: $groupId');
  }
  
  /// チェンジノーティファイアの登録
  static void registerChangeNotifier(String groupId, ChangeNotifier notifier) {
    _changeNotifierGroups.putIfAbsent(groupId, () => []).add(notifier);
    Logger.debug('チェンジノーティファイア登録: $groupId');
  }
  
  /// 特定グループのリソース解放
  static void disposeGroup(String groupId) {
    // コントローラーの解放
    final controllers = _controllerGroups.remove(groupId);
    if (controllers != null) {
      for (final controller in controllers) {
        try {
          controller.dispose();
        } catch (e) {
          Logger.warning('コントローラー解放エラー: $e');
        }
      }
      Logger.debug('コントローラー解放完了: $groupId (${controllers.length}個)');
    }
    
    // フォーカスノードの解放
    final focusNodes = _focusNodeGroups.remove(groupId);
    if (focusNodes != null) {
      for (final focusNode in focusNodes) {
        try {
          focusNode.dispose();
        } catch (e) {
          Logger.warning('フォーカスノード解放エラー: $e');
        }
      }
      Logger.debug('フォーカスノード解放完了: $groupId (${focusNodes.length}個)');
    }
    
    // ストリームサブスクリプションの解放
    final subscriptions = _subscriptionGroups.remove(groupId);
    if (subscriptions != null) {
      for (final subscription in subscriptions) {
        try {
          subscription.cancel();
        } catch (e) {
          Logger.warning('ストリームサブスクリプション解放エラー: $e');
        }
      }
      Logger.debug('ストリームサブスクリプション解放完了: $groupId (${subscriptions.length}個)');
    }
    
    // タイマーの解放
    final timers = _timerGroups.remove(groupId);
    if (timers != null) {
      for (final timer in timers) {
        try {
          timer.cancel();
        } catch (e) {
          Logger.warning('タイマー解放エラー: $e');
        }
      }
      Logger.debug('タイマー解放完了: $groupId (${timers.length}個)');
    }
    
    // アニメーションコントローラーの解放
    final animationControllers = _animationGroups.remove(groupId);
    if (animationControllers != null) {
      for (final controller in animationControllers) {
        try {
          controller.dispose();
        } catch (e) {
          Logger.warning('アニメーションコントローラー解放エラー: $e');
        }
      }
      Logger.debug('アニメーションコントローラー解放完了: $groupId (${animationControllers.length}個)');
    }
    
    // スクロールコントローラーの解放
    final scrollControllers = _scrollGroups.remove(groupId);
    if (scrollControllers != null) {
      for (final controller in scrollControllers) {
        try {
          controller.dispose();
        } catch (e) {
          Logger.warning('スクロールコントローラー解放エラー: $e');
        }
      }
      Logger.debug('スクロールコントローラー解放完了: $groupId (${scrollControllers.length}個)');
    }
    
    // バリューノーティファイアの解放
    final valueNotifiers = _valueNotifierGroups.remove(groupId);
    if (valueNotifiers != null) {
      for (final notifier in valueNotifiers) {
        try {
          notifier.dispose();
        } catch (e) {
          Logger.warning('バリューノーティファイア解放エラー: $e');
        }
      }
      Logger.debug('バリューノーティファイア解放完了: $groupId (${valueNotifiers.length}個)');
    }
    
    // チェンジノーティファイアの解放
    final changeNotifiers = _changeNotifierGroups.remove(groupId);
    if (changeNotifiers != null) {
      for (final notifier in changeNotifiers) {
        try {
          notifier.dispose();
        } catch (e) {
          Logger.warning('チェンジノーティファイア解放エラー: $e');
        }
      }
      Logger.debug('チェンジノーティファイア解放完了: $groupId (${changeNotifiers.length}個)');
    }
  }
  
  /// 全リソースの解放
  static void disposeAll() {
    // 全グループの解放
    final allGroups = <String>{};
    allGroups.addAll(_controllerGroups.keys);
    allGroups.addAll(_focusNodeGroups.keys);
    allGroups.addAll(_subscriptionGroups.keys);
    allGroups.addAll(_timerGroups.keys);
    allGroups.addAll(_animationGroups.keys);
    allGroups.addAll(_scrollGroups.keys);
    allGroups.addAll(_valueNotifierGroups.keys);
    allGroups.addAll(_changeNotifierGroups.keys);
    
    for (final groupId in allGroups) {
      disposeGroup(groupId);
    }
    
    Logger.info('全リソース解放完了');
  }
  
  /// リソース統計の取得
  static Map<String, dynamic> getResourceStats() {
    return {
      'controllerGroups': _controllerGroups.length,
      'focusNodeGroups': _focusNodeGroups.length,
      'subscriptionGroups': _subscriptionGroups.length,
      'timerGroups': _timerGroups.length,
      'animationGroups': _animationGroups.length,
      'scrollGroups': _scrollGroups.length,
      'valueNotifierGroups': _valueNotifierGroups.length,
      'changeNotifierGroups': _changeNotifierGroups.length,
      'totalControllers': _controllerGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalFocusNodes': _focusNodeGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalSubscriptions': _subscriptionGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalTimers': _timerGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalAnimationControllers': _animationGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalScrollControllers': _scrollGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalValueNotifiers': _valueNotifierGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalChangeNotifiers': _changeNotifierGroups.values.fold(0, (sum, list) => sum + list.length),
    };
  }
}

/// 動的コントローラー管理
class DynamicControllerManager {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Timer> _timers = {};
  bool _disposed = false;
  
  /// コントローラーの取得
  TextEditingController getController(String id) {
    if (_disposed) {
      Logger.warning('DynamicControllerManagerは既に破棄されています');
      return TextEditingController();
    }
    
    return _controllers.putIfAbsent(id, () => TextEditingController());
  }
  
  /// フォーカスノードの取得
  FocusNode getFocusNode(String id) {
    if (_disposed) {
      Logger.warning('DynamicControllerManagerは既に破棄されています');
      return FocusNode();
    }
    
    return _focusNodes.putIfAbsent(id, () => FocusNode());
  }
  
  /// ストリームサブスクリプションの登録
  void registerSubscription(String id, StreamSubscription subscription) {
    if (_disposed) return;
    
    _subscriptions[id] = subscription;
    Logger.debug('ストリームサブスクリプション登録: $id');
  }
  
  /// タイマーの登録
  void registerTimer(String id, Timer timer) {
    if (_disposed) return;
    
    _timers[id] = timer;
    Logger.debug('タイマー登録: $id');
  }
  
  /// コントローラーの削除
  void removeController(String id) {
    if (_disposed) return;
    
    try {
      _controllers[id]?.dispose();
      _focusNodes[id]?.dispose();
      _subscriptions[id]?.cancel();
      _timers[id]?.cancel();
      
      _controllers.remove(id);
      _focusNodes.remove(id);
      _subscriptions.remove(id);
      _timers.remove(id);
      
      Logger.debug('コントローラー削除: $id');
    } catch (e) {
      Logger.warning('コントローラー削除エラー: $e');
    }
  }
  
  /// 全リソースの解放
  void dispose() {
    if (_disposed) return;
    
    _disposed = true;
    
    // 全コントローラーの解放
    for (final controller in _controllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        Logger.warning('コントローラー解放エラー: $e');
      }
    }
    
    // 全フォーカスノードの解放
    for (final focusNode in _focusNodes.values) {
      try {
        focusNode.dispose();
      } catch (e) {
        Logger.warning('フォーカスノード解放エラー: $e');
      }
    }
    
    // 全ストリームサブスクリプションの解放
    for (final subscription in _subscriptions.values) {
      try {
        subscription.cancel();
      } catch (e) {
        Logger.warning('ストリームサブスクリプション解放エラー: $e');
      }
    }
    
    // 全タイマーの解放
    for (final timer in _timers.values) {
      try {
        timer.cancel();
      } catch (e) {
        Logger.warning('タイマー解放エラー: $e');
      }
    }
    
    _controllers.clear();
    _focusNodes.clear();
    _subscriptions.clear();
    _timers.clear();
    
    Logger.info('DynamicControllerManager解放完了');
  }
  
  /// 統計情報の取得
  Map<String, dynamic> getStats() {
    return {
      'controllers': _controllers.length,
      'focusNodes': _focusNodes.length,
      'subscriptions': _subscriptions.length,
      'timers': _timers.length,
      'disposed': _disposed,
    };
  }
}

/// メモリリーク検出
class MemoryLeakDetector {
  static final Map<String, DateTime> _resourceCreationTimes = {};
  static final Map<String, int> _resourceCounts = {};
  static final Map<String, List<String>> _resourceGroups = {};
  
  /// リソースの作成を記録
  static void recordResourceCreation(String resourceType, String id, {String? groupId}) {
    _resourceCreationTimes['$resourceType:$id'] = DateTime.now();
    _resourceCounts[resourceType] = (_resourceCounts[resourceType] ?? 0) + 1;
    
    if (groupId != null) {
      _resourceGroups.putIfAbsent(groupId, () => []).add('$resourceType:$id');
    }
    
    Logger.debug('リソース作成記録: $resourceType:$id');
  }
  
  /// リソースの削除を記録
  static void recordResourceDisposal(String resourceType, String id) {
    _resourceCreationTimes.remove('$resourceType:$id');
    _resourceCounts[resourceType] = (_resourceCounts[resourceType] ?? 0) - 1;
    Logger.debug('リソース削除記録: $resourceType:$id');
  }
  
  /// メモリリークの検出
  static List<String> detectMemoryLeaks() {
    final leaks = <String>[];
    final now = DateTime.now();
    
    for (final entry in _resourceCreationTimes.entries) {
      final age = now.difference(entry.value);
      if (age.inMinutes > 10) { // 10分以上経過したリソース
        leaks.add('古いリソース: ${entry.key} (${age.inMinutes}分前)');
      }
    }
    
    for (final entry in _resourceCounts.entries) {
      if (entry.value > 100) { // 100個以上のリソース
        leaks.add('リソース数過多: ${entry.key} (${entry.value}個)');
      }
    }
    
    return leaks;
  }
  
  /// リソース統計の取得
  static Map<String, dynamic> getResourceStats() {
    return {
      'activeResources': _resourceCreationTimes.length,
      'resourceCounts': Map.from(_resourceCounts),
      'resourceGroups': Map.from(_resourceGroups),
      'memoryLeaks': detectMemoryLeaks(),
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _resourceCreationTimes.clear();
    _resourceCounts.clear();
    _resourceGroups.clear();
    Logger.info('リソース統計をクリアしました');
  }
}

/// 最適化されたメディケーションホームページの実装例
class OptimizedMedicationHomePage extends StatefulWidget {
  const OptimizedMedicationHomePage({super.key});
  
  @override
  State<OptimizedMedicationHomePage> createState() => _OptimizedMedicationHomePageState();
}

class _OptimizedMedicationHomePageState extends State<OptimizedMedicationHomePage> {
  // ✅ 改善: 動的コントローラー管理
  final DynamicControllerManager _controllerManager = DynamicControllerManager();
  
  // データ
  List<dynamic> _medicationMemos = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeOptimizedApp();
  }
  
  void _initializeOptimizedApp() {
    // メモリリーク対策の初期化
    MemoryLeakDetector.clearStats();
    
    // 初期データの読み込み
    _loadInitialData();
  }
  
  @override
  void dispose() {
    // ✅ 改善: 完全なリソース解放
    _controllerManager.dispose();
    MemoryLeakPreventionAdvanced.disposeAll();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 初期データの読み込み
      // 実装は必要に応じて追加
      
      setState(() {
        _isLoading = false;
      });
      
      Logger.info('最適化されたアプリの初期化完了');
    } catch (e) {
      Logger.error('最適化されたアプリの初期化エラー', e);
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // ✅ 改善: 最適化されたメディケーションリスト
  Widget _buildOptimizedMedicationList() {
    return PerformanceOptimizer.buildOptimizedListView(
      items: _medicationMemos,
      itemBuilder: (context, medication, index) {
        return _buildMedicationItem(medication, index);
      },
      enableCaching: true,
      enableRepaintBoundary: true,
    );
  }
  
  Widget _buildMedicationItem(dynamic medication, int index) {
    final medicationId = medication['id'] as String? ?? index.toString();
    final controller = _controllerManager.getController(medicationId);
    final focusNode = _controllerManager.getFocusNode(medicationId);
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: '薬名',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMemoryReport() {
    final stats = MemoryLeakPreventionAdvanced.getResourceStats();
    final leakStats = MemoryLeakDetector.getResourceStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモリレポート'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('リソース統計:\n${stats.toString()}'),
              const SizedBox(height: 16),
              Text('メモリリーク検出:\n${leakStats.toString()}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('最適化された服薬管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.memory),
            onPressed: _showMemoryReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // メモリ情報の表示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.withOpacity(0.1),
                  child: const Text(
                    'メモリリーク対策が有効です',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                
                // メインコンテンツ
                Expanded(
                  child: _buildOptimizedMedicationList(),
                ),
              ],
            ),
    );
  }
}
