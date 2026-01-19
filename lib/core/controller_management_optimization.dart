import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// コントローラー管理の最適化 - 動的コントローラーの効率的な管理
class ControllerManagementOptimization {
  static final Map<String, TextEditingController> _controllers = {};
  static final Map<String, FocusNode> _focusNodes = {};
  static final Map<String, List<String>> _controllerGroups = {};
  static bool _disposed = false;
  
  /// コントローラーの取得または作成
  static TextEditingController getController(String id, {String? groupId}) {
    if (_disposed) {
      Logger.warning('ControllerManagementOptimizationは既に破棄されています');
      return TextEditingController();
    }
    
    if (_controllers.containsKey(id)) {
      return _controllers[id]!;
    }
    
    final controller = TextEditingController();
    _controllers[id] = controller;
    
    if (groupId != null) {
      _controllerGroups.putIfAbsent(groupId, () => []).add(id);
    }
    
    Logger.debug('コントローラー作成: $id${groupId != null ? ' (グループ: $groupId)' : ''}');
    return controller;
  }
  
  /// フォーカスノードの取得または作成
  static FocusNode getFocusNode(String id, {String? groupId}) {
    if (_disposed) {
      Logger.warning('ControllerManagementOptimizationは既に破棄されています');
      return FocusNode();
    }
    
    if (_focusNodes.containsKey(id)) {
      return _focusNodes[id]!;
    }
    
    final focusNode = FocusNode();
    _focusNodes[id] = focusNode;
    
    if (groupId != null) {
      _controllerGroups.putIfAbsent(groupId, () => []).add(id);
    }
    
    Logger.debug('フォーカスノード作成: $id${groupId != null ? ' (グループ: $groupId)' : ''}');
    return focusNode;
  }
  
  /// コントローラーの削除
  static void removeController(String id) {
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
  static void removeFocusNode(String id) {
    if (_disposed) return;
    
    try {
      _focusNodes[id]?.dispose();
      _focusNodes.remove(id);
      Logger.debug('フォーカスノード削除: $id');
    } catch (e) {
      Logger.warning('フォーカスノード削除エラー: $e');
    }
  }
  
  /// グループ内の全コントローラーを削除
  static void removeGroupControllers(String groupId) {
    if (_disposed) return;
    
    final controllerIds = _controllerGroups.remove(groupId);
    if (controllerIds != null) {
      for (final id in controllerIds) {
        removeController(id);
        removeFocusNode(id);
      }
      Logger.debug('グループコントローラー削除: $groupId (${controllerIds.length}個)');
    }
  }
  
  /// 全コントローラーの解放
  static void dispose() {
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
    _controllerGroups.clear();
    
    Logger.info('ControllerManagementOptimization解放完了');
  }
  
  /// 統計情報の取得
  static Map<String, dynamic> getStats() {
    return {
      'controllers': _controllers.length,
      'focusNodes': _focusNodes.length,
      'groups': _controllerGroups.length,
      'disposed': _disposed,
    };
  }
}

/// 動的メディケーションコントローラー管理
class DynamicMedicationControllerManager {
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
      Logger.warning('DynamicMedicationControllerManagerは既に破棄されています');
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
    
    Logger.info('DynamicMedicationControllerManager解放完了');
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

/// コントローラー監視機能
class ControllerMonitor {
  static final Map<String, DateTime> _controllerCreationTimes = {};
  static final Map<String, int> _controllerUsageCounts = {};
  
  /// コントローラーの作成を記録
  static void recordControllerCreation(String id, String type) {
    _controllerCreationTimes['$type:$id'] = DateTime.now();
    _controllerUsageCounts[type] = (_controllerUsageCounts[type] ?? 0) + 1;
    Logger.debug('コントローラー作成記録: $type:$id');
  }
  
  /// コントローラーの使用を記録
  static void recordControllerUsage(String id, String type) {
    _controllerUsageCounts['$type:$id'] = (_controllerUsageCounts['$type:$id'] ?? 0) + 1;
  }
  
  /// 古いコントローラーの検出
  static List<String> detectOldControllers({Duration threshold = const Duration(minutes: 30)}) {
    final now = DateTime.now();
    final oldControllers = <String>[];
    
    for (final entry in _controllerCreationTimes.entries) {
      final age = now.difference(entry.value);
      if (age.compareTo(threshold) > 0) {
        oldControllers.add('${entry.key}: ${age.inMinutes}分前');
      }
    }
    
    return oldControllers;
  }
  
  /// 使用頻度の低いコントローラーの検出
  static List<String> detectUnusedControllers({int threshold = 5}) {
    final unusedControllers = <String>[];
    
    for (final entry in _controllerUsageCounts.entries) {
      if (entry.value < threshold) {
        unusedControllers.add('${entry.key}: ${entry.value}回');
      }
    }
    
    return unusedControllers;
  }
  
  /// コントローラー統計の取得
  static Map<String, dynamic> getControllerStats() {
    return {
      'activeControllers': _controllerCreationTimes.length,
      'usageCounts': Map.from(_controllerUsageCounts),
      'oldControllers': detectOldControllers(),
      'unusedControllers': detectUnusedControllers(),
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _controllerCreationTimes.clear();
    _controllerUsageCounts.clear();
    Logger.info('コントローラー統計をクリアしました');
  }
}

/// 統合コントローラー管理
class IntegratedControllerManagement {
  static final DynamicMedicationControllerManager _medicationManager = DynamicMedicationControllerManager();
  
  /// メディケーションコントローラーの取得
  static Map<String, dynamic> getMedicationControllers(String medicationId) {
    return _medicationManager.getMedicationControllers(medicationId);
  }
  
  /// メディケーションコントローラーの削除
  static void removeMedicationControllers(String medicationId) {
    _medicationManager.removeMedicationControllers(medicationId);
  }
  
  /// 全リソースの解放
  static void disposeAll() {
    ControllerManagementOptimization.dispose();
    _medicationManager.dispose();
    ControllerMonitor.clearStats();
    Logger.info('統合コントローラー管理解放完了');
  }
  
  /// 統合統計の取得
  static Map<String, dynamic> getIntegratedStats() {
    return {
      'controllerOptimization': ControllerManagementOptimization.getStats(),
      'medicationManager': _medicationManager.getStats(),
      'controllerMonitor': ControllerMonitor.getControllerStats(),
    };
  }
}
