import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// メモリリーク防止機能 - コントローラーとリソースの適切な管理
class MemoryLeakPrevention {
  static final Map<String, List<TextEditingController>> _controllerGroups = {};
  static final Map<String, List<FocusNode>> _focusNodeGroups = {};
  static final Map<String, List<StreamSubscription>> _subscriptionGroups = {};
  static final Map<String, List<Timer>> _timerGroups = {};
  
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
  }
  
  /// 全リソースの解放
  static void disposeAll() {
    // 全グループの解放
    final allGroups = <String>{};
    allGroups.addAll(_controllerGroups.keys);
    allGroups.addAll(_focusNodeGroups.keys);
    allGroups.addAll(_subscriptionGroups.keys);
    allGroups.addAll(_timerGroups.keys);
    
    for (final groupId in allGroups) {
      disposeGroup(groupId);
    }
    
    Logger.info('全リソース解放完了');
  }
  
  /// リソース統計の取得
  static Map<String, int> getResourceStats() {
    return {
      'controllerGroups': _controllerGroups.length,
      'focusNodeGroups': _focusNodeGroups.length,
      'subscriptionGroups': _subscriptionGroups.length,
      'timerGroups': _timerGroups.length,
      'totalControllers': _controllerGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalFocusNodes': _focusNodeGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalSubscriptions': _subscriptionGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalTimers': _timerGroups.values.fold(0, (sum, list) => sum + list.length),
    };
  }
}

/// 動的コントローラー管理
class DynamicControllerManager {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _disposed = false;
  
  /// コントローラーの取得または作成
  TextEditingController getController(String id) {
    if (_disposed) {
      Logger.warning('DynamicControllerManagerは既に破棄されています');
      return TextEditingController();
    }
    
    return _controllers.putIfAbsent(id, () {
      final controller = TextEditingController();
      MemoryLeakPrevention.registerController('dynamic_controllers', controller);
      return controller;
    });
  }
  
  /// フォーカスノードの取得または作成
  FocusNode getFocusNode(String id) {
    if (_disposed) {
      Logger.warning('DynamicControllerManagerは既に破棄されています');
      return FocusNode();
    }
    
    return _focusNodes.putIfAbsent(id, () {
      final focusNode = FocusNode();
      MemoryLeakPrevention.registerFocusNode('dynamic_focus_nodes', focusNode);
      return focusNode;
    });
  }
  
  /// コントローラーの削除
  void removeController(String id) {
    if (_disposed) return;
    
    try {
      _controllers[id]?.dispose();
      _controllers.remove(id);
      Logger.debug('コントローラー削除: $id');
    } catch (e) {
      Logger.warning('コントローラー削除エラー: $e');
    }
  }
  
  /// フォーカスノードの削除
  void removeFocusNode(String id) {
    if (_disposed) return;
    
    try {
      _focusNodes[id]?.dispose();
      _focusNodes.remove(id);
      Logger.debug('フォーカスノード削除: $id');
    } catch (e) {
      Logger.warning('フォーカスノード削除エラー: $e');
    }
  }
  
  /// リソースの解放
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
    
    _controllers.clear();
    _focusNodes.clear();
    
    Logger.info('DynamicControllerManager解放完了');
  }
  
  /// 統計情報の取得
  Map<String, int> getStats() {
    return {
      'controllers': _controllers.length,
      'focusNodes': _focusNodes.length,
      'disposed': _disposed,
    };
  }
}

/// メモリリーク検出機能
class MemoryLeakDetector {
  static final Map<String, DateTime> _resourceCreationTimes = {};
  static final Map<String, int> _resourceCounts = {};
  
  /// リソースの作成を記録
  static void recordResourceCreation(String resourceType, String id) {
    _resourceCreationTimes['$resourceType:$id'] = DateTime.now();
    _resourceCounts[resourceType] = (_resourceCounts[resourceType] ?? 0) + 1;
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
      'memoryLeaks': detectMemoryLeaks(),
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _resourceCreationTimes.clear();
    _resourceCounts.clear();
    Logger.info('リソース統計をクリアしました');
  }
}
