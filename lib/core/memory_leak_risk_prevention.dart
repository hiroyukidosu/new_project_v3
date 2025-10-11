import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// メモリリークリスク防止機能 - コントローラーの完全な解放管理
class MemoryLeakRiskPrevention {
  static final Map<String, List<TextEditingController>> _controllerGroups = {};
  static final Map<String, List<FocusNode>> _focusNodeGroups = {};
  static final Map<String, List<StreamSubscription>> _subscriptionGroups = {};
  static final Map<String, List<Timer>> _timerGroups = {};
  static final Map<String, List<AnimationController>> _animationGroups = {};
  static final Map<String, List<ScrollController>> _scrollGroups = {};
  
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
      'animationGroups': _animationGroups.length,
      'scrollGroups': _scrollGroups.length,
      'totalControllers': _controllerGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalFocusNodes': _focusNodeGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalSubscriptions': _subscriptionGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalTimers': _timerGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalAnimationControllers': _animationGroups.values.fold(0, (sum, list) => sum + list.length),
      'totalScrollControllers': _scrollGroups.values.fold(0, (sum, list) => sum + list.length),
    };
  }
}

/// メディケーションコントローラーの一元管理
class MedicationController {
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _dosageControllers = {};
  final Map<String, TextEditingController> _notesControllers = {};
  final Map<String, FocusNode> _nameFocusNodes = {};
  final Map<String, FocusNode> _dosageFocusNodes = {};
  final Map<String, FocusNode> _notesFocusNodes = {};
  bool _disposed = false;
  
  /// メディケーションコントローラーの取得
  Map<String, dynamic> getMedicationControllers(String medicationId) {
    if (_disposed) {
      Logger.warning('MedicationControllerは既に破棄されています');
      return {};
    }
    
    return {
      'nameController': _nameControllers.putIfAbsent(medicationId, () => TextEditingController()),
      'dosageController': _dosageControllers.putIfAbsent(medicationId, () => TextEditingController()),
      'notesController': _notesControllers.putIfAbsent(medicationId, () => TextEditingController()),
      'nameFocusNode': _nameFocusNodes.putIfAbsent(medicationId, () => FocusNode()),
      'dosageFocusNode': _dosageFocusNodes.putIfAbsent(medicationId, () => FocusNode()),
      'notesFocusNode': _notesFocusNodes.putIfAbsent(medicationId, () => FocusNode()),
    };
  }
  
  /// メディケーションコントローラーの削除
  void removeMedicationControllers(String medicationId) {
    if (_disposed) return;
    
    try {
      _nameControllers[medicationId]?.dispose();
      _dosageControllers[medicationId]?.dispose();
      _notesControllers[medicationId]?.dispose();
      _nameFocusNodes[medicationId]?.dispose();
      _dosageFocusNodes[medicationId]?.dispose();
      _notesFocusNodes[medicationId]?.dispose();
      
      _nameControllers.remove(medicationId);
      _dosageControllers.remove(medicationId);
      _notesControllers.remove(medicationId);
      _nameFocusNodes.remove(medicationId);
      _dosageFocusNodes.remove(medicationId);
      _notesFocusNodes.remove(medicationId);
      
      Logger.debug('メディケーションコントローラー削除: $medicationId');
    } catch (e) {
      Logger.warning('メディケーションコントローラー削除エラー: $e');
    }
  }
  
  /// 全メディケーションコントローラーの解放
  void dispose() {
    if (_disposed) return;
    
    _disposed = true;
    
    // 全コントローラーの解放
    for (final controller in _nameControllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        Logger.warning('名前コントローラー解放エラー: $e');
      }
    }
    
    for (final controller in _dosageControllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        Logger.warning('用量コントローラー解放エラー: $e');
      }
    }
    
    for (final controller in _notesControllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        Logger.warning('メモコントローラー解放エラー: $e');
      }
    }
    
    // 全フォーカスノードの解放
    for (final focusNode in _nameFocusNodes.values) {
      try {
        focusNode.dispose();
      } catch (e) {
        Logger.warning('名前フォーカスノード解放エラー: $e');
      }
    }
    
    for (final focusNode in _dosageFocusNodes.values) {
      try {
        focusNode.dispose();
      } catch (e) {
        Logger.warning('用量フォーカスノード解放エラー: $e');
      }
    }
    
    for (final focusNode in _notesFocusNodes.values) {
      try {
        focusNode.dispose();
      } catch (e) {
        Logger.warning('メモフォーカスノード解放エラー: $e');
      }
    }
    
    _nameControllers.clear();
    _dosageControllers.clear();
    _notesControllers.clear();
    _nameFocusNodes.clear();
    _dosageFocusNodes.clear();
    _notesFocusNodes.clear();
    
    Logger.info('MedicationController解放完了');
  }
  
  /// 統計情報の取得
  Map<String, dynamic> getStats() {
    return {
      'nameControllers': _nameControllers.length,
      'dosageControllers': _dosageControllers.length,
      'notesControllers': _notesControllers.length,
      'nameFocusNodes': _nameFocusNodes.length,
      'dosageFocusNodes': _dosageFocusNodes.length,
      'notesFocusNodes': _notesFocusNodes.length,
      'disposed': _disposed,
    };
  }
}

/// メモリリーク検出機能
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
