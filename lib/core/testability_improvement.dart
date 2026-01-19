import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// テスト可能性の向上 - 依存性注入とモック対応
class TestabilityImprovement {
  
  /// 依存性注入対応のメディケーションサービス
  static MedicationService createMedicationService({
    StorageRepository? storage,
    NotificationService? notification,
    AnalyticsService? analytics,
  }) {
    return MedicationService(
      storage: storage ?? MockStorageRepository(),
      notification: notification ?? MockNotificationService(),
      analytics: analytics ?? MockAnalyticsService(),
    );
  }
  
  /// テスト用のモックリポジトリ
  static MockStorageRepository createMockStorageRepository() {
    return MockStorageRepository();
  }
  
  /// テスト用のモック通知サービス
  static MockNotificationService createMockNotificationService() {
    return MockNotificationService();
  }
  
  /// テスト用のモックアナリティクスサービス
  static MockAnalyticsService createMockAnalyticsService() {
    return MockAnalyticsService();
  }
}

/// メディケーションサービス（依存性注入対応）
class MedicationService {
  final StorageRepository storage;
  final NotificationService notification;
  final AnalyticsService analytics;
  
  MedicationService({
    required this.storage,
    required this.notification,
    required this.analytics,
  });
  
  /// メディケーションの追加
  Future<void> addMedication(Medication med) async {
    try {
      await storage.save(med);
      await notification.schedule(med);
      await analytics.track('medication_added', {
        'type': med.type,
        'frequency': med.dosageFrequency,
      });
      
      Logger.info('メディケーション追加完了: ${med.name}');
    } catch (e) {
      Logger.error('メディケーション追加エラー', e);
      rethrow;
    }
  }
  
  /// メディケーションの更新
  Future<void> updateMedication(Medication med) async {
    try {
      await storage.update(med);
      await notification.update(med);
      await analytics.track('medication_updated', {
        'type': med.type,
        'frequency': med.dosageFrequency,
      });
      
      Logger.info('メディケーション更新完了: ${med.name}');
    } catch (e) {
      Logger.error('メディケーション更新エラー', e);
      rethrow;
    }
  }
  
  /// メディケーションの削除
  Future<void> deleteMedication(String id) async {
    try {
      await storage.delete(id);
      await notification.cancel(id);
      await analytics.track('medication_deleted', {
        'id': id,
      });
      
      Logger.info('メディケーション削除完了: $id');
    } catch (e) {
      Logger.error('メディケーション削除エラー', e);
      rethrow;
    }
  }
  
  /// メディケーションの取得
  Future<List<Medication>> getMedications() async {
    try {
      final medications = await storage.getAll();
      await analytics.track('medications_loaded', {
        'count': medications.length,
      });
      
      Logger.info('メディケーション取得完了: ${medications.length}件');
      return medications;
    } catch (e) {
      Logger.error('メディケーション取得エラー', e);
      rethrow;
    }
  }
}

/// メディケーションモデル
class Medication {
  final String id;
  final String name;
  final String type;
  final String dosageFrequency;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Medication({
    required this.id,
    required this.name,
    required this.type,
    required this.dosageFrequency,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'dosageFrequency': dosageFrequency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      dosageFrequency: json['dosageFrequency'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// ストレージリポジトリのインターフェース
abstract class StorageRepository {
  Future<void> save(Medication medication);
  Future<void> update(Medication medication);
  Future<void> delete(String id);
  Future<List<Medication>> getAll();
  Future<Medication?> getById(String id);
}

/// 通知サービスのインターフェース
abstract class NotificationService {
  Future<void> schedule(Medication medication);
  Future<void> update(Medication medication);
  Future<void> cancel(String id);
  Future<void> cancelAll();
}

/// アナリティクスサービスのインターフェース
abstract class AnalyticsService {
  Future<void> track(String event, Map<String, dynamic> parameters);
  Future<void> setUserProperty(String key, String value);
  Future<void> setUserId(String userId);
}

/// モックストレージリポジトリ
class MockStorageRepository implements StorageRepository {
  final Map<String, Medication> _medications = {};
  
  @override
  Future<void> save(Medication medication) async {
    _medications[medication.id] = medication;
    Logger.debug('MockStorageRepository: メディケーション保存: ${medication.name}');
  }
  
  @override
  Future<void> update(Medication medication) async {
    _medications[medication.id] = medication;
    Logger.debug('MockStorageRepository: メディケーション更新: ${medication.name}');
  }
  
  @override
  Future<void> delete(String id) async {
    _medications.remove(id);
    Logger.debug('MockStorageRepository: メディケーション削除: $id');
  }
  
  @override
  Future<List<Medication>> getAll() async {
    Logger.debug('MockStorageRepository: 全メディケーション取得: ${_medications.length}件');
    return _medications.values.toList();
  }
  
  @override
  Future<Medication?> getById(String id) async {
    Logger.debug('MockStorageRepository: メディケーション取得: $id');
    return _medications[id];
  }
  
  /// テスト用のメソッド
  void clear() {
    _medications.clear();
    Logger.debug('MockStorageRepository: データクリア');
  }
  
  int get count => _medications.length;
}

/// モック通知サービス
class MockNotificationService implements NotificationService {
  final Map<String, Medication> _scheduledNotifications = {};
  
  @override
  Future<void> schedule(Medication medication) async {
    _scheduledNotifications[medication.id] = medication;
    Logger.debug('MockNotificationService: 通知スケジュール: ${medication.name}');
  }
  
  @override
  Future<void> update(Medication medication) async {
    _scheduledNotifications[medication.id] = medication;
    Logger.debug('MockNotificationService: 通知更新: ${medication.name}');
  }
  
  @override
  Future<void> cancel(String id) async {
    _scheduledNotifications.remove(id);
    Logger.debug('MockNotificationService: 通知キャンセル: $id');
  }
  
  @override
  Future<void> cancelAll() async {
    _scheduledNotifications.clear();
    Logger.debug('MockNotificationService: 全通知キャンセル');
  }
  
  /// テスト用のメソッド
  void clear() {
    _scheduledNotifications.clear();
    Logger.debug('MockNotificationService: データクリア');
  }
  
  int get scheduledCount => _scheduledNotifications.length;
}

/// モックアナリティクスサービス
class MockAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> _events = [];
  final Map<String, String> _userProperties = {};
  String? _userId;
  
  @override
  Future<void> track(String event, Map<String, dynamic> parameters) async {
    _events.add({
      'event': event,
      'parameters': parameters,
      'timestamp': DateTime.now().toIso8601String(),
    });
    Logger.debug('MockAnalyticsService: イベント追跡: $event');
  }
  
  @override
  Future<void> setUserProperty(String key, String value) async {
    _userProperties[key] = value;
    Logger.debug('MockAnalyticsService: ユーザープロパティ設定: $key = $value');
  }
  
  @override
  Future<void> setUserId(String userId) async {
    _userId = userId;
    Logger.debug('MockAnalyticsService: ユーザーID設定: $userId');
  }
  
  /// テスト用のメソッド
  void clear() {
    _events.clear();
    _userProperties.clear();
    _userId = null;
    Logger.debug('MockAnalyticsService: データクリア');
  }
  
  List<Map<String, dynamic>> get events => List.unmodifiable(_events);
  Map<String, String> get userProperties => Map.unmodifiable(_userProperties);
  String? get userId => _userId;
}

/// テスト可能性の監視
class TestabilityMonitor {
  static final Map<String, int> _testExecutionCounts = {};
  static final Map<String, DateTime> _lastTestExecutionTimes = {};
  static final List<String> _testErrors = [];
  
  /// テスト実行の記録
  static void recordTestExecution(String testName) {
    _testExecutionCounts[testName] = (_testExecutionCounts[testName] ?? 0) + 1;
    _lastTestExecutionTimes[testName] = DateTime.now();
    Logger.debug('テスト実行記録: $testName');
  }
  
  /// テストエラーの記録
  static void recordTestError(String testName, String error) {
    _testErrors.add('$testName: $error');
    Logger.error('テストエラー: $testName - $error');
  }
  
  /// テスト統計の取得
  static Map<String, dynamic> getTestStats() {
    return {
      'executionCounts': Map.from(_testExecutionCounts),
      'lastExecutionTimes': Map.from(_lastTestExecutionTimes),
      'testErrors': List.from(_testErrors),
      'totalExecutions': _testExecutionCounts.values.fold(0, (sum, count) => sum + count),
      'totalErrors': _testErrors.length,
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _testExecutionCounts.clear();
    _lastTestExecutionTimes.clear();
    _testErrors.clear();
    Logger.info('テスト統計をクリアしました');
  }
}

/// テスト可能性の向上の実装例
class TestableOptimizedApp extends StatelessWidget {
  final MedicationService? medicationService;
  
  const TestableOptimizedApp({
    super.key,
    this.medicationService,
  });
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'テスト可能性向上アプリ',
      home: TestableOptimizedHomePage(
        medicationService: medicationService,
      ),
    );
  }
}

/// テスト可能性の向上のホームページ
class TestableOptimizedHomePage extends StatefulWidget {
  final MedicationService? medicationService;
  
  const TestableOptimizedHomePage({
    super.key,
    this.medicationService,
  });
  
  @override
  State<TestableOptimizedHomePage> createState() => _TestableOptimizedHomePageState();
}

class _TestableOptimizedHomePageState extends State<TestableOptimizedHomePage> {
  late MedicationService _medicationService;
  List<Medication> _medications = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadMedications();
  }
  
  void _initializeService() {
    _medicationService = widget.medicationService ?? 
        TestabilityImprovement.createMedicationService();
    Logger.info('メディケーションサービス初期化完了');
  }
  
  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final medications = await _medicationService.getMedications();
      setState(() {
        _medications = medications;
        _isLoading = false;
      });
      
      Logger.info('メディケーション読み込み完了: ${medications.length}件');
    } catch (e) {
      Logger.error('メディケーション読み込みエラー', e);
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _addMedication() async {
    try {
      final medication = Medication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'テストメディケーション',
        type: '錠剤',
        dosageFrequency: '1日3回',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _medicationService.addMedication(medication);
      await _loadMedications();
      
      Logger.info('メディケーション追加完了');
    } catch (e) {
      Logger.error('メディケーション追加エラー', e);
    }
  }
  
  void _showTestInfo() {
    final stats = TestabilityMonitor.getTestStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テスト情報'),
        content: SingleChildScrollView(
          child: Text('統計情報:\n${stats.toString()}'),
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
        title: const Text('テスト可能性向上アプリ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _showTestInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // テスト情報の表示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.withOpacity(0.1),
                  child: const Text(
                    'テスト可能性が向上しています',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                
                // メインコンテンツ
                Expanded(
                  child: ListView.builder(
                    itemCount: _medications.length,
                    itemBuilder: (context, index) {
                      final medication = _medications[index];
                      return ListTile(
                        title: Text(medication.name),
                        subtitle: Text('${medication.type} - ${medication.dosageFrequency}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteMedication(medication.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Future<void> _deleteMedication(String id) async {
    try {
      await _medicationService.deleteMedication(id);
      await _loadMedications();
      
      Logger.info('メディケーション削除完了');
    } catch (e) {
      Logger.error('メディケーション削除エラー', e);
    }
  }
}
