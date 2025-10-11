// import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/logger.dart';

/// アナリティクスの統合 - Firebase Analytics
class AnalyticsIntegration {
  // 一時的に無効化
  static Future<void> initialize() async {
    // アナリティクス機能は一時的に無効化
  }
  
  static void logEvent(String name, Map<String, dynamic> parameters) {
    // アナリティクス機能は一時的に無効化
  }
  
  static void setUserProperty(String name, String value) {
    // アナリティクス機能は一時的に無効化
  }
  
  static void setUserId(String userId) {
    // アナリティクス機能は一時的に無効化
  }
}

/*
class AnalyticsIntegration {
  // static FirebaseAnalytics? _analytics;
  // static FirebaseAnalyticsObserver? _observer;
  
  /// アナリティクスの初期化
  static Future<void> initialize() async {
    try {
      // _analytics = FirebaseAnalytics.instance;
      // _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      
      // アナリティクス設定
      await _analytics!.setAnalyticsCollectionEnabled(true);
      await _analytics!.setSessionTimeoutDuration(const Duration(minutes: 30));
      
      Logger.info('Firebase Analytics初期化完了');
    } catch (e) {
      Logger.error('Firebase Analytics初期化エラー', e);
    }
  }
  
  /// アナリティクスインスタンスの取得
  static FirebaseAnalytics? get analytics => _analytics;
  
  /// アナリティクスオブザーバーの取得
  static FirebaseAnalyticsObserver? get observer => _observer;
  
  /// イベントの追跡
  static Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      if (_analytics != null) {
        await _analytics!.logEvent(
          name: eventName,
          parameters: parameters,
        );
        Logger.debug('アナリティクスイベント追跡: $eventName');
      }
    } catch (e) {
      Logger.error('アナリティクスイベント追跡エラー: $eventName', e);
    }
  }
  
  /// ユーザープロパティの設定
  static Future<void> setUserProperty(String name, String value) async {
    try {
      if (_analytics != null) {
        await _analytics!.setUserProperty(name: name, value: value);
        Logger.debug('ユーザープロパティ設定: $name = $value');
      }
    } catch (e) {
      Logger.error('ユーザープロパティ設定エラー: $name', e);
    }
  }
  
  /// ユーザーIDの設定
  static Future<void> setUserId(String userId) async {
    try {
      if (_analytics != null) {
        await _analytics!.setUserId(id: userId);
        Logger.debug('ユーザーID設定: $userId');
      }
    } catch (e) {
      Logger.error('ユーザーID設定エラー: $userId', e);
    }
  }
  
  /// カスタムディメンションの設定
  static Future<void> setCustomDimension(int index, String value) async {
    try {
      if (_analytics != null) {
        await _analytics!.setUserProperty(
          name: 'custom_dimension_$index',
          value: value,
        );
        Logger.debug('カスタムディメンション設定: $index = $value');
      }
    } catch (e) {
      Logger.error('カスタムディメンション設定エラー: $index', e);
    }
  }
  
  /// スクリーンビューの追跡
  static Future<void> trackScreenView(String screenName) async {
    try {
      if (_analytics != null) {
        await _analytics!.logScreenView(screenName: screenName);
        Logger.debug('スクリーンビュー追跡: $screenName');
      }
    } catch (e) {
      Logger.error('スクリーンビュー追跡エラー: $screenName', e);
    }
  }
  
  /// 購入イベントの追跡
  static Future<void> trackPurchase({
    required String transactionId,
    required String currency,
    required double value,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      if (_analytics != null) {
        await _analytics!.logPurchase(
          transactionId: transactionId,
          currency: currency,
          value: value,
          parameters: parameters,
        );
        Logger.debug('購入イベント追跡: $transactionId');
      }
    } catch (e) {
      Logger.error('購入イベント追跡エラー: $transactionId', e);
    }
  }
  
  /// ログインイベントの追跡
  static Future<void> trackLogin(String loginMethod) async {
    try {
      if (_analytics != null) {
        await _analytics!.logLogin(loginMethod: loginMethod);
        Logger.debug('ログインイベント追跡: $loginMethod');
      }
    } catch (e) {
      Logger.error('ログインイベント追跡エラー: $loginMethod', e);
    }
  }
  
  /// サインアップイベントの追跡
  static Future<void> trackSignUp(String signUpMethod) async {
    try {
      if (_analytics != null) {
        await _analytics!.logSignUp(signUpMethod: signUpMethod);
        Logger.debug('サインアップイベント追跡: $signUpMethod');
      }
    } catch (e) {
      Logger.error('サインアップイベント追跡エラー: $signUpMethod', e);
    }
  }
  
  /// 検索イベントの追跡
  static Future<void> trackSearch(String searchTerm) async {
    try {
      if (_analytics != null) {
        await _analytics!.logSearch(searchTerm: searchTerm);
        Logger.debug('検索イベント追跡: $searchTerm');
      }
    } catch (e) {
      Logger.error('検索イベント追跡エラー: $searchTerm', e);
    }
  }
  
  /// 共有イベントの追跡
  static Future<void> trackShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    try {
      if (_analytics != null) {
        await _analytics!.logShare(
          contentType: contentType,
          itemId: itemId,
          method: method,
        );
        Logger.debug('共有イベント追跡: $contentType');
      }
    } catch (e) {
      Logger.error('共有イベント追跡エラー: $contentType', e);
    }
  }
  
  /// アプリの開始イベントの追跡
  static Future<void> trackAppStart() async {
    await trackEvent('app_start', {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'mobile',
    });
  }
  
  /// アプリの終了イベントの追跡
  static Future<void> trackAppEnd() async {
    await trackEvent('app_end', {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'mobile',
    });
  }
  
  /// メディケーション追加イベントの追跡
  static Future<void> trackMedicationAdded({
    required String medicationId,
    required String medicationName,
    required String medicationType,
    required String dosageFrequency,
  }) async {
    await trackEvent('medication_added', {
      'medication_id': medicationId,
      'medication_name': medicationName,
      'medication_type': medicationType,
      'dosage_frequency': dosageFrequency,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// メディケーション編集イベントの追跡
  static Future<void> trackMedicationEdited({
    required String medicationId,
    required String medicationName,
    required String medicationType,
    required String dosageFrequency,
  }) async {
    await trackEvent('medication_edited', {
      'medication_id': medicationId,
      'medication_name': medicationName,
      'medication_type': medicationType,
      'dosage_frequency': dosageFrequency,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// メディケーション削除イベントの追跡
  static Future<void> trackMedicationDeleted({
    required String medicationId,
    required String medicationName,
  }) async {
    await trackEvent('medication_deleted', {
      'medication_id': medicationId,
      'medication_name': medicationName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// メディケーション服用イベントの追跡
  static Future<void> trackMedicationTaken({
    required String medicationId,
    required String medicationName,
    required String dosage,
  }) async {
    await trackEvent('medication_taken', {
      'medication_id': medicationId,
      'medication_name': medicationName,
      'dosage': dosage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// アラーム設定イベントの追跡
  static Future<void> trackAlarmSet({
    required String alarmId,
    required String medicationId,
    required String time,
    required bool isEnabled,
  }) async {
    await trackEvent('alarm_set', {
      'alarm_id': alarmId,
      'medication_id': medicationId,
      'time': time,
      'is_enabled': isEnabled,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// アラーム削除イベントの追跡
  static Future<void> trackAlarmDeleted({
    required String alarmId,
    required String medicationId,
  }) async {
    await trackEvent('alarm_deleted', {
      'alarm_id': alarmId,
      'medication_id': medicationId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// カレンダー表示イベントの追跡
  static Future<void> trackCalendarViewed({
    required String date,
    required String viewType,
  }) async {
    await trackEvent('calendar_viewed', {
      'date': date,
      'view_type': viewType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// 統計表示イベントの追跡
  static Future<void> trackStatisticsViewed({
    required String statisticsType,
    required String period,
  }) async {
    await trackEvent('statistics_viewed', {
      'statistics_type': statisticsType,
      'period': period,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// 設定変更イベントの追跡
  static Future<void> trackSettingsChanged({
    required String settingName,
    required String oldValue,
    required String newValue,
  }) async {
    await trackEvent('settings_changed', {
      'setting_name': settingName,
      'old_value': oldValue,
      'new_value': newValue,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// エラーイベントの追跡
  static Future<void> trackError({
    required String errorType,
    required String errorMessage,
    required String errorContext,
  }) async {
    await trackEvent('error_occurred', {
      'error_type': errorType,
      'error_message': errorMessage,
      'error_context': errorContext,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// パフォーマンスイベントの追跡
  static Future<void> trackPerformance({
    required String operationName,
    required int durationMs,
    required String status,
  }) async {
    await trackEvent('performance_measured', {
      'operation_name': operationName,
      'duration_ms': durationMs,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// ユーザーエンゲージメントイベントの追跡
  static Future<void> trackUserEngagement({
    required String engagementType,
    required int durationSeconds,
    required String context,
  }) async {
    await trackEvent('user_engagement', {
      'engagement_type': engagementType,
      'duration_seconds': durationSeconds,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// アプリの使用状況イベントの追跡
  static Future<void> trackAppUsage({
    required String feature,
    required int usageCount,
    required int sessionDuration,
  }) async {
    await trackEvent('app_usage', {
      'feature': feature,
      'usage_count': usageCount,
      'session_duration': sessionDuration,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// アナリティクス設定の更新
  static Future<void> updateAnalyticsSettings({
    bool? collectionEnabled,
    Duration? sessionTimeout,
    String? userId,
    Map<String, String>? userProperties,
  }) async {
    try {
      if (_analytics != null) {
        if (collectionEnabled != null) {
          await _analytics!.setAnalyticsCollectionEnabled(collectionEnabled);
        }
        
        if (sessionTimeout != null) {
          await _analytics!.setSessionTimeoutDuration(sessionTimeout);
        }
        
        if (userId != null) {
          await _analytics!.setUserId(id: userId);
        }
        
        if (userProperties != null) {
          for (final entry in userProperties.entries) {
            await _analytics!.setUserProperty(
              name: entry.key,
              value: entry.value,
            );
          }
        }
        
        Logger.info('アナリティクス設定更新完了');
      }
    } catch (e) {
      Logger.error('アナリティクス設定更新エラー', e);
    }
  }
  
  /// アナリティクス統計の取得
  static Map<String, dynamic> getAnalyticsStats() {
    return {
      'isInitialized': _analytics != null,
      'hasObserver': _observer != null,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// アナリティクスのリセット
  static Future<void> resetAnalytics() async {
    try {
      if (_analytics != null) {
        await _analytics!.resetAnalyticsData();
        Logger.info('アナリティクスデータリセット完了');
      }
    } catch (e) {
      Logger.error('アナリティクスデータリセットエラー', e);
    }
  }
}

/// アナリティクス統合の実装例
class AnalyticsIntegratedApp extends StatelessWidget {
  final Widget child;
  
  const AnalyticsIntegratedApp({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'アナリティクス統合アプリ',
      navigatorObservers: [
        if (AnalyticsIntegration.observer != null)
          AnalyticsIntegration.observer!,
      ],
      home: child,
    );
  }
}

/// アナリティクス統合のホームページ
class AnalyticsIntegratedHomePage extends StatefulWidget {
  const AnalyticsIntegratedHomePage({super.key});
  
  @override
  State<AnalyticsIntegratedHomePage> createState() => _AnalyticsIntegratedHomePageState();
}

class _AnalyticsIntegratedHomePageState extends State<AnalyticsIntegratedHomePage> {
  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
  }
  
  Future<void> _initializeAnalytics() async {
    await AnalyticsIntegration.initialize();
    await AnalyticsIntegration.trackAppStart();
    await AnalyticsIntegration.trackScreenView('home');
  }
  
  @override
  void dispose() {
    AnalyticsIntegration.trackAppEnd();
    super.dispose();
  }
  
  void _showAnalyticsInfo() {
    final stats = AnalyticsIntegration.getAnalyticsStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アナリティクス情報'),
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
        title: const Text('アナリティクス統合アプリ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalyticsInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // アナリティクス情報の表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: const Text(
              'アナリティクス機能が有効です',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          
          // メインコンテンツ
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.analytics,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'アナリティクス統合アプリ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Firebase Analyticsが統合されています',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      await AnalyticsIntegration.trackEvent('button_clicked', {
                        'button_name': 'test_button',
                        'timestamp': DateTime.now().toIso8601String(),
                      });
                    },
                    child: const Text('テストイベント送信'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
