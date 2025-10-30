library medication_alarm_app;

// Dart core imports
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

// Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:table_calendar/table_calendar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Local imports
import 'simple_alarm_app.dart';
import 'core/snapshot_service.dart';
import 'utils/locale_helper.dart';

// 分割したファイルのインポート
import 'constants/app_constants.dart';
import 'constants/app_dimensions.dart';
import 'utils/logger.dart';
import 'utils/error_handler.dart';
import 'widgets/common/medication_card.dart';
import 'widgets/common/weekday_selector.dart';
import 'widgets/common/error_boundary.dart';
import 'models/medication_memo.dart';
import 'models/medicine_data.dart';
import 'models/medication_info.dart';
import 'models/medication_state.dart';
import 'models/result.dart';
import 'models/notification_types.dart';
import 'models/adapters/medication_memo_adapter.dart';
import 'models/adapters/medicine_data_adapter.dart';
import 'models/adapters/medication_info_adapter.dart';
import 'services/notification_service.dart';
import 'services/medication_service.dart';
import 'services/data_repository.dart';
import 'services/data_manager.dart';
import 'services/in_app_purchase_service.dart';
import 'services/trial_service.dart';

// Part files for code splitting
part 'utils/app_utils.dart';

// デバッグ用のログ関数は app_utils.dart のものを使用

// コントローラー管理クラス
class ControllerManager {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<ScrollController> _scrollControllers = [];
  final List<PageController> _pageControllers = [];
  bool _disposed = false;

  // コントローラーを追加
  TextEditingController addTextController() {
    if (_disposed) throw StateError('ControllerManager is disposed');
    final controller = TextEditingController();
    _controllers.add(controller);
    return controller;
  }

  FocusNode addFocusNode() {
    if (_disposed) throw StateError('ControllerManager is disposed');
    final focusNode = FocusNode();
    _focusNodes.add(focusNode);
    return focusNode;
  }

  ScrollController addScrollController() {
    if (_disposed) throw StateError('ControllerManager is disposed');
    final controller = ScrollController();
    _scrollControllers.add(controller);
    return controller;
  }

  PageController addPageController() {
    if (_disposed) throw StateError('ControllerManager is disposed');
    final controller = PageController();
    _pageControllers.add(controller);
    return controller;
  }

  // 全てのコントローラーを破棄
  void dispose() {
    if (_disposed) return;
    
    try {
      for (final controller in _controllers) {
        controller.dispose();
      }
      for (final focusNode in _focusNodes) {
        focusNode.dispose();
      }
      for (final controller in _scrollControllers) {
        controller.dispose();
      }
      for (final controller in _pageControllers) {
        controller.dispose();
      }
      
      _controllers.clear();
      _focusNodes.clear();
      _scrollControllers.clear();
      _pageControllers.clear();
      _disposed = true;
    } catch (e) {
      Logger.warning('コントローラー破棄エラー: $e');
    }
  }
  
  // コントローラーの状態を取得
  bool get isDisposed => _disposed;
  int get controllerCount => _controllers.length;
  int get focusNodeCount => _focusNodes.length;
}

// 非同期データローダー
class AsyncDataLoader {
  // 全てのデータを非同期で読み込み
  static Future<void> loadAllData() async {
    try {
      await Future.wait([
        _loadMedicationData(),
        _loadMemoStatus(),
        _loadAlarmData(),
        _loadCalendarMarks(),
        _loadSettings(),
        _loadAdherenceStats(),
      ]);
    } catch (e) {
      Logger.error('データ読み込みエラー', e);
    }
  }

  static Future<void> _loadMedicationData() async {
    try {
      await MedicationService.loadMedicationData();
    } catch (e) {
      Logger.error('薬物データ読み込みエラー', e);
    }
  }

  static Future<void> _loadMemoStatus() async {
    try {
      // メモステータスの読み込み処理
    } catch (e) {
      Logger.error('メモステータス読み込みエラー', e);
    }
  }

  static Future<void> _loadAlarmData() async {
    try {
      // アラームデータの読み込み処理
    } catch (e) {
      Logger.error('アラームデータ読み込みエラー', e);
    }
  }

  static Future<void> _loadCalendarMarks() async {
    try {
      // カレンダーマークの読み込み処理
    } catch (e) {
      Logger.error('カレンダーマーク読み込みエラー', e);
    }
  }

  static Future<void> _loadSettings() async {
    try {
      await MedicationService.loadSettings();
    } catch (e) {
      Logger.error('設定読み込みエラー', e);
    }
  }

  static Future<void> _loadAdherenceStats() async {
    try {
      await MedicationService.loadAdherenceStats();
    } catch (e) {
      Logger.error('服薬統計読み込みエラー', e);
    }
  }
}

// メインアプリケーションクラス
class MedicationAlarmApp extends StatelessWidget {
  const MedicationAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '薬物アラームアプリ',
      locale: const Locale('ja', 'JP'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F7A5C),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16.0)),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F7A5C),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16.0)),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const TutorialWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// チュートリアルラッパー
class TutorialWrapper extends StatefulWidget {
  const TutorialWrapper({super.key});

  @override
  State<TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends State<TutorialWrapper> {
  bool _isTrialExpired = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTrialStatus();
  }

  Future<void> _checkTrialStatus() async {
    try {
      final isExpired = await TrialService.isTrialExpired();
      setState(() {
        _isTrialExpired = isExpired;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('トライアル状態確認エラー', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const TutorialPage();
  }
}

// チュートリアルページ
class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildTutorialPage(
            '薬物アラームアプリへようこそ',
            'このアプリで薬物の服用を管理できます',
            Icons.medication,
          ),
          _buildTutorialPage(
            'アラーム設定',
            '薬物の服用時間にアラームを設定できます',
            Icons.alarm,
          ),
          _buildTutorialPage(
            '記録と管理',
            '服用記録を確認し、統計を見ることができます',
            Icons.analytics,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              TextButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('戻る'),
              )
            else
              const SizedBox.shrink(),
            ElevatedButton(
              onPressed: () {
                if (_currentPage < _totalPages - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MedicationHomePage(),
                    ),
                  );
                }
              },
              child: Text(_currentPage < _totalPages - 1 ? '次へ' : '開始'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// トライアル制限ダイアログ
class TrialLimitDialog extends StatelessWidget {
  final String featureName;
  
  const TrialLimitDialog({super.key, required this.featureName});
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // アイコンとタイトル
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'トライアル期間終了',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 説明文
          Text(
            '$featureName のトライアル期間が終了しました。',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '続けて使用するには、アプリ内購入を行ってください。',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('キャンセル'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  // アプリ内購入の処理
                  try {
                    final success = await InAppPurchaseService.purchaseProduct();
                    if (success) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MedicationHomePage(),
                        ),
                      );
                    }
                  } catch (e) {
                    Logger.error('購入エラー', e);
                  }
                },
                child: Text('購入'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// メイン画面
class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});

  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}

class _MedicationHomePageState extends State<MedicationHomePage> {
  final ControllerManager _controllerManager = ControllerManager();
  DateTime _selectedDay = DateTime.now();
  Map<String, List<MedicationMemo>> _medicationData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controllerManager.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await AsyncDataLoader.loadAllData();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('データ読み込みエラー', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('薬物アラーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 設定画面への遷移
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // カレンダー
          TableCalendar<MedicationMemo>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          
          // 薬物リスト
          Expanded(
            child: ListView.builder(
              itemCount: _medicationData.length,
              itemBuilder: (context, index) {
                final key = _medicationData.keys.elementAt(index);
                final medications = _medicationData[key] ?? [];
                
                return Card(
                  child: ListTile(
                    title: Text(key),
                    subtitle: Text('${medications.length}個の薬物'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // 薬物詳細画面への遷移
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 薬物追加画面への遷移
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// メイン関数
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // システムUIの設定
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // 画面の向きを設定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // タイムゾーンの初期化
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
  
  // 日本語ロケールの初期化
  await initializeDateFormatting('ja_JP', null);
  
  // Firebaseの初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Hiveの初期化
  await Hive.initFlutter();
  
  // アダプターの登録
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(MedicationInfoAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MedicineDataAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MedicationMemoAdapter());
  }
  
  // エラーハンドリングの設定
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  // アプリの実行
  runZonedGuarded(
    () => runApp(const MedicationAlarmApp()),
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    },
  );
}