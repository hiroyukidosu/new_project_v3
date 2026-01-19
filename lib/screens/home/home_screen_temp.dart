class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});
  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}
class _MedicationHomePageState extends State<MedicationHomePage> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<DateTime> _selectedDates = <DateTime>{};
  // 蜍慕噪縺ｫ霑ｽ蜉縺輔ｌ繧玖脈縺ｮ繝ｪ繧ｹ繝・  List<Map<String, dynamic>> _addedMedications = [];
  late TabController _tabController;
  bool _notificationError = false;
  bool _isInitialized = false;
  bool _isAlarmPlaying = false;
  bool _isLoading = false; // 笨・菫ｮ豁｣・壹Ο繝ｼ繝・ぅ繝ｳ繧ｰ迥ｶ諷九ｒ霑ｽ蜉
  Map<String, Map<String, MedicationInfo>> _medicationData = {};
  Map<String, double> _adherenceRates = {};
  List<MedicineData> _medicines = [];
  List<MedicationMemo> _medicationMemos = [];
  Timer? _debounce;
  Timer? _saveDebounceTimer; // 笨・菫ｮ豁｣・壻ｿ晏ｭ倡畑繝・ヰ繧ｦ繝ｳ繧ｹ繧ｿ繧､繝槭・繧定ｿｽ蜉
  StreamSubscription<List<PurchaseDetails>>? _subscription; // 笨・菫ｮ豁｣・售treamSubscription繧定ｿｽ蜉
  
  // 笨・菫ｮ豁｣・壼､画峩繝輔Λ繧ｰ螟画焚繧定ｿｽ蜉
  bool _medicationMemoStatusChanged = false;

  bool _weekdayMedicationStatusChanged = false;
  bool _addedMedicationsChanged = false;
 
  
  // 笨・繧｢繝ｩ繝ｼ繝繧ｿ繝悶・繧ｭ繝ｼ・亥ｼｷ蛻ｶ蜀肴ｧ狗ｯ臥畑・・  Key _alarmTabKey = UniqueKey();
  
  // 笨・邨ｱ險医ち繝也畑縺ｮScrollController
  final ScrollController _statsScrollController = ScrollController();
  
  // 笨・莉ｻ諢上・譌･謨ｰ縺ｮ驕ｵ螳育紫讖溯・逕ｨ縺ｮ螟画焚
  double? _customAdherenceResult;
  int? _customDaysResult;
  final TextEditingController _customDaysController = TextEditingController();
  final FocusNode _customDaysFocusNode = FocusNode();
  
  
  // 笨・謇句虚蠕ｩ蜈・ｩ溯・縺ｮ縺溘ａ縺ｮ螟画焚
  DateTime? _lastOperationTime;
  
  // 笨・閾ｪ蜍輔ヰ繝・け繧｢繝・・讖溯・縺ｮ縺溘ａ縺ｮ螟画焚
  Timer? _autoBackupTimer;
  bool _autoBackupEnabled = true;
 
  // 笨・菫ｮ豁｣・壹ョ繝ｼ繧ｿ繧ｭ繝ｼ縺ｮ邨ｱ荳縺ｨ繝舌・繧ｸ繝ｧ繝ｳ邂｡逅・  static const String _medicationMemosKey = 'medication_memos_v2';
  static const String _medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String _weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String _addedMedicationsKey = 'added_medications_v2';
  
  // 繝舌ャ繧ｯ繧｢繝・・繧ｭ繝ｼ
  static const String _backupSuffix = '_backup';

  
  // 繝｡繝｢逕ｨ縺ｮ迥ｶ諷句､画焚
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();
  bool _isMemoFocused = false;
  bool _memoSnapshotSaved = false; // 繝｡繝｢螟画峩譎ゅ・繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ倥ヵ繝ｩ繧ｰ
  // 笨・驛ｨ蛻・峩譁ｰ逕ｨ縺ｮValueNotifier
  final ValueNotifier<String> _memoTextNotifier = ValueNotifier<String>('');
  final ValueNotifier<Map<String, Color>> _dayColorsNotifier = ValueNotifier<Map<String, Color>>({});
  
  
  // 譖懈律險ｭ螳壹＆繧後◆阮ｬ縺ｮ譛咲畑迥ｶ豕√ｒ邂｡逅・  Map<String, Map<String, bool>> _weekdayMedicationStatus = {};
  
  // 譛咲畑蝗樊焚蛻･縺ｮ譛咲畑迥ｶ豕√ｒ邂｡逅・ｼ域律莉・-> 繝｡繝｢ID -> 蝗樊焚繧､繝ｳ繝・ャ繧ｯ繧ｹ -> 譛咲畑貂医∩・・  Map<String, Map<String, Map<int, bool>>> _weekdayMedicationDoseStatus = {};
  
  // 譛咲畑繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ豕√ｒ邂｡逅・  Map<String, bool> _medicationMemoStatus = {};
  
  // 繝｡繝｢驕ｸ謚樒憾諷九ｒ邂｡逅・  bool _isMemoSelected = false;
  MedicationMemo? _selectedMemo;
  
  
  // 繧｢繝ｩ繝ｼ繝繝・・繧ｿ繧堤ｮ｡逅・  List<Map<String, dynamic>> _alarmList = [];
  Map<String, dynamic> _alarmSettings = {};
  
  // 繧ｪ繝ｼ繝舌・繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ讀懷・逕ｨ縺ｮ迥ｶ諷句､画焚
  bool _isAtTop = false;
  double _lastScrollPosition = 0.0;
  
  // 繧ｫ繝ｬ繝ｳ繝繝ｼ繧ｿ繝悶・繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ蛻ｶ蠕｡逕ｨ
  final ScrollController _calendarScrollController = ScrollController();
  
  // 譛咲畑螻･豁ｴ繝｡繝｢逕ｨ縺ｮScrollController
  final ScrollController _medicationHistoryScrollController = ScrollController();
  
  // 譛咲畑險倬鹸繝壹・繧ｸ繧√￥繧顔畑縺ｮ繧ｳ繝ｳ繝医Ο繝ｼ繝ｩ繝ｼ
  late PageController _medicationPageController;
  int _currentMedicationPage = 0;
  
  // 繧ｫ繝ｬ繝ｳ繝繝ｼ荳九・菴咲ｽｮ繧貞叙蠕励☆繧九◆繧√・GlobalKey
  final GlobalKey _calendarBottomKey = GlobalKey();
  
  // 繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ繝舌ヨ繝ｳ繧ｿ繝・メ逕ｨ縺ｮ螟画焚
  bool _isScrollBatonPassActive = false;
  
  // 繝ｭ繧ｰ蛻ｶ蠕｡逕ｨ縺ｮ螟画焚
  DateTime _lastAlarmCheckLog = DateTime.now();
  
  // 繧ｫ繝ｬ繝ｳ繝繝ｼ濶ｲ螟画峩逕ｨ縺ｮ螟画焚
  Map<String, Color> _dayColors = {};
  static const Duration _logInterval = Duration(seconds: 30); // 30遘帝俣髫斐〒繝ｭ繧ｰ蜃ｺ蜉・  
  // 繝ｭ繧ｰ蜃ｺ蜉帙ｒ蛻ｶ髯舌☆繧九・繝ｫ繝代・繝｡繧ｽ繝・ラ
  bool _shouldLog() {
    final now = DateTime.now();
    if (now.difference(_lastAlarmCheckLog) >= _logInterval) {
      _lastAlarmCheckLog = now;
      return true;
    }
    return false;
  }
  
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // 笨・SnapshotService縺ｫ繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ倬未謨ｰ繧堤匳骭ｲ
    SnapshotService.register((label) => _saveSnapshotBeforeChange(label));
    
   
    
    // PageController繧貞・譛溷喧
    _medicationPageController = PageController(viewportFraction: 1.0);
    // ValueNotifier蛻晄悄蛟､
    _memoTextNotifier.value = '';
    _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
    
    // 繝壹・繧ｸ繝阪・繧ｷ繝ｧ繝ｳ蛻晄悄蛹・    _initializeScrollListener();
      
    // 笨・菫ｮ豁｣・壹ョ繝ｼ繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧堤｢ｺ螳溘↓螳溯｡・    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('売 繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ髢句ｧ・..');
      
      try {
        // 1. 蜈ｨ繝・・繧ｿ繧定ｪｭ縺ｿ霎ｼ縺ｿ
        await _loadSavedData();
        debugPrint('笨・蜈ｨ繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・);
        
        // 2. 譛咲畑繝｡繝｢繧呈・遉ｺ逧・↓隱ｭ縺ｿ霎ｼ縺ｿ・育｢ｺ螳溘↓螳溯｡鯉ｼ・        await _loadMedicationMemosWithRetry();
        debugPrint('笨・譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ ${_medicationMemos.length}莉ｶ');
        
        // 3. 繝壹・繧ｸ繝阪・繧ｷ繝ｧ繝ｳ蛻晄悄蛹・        _currentPage = 0;
        _displayedMemos.clear();
        _loadMoreMemos();
        debugPrint('笨・繝壹・繧ｸ繝阪・繧ｷ繝ｧ繝ｳ蛻晄悄蛹門ｮ御ｺ・);
        
        // 4. 蝓ｺ譛ｬ險ｭ螳・        if (_selectedDay == null) {
          _selectedDay = DateTime.now();
        }
        if (_selectedDates.isEmpty) {
          _selectedDates.add(_normalizeDate(DateTime.now()));
        }
        _setupControllerListeners();
        
        // 5. 蛻晄悄蛹門ｮ御ｺ・ヵ繝ｩ繧ｰ繧定ｨｭ螳夲ｼ域怙蠕後↓險ｭ螳夲ｼ・      _isInitialized = true;
      
        // 6. UI繧貞ｼｷ蛻ｶ譖ｴ譁ｰ
        if (mounted) {
          setState(() {
            debugPrint('笨・UI譖ｴ譁ｰ螳御ｺ・);
          });
        }
        
        debugPrint('笨・蛻晄悄蛹門ｮ御ｺ・ 繝｡繝｢${_medicationMemos.length}莉ｶ');
      } catch (e, stackTrace) {
        debugPrint('笶・蛻晄悄蛹悶お繝ｩ繝ｼ: $e');
        debugPrint('繧ｹ繧ｿ繝・け繝医Ξ繝ｼ繧ｹ: $stackTrace');
        
        // 繧ｨ繝ｩ繝ｼ譎ゅｂ蛻晄悄蛹門ｮ御ｺ・ヵ繝ｩ繧ｰ繧定ｨｭ螳夲ｼ医い繝励Μ縺悟虚菴懊☆繧九ｈ縺・↓縺吶ｋ・・        _isInitialized = true;
      if (mounted) {
        setState(() {});
        }
      }
    });
  }
  
  // 蛹・峡逧・ョ繝ｼ繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧ｷ繧ｹ繝・Β・壹☆縺ｹ縺ｦ縺ｮ繝・・繧ｿ繧貞ｾｩ蜈・  Future<void> _loadSavedData() async {
    try {
      // 蛹・峡逧・ョ繝ｼ繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ・壹☆縺ｹ縺ｦ縺ｮ繝・・繧ｿ繧貞ｾｩ蜈・      await _loadAllData();
      
      // 驥阪＞蜃ｦ逅・ｂ螳溯｡・      await _initializeAsync();
      
      // 繧｢繝ｩ繝ｼ繝縺ｮ蜀咲匳骭ｲ
      await _reRegisterAlarms();
      
      // 繝・・繧ｿ菫晄戟繝・せ繝・      await _testDataPersistence();
      
      // 笨・閾ｪ蜍輔ヰ繝・け繧｢繝・・讖溯・繧貞・譛溷喧
      _initializeAutoBackup();
      
      _debugLog('蜈ｨ繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ｼ亥桁諡ｬ逧・Ο繝ｼ繧ｫ繝ｫ蠕ｩ蜈・ｼ・);
    } catch (e) {
      _debugLog('繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 蛹・峡逧・ョ繝ｼ繧ｿ菫晏ｭ倥す繧ｹ繝・Β・壹☆縺ｹ縺ｦ縺ｮ繝・・繧ｿ繧偵Ο繝ｼ繧ｫ繝ｫ菫晏ｭ・  Future<void> _saveAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. 繝｡繝｢迥ｶ諷九・菫晏ｭ・      await _saveMemoStatus();
      
      // 2. 譛咲畑阮ｬ繝・・繧ｿ縺ｮ菫晏ｭ・      await _saveMedicationList();
      
      // 3. 繧｢繝ｩ繝ｼ繝繝・・繧ｿ縺ｮ菫晏ｭ・      await _saveAlarmData();
      
      // 4. 繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ縺ｮ菫晏ｭ・      await _saveCalendarMarks();
      
      // 5. 繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳壹・菫晏ｭ・      await _saveUserPreferences();
      
      // 6. 譛咲畑繝・・繧ｿ縺ｮ菫晏ｭ・      await _saveMedicationData();
      
      // 7. 譌･蛻･濶ｲ險ｭ螳壹・菫晏ｭ・      await _saveDayColors();
      
      // 8. 邨ｱ險医ョ繝ｼ繧ｿ縺ｮ菫晏ｭ・      await _saveStatistics();
      
      // 9. 繧｢繝励Μ險ｭ螳壹・菫晏ｭ・      await _saveAppSettings();
      
      // 10. 譛咲畑蝗樊焚蛻･迥ｶ諷九・菫晏ｭ・      await _saveMedicationDoseStatus();
      
      _debugLog('蜈ｨ繝・・繧ｿ菫晏ｭ伜ｮ御ｺ・ｼ亥桁諡ｬ逧・Ο繝ｼ繧ｫ繝ｫ菫晏ｭ假ｼ・);
      
      // 笨・謫堺ｽ懈凾髢薙ｒ險倬鹸・域焔蜍募ｾｩ蜈・畑・・      _lastOperationTime = DateTime.now();
      
      // 笨・謫堺ｽ懊せ繝翫ャ繝励す繝ｧ繝・ヨ繧貞ｸｸ縺ｫ菫晏ｭ假ｼ・蛻・ｻ･髯阪〒繧よ焔蜍募ｾｩ蜈・庄閭ｽ・・      try {
        final backupData = await _createSafeBackupData('謫堺ｽ懊せ繝翫ャ繝励す繝ｧ繝・ヨ');
        final jsonString = await _safeJsonEncode(backupData);
        final encryptedData = await _encryptDataAsync(jsonString);
        final snapshotKey = 'operation_snapshot_latest';
        await prefs.setString(snapshotKey, encryptedData);
        await _updateBackupHistory('謫堺ｽ懊せ繝翫ャ繝励す繝ｧ繝・ヨ', snapshotKey, type: 'snapshot');
        await prefs.setString('last_snapshot_key', snapshotKey);
      } catch (e) {
        debugPrint('謫堺ｽ懊せ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ倥お繝ｩ繝ｼ: $e');
      }
    } catch (e) {
      _debugLog('蜈ｨ繝・・繧ｿ菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 笨・閾ｪ蜍輔ヰ繝・け繧｢繝・・讖溯・縺ｮ蛻晄悄蛹・  void _initializeAutoBackup() {
    _scheduleAutoBackup();
    debugPrint('売 閾ｪ蜍輔ヰ繝・け繧｢繝・・讖溯・繧貞・譛溷喧縺励∪縺励◆');
  }
  
  // 笨・豺ｱ螟・:00縺ｮ閾ｪ蜍輔ヰ繝・け繧｢繝・・繧偵せ繧ｱ繧ｸ繝･繝ｼ繝ｫ
  void _scheduleAutoBackup() {
    _autoBackupTimer?.cancel();
    
    final now = DateTime.now();
    // 谺｡縺ｮ螳溯｡梧凾蛻ｻ繧貞ｽ捺律20:12・磯℃縺弱※縺・ｌ縺ｰ鄙梧律20:12・峨↓險ｭ螳・    final todayTarget = DateTime(now.year, now.month, now.day, 20, 12);
    final nextRun = now.isBefore(todayTarget)
        ? todayTarget
        : DateTime(now.year, now.month, now.day + 1, 20, 12);
    final duration = nextRun.difference(now);
    
    _autoBackupTimer = Timer(duration, () async {
      if (_autoBackupEnabled) {
        await _performAutoBackup();
        // 谺｡縺ｮ譌･縺ｮ豺ｱ螟・:00繧偵せ繧ｱ繧ｸ繝･繝ｼ繝ｫ
        _scheduleAutoBackup();
      }
    });
    
    debugPrint('売 閾ｪ蜍輔ヰ繝・け繧｢繝・・繧偵せ繧ｱ繧ｸ繝･繝ｼ繝ｫ縺励∪縺励◆: ${nextRun.toString()}');
  }
  
  // 笨・閾ｪ蜍輔ヰ繝・け繧｢繝・・繧貞ｮ溯｡・  Future<void> _performAutoBackup() async {
    try {
      final backupName = '閾ｪ蜍輔ヰ繝・け繧｢繝・・_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
      debugPrint('売 閾ｪ蜍輔ヰ繝・け繧｢繝・・繧貞ｮ溯｡・ $backupName');
      
      // 繝舌ャ繧ｯ繧｢繝・・繝・・繧ｿ繧剃ｽ懈・
      final backupData = await _createSafeBackupData(backupName);
      final jsonString = await _safeJsonEncode(backupData);
      final encryptedData = await _encryptDataAsync(jsonString);
      
      // 繝舌ャ繧ｯ繧｢繝・・繧剃ｿ晏ｭ・      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'auto_backup_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(backupKey, encryptedData);
      
      // 螻･豁ｴ繧呈峩譁ｰ・医ヵ繝ｫ縺ｨ縺励※謇ｱ縺・ｼ・      await _updateBackupHistory(backupName, backupKey, type: 'full');
      
      // 譛譁ｰ繝舌ャ繧ｯ繧｢繝・・蜿ら・繧ｭ繝ｼ繧剃ｿ晏ｭ・      await prefs.setString('last_auto_backup_key', backupKey);
      await prefs.setString('last_full_backup_key', backupKey);
      
      debugPrint('笨・閾ｪ蜍輔ヰ繝・け繧｢繝・・螳御ｺ・ $backupName');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('売 豺ｱ螟・:00縺ｮ閾ｪ蜍輔ヰ繝・け繧｢繝・・縺悟ｮ御ｺ・＠縺ｾ縺励◆'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('笶・閾ｪ蜍輔ヰ繝・け繧｢繝・・繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 笨・謫堺ｽ懷ｾ・蛻・ｻ･蜀・・謇句虚蠕ｩ蜈・ｩ溯・
  Future<void> _showManualRestoreDialog() async {
    if (!mounted) return;
    
    final now = DateTime.now();
    final canRestore = _lastOperationTime != null && 
        now.difference(_lastOperationTime!).inMinutes <= 5;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.blue),
            SizedBox(width: 8),
            Text('謇句虚蠕ｩ蜈・),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canRestore ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  canRestore 
                    ? '笨・謫堺ｽ懷ｾ・蛻・ｻ･蜀・〒縺兔n譛蠕後・謫堺ｽ懊°繧・{now.difference(_lastOperationTime!).inMinutes}蛻・ｵ碁℃'
                    : '笞・・謫堺ｽ懷ｾ・蛻・ｒ驕弱℃縺ｦ縺・∪縺兔n譛蠕後・謫堺ｽ懊°繧・{_lastOperationTime != null ? now.difference(_lastOperationTime!).inMinutes : 0}蛻・ｵ碁℃',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              if (canRestore) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _performManualRestore();
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('謫堺ｽ懷燕縺ｮ迥ｶ諷九↓蠕ｩ蜈・),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                const Text(
                  '謫堺ｽ懷ｾ・蛻・ｻ･蜀・↓蠕ｩ蜈・・繧ｿ繝ｳ繧呈款縺励※縺上□縺輔＞',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('髢峨§繧・),
          ),
        ],
      ),
    );
  }
  
  // 笨・謇句虚蠕ｩ蜈・ｒ螳溯｡・  Future<void> _performManualRestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 笨・謫堺ｽ懊せ繝翫ャ繝励す繝ｧ繝・ヨ・育峩霑台ｿ晏ｭ俶凾縺ｫ蟶ｸ縺ｫ譖ｴ譁ｰ・峨ｒ蜿ら・
      final lastBackupKey = prefs.getString('last_snapshot_key');
      
      if (lastBackupKey != null) {
        debugPrint('売 謇句虚蠕ｩ蜈・ｒ螳溯｡・ $lastBackupKey');
        await _restoreBackup(lastBackupKey);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('売 謫堺ｽ懷燕縺ｮ迥ｶ諷九↓蠕ｩ蜈・＠縺ｾ縺励◆'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('笶・蠕ｩ蜈・庄閭ｽ縺ｪ繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('笶・謇句虚蠕ｩ蜈・お繝ｩ繝ｼ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('笶・蠕ｩ蜈・お繝ｩ繝ｼ: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // 蛹・峡逧・ョ繝ｼ繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧ｷ繧ｹ繝・Β・壹☆縺ｹ縺ｦ縺ｮ繝・・繧ｿ繧貞ｾｩ蜈・  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. 繝｡繝｢迥ｶ諷九・隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadMemoStatus();
      
      // 2. 譛咲畑阮ｬ繝・・繧ｿ縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadMedicationList();
      
      // 3. 繧｢繝ｩ繝ｼ繝繝・・繧ｿ縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadAlarmData();
      
      // 3.5. 繧｢繝ｩ繝ｼ繝縺ｮ蜀咲匳骭ｲ
      await _reRegisterAlarms();
      
      // 4. 繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadCalendarMarks();
      
      // 5. 繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳壹・隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadUserPreferences();
      
      // 6. 譛咲畑繝・・繧ｿ縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadMedicationData();
      
      // 7. 譌･蛻･濶ｲ險ｭ螳壹・隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadDayColors();
      
      // 8. 邨ｱ險医ョ繝ｼ繧ｿ縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadStatistics();
      
      // 9. 譛咲畑蝗樊焚蛻･迥ｶ諷九・隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadMedicationDoseStatus();
      
      // 9. 繧｢繝励Μ險ｭ螳壹・隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadAppSettings();
      
      // 10. 繝・・繧ｿ讀懆ｨｼ縺ｨUI譖ｴ譁ｰ
      await _validateAndUpdateUI();
      
      _debugLog('蜈ｨ繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ｼ亥桁諡ｬ逧・Ο繝ｼ繧ｫ繝ｫ蠕ｩ蜈・ｼ・);
    } catch (e) {
      _debugLog('蜈ｨ繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 繝・・繧ｿ讀懆ｨｼ縺ｨUI譖ｴ譁ｰ
  Future<void> _validateAndUpdateUI() async {
    try {
      // 繝・・繧ｿ縺ｮ謨ｴ蜷域ｧ繧偵メ繧ｧ繝・け
      await _validateDataIntegrity();
      
      // UI繧貞ｼｷ蛻ｶ譖ｴ譁ｰ
      if (mounted) {
        setState(() {
          // 迥ｶ諷九ｒ蠑ｷ蛻ｶ譖ｴ譁ｰ
        });
      }
      
      // 繧ｫ繝ｬ繝ｳ繝繝ｼ縺ｮ譌･莉倥ｒ譖ｴ譁ｰ
      await _updateCalendarForSelectedDate();
      
      // 譛咲畑繝｡繝｢縺ｮ迥ｶ諷九ｒ譖ｴ譁ｰ
      await _updateMedicationMemoDisplay();
      
      // 繧｢繝ｩ繝ｼ繝繝・・繧ｿ縺ｮ讀懆ｨｼ
      await _validateAlarmData();
      
      // 繧｢繝ｩ繝ｼ繝繝・・繧ｿ縺ｮ謨ｴ蜷域ｧ繝√ぉ繝・け
      await _checkAlarmDataIntegrity();
      
      // 繧｢繝励Μ蜀崎ｵｷ蜍墓凾縺ｮ繝・・繧ｿ陦ｨ遉ｺ繧堤｢ｺ螳溘↓縺吶ｋ
      await _ensureDataDisplayOnRestart();
      
      // 譛邨ら噪縺ｪ繝・・繧ｿ陦ｨ遉ｺ遒ｺ隱・      await _finalDataDisplayCheck();
      
      _debugLog('繝・・繧ｿ讀懆ｨｼ縺ｨUI譖ｴ譁ｰ螳御ｺ・);
    } catch (e) {
      _debugLog('繝・・繧ｿ讀懆ｨｼ縺ｨUI譖ｴ譁ｰ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 譛邨ら噪縺ｪ繝・・繧ｿ陦ｨ遉ｺ遒ｺ隱・  Future<void> _finalDataDisplayCheck() async {
    try {
      // 繝・・繧ｿ陦ｨ遉ｺ縺ｮ譛邨ら｢ｺ隱・      debugPrint('=== 譛邨ゅョ繝ｼ繧ｿ陦ｨ遉ｺ遒ｺ隱・===');
      debugPrint('驕ｸ謚樊律莉・ ${_selectedDay != null ? DateFormat('yyyy-MM-dd').format(_selectedDay!) : '縺ｪ縺・}');
      debugPrint('譛咲畑繝｡繝｢謨ｰ: ${_medicationMemos.length}莉ｶ');
      debugPrint('繝｡繝｢迥ｶ諷区焚: ${_medicationMemoStatus.length}莉ｶ');
      debugPrint('蜍慕噪阮ｬ繝ｪ繧ｹ繝域焚: ${_addedMedications.length}莉ｶ');
      debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ謨ｰ: ${_selectedDates.length}莉ｶ');
      debugPrint('譌･蛻･濶ｲ險ｭ螳壽焚: ${_dayColors.length}莉ｶ');
      
      // UI繧呈怙邨よ峩譁ｰ
      if (mounted) {
        setState(() {
          // 譛邨ら噪縺ｪUI譖ｴ譁ｰ
        });
      }
      
      debugPrint('=== 譛邨ゅョ繝ｼ繧ｿ陦ｨ遉ｺ遒ｺ隱榊ｮ御ｺ・===');
    } catch (e) {
      debugPrint('譛邨ゅョ繝ｼ繧ｿ陦ｨ遉ｺ遒ｺ隱阪お繝ｩ繝ｼ: $e');
    }
  }
  
  // 繝・・繧ｿ縺ｮ謨ｴ蜷域ｧ繧偵メ繧ｧ繝・け
  Future<void> _validateDataIntegrity() async {
    try {
      // 驕ｸ謚槭＆繧後◆譌･莉倥・繝・・繧ｿ繧堤｢ｺ隱・      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final dayData = _medicationData[dateStr];
        
        if (dayData != null) {
          debugPrint('驕ｸ謚樊律莉倥・繝・・繧ｿ遒ｺ隱・ $dateStr - ${dayData.length}莉ｶ');
        } else {
          debugPrint('驕ｸ謚樊律莉倥・繝・・繧ｿ縺ｪ縺・ $dateStr');
        }
      }
      
      // 譛咲畑繝｡繝｢縺ｮ迥ｶ諷九ｒ遒ｺ隱・      debugPrint('譛咲畑繝｡繝｢迥ｶ諷・ ${_medicationMemoStatus.length}莉ｶ');
      
      // 繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ繧堤｢ｺ隱・      debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ: ${_selectedDates.length}莉ｶ');
      
      // 譌･蛻･濶ｲ險ｭ螳壹ｒ遒ｺ隱・      debugPrint('譌･蛻･濶ｲ險ｭ螳・ ${_dayColors.length}莉ｶ');
      
    } catch (e) {
      debugPrint('繝・・繧ｿ謨ｴ蜷域ｧ繝√ぉ繝・け繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧ｫ繝ｬ繝ｳ繝繝ｼ縺ｮ譌･莉倥ｒ譖ｴ譁ｰ
  Future<void> _updateCalendarForSelectedDate() async {
    try {
      if (_selectedDay != null) {
        // 驕ｸ謚槭＆繧後◆譌･莉倥・繝・・繧ｿ繧定ｪｭ縺ｿ霎ｼ縺ｿ
        await _updateMedicineInputsForSelectedDate();
        
        // 繝｡繝｢繧定ｪｭ縺ｿ霎ｼ縺ｿ
        await _loadMemoForSelectedDate();
        
        debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ譌･莉俶峩譁ｰ螳御ｺ・ ${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
      }
    } catch (e) {
      debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ譌･莉俶峩譁ｰ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 譛咲畑繝｡繝｢縺ｮ陦ｨ遉ｺ繧呈峩譁ｰ
  Future<void> _updateMedicationMemoDisplay() async {
    try {
      // 譛咲畑繝｡繝｢縺ｮ迥ｶ諷九ｒ蜀崎ｨ育ｮ・      for (final memo in _medicationMemos) {
        if (!_medicationMemoStatus.containsKey(memo.id)) {
          _medicationMemoStatus[memo.id] = false;
        }
      }
      
      debugPrint('譛咲畑繝｡繝｢陦ｨ遉ｺ譖ｴ譁ｰ螳御ｺ・ ${_medicationMemos.length}莉ｶ');
    } catch (e) {
      debugPrint('譛咲畑繝｡繝｢陦ｨ遉ｺ譖ｴ譁ｰ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 閥 譛驥崎ｦ・ｼ壹ョ繝ｼ繧ｿ菫晄戟繝・せ繝茨ｼ亥ｮ悟・迚茨ｼ・  Future<void> _testDataPersistence() async {
    try {
      // 閥 譛驥崎ｦ・ｼ壽怙蟆乗ｧ区・繝・Φ繝励Ξ繝ｼ繝・      final testKey = 'flutter_storage_test';
      final testValue = 'data_persistence_test_${DateTime.now().millisecondsSinceEpoch}';
      
      debugPrint('閥 繝・・繧ｿ菫晄戟繝・せ繝磯幕蟋・ $testValue');
      
      // 閥 譛驥崎ｦ・ｼ壻ｿ晏ｭ伜・逅・ｼ・wait繧堤｢ｺ螳溘↓莉倥￠繧具ｼ・      await AppPreferences.saveString(testKey, testValue);
      debugPrint('閥 繝・・繧ｿ菫晄戟繝・せ繝井ｿ晏ｭ伜ｮ御ｺ・ｼ亥ｮ悟・迚茨ｼ・);
      
      // 閥 譛驥崎ｦ・ｼ壼ｾｩ蜈・・逅・ｼ郁ｵｷ蜍墓凾・・      final readValue = AppPreferences.getString(testKey);
      if (readValue == testValue) {
        debugPrint('閥 繝・・繧ｿ菫晄戟繝・せ繝域・蜉・ $readValue・亥ｮ悟・迚茨ｼ・);
      } else {
        debugPrint('閥 繝・・繧ｿ菫晄戟繝・せ繝亥､ｱ謨・ 譛溷ｾ・､=$testValue, 螳滄圀蛟､=$readValue');
      }
      
      // 閥 譛驥崎ｦ・ｼ壹ョ繝舌ャ繧ｰ逕ｨ・壹☆縺ｹ縺ｦ縺ｮ繧ｭ繝ｼ繧定｡ｨ遉ｺ
      AppPreferences.debugAllKeys();
      
      // 繝・せ繝医ョ繝ｼ繧ｿ縺ｮ蜑企勁
      await AppPreferences.remove(testKey);
      debugPrint('閥 繝・せ繝医ョ繝ｼ繧ｿ蜑企勁螳御ｺ・);
    } catch (e) {
      debugPrint('閥 繝・・繧ｿ菫晄戟繝・せ繝医お繝ｩ繝ｼ: $e');
    }
  }
  
  // 譛咲畑繝・・繧ｿ縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadMedicationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSaveDate = prefs.getString('last_save_date');
      
      if (lastSaveDate != null) {
        final backupData = prefs.getString('medication_backup_$lastSaveDate');
        if (backupData != null) {
          final dataJson = jsonDecode(backupData) as Map<String, dynamic>;
          debugPrint('譛咲畑繝・・繧ｿ蠕ｩ蜈・ $lastSaveDate');
        }
      }
    } catch (e) {
      debugPrint('譛咲畑繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 縺薙・縺輔ｓ豬・ｼ壽恪逕ｨ阮ｬ繝・・繧ｿ繧定ｪｭ縺ｿ霎ｼ縺ｿ・育｢ｺ螳溘↑繝・・繧ｿ蠕ｩ蜈・ｼ・  Future<void> _loadMedicationList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? medicationListStr;
      
      // 縺薙・縺輔ｓ豬・ｼ夊､・焚繧ｭ繝ｼ縺九ｉ隱ｭ縺ｿ霎ｼ縺ｿ
      final keys = ['medicationList', 'medicationList_backup'];
      
      for (final key in keys) {
        medicationListStr = prefs.getString(key);
        if (medicationListStr != null && medicationListStr.isNotEmpty) {
          debugPrint('譛咲畑阮ｬ繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ謌仙粥: $key・医％縺ｱ縺輔ｓ豬・ｼ・);
          break;
        }
      }
      
      if (medicationListStr != null && medicationListStr.isNotEmpty) {
        final medicationListJson = jsonDecode(medicationListStr) as Map<String, dynamic>;
        _addedMedications.clear();
        
        final count = prefs.getInt('medicationList_count') ?? 0;
        for (int i = 0; i < count; i++) {
          final medKey = 'medication_$i';
          if (medicationListJson.containsKey(medKey)) {
            final medData = medicationListJson[medKey] as Map<String, dynamic>;
            _addedMedications.add({
              'id': medData['id'],
              'name': medData['name'],
              'type': medData['type'],
              'dosage': medData['dosage'],
              'color': medData['color'],
              'taken': medData['taken'],
              'takenTime': medData['takenTime'] != null ? DateTime.parse(medData['takenTime']) : null,
              'notes': medData['notes'],
            });
          }
        }
        
        debugPrint('譛咲畑阮ｬ繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ ${_addedMedications.length}莉ｶ・医％縺ｱ縺輔ｓ豬・ｼ・);
        
        // 縺薙・縺輔ｓ豬・ｼ啅I縺ｫ蜿肴丐
        if (mounted) {
          setState(() {
            // 菫晏ｭ倥＆繧後◆蛟､縺後≠繧後・縺昴ｌ繧剃ｽｿ縺・          });
        }
      } else {
        debugPrint('譛咲畑阮ｬ繝・・繧ｿ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ・医％縺ｱ縺輔ｓ豬・ｼ・);
        _addedMedications.clear();
      }
    } catch (e) {
      debugPrint('譛咲畑阮ｬ繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
      _addedMedications.clear();
    }
  }
  
  // 遒ｺ螳溘↑繧｢繝ｩ繝ｼ繝繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ・域欠螳壹ヱ繧ｹ譁ｹ蠑上ｒ謗｡逕ｨ・・  Future<void> _loadAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmCount = prefs.getInt('alarm_count') ?? 0;
      final alarmsList = <Map<String, dynamic>>[];
      
      debugPrint('繧｢繝ｩ繝ｼ繝繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ髢句ｧ・ $alarmCount莉ｶ');
      
      for (int i = 0; i < alarmCount; i++) {
        final name = prefs.getString('alarm_${i}_name');
        final time = prefs.getString('alarm_${i}_time');
        final repeat = prefs.getString('alarm_${i}_repeat');
        final enabled = prefs.getBool('alarm_${i}_enabled');
        final alarmType = prefs.getString('alarm_${i}_alarmType');
        final volume = prefs.getInt('alarm_${i}_volume');
        final message = prefs.getString('alarm_${i}_message');
        
        if (name != null && time != null) {
          alarmsList.add({
            'name': name,
            'time': time,
            'repeat': repeat ?? '荳蠎ｦ縺縺・,
            'enabled': enabled ?? true,
            'alarmType': alarmType ?? 'sound',
            'volume': volume ?? 80,
            'message': message ?? '阮ｬ繧呈恪逕ｨ縺吶ｋ譎る俣縺ｧ縺・,
          });
        }
      }
      
      setState(() {
        _alarmList = alarmsList;
      });
      
      debugPrint('繧｢繝ｩ繝ｼ繝繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ ${_alarmList.length}莉ｶ・域欠螳壹ヱ繧ｹ譁ｹ蠑擾ｼ・);
      
      // UI繧呈峩譁ｰ
      if (mounted) {
        setState(() {
          // 繧｢繝ｩ繝ｼ繝繝・・繧ｿ繧貞渚譏
        });
      }
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
      _alarmList = [];
    }
  }
  
  // 縺薙・縺輔ｓ豬・ｼ壹い繝ｩ繝ｼ繝縺ｮ蜀咲匳骭ｲ
  Future<void> _reRegisterAlarms() async {
    try {
      if (_alarmList.isEmpty) {
        debugPrint('繧｢繝ｩ繝ｼ繝蜀咲匳骭ｲ: 繧｢繝ｩ繝ｼ繝繝・・繧ｿ縺ｪ縺・);
        return;
      }
      
      debugPrint('繧｢繝ｩ繝ｼ繝蜀咲匳骭ｲ髢句ｧ・ ${_alarmList.length}莉ｶ');
      
      // 譌｢蟄倥・騾夂衍繧偵く繝｣繝ｳ繧ｻ繝ｫ
      // await NotificationService.cancelAllNotifications();
      
      // 蜷・い繝ｩ繝ｼ繝繧貞・逋ｻ骭ｲ
      for (int i = 0; i < _alarmList.length; i++) {
        final alarm = _alarmList[i];
        await _registerSingleAlarm(alarm, i);
      }
      
      debugPrint('繧｢繝ｩ繝ｼ繝蜀咲匳骭ｲ螳御ｺ・ ${_alarmList.length}莉ｶ');
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝蜀咲匳骭ｲ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 蜊倅ｸ繧｢繝ｩ繝ｼ繝縺ｮ逋ｻ骭ｲ
  Future<void> _registerSingleAlarm(Map<String, dynamic> alarm, int index) async {
    try {
      // 繧｢繝ｩ繝ｼ繝縺ｮ隧ｳ邏ｰ諠・ｱ繧貞叙蠕暦ｼ亥ｮ牙・縺ｪ蝙句､画鋤・・      final time = alarm['time']?.toString() ?? '09:00';
      final enabled = alarm['enabled'] is bool ? alarm['enabled'] as bool : true;
      final title = alarm['title']?.toString() ?? '譛咲畑繧｢繝ｩ繝ｼ繝';
      final message = alarm['message']?.toString() ?? '阮ｬ繧呈恪逕ｨ縺吶ｋ譎る俣縺ｧ縺・;
      
      if (!enabled) {
        debugPrint('繧｢繝ｩ繝ｼ繝 $index 縺ｯ辟｡蜉ｹ蛹悶＆繧後※縺・∪縺・);
        return;
      }
      
      // 譎る俣繧定ｧ｣譫・      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // 莉頑律縺ｮ譌･譎ゅｒ險ｭ螳・      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // 驕主悉縺ｮ譎る俣縺ｮ蝣ｴ蜷医・譏取律縺ｫ險ｭ螳・      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      // 騾夂衍繧偵せ繧ｱ繧ｸ繝･繝ｼ繝ｫ
      // await NotificationService.scheduleNotification(
      //   id: index,
      //   title: title,
      //   body: message,
      //   scheduledTime: scheduledTime,
      // );
      
      debugPrint('繧｢繝ｩ繝ｼ繝 $index 逋ｻ骭ｲ螳御ｺ・ $time');
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝 $index 逋ｻ骭ｲ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧｢繝ｩ繝ｼ繝縺ｮ霑ｽ蜉・域欠螳壹ヱ繧ｹ譁ｹ蠑擾ｼ・  Future<void> addAlarm(Map<String, dynamic> alarm) async {
    try {
      // 笨・霑ｽ蜉・壼､画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
      await _saveSnapshotBeforeChange('繧｢繝ｩ繝ｼ繝霑ｽ蜉_${alarm['name']}');
      setState(() {
        _alarmList.add(alarm);
      });
      
      // 繧｢繝ｩ繝ｼ繝霑ｽ蜉蠕後↓閾ｪ蜍穂ｿ晏ｭ・      await _saveAlarmData();
      
      // 譁ｰ縺励＞繧｢繝ｩ繝ｼ繝繧堤匳骭ｲ
      await _registerSingleAlarm(alarm, _alarmList.length - 1);
      
      debugPrint('繧｢繝ｩ繝ｼ繝霑ｽ蜉螳御ｺ・ ${alarm['name']}');
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝霑ｽ蜉繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧｢繝ｩ繝ｼ繝縺ｮ蜑企勁・域欠螳壹ヱ繧ｹ譁ｹ蠑擾ｼ・  Future<void> removeAlarm(int index) async {
    try {
      if (index >= 0 && index < _alarmList.length) {
        // 笨・霑ｽ蜉・壼､画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
        final alarm = _alarmList[index];
        await _saveSnapshotBeforeChange('繧｢繝ｩ繝ｼ繝蜑企勁_${alarm['name']}');
        setState(() {
          _alarmList.removeAt(index);
        });
        
        // 繧｢繝ｩ繝ｼ繝蜑企勁蠕後↓閾ｪ蜍穂ｿ晏ｭ・        await _saveAlarmData();
        
        debugPrint('繧｢繝ｩ繝ｼ繝蜑企勁螳御ｺ・ 繧､繝ｳ繝・ャ繧ｯ繧ｹ $index');
      }
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝蜑企勁繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧｢繝ｩ繝ｼ繝縺ｮ譖ｴ譁ｰ・域欠螳壹ヱ繧ｹ譁ｹ蠑擾ｼ・  Future<void> updateAlarm(int index, Map<String, dynamic> updatedAlarm) async {
    try {
      if (index >= 0 && index < _alarmList.length) {
        // 笨・霑ｽ蜉・壼､画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
        final alarm = _alarmList[index];
        await _saveSnapshotBeforeChange('繧｢繝ｩ繝ｼ繝邱ｨ髮・${alarm['name']}');
        setState(() {
          _alarmList[index] = updatedAlarm;
        });
        
        // 繧｢繝ｩ繝ｼ繝譖ｴ譁ｰ蠕後↓閾ｪ蜍穂ｿ晏ｭ・        await _saveAlarmData();
        
        debugPrint('繧｢繝ｩ繝ｼ繝譖ｴ譁ｰ螳御ｺ・ 繧､繝ｳ繝・ャ繧ｯ繧ｹ $index');
      }
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝譖ｴ譁ｰ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧｢繝ｩ繝ｼ繝縺ｮ譛牙柑/辟｡蜉ｹ蛻・ｊ譖ｿ縺茨ｼ域欠螳壹ヱ繧ｹ譁ｹ蠑擾ｼ・  Future<void> toggleAlarm(int index) async {
    try {
      if (index >= 0 && index < _alarmList.length) {
        final alarm = _alarmList[index];
        final newEnabled = !(alarm['enabled'] as bool? ?? true);
        
        // 笨・霑ｽ蜉・壼､画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
        await _saveSnapshotBeforeChange('繧｢繝ｩ繝ｼ繝蛻・崛_${alarm['name']}_${newEnabled ? '譛牙柑' : '辟｡蜉ｹ'}');
        setState(() {
          alarm['enabled'] = newEnabled;
        });
        
        // 繧｢繝ｩ繝ｼ繝蛻・ｊ譖ｿ縺亥ｾ後↓閾ｪ蜍穂ｿ晏ｭ・        await _saveAlarmData();
        
        debugPrint('繧｢繝ｩ繝ｼ繝蛻・ｊ譖ｿ縺亥ｮ御ｺ・ 繧､繝ｳ繝・ャ繧ｯ繧ｹ $index, 譛牙柑=$newEnabled');
      }
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝蛻・ｊ譖ｿ縺医お繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧｢繝ｩ繝ｼ繝繝・・繧ｿ縺ｮ讀懆ｨｼ
  Future<void> _validateAlarmData() async {
    try {
      debugPrint('=== 繧｢繝ｩ繝ｼ繝繝・・繧ｿ讀懆ｨｼ ===');
      debugPrint('繧｢繝ｩ繝ｼ繝謨ｰ: ${_alarmList.length}莉ｶ');
      
      for (int i = 0; i < _alarmList.length; i++) {
        final alarm = _alarmList[i];
        debugPrint('繧｢繝ｩ繝ｼ繝 $i:');
        debugPrint('  繧ｿ繧､繝医Ν: ${alarm['title'] ?? '縺ｪ縺・}');
        debugPrint('  譎る俣: ${alarm['time'] ?? '縺ｪ縺・}');
        debugPrint('  譛牙柑: ${alarm['enabled'] ?? false}');
        debugPrint('  繝｡繝・そ繝ｼ繧ｸ: ${alarm['message'] ?? '縺ｪ縺・}');
      }
      
      debugPrint('繧｢繝ｩ繝ｼ繝險ｭ螳・ ${_alarmSettings.length}莉ｶ');
      for (final entry in _alarmSettings.entries) {
        debugPrint('  ${entry.key}: ${entry.value}');
      }
      
      debugPrint('=== 繧｢繝ｩ繝ｼ繝繝・・繧ｿ讀懆ｨｼ螳御ｺ・===');
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝繝・・繧ｿ讀懆ｨｼ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧｢繝ｩ繝ｼ繝繝・・繧ｿ縺ｮ謨ｴ蜷域ｧ繝√ぉ繝・け
  Future<void> _checkAlarmDataIntegrity() async {
    try {
      // 繧｢繝ｩ繝ｼ繝繝・・繧ｿ縺ｮ謨ｴ蜷域ｧ繧偵メ繧ｧ繝・け
      for (int i = 0; i < _alarmList.length; i++) {
        final alarm = _alarmList[i];
        
        // 蠢・医ヵ繧｣繝ｼ繝ｫ繝峨・繝√ぉ繝・け
        if (!alarm.containsKey('title') || alarm['title'] == null) {
          alarm['title'] = '譛咲畑繧｢繝ｩ繝ｼ繝';
        }
        if (!alarm.containsKey('time') || alarm['time'] == null) {
          alarm['time'] = '09:00';
        }
        if (!alarm.containsKey('enabled') || alarm['enabled'] == null) {
          alarm['enabled'] = true;
        }
        if (!alarm.containsKey('message') || alarm['message'] == null) {
          alarm['message'] = '阮ｬ繧呈恪逕ｨ縺吶ｋ譎る俣縺ｧ縺・;
        }
      }
      
      // 繝・・繧ｿ繧貞・菫晏ｭ・      await _saveAlarmData();
      
      debugPrint('繧｢繝ｩ繝ｼ繝繝・・繧ｿ謨ｴ蜷域ｧ繝√ぉ繝・け螳御ｺ・);
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝繝・・繧ｿ謨ｴ蜷域ｧ繝√ぉ繝・け繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ縺ｮ菫晏ｭ・  Future<void> _saveCalendarMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final marksJson = <String, dynamic>{};
      
      // 驕ｸ謚槭＆繧後◆譌･莉倥ｒ菫晏ｭ・      for (final date in _selectedDates) {
        marksJson[date.toIso8601String()] = {
          'date': date.toIso8601String(),
          'hasData': _addedMedications.isNotEmpty,
          'medicationCount': _addedMedications.length,
        };
      }
      
      final success1 = await prefs.setString('calendar_marks', jsonEncode(marksJson));
      final success2 = await prefs.setString('calendar_marks_backup', jsonEncode(marksJson));
      final success3 = await prefs.setInt('calendar_marks_count', _selectedDates.length);
      
      if (success1 && success2 && success3) {
        debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ菫晏ｭ伜ｮ御ｺ・ ${_selectedDates.length}莉ｶ');
      } else {
        debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ菫晏ｭ倥↓螟ｱ謨・);
      }
    } catch (e) {
      debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadCalendarMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? marksStr;
      
      final keys = ['calendar_marks', 'calendar_marks_backup'];
      
      for (final key in keys) {
        try {
          marksStr = prefs.getString(key);
          if (marksStr != null && marksStr.isNotEmpty) {
            debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ隱ｭ縺ｿ霎ｼ縺ｿ謌仙粥: $key');
            break;
          }
        } catch (e) {
          debugPrint('繧ｭ繝ｼ $key 縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
          continue;
        }
      }
      
      if (marksStr != null && marksStr.isNotEmpty) {
        try {
          final marksJson = jsonDecode(marksStr) as Map<String, dynamic>;
          _selectedDates.clear();
          
          for (final entry in marksJson.entries) {
            final dateStr = entry.key;
            final date = DateTime.parse(dateStr);
            _selectedDates.add(_normalizeDate(date));
          }
          
          debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ ${_selectedDates.length}莉ｶ');
        } catch (e) {
          debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯJSON繝・さ繝ｼ繝峨お繝ｩ繝ｼ: $e');
          _selectedDates.clear();
        }
      } else {
        debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ');
        _selectedDates.clear();
      }
    } catch (e) {
      debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
      _selectedDates.clear();
    }
  }
  
  // 繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳壹・菫晏ｭ・  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = <String, dynamic>{
        'selectedDay': _selectedDay?.toIso8601String(),
        'isMemoSelected': _isMemoSelected,
        'selectedMemoId': _selectedMemo?.id,
        'isAlarmPlaying': _isAlarmPlaying,
        'notificationError': _notificationError,
        'lastSaveTime': DateTime.now().toIso8601String(),
      };
      
      final success1 = await prefs.setString('user_preferences', jsonEncode(preferencesJson));
      final success2 = await prefs.setString('user_preferences_backup', jsonEncode(preferencesJson));
      
      if (success1 && success2) {
        debugPrint('繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳壻ｿ晏ｭ伜ｮ御ｺ・);
      } else {
        debugPrint('繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳壻ｿ晏ｭ倥↓螟ｱ謨・);
      }
    } catch (e) {
      debugPrint('繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳壻ｿ晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳壹・隱ｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? preferencesStr;
      
      final keys = ['user_preferences', 'user_preferences_backup'];
      
      for (final key in keys) {
        try {
          preferencesStr = prefs.getString(key);
          if (preferencesStr != null && preferencesStr.isNotEmpty) {
            debugPrint('繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ謌仙粥: $key');
            break;
          }
        } catch (e) {
          debugPrint('繧ｭ繝ｼ $key 縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
          continue;
        }
      }
      
      if (preferencesStr != null && preferencesStr.isNotEmpty) {
        try {
          final preferencesJson = jsonDecode(preferencesStr) as Map<String, dynamic>;
          
          if (preferencesJson['selectedDay'] != null) {
            _selectedDay = DateTime.parse(preferencesJson['selectedDay']);
          }
          
          _isMemoSelected = preferencesJson['isMemoSelected'] ?? false;
          _isAlarmPlaying = preferencesJson['isAlarmPlaying'] ?? false;
          _notificationError = preferencesJson['notificationError'] ?? false;
          
          debugPrint('繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ螳御ｺ・);
        } catch (e) {
          debugPrint('繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳哽SON繝・さ繝ｼ繝峨お繝ｩ繝ｼ: $e');
        }
      } else {
        debugPrint('繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳壹′隕九▽縺九ｊ縺ｾ縺帙ｓ');
      }
    } catch (e) {
      debugPrint('繝ｦ繝ｼ繧ｶ繝ｼ險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 譌･蛻･濶ｲ險ｭ螳壹・菫晏ｭ・  Future<void> _saveDayColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorsJson = <String, dynamic>{};
      
      for (final entry in _dayColors.entries) {
        colorsJson[entry.key] = entry.value.value;
      }
      
      final success1 = await prefs.setString('day_colors', jsonEncode(colorsJson));
      final success2 = await prefs.setString('day_colors_backup', jsonEncode(colorsJson));
      
      if (success1 && success2) {
        debugPrint('譌･蛻･濶ｲ險ｭ螳壻ｿ晏ｭ伜ｮ御ｺ・ ${_dayColors.length}莉ｶ');
      } else {
        debugPrint('譌･蛻･濶ｲ險ｭ螳壻ｿ晏ｭ倥↓螟ｱ謨・);
      }
    } catch (e) {
      debugPrint('譌･蛻･濶ｲ險ｭ螳壻ｿ晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 譌･蛻･濶ｲ險ｭ螳壹・隱ｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadDayColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? colorsStr;
      
      final keys = ['day_colors', 'day_colors_backup'];
      
      for (final key in keys) {
        try {
          colorsStr = prefs.getString(key);
          if (colorsStr != null && colorsStr.isNotEmpty) {
            debugPrint('譌･蛻･濶ｲ險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ謌仙粥: $key');
            break;
          }
        } catch (e) {
          debugPrint('繧ｭ繝ｼ $key 縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
          continue;
        }
      }
      
      if (colorsStr != null && colorsStr.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(colorsStr);
          _dayColors = decoded.map((key, value) => MapEntry(key, Color(value)));
          debugPrint('譌･蛻･濶ｲ險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ ${_dayColors.length}莉ｶ');
        } catch (e) {
          debugPrint('譌･蛻･濶ｲ險ｭ螳哽SON繝・さ繝ｼ繝峨お繝ｩ繝ｼ: $e');
          _dayColors = {};
        }
      } else {
        debugPrint('譌･蛻･濶ｲ險ｭ螳壹′隕九▽縺九ｊ縺ｾ縺帙ｓ');
        _dayColors = {};
      }
    } catch (e) {
      debugPrint('譌･蛻･濶ｲ險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
      _dayColors = {};
    }
  }
  
  // 邨ｱ險医ョ繝ｼ繧ｿ縺ｮ菫晏ｭ・  Future<void> _saveStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statisticsJson = <String, dynamic>{
        'adherenceRates': _adherenceRates,
        'totalMedications': _addedMedications.length,
        'lastCalculation': DateTime.now().toIso8601String(),
      };
      
      final success1 = await prefs.setString('statistics', jsonEncode(statisticsJson));
      final success2 = await prefs.setString('statistics_backup', jsonEncode(statisticsJson));
      
      if (success1 && success2) {
        debugPrint('邨ｱ險医ョ繝ｼ繧ｿ菫晏ｭ伜ｮ御ｺ・);
      } else {
        debugPrint('邨ｱ險医ョ繝ｼ繧ｿ菫晏ｭ倥↓螟ｱ謨・);
      }
    } catch (e) {
      debugPrint('邨ｱ險医ョ繝ｼ繧ｿ菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 邨ｱ險医ョ繝ｼ繧ｿ縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? statisticsStr;
      
      final keys = ['statistics', 'statistics_backup'];
      
      for (final key in keys) {
        try {
          statisticsStr = prefs.getString(key);
          if (statisticsStr != null && statisticsStr.isNotEmpty) {
            debugPrint('邨ｱ險医ョ繝ｼ繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ謌仙粥: $key');
            break;
          }
        } catch (e) {
          debugPrint('繧ｭ繝ｼ $key 縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
          continue;
        }
      }
      
      if (statisticsStr != null && statisticsStr.isNotEmpty) {
        try {
          final statisticsJson = jsonDecode(statisticsStr) as Map<String, dynamic>;
          _adherenceRates = Map<String, double>.from(statisticsJson['adherenceRates'] ?? {});
          debugPrint('邨ｱ險医ョ繝ｼ繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・);
        } catch (e) {
          debugPrint('邨ｱ險医ョ繝ｼ繧ｿJSON繝・さ繝ｼ繝峨お繝ｩ繝ｼ: $e');
          _adherenceRates = {};
        }
      } else {
        debugPrint('邨ｱ險医ョ繝ｼ繧ｿ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ');
        _adherenceRates = {};
      }
    } catch (e) {
      debugPrint('邨ｱ險医ョ繝ｼ繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
      _adherenceRates = {};
    }
  }
  
  // 繧｢繝励Μ險ｭ螳壹・菫晏ｭ・  Future<void> _saveAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = <String, dynamic>{
        'appVersion': '1.0.1',
        'lastUpdate': DateTime.now().toIso8601String(),
        'dataVersion': 'flutter_3_29_3',
        'backupEnabled': true,
      };
      
      final success1 = await prefs.setString('app_settings', jsonEncode(settingsJson));
      final success2 = await prefs.setString('app_settings_backup', jsonEncode(settingsJson));
      
      if (success1 && success2) {
        debugPrint('繧｢繝励Μ險ｭ螳壻ｿ晏ｭ伜ｮ御ｺ・);
      } else {
        debugPrint('繧｢繝励Μ險ｭ螳壻ｿ晏ｭ倥↓螟ｱ謨・);
      }
    } catch (e) {
      debugPrint('繧｢繝励Μ險ｭ螳壻ｿ晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 譛咲畑蝗樊焚蛻･迥ｶ諷九・菫晏ｭ・  Future<void> _saveMedicationDoseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doseStatusJson = <String, dynamic>{};
      
      for (final dateEntry in _weekdayMedicationDoseStatus.entries) {
        final dateStr = dateEntry.key;
        final memoStatus = dateEntry.value;
        final memoStatusJson = <String, dynamic>{};
        
        for (final memoEntry in memoStatus.entries) {
          final memoId = memoEntry.key;
          final doseStatus = memoEntry.value;
          final doseStatusJson = <String, dynamic>{};
          
          for (final doseEntry in doseStatus.entries) {
            doseStatusJson[doseEntry.key.toString()] = doseEntry.value;
          }
          
          memoStatusJson[memoId] = doseStatusJson;
        }
        
        doseStatusJson[dateStr] = memoStatusJson;
      }
      
      final success1 = await prefs.setString('medication_dose_status', jsonEncode(doseStatusJson));
      final success2 = await prefs.setString('medication_dose_status_backup', jsonEncode(doseStatusJson));
      
      if (success1 && success2) {
        debugPrint('譛咲畑蝗樊焚蛻･迥ｶ諷倶ｿ晏ｭ伜ｮ御ｺ・);
      } else {
        debugPrint('譛咲畑蝗樊焚蛻･迥ｶ諷倶ｿ晏ｭ倥↓螟ｱ謨・);
      }
    } catch (e) {
      debugPrint('譛咲畑蝗樊焚蛻･迥ｶ諷倶ｿ晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 譛咲畑蝗樊焚蛻･迥ｶ諷九・隱ｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadMedicationDoseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doseStatusStr = prefs.getString('medication_dose_status') ?? 
                           prefs.getString('medication_dose_status_backup') ?? '{}';
      final doseStatusJson = jsonDecode(doseStatusStr) as Map<String, dynamic>;
      
      _weekdayMedicationDoseStatus.clear();
      
      for (final dateEntry in doseStatusJson.entries) {
        final dateStr = dateEntry.key;
        final memoStatus = dateEntry.value as Map<String, dynamic>;
        final memoStatusMap = <String, Map<int, bool>>{};
        
        for (final memoEntry in memoStatus.entries) {
          final memoId = memoEntry.key;
          final doseStatus = memoEntry.value as Map<String, dynamic>;
          final doseStatusMap = <int, bool>{};
          
          for (final doseEntry in doseStatus.entries) {
            doseStatusMap[int.parse(doseEntry.key)] = doseEntry.value as bool;
          }
          
          memoStatusMap[memoId] = doseStatusMap;
        }
        
        _weekdayMedicationDoseStatus[dateStr] = memoStatusMap;
      }
      
      debugPrint('譛咲畑蝗樊焚蛻･迥ｶ諷玖ｪｭ縺ｿ霎ｼ縺ｿ螳御ｺ・);
    } catch (e) {
      debugPrint('譛咲畑蝗樊焚蛻･迥ｶ諷玖ｪｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 繧｢繝励Μ險ｭ螳壹・隱ｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? settingsStr;
      
      final keys = ['app_settings', 'app_settings_backup'];
      
      for (final key in keys) {
        try {
          settingsStr = prefs.getString(key);
          if (settingsStr != null && settingsStr.isNotEmpty) {
            debugPrint('繧｢繝励Μ險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ謌仙粥: $key');
            break;
          }
        } catch (e) {
          debugPrint('繧ｭ繝ｼ $key 縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
          continue;
        }
      }
      
      if (settingsStr != null && settingsStr.isNotEmpty) {
        try {
          final settingsJson = jsonDecode(settingsStr) as Map<String, dynamic>;
          debugPrint('繧｢繝励Μ險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ ${settingsJson['appVersion']}');
        } catch (e) {
          debugPrint('繧｢繝励Μ險ｭ螳哽SON繝・さ繝ｼ繝峨お繝ｩ繝ｼ: $e');
        }
      } else {
        debugPrint('繧｢繝励Μ險ｭ螳壹′隕九▽縺九ｊ縺ｾ縺帙ｓ');
      }
    } catch (e) {
      debugPrint('繧｢繝励Μ險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // 縺昴・莉悶・險ｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadOtherSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 譌･蛻･縺ｮ濶ｲ險ｭ螳・      final colorsJson = prefs.getString('day_colors');
      if (colorsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(colorsJson);
        _dayColors = decoded.map((key, value) => MapEntry(key, Color(value)));
      }
      
      debugPrint('縺昴・莉冶ｨｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ螳御ｺ・);
    } catch (e) {
      debugPrint('縺昴・莉冶ｨｭ螳夊ｪｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  void _setupControllerListeners() {
    // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・繝ｪ繧ｹ繝翫・險ｭ螳壹・荳崎ｦ・  }
  
  /// 霆ｽ驥上↑蛻晄悄蛹門・逅・ｼ医い繝励Μ襍ｷ蜍輔ｒ髦ｻ螳ｳ縺励↑縺・ｼ・  Future<void> _initializeAsync() async {
    try {
      // 驥崎､・・譛溷喧繧帝亟縺・      if (_isInitialized) {
        debugPrint('蛻晄悄蛹匁ｸ医∩縺ｮ縺溘ａ繧ｹ繧ｭ繝・・');
        return;
      }
      
      // 霆ｽ驥上↑蛻晄悄蛹悶・縺ｿ螳溯｡・      _notificationError = !await NotificationService.initialize();
      
      // 驥阪＞蜃ｦ逅・・蠕悟屓縺・      Future.delayed(const Duration(milliseconds: 500), () {
        _loadHeavyData();
      });
      
      debugPrint('霆ｽ驥丞・譛溷喧螳御ｺ・);
    } catch (e) {
      debugPrint('蛻晄悄蛹悶お繝ｩ繝ｼ: $e');
    }
  }
  
  // 驥阪＞繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ・亥ｾ悟屓縺暦ｼ・  Future<void> _loadHeavyData() async {
    try {
      final futures = await Future.wait([
        MedicationService.loadMedicationData(),
        MedicationService.loadMedicines(),
        MedicationService.loadAdherenceStats(),
        MedicationService.loadSettings(),
      ]);
      
      setState(() {
        _medicationData = futures[0] as Map<String, Map<String, MedicationInfo>>;
        _medicines = futures[1] as List<MedicineData>;
        _adherenceRates = futures[2] as Map<String, double>;
      });
      
      debugPrint('驥阪＞繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・);
    } catch (e) {
      debugPrint('驥阪＞繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
    }
  }
  
  // SharedPreferences縺九ｉ繝舌ャ繧ｯ繧｢繝・・蠕ｩ蜈・  Future<void> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSaveDate = prefs.getString('last_save_date');
      
      if (lastSaveDate != null) {
        final backupData = prefs.getString('medication_backup_$lastSaveDate');
        if (backupData != null) {
          final dataJson = jsonDecode(backupData) as Map<String, dynamic>;
          debugPrint('繝舌ャ繧ｯ繧｢繝・・繝・・繧ｿ蠕ｩ蜈・ $lastSaveDate');
        }
      }
    } catch (e) {
      debugPrint('繝舌ャ繧ｯ繧｢繝・・蠕ｩ蜈・お繝ｩ繝ｼ: $e');
    }
  }
  @override
  void dispose() {
    // 笨・菫ｮ豁｣・壹☆縺ｹ縺ｦ縺ｮ繧ｿ繧､繝槭・縺ｨ繧ｳ繝ｳ繝医Ο繝ｼ繝ｩ繝ｼ繧帝←蛻・↓隗｣謾ｾ
    _debounce?.cancel();
    _debounce = null;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    
    // 笨・菫ｮ豁｣・售treamSubscription縺ｮ螳悟・隗｣謾ｾ
    _subscription?.cancel();
    _subscription = null;
    
    // 笨・菫ｮ豁｣・壼虚逧・脈繝ｪ繧ｹ繝医・繝ｪ繧ｹ繝翫・隗｣謾ｾ
    for (final medication in _addedMedications) {
      // 蜷・脈縺ｮ繧ｳ繝ｳ繝医Ο繝ｼ繝ｩ繝ｼ縺後≠繧後・隗｣謾ｾ
      if (medication.containsKey('controller')) {
        (medication['controller'] as TextEditingController?)?.dispose();
      }
    }
    
    // 笨・菫ｮ豁｣・壹Γ繝｢繧ｳ繝ｳ繝医Ο繝ｼ繝ｩ繝ｼ縺ｨ繝輔か繝ｼ繧ｫ繧ｹ繝弱・繝峨・繧ｯ繝ｪ繝ｼ繝ｳ繧｢繝・・
    _memoController.dispose();
    _memoFocusNode.dispose();
    _tabController.dispose();
    _calendarScrollController.dispose();
    _medicationHistoryScrollController.dispose();
    _statsScrollController.dispose();
    _medicationPageController.dispose();
    _customDaysController.dispose();
    _customDaysFocusNode.dispose();
    
    // 笨・菫ｮ豁｣・夊ｳｼ蜈･繧ｵ繝ｼ繝薙せ繧りｧ｣謾ｾ
    InAppPurchaseService.dispose();
    
    // 笨・菫ｮ豁｣・唏ive繝懊ャ繧ｯ繧ｹ縺ｮ繧ｯ繝ｪ繝ｼ繝ｳ繧｢繝・・
    try {
      Hive.close();
    } catch (e) {
      Logger.warning('Hive縺ｮ隗｣謾ｾ繧ｨ繝ｩ繝ｼ: $e');
    }
    
    super.dispose();
  }
  DateTime _normalizeDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);
  Future<void> _calculateAdherenceStats() async {
    try {
      final now = DateTime.now();
      final stats = <String, double>{};
      for (final period in [7, 30, 90]) {
        int totalDoses = 0;
        int takenDoses = 0;
        for (int i = 0; i < period; i++) {
          final date = now.subtract(Duration(days: i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final dayData = _medicationData[dateStr];
        
        // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・邨ｱ險・          if (dayData != null) {
            for (final timeSlot in dayData.values) {
              if (timeSlot.medicine.isNotEmpty) {
                totalDoses++;
                if (timeSlot.checked) takenDoses++;
              }
            }
          }
        
        // 譖懈律險ｭ螳壹＆繧後◆阮ｬ縺ｮ邨ｱ險茨ｼ域恪逕ｨ繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ諷九ｒ蜿肴丐・・        final weekday = date.weekday % 7; // 0=譌･譖懈律, 1=譛域屆譌･, ..., 6=蝨滓屆譌･
        final weekdayMemos = _medicationMemos.where((memo) => memo.selectedWeekdays.contains(weekday)).toList();
        
        for (final memo in weekdayMemos) {
          totalDoses++;
          // 譛咲畑繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ諷九ｒ遒ｺ隱・          if (_medicationMemoStatus[memo.id] == true) {
            takenDoses++;
          }
        }
        }
        stats['$period譌･髢・] = totalDoses > 0 ? (takenDoses / totalDoses * 100) : 0;
      }
      setState(() => _adherenceRates = stats);
      await MedicationService.saveAdherenceStats(stats);
    } catch (e) {
    }
  }
  // 笨・菫ｮ豁｣・壹ョ繝舌え繝ｳ繧ｹ菫晏ｭ倥・螳溯｣・  void _saveCurrentDataDebounced() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
      _saveCurrentDataDebounced();
    });
  }

  // 蠑ｷ蛹悶＆繧後◆繝・・繧ｿ菫晏ｭ倥Γ繧ｽ繝・ラ・亥ｷｮ蛻・ｿ晏ｭ伜ｯｾ蠢懶ｼ・  void _saveCurrentData() async {
    try {
      if (!_isInitialized) return;
      
      // 笨・菫ｮ豁｣・壼､画峩縺後≠縺｣縺滄Κ蛻・・縺ｿ菫晏ｭ・      if (_medicationMemoStatusChanged) {
        await _saveMedicationMemoStatus();
        _medicationMemoStatusChanged = false;
      }
      
      if (_weekdayMedicationStatusChanged) {
        await _saveWeekdayMedicationStatus();
        _weekdayMedicationStatusChanged = false;
      }
      
      if (_addedMedicationsChanged) {
      await _saveAddedMedications();
        _addedMedicationsChanged = false;
      }
      
      // 譛咲畑繝｡繝｢縺ｮ菫晏ｭ假ｼ・ive繝吶・繧ｹ・・      for (final memo in _medicationMemos) {
        await AppPreferences.saveMedicationMemo(memo);
      }
      
      // 繝｡繝｢縺ｮ菫晏ｭ・      await _saveMemo();
      
      // 邨ｱ險医・蜀崎ｨ育ｮ・      await _calculateAdherenceStats();
      
    } catch (e) {
    }
  }
  
  // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・菫晏ｭ・  Future<void> _saveAddedMedications() async {
    try {
      if (_selectedDay == null) return;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      _medicationData.putIfAbsent(dateStr, () => {});
      
      // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・菫晏ｭ假ｼ亥句挨縺ｫ菫晏ｭ假ｼ・      for (final medication in _addedMedications) {
        final key = 'added_medication_${medication.hashCode}';
        _medicationData[dateStr]![key] = MedicationInfo(
          checked: medication['isChecked'] as bool,
          medicine: medication['name'] as String,
          actualTime: medication['isChecked'] as bool ? DateTime.now() : null,
        );
      }
      
      await MedicationService.saveMedicationData(_medicationData);
    } catch (e) {
    }
  }
  
  // 譛咲畑繝｡繝｢縺ｮ迥ｶ諷倶ｿ晏ｭ・  Future<void> _saveMedicationMemoStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoStatusJson = <String, dynamic>{};
      
      for (final entry in _medicationMemoStatus.entries) {
        memoStatusJson[entry.key] = entry.value;
      }
      
      // 笨・菫ｮ豁｣・夂ｵｱ荳縺輔ｌ縺溘く繝ｼ縺ｨ繝舌ャ繧ｯ繧｢繝・・菫晏ｭ・      final data = jsonEncode(memoStatusJson);
      await prefs.setString(_medicationMemoStatusKey, data);
      await prefs.setString(_medicationMemoStatusKey + _backupSuffix, data);
    } catch (e) {
    }
  }
  
  // 譖懈律險ｭ螳夊脈縺ｮ迥ｶ諷倶ｿ晏ｭ・  Future<void> _saveWeekdayMedicationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weekdayStatusJson = <String, dynamic>{};
      
      for (final dateEntry in _weekdayMedicationStatus.entries) {
        weekdayStatusJson[dateEntry.key] = dateEntry.value;
      }
      
      await prefs.setString('weekday_medication_status', jsonEncode(weekdayStatusJson));
    } catch (e) {
    }
  }
  
  // 蠑ｷ蛹悶＆繧後◆繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ繝｡繧ｽ繝・ラ
  Future<void> _loadCurrentData() async {
    try {
      // 譛咲畑繝｡繝｢縺ｮ迥ｶ諷玖ｪｭ縺ｿ霎ｼ縺ｿ
      await _loadMedicationMemoStatus();
      
      // 譖懈律險ｭ螳夊脈縺ｮ迥ｶ諷玖ｪｭ縺ｿ霎ｼ縺ｿ
      await _loadWeekdayMedicationStatus();
      
      // 繝｡繝｢縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
      await _loadMemo();
      
    } catch (e) {
    }
  }
  
  // 譛咲畑繝｡繝｢縺ｮ迥ｶ諷玖ｪｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadMedicationMemoStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoStatusJson = prefs.getString('medication_memo_status');
      
      if (memoStatusJson != null) {
        final Map<String, dynamic> memoStatusData = jsonDecode(memoStatusJson);
        _medicationMemoStatus.clear();
        
        for (final entry in memoStatusData.entries) {
          _medicationMemoStatus[entry.key] = entry.value as bool;
        }
      }
      
      // 譛咲畑繝｡繝｢縺ｮ蛻晄悄迥ｶ諷九ｒ譛ｪ繝√ぉ繝・け縺ｫ險ｭ螳・      for (final memo in _medicationMemos) {
        if (!_medicationMemoStatus.containsKey(memo.id)) {
          _medicationMemoStatus[memo.id] = false;
        }
      }
    } catch (e) {
      // 繧ｨ繝ｩ繝ｼ譎ゅｂ蛻晄悄迥ｶ諷九ｒ譛ｪ繝√ぉ繝・け縺ｫ險ｭ螳・      for (final memo in _medicationMemos) {
        _medicationMemoStatus[memo.id] = false;
      }
    }
  }
  
  // 譖懈律險ｭ螳夊脈縺ｮ迥ｶ諷玖ｪｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadWeekdayMedicationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weekdayStatusJson = prefs.getString('weekday_medication_status');
      
      if (weekdayStatusJson != null) {
        final Map<String, dynamic> weekdayStatusData = jsonDecode(weekdayStatusJson);
        _weekdayMedicationStatus.clear();
        
        for (final dateEntry in weekdayStatusData.entries) {
          _weekdayMedicationStatus[dateEntry.key] = Map<String, bool>.from(dateEntry.value);
        }
      }
    } catch (e) {
    }
  }
  
  // 繝｡繝｢縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadMemo() async {
    try {
      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final prefs = await SharedPreferences.getInstance();
        final memo = prefs.getString('memo_$dateStr');
        if (memo != null) {
          _memoController.text = memo;
        }
      }
    } catch (e) {
    }
  }
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    try {
      // 繝医Λ繧､繧｢繝ｫ蛻ｶ髯舌メ繧ｧ繝・け・亥ｽ捺律莉･螟悶・驕ｸ謚樊凾・・      final isExpired = await TrialService.isTrialExpired();
      final today = DateTime.now();
      final isToday = selectedDay.year == today.year && 
                      selectedDay.month == today.month && 
                      selectedDay.day == today.day;
      
      if (isExpired && !isToday) {
        showDialog(
          context: context,
          builder: (context) => TrialLimitDialog(featureName: '繧ｫ繝ｬ繝ｳ繝繝ｼ'),
        );
        return;
      }
      
      // 笨・菫ｮ豁｣・壼・縺ｫ繝・・繧ｿ貅門ｙ
      final normalizedDay = _normalizeDate(selectedDay);
      final wasSelected = _selectedDates.contains(normalizedDay);
      
      // 笨・菫ｮ豁｣・・蝗槭・setState縺ｧ蜈ｨ縺ｦ譖ｴ譁ｰ
      setState(() {
        if (wasSelected) {
          _selectedDates.remove(normalizedDay);
            _selectedDay = null;
            _addedMedications.clear();
        } else {
          _selectedDates.add(normalizedDay);
          _selectedDay = normalizedDay;
        }
        _focusedDay = focusedDay;
      });
      
      // 笨・菫ｮ豁｣・夐撼蜷梧悄蜃ｦ逅・・螟悶〒螳溯｡・      if (!wasSelected && _selectedDay != null) {
        await _updateMedicineInputsForSelectedDate();
        await _loadCurrentData();
      }
      
      // 繝｡繝｢繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ倥ヵ繝ｩ繧ｰ繧偵Μ繧ｻ繝・ヨ
      _memoSnapshotSaved = false;
    } catch (e) {
      _showSnackBar('譌･莉倥・驕ｸ謚槭↓螟ｱ謨励＠縺ｾ縺励◆: $e');
    }
  }
  
  
  // 繧ｫ繝ｬ繝ｳ繝繝ｼ繧ｹ繧ｿ繧､繝ｫ繧貞虚逧・↓逕滓・・域律莉倥・濶ｲ縺ｫ蝓ｺ縺･縺擾ｼ・  CalendarStyle _buildCalendarStyle() {
    return CalendarStyle(
      outsideDaysVisible: false,
      cellMargin: const EdgeInsets.all(2),
      cellPadding: const EdgeInsets.all(4),
      cellAlignment: Alignment.center,
      defaultTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      selectedTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      todayTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      weekendTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      defaultDecoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      selectedDecoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFff6b6b),
            Color(0xFFee5a24),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff6b6b).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      todayDecoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4ecdc4),
            Color(0xFF44a08d),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ecdc4).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      markersMaxCount: 1,
      markerDecoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
  
  // 繧ｫ繧ｹ繧ｿ繝譌･莉倩｣・｣ｾ繧貞叙蠕・  BoxDecoration? _getCustomDayDecoration(DateTime day) {
    final dateKey = DateFormat('yyyy-MM-dd').format(day);
    final customColor = _dayColors[dateKey];
    
    if (customColor != null) {
      return BoxDecoration(
        color: customColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: customColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    return null;
  }
  
  // 濶ｲ驕ｸ謚槭ム繧､繧｢繝ｭ繧ｰ
  void _showColorPickerDialog(String dateKey) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('譌･莉倥・濶ｲ繧帝∈謚・),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) => GestureDetector(
            onTap: () async {
              // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ・医き繝ｬ繝ｳ繝繝ｼ譌･莉倩牡縺ｮ險ｭ螳夲ｼ・              await _saveSnapshotBeforeChange('譌･莉倩牡螟画峩_$dateKey');
              _dayColors[dateKey] = color;
              _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
              _saveDayColors();
              Navigator.pop(context);
              _showSnackBar('濶ｲ繧定ｨｭ螳壹＠縺ｾ縺励◆');
              // 繧ｫ繝ｬ繝ｳ繝繝ｼ繧貞・謠冗判
              // 驛ｨ蛻・峩譁ｰ縺ｯNotifier縺ｧ蜿肴丐貂医∩
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ・医き繝ｬ繝ｳ繝繝ｼ譌･莉倩牡縺ｮ繝ｪ繧ｻ繝・ヨ・・              await _saveSnapshotBeforeChange('譌･莉倩牡繝ｪ繧ｻ繝・ヨ_$dateKey');
              _dayColors.remove(dateKey);
              _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
              _saveDayColors();
              Navigator.pop(context);
              _showSnackBar('濶ｲ繧貞炎髯､縺励∪縺励◆');
              // 繧ｫ繝ｬ繝ｳ繝繝ｼ繧貞・謠冗判
              // 驛ｨ蛻・峩譁ｰ縺ｯNotifier縺ｧ蜿肴丐貂医∩
            },
            child: const Text('濶ｲ繧貞炎髯､'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
          ),
        ],
      ),
    );
  }
  Future<void> _updateMedicineInputsForSelectedDate() async {
    try {
      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final dayData = _medicationData[dateStr];
        // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・蠕ｩ蜈・        _addedMedications = [];
        if (dayData != null) {
          for (final entry in dayData.entries) {
            if (entry.key.startsWith('added_medication_')) {
              _addedMedications.add({
                'name': entry.value.medicine,
                'type': '阮ｬ',
                'color': Colors.blue,
                'dosage': '',
                'notes': '',
                'isChecked': entry.value.checked,
              });
            }
          }
        }
        // 繝｡繝｢縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ
        _loadMemoForSelectedDate();
      } else {
        _addedMedications = [];
        _memoController.clear();
      }
    } catch (e) {
    }
  }

  Future<void> _loadMemoForSelectedDate() async {
    try {
      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final prefs = await SharedPreferences.getInstance();
        final savedMemo = prefs.getString('memo_$dateStr');
        if (savedMemo != null) {
          _memoController.text = savedMemo;
        } else {
          _memoController.clear();
        }
      }
    } catch (e) {
    }
  }


  // 笨・謾ｹ蝟・沿・壽恪逕ｨ繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ讖溯・・亥､夐㍾繝舌ャ繧ｯ繧｢繝・・莉倥″・・  Future<void> _loadMedicationMemos() async {
    try {
      debugPrint('当 譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ髢句ｧ・..');
      
      // 笨・1. Hive繝懊ャ繧ｯ繧ｹ縺九ｉ隱ｭ縺ｿ霎ｼ縺ｿ
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        final memos = box.values.toList();
        debugPrint('笨・Hive縺九ｉ譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ謌仙粥: ${memos.length}莉ｶ');
        
        setState(() {
          _medicationMemos = memos;
        });
        
        // 笨・繝舌ャ繧ｯ繧｢繝・・縺ｨ縺励※SharedPreferences縺ｫ繧ゆｿ晏ｭ・        await _backupMemosToSharedPreferences();
        return;
      }
      
      // 笨・2. Hive縺碁幕縺・※縺・↑縺・ｴ蜷医ヾharedPreferences縺九ｉ隱ｭ縺ｿ霎ｼ縺ｿ
      debugPrint('笞・・Hive繝懊ャ繧ｯ繧ｹ縺碁幕縺・※縺・∪縺帙ｓ縲４haredPreferences縺九ｉ隱ｭ縺ｿ霎ｼ縺ｿ...');
      final memos = await _loadMemosFromSharedPreferences();
      
      setState(() {
        _medicationMemos = memos;
      });
      
      debugPrint('笨・SharedPreferences縺九ｉ譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ ${memos.length}莉ｶ');
    } catch (e, stackTrace) {
      debugPrint('笶・譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
      debugPrint('繧ｹ繧ｿ繝・け繝医Ξ繝ｼ繧ｹ: $stackTrace');
      
      // 笨・3. 繧ｨ繝ｩ繝ｼ譎ゅ・遨ｺ縺ｮ繝ｪ繧ｹ繝医〒蛻晄悄蛹・      setState(() {
        _medicationMemos = [];
      });
    }
  }
  
  // 笨・SharedPreferences縺九ｉ縺ｮ譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ
  Future<List<MedicationMemo>> _loadMemosFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKeys = [
        'medication_memos_backup', 
        'medication_memos_backup2', 
        'medication_memos_backup3',
        'medication_memos_v2',
        'medication_memos'
      ];
      
      for (final key in backupKeys) {
        try {
          final backupJson = prefs.getString(key);
          if (backupJson != null && backupJson.isNotEmpty) {
            final List<dynamic> memosList = jsonDecode(backupJson);
            final memos = memosList
                .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
                .toList();
            debugPrint('笨・SharedPreferences縺九ｉ蠕ｩ蜈・ ${memos.length}莉ｶ ($key)');
            return memos;
      }
    } catch (e) {
          debugPrint('笞・・繧ｭ繝ｼ $key 縺ｮ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
          continue;
        }
      }
      
      debugPrint('笞・・蜈ｨ縺ｦ縺ｮ繝舌ャ繧ｯ繧｢繝・・縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ');
      return [];
    } catch (e) {
      debugPrint('笶・SharedPreferences隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
      return [];
    }
  }
  
  // 笨・SharedPreferences縺ｸ縺ｮ繝舌ャ繧ｯ繧｢繝・・菫晏ｭ・  Future<void> _backupMemosToSharedPreferences() async {
    try {
      if (_medicationMemos.isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      final memosJson = _medicationMemos.map((memo) => memo.toJson()).toList();
      final jsonString = jsonEncode(memosJson);
      
      // 笨・隍・焚繧ｭ繝ｼ縺ｫ菫晏ｭ假ｼ・驥阪ヰ繝・け繧｢繝・・・・      await Future.wait([
        prefs.setString('medication_memos_backup', jsonString),
        prefs.setString('medication_memos_backup2', jsonString),
        prefs.setString('medication_memos_backup3', jsonString),
        prefs.setString('medication_memos_v2', jsonString),
      ]);
      
      debugPrint('笨・譛咲畑繝｡繝｢繝舌ャ繧ｯ繧｢繝・・菫晏ｭ伜ｮ御ｺ・ ${_medicationMemos.length}莉ｶ');
    } catch (e) {
      debugPrint('笶・譛咲畑繝｡繝｢繝舌ャ繧ｯ繧｢繝・・菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 笨・謾ｹ蝟・沿・壽恪逕ｨ繝｡繝｢菫晏ｭ俶ｩ溯・・亥､夐㍾繝舌ャ繧ｯ繧｢繝・・莉倥″・・  Future<void> _saveMedicationMemoWithBackup(MedicationMemo memo) async {
    try {
      debugPrint('沈 譛咲畑繝｡繝｢菫晏ｭ倬幕蟋・ ${memo.name}');
      
      // 笨・1. Hive繝懊ャ繧ｯ繧ｹ縺ｫ菫晏ｭ・      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        await box.put(memo.id, memo);
        debugPrint('笨・Hive縺ｫ譛咲畑繝｡繝｢菫晏ｭ伜ｮ御ｺ・);
      } else {
        debugPrint('笞・・Hive繝懊ャ繧ｯ繧ｹ縺碁幕縺・※縺・∪縺帙ｓ');
      }
      
      // 笨・2. SharedPreferences縺ｫ繧ゅヰ繝・け繧｢繝・・菫晏ｭ・      await _backupMemosToSharedPreferences();
      
      debugPrint('笨・譛咲畑繝｡繝｢菫晏ｭ伜ｮ御ｺ・ ${memo.name}');
    } catch (e, stackTrace) {
      debugPrint('笶・譛咲畑繝｡繝｢菫晏ｭ倥お繝ｩ繝ｼ: $e');
      debugPrint('繧ｹ繧ｿ繝・け繝医Ξ繝ｼ繧ｹ: $stackTrace');
      
      // 笨・繧ｨ繝ｩ繝ｼ譎ゅｂSharedPreferences縺ｫ菫晏ｭ倥ｒ隧ｦ陦・      try {
        await _backupMemosToSharedPreferences();
        debugPrint('笨・繝輔か繝ｼ繝ｫ繝舌ャ繧ｯ菫晏ｭ俶・蜉・);
      } catch (backupError) {
        debugPrint('笶・繝輔か繝ｼ繝ｫ繝舌ャ繧ｯ菫晏ｭ倥ｂ螟ｱ謨・ $backupError');
      }
    }
  }
  
  // 笨・謾ｹ蝟・沿・壽恪逕ｨ繝｡繝｢蜑企勁讖溯・・亥､夐㍾繝舌ャ繧ｯ繧｢繝・・莉倥″・・  Future<void> _deleteMedicationMemoWithBackup(String memoId) async {
    try {
      debugPrint('卵・・譛咲畑繝｡繝｢蜑企勁髢句ｧ・ $memoId');
      
      // 笨・1. Hive繝懊ャ繧ｯ繧ｹ縺九ｉ蜑企勁
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        await box.delete(memoId);
        debugPrint('笨・Hive縺九ｉ譛咲畑繝｡繝｢蜑企勁螳御ｺ・);
      } else {
        debugPrint('笞・・Hive繝懊ャ繧ｯ繧ｹ縺碁幕縺・※縺・∪縺帙ｓ');
      }
      
      // 笨・2. SharedPreferences縺ｫ繧ゅヰ繝・け繧｢繝・・菫晏ｭ・      await _backupMemosToSharedPreferences();
      
      debugPrint('笨・譛咲畑繝｡繝｢蜑企勁螳御ｺ・ $memoId');
    } catch (e, stackTrace) {
      debugPrint('笶・譛咲畑繝｡繝｢蜑企勁繧ｨ繝ｩ繝ｼ: $e');
      debugPrint('繧ｹ繧ｿ繝・け繝医Ξ繝ｼ繧ｹ: $stackTrace');
      
      // 笨・繧ｨ繝ｩ繝ｼ譎ゅｂSharedPreferences縺ｫ菫晏ｭ倥ｒ隧ｦ陦・      try {
        await _backupMemosToSharedPreferences();
        debugPrint('笨・繝輔か繝ｼ繝ｫ繝舌ャ繧ｯ菫晏ｭ俶・蜉・);
      } catch (backupError) {
        debugPrint('笶・繝輔か繝ｼ繝ｫ繝舌ャ繧ｯ菫晏ｭ倥ｂ螟ｱ謨・ $backupError');
      }
    }
  }
  
  // 笨・譁ｰ隕剰ｿｽ蜉・壹Μ繝医Λ繧､讖溯・莉倥″縺ｮ譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ
  Future<void> _loadMedicationMemosWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('売 譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ隧ｦ陦・$attempt/$maxRetries');
        
        // Hive繝懊ャ繧ｯ繧ｹ縺碁幕縺・※縺・ｋ縺狗｢ｺ隱・        if (!Hive.isBoxOpen('medication_memos')) {
          debugPrint('笞・・medication_memos繝懊ャ繧ｯ繧ｹ縺碁幕縺・※縺・∪縺帙ｓ縲ょ・蠎ｦ髢九″縺ｾ縺・..');
          await Hive.openBox<MedicationMemo>('medication_memos');
        }
        
        // 繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ
        final memos = await AppPreferences.loadMedicationMemos();
        
        if (memos.isNotEmpty || attempt == maxRetries) {
          setState(() {
            _medicationMemos = memos;
          });
          debugPrint('笨・譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ謌仙粥: ${memos.length}莉ｶ・郁ｩｦ陦・attempt蝗樒岼・・);
          return;
        }
        
        // 繝・・繧ｿ縺檎ｩｺ縺ｮ蝣ｴ蜷医∵ｬ｡縺ｮ隧ｦ陦悟燕縺ｫ蟆代＠蠕・▽
        if (attempt < maxRetries) {
          debugPrint('笞・・繝・・繧ｿ縺檎ｩｺ縺ｧ縺吶・{attempt + 1}蝗樒岼縺ｮ隧ｦ陦後ｒ螳溯｡後＠縺ｾ縺・..');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
    } catch (e) {
        debugPrint('笶・譛咲畑繝｡繝｢隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ・郁ｩｦ陦・attempt蝗樒岼・・ $e');
        
        if (attempt == maxRetries) {
          debugPrint('笶・譛螟ｧ隧ｦ陦悟屓謨ｰ縺ｫ驕斐＠縺ｾ縺励◆縲ゅヰ繝・け繧｢繝・・縺九ｉ蠕ｩ蜈・ｒ隧ｦ縺ｿ縺ｾ縺・..');
          // 繝舌ャ繧ｯ繧｢繝・・縺九ｉ蠕ｩ蜈・ｒ隧ｦ縺ｿ繧・          await _restoreMedicationMemosFromBackup();
        } else {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
  }
  
  // 笨・譁ｰ隕剰ｿｽ蜉・壹ヰ繝・け繧｢繝・・縺九ｉ縺ｮ蠕ｩ蜈・  Future<void> _restoreMedicationMemosFromBackup() async {
    try {
      debugPrint('売 繝舌ャ繧ｯ繧｢繝・・縺九ｉ譛咲畑繝｡繝｢繧貞ｾｩ蜈・ｸｭ...');
      final prefs = await SharedPreferences.getInstance();
      
      // 隍・焚縺ｮ繝舌ャ繧ｯ繧｢繝・・繧ｭ繝ｼ繧定ｩｦ縺・      final backupKeys = [
        'medication_memos_backup',
        'medication_memos_backup2',
        'medication_memos_backup3',
      ];
      
      for (final key in backupKeys) {
        final backupJson = prefs.getString(key);
        if (backupJson != null && backupJson.isNotEmpty) {
          try {
            final List<dynamic> memosList = jsonDecode(backupJson);
            final memos = memosList
                .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
                .toList();
            
            if (memos.isNotEmpty) {
              // Hive繝懊ャ繧ｯ繧ｹ縺ｫ蠕ｩ蜈・              final box = Hive.box<MedicationMemo>('medication_memos');
              await box.clear();
              for (final memo in memos) {
                await box.put(memo.id, memo);
              }
      
      setState(() {
        _medicationMemos = memos;
      });
      
              debugPrint('笨・繝舌ャ繧ｯ繧｢繝・・縺九ｉ蠕ｩ蜈・・蜉・ ${memos.length}莉ｶ ($key)');
      
              // 謌仙粥繝｡繝・そ繝ｼ繧ｸ繧定｡ｨ遉ｺ
      if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('繝舌ャ繧ｯ繧｢繝・・縺九ｉ${memos.length}莉ｶ縺ｮ繝｡繝｢繧貞ｾｩ蜈・＠縺ｾ縺励◆'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              return;
      }
    } catch (e) {
            debugPrint('笞・・繝舌ャ繧ｯ繧｢繝・・隗｣譫舌お繝ｩ繝ｼ ($key): $e');
            continue;
          }
        }
      }
      
      debugPrint('笞・・蜈ｨ縺ｦ縺ｮ繝舌ャ繧ｯ繧｢繝・・縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ');
    } catch (e) {
      debugPrint('笶・繝舌ャ繧ｯ繧｢繝・・蠕ｩ蜈・お繝ｩ繝ｼ: $e');
    }
  }

  void _showSnackBar(String message) async {
    if (!mounted) return;
    try {
      final fontSize = await MedicationAlarmApp.getFontSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
    }
  }
  // 螳悟・縺ｫ菴懊ｊ逶ｴ縺輔ｌ縺溘き繝ｬ繝ｳ繝繝ｼ繧､繝吶Φ繝亥叙蠕・  List<Widget> _getEventsForDay(DateTime day) {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final weekday = day.weekday % 7;
      
      // 螳悟・縺ｫ菴懊ｊ逶ｴ縺輔ｌ縺溘メ繧ｧ繝・け
      bool hasMedications = false;
      bool allTaken = true;
      int takenCount = 0;
      int totalCount = 0;
      
      // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・繝√ぉ繝・け
      if (_addedMedications.isNotEmpty) {
        hasMedications = true;
        totalCount += _addedMedications.length;
        for (final medication in _addedMedications) {
          if (medication['isChecked'] == true) {
            takenCount++;
          } else {
            allTaken = false;
          }
        }
      }
      
      // 譛咲畑繝｡繝｢縺ｮ繝√ぉ繝・け
      for (final memo in _medicationMemos) {
        if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
          hasMedications = true;
          totalCount++;
          if (_medicationMemoStatus[memo.id] == true) {
            takenCount++;
          } else {
            allTaken = false;
          }
        }
      }
      
      // 螳悟・縺ｫ菴懊ｊ逶ｴ縺輔ｌ縺溘・繝ｼ繧ｯ陦ｨ遉ｺ・医☆縺ｹ縺ｦ縺ｮ繝槭・繧ｯ繧貞炎髯､・・      // 襍､荳ｸ繧貞性繧縺吶∋縺ｦ縺ｮ繝槭・繧ｯ繧貞炎髯､
      return [];
    } catch (e) {
      return [];
    }
  }
  // 譛咲畑險倬鹸縺ｮ莉ｶ謨ｰ繧貞叙蠕励☆繧九・繝ｫ繝代・繝｡繧ｽ繝・ラ
  int _getMedicationRecordCount() {
    return _addedMedications.length + _getMedicationsForSelectedDay().length;
  }




  Widget _buildCalendarTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 600;
        final isNarrowScreen = screenWidth < 360;
        
        return Column(
            children: [
            // 笨・繧ｹ繝ｯ繧､繝怜庄閭ｽ縺ｪ繧ｫ繝ｬ繝ｳ繝繝ｼ繧ｨ繝ｪ繧｢
              Expanded(
                flex: 1,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // 繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ騾夂衍繧貞・逅・                  return true;
                  },
                  child: SingleChildScrollView(
          controller: _calendarScrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
          padding: EdgeInsets.symmetric(
                        horizontal: isNarrowScreen ? 8 : screenWidth * 0.05,
                        vertical: isSmallScreen ? 4 : 8,
          ),
          child: Column(
            children: [
                          // 繝｡繝｢繝輔ぅ繝ｼ繝ｫ繝・              if (_selectedDay != null)
                Container(
                              margin: const EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.fromLTRB(
                                isSmallScreen ? 8 : (isNarrowScreen ? 12 : 16),
                                0,
                                isSmallScreen ? 8 : (isNarrowScreen ? 12 : 16),
                                isSmallScreen ? 8 : (isNarrowScreen ? 12 : 16),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '莉頑律縺ｮ繝｡繝｢',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      _buildMemoField(),
                    ],
                  ),
                ),
                        
                            // 笨・繧ｫ繝ｬ繝ｳ繝繝ｼ譛ｬ菴難ｼ医せ繝ｯ繧､繝玲､懷・繧呈隼蝟・ｼ・                            GestureDetector(
                              // 笨・菫ｮ豁｣・壹せ繝ｯ繧､繝励ｒ遒ｺ螳溘↓讀懷・
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragStart: (_) {
                                // 繝峨Λ繝・げ髢句ｧ九ｒ讀懷・
                                debugPrint('繧ｫ繝ｬ繝ｳ繝繝ｼ: 繝峨Λ繝・げ髢句ｧ・);
                              },
                              onVerticalDragUpdate: (details) {
                                // 繧ｹ繝ｯ繧､繝励・譁ｹ蜷代→霍晞屬繧呈､懷・
                                final delta = details.delta.dy;
                                
                                if (delta < -3) { // 荳翫せ繝ｯ繧､繝暦ｼ域─蠎ｦ繧定ｪｿ謨ｴ・・                                  // 荳九↓繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ・域恪逕ｨ險倬鹸繧定｡ｨ遉ｺ・・                                  if (_calendarScrollController.hasClients) {
                                    final maxScroll = _calendarScrollController.position.maxScrollExtent;
                                    final currentScroll = _calendarScrollController.offset;
                                    final targetScroll = (currentScroll + 30).clamp(0.0, maxScroll);
                                    
                                    _calendarScrollController.animateTo(
                                      targetScroll,
                                      duration: const Duration(milliseconds: 100),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                } else if (delta > 3) { // 荳九せ繝ｯ繧､繝暦ｼ域─蠎ｦ繧定ｪｿ謨ｴ・・                                  // 荳翫↓繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ・医き繝ｬ繝ｳ繝繝ｼ繧定｡ｨ遉ｺ・・                                  if (_calendarScrollController.hasClients) {
                                    final currentScroll = _calendarScrollController.offset;
                                    final targetScroll = (currentScroll - 30).clamp(0.0, double.infinity);
                                    
                                    _calendarScrollController.animateTo(
                                      targetScroll,
                                      duration: const Duration(milliseconds: 100),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                }
                              },
                              onVerticalDragEnd: (details) {
                                // 繝峨Λ繝・げ邨ゆｺ・凾縺ｮ蜃ｦ逅・                                final velocity = details.primaryVelocity ?? 0;
                                
                                if (!_calendarScrollController.hasClients) return;
                                
                                if (velocity < -300) { // 荳翫せ繝ｯ繧､繝暦ｼ磯溘＞・・                                  // 譛咲畑險倬鹸縺ｾ縺ｧ荳豌励↓繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ
                                  _calendarScrollController.animateTo(
                                    _calendarScrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                } else if (velocity > 300) { // 荳九せ繝ｯ繧､繝暦ｼ磯溘＞・・                                  // 繧ｫ繝ｬ繝ｳ繝繝ｼ縺ｾ縺ｧ荳豌励↓繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ
                                  _calendarScrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              child: SizedBox(
                            height: 350,
                child: Container(
                decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                              child: Stack(
                                children: [
                                      // 繧ｫ繝ｬ繝ｳ繝繝ｼ譛ｬ菴・                                      ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                    child: TableCalendar<dynamic>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      eventLoader: _getEventsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      locale: 'ja_JP', // 譌･譛ｬ隱槭Ο繧ｱ繝ｼ繝ｫ・・nitializeDateFormatting縺ｧ蛻晄悄蛹匁ｸ医∩・・                                          // 笨・繧ｫ繝ｬ繝ｳ繝繝ｼ迢ｬ閾ｪ縺ｮ繧ｸ繧ｧ繧ｹ繝√Ε繝ｼ繧堤┌蜉ｹ蛹・                                          availableGestures: AvailableGestures.none,
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                                        return _buildCalendarDay(day);
                                      },
                                      selectedBuilder: (context, day, focusedDay) {
                                        return _buildCalendarDay(day, isSelected: true);
                                      },
                                      todayBuilder: (context, day, focusedDay) {
                                        return _buildCalendarDay(day, isToday: true);
                                      },
                                    ),
                                    headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                                      titleTextStyle: const TextStyle(
                                        fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                                      leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                                      rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF667eea),
                              Color(0xFF764ba2),
                            ],
                          ),
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                                        fontSize: 12,
                          color: Colors.white,
                        ),
                        weekendStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                                        fontSize: 12,
                        ),
                      ),
                      calendarStyle: _buildCalendarStyle(),
                      onDaySelected: _onDaySelected,
                      selectedDayPredicate: (day) {
                        return _selectedDates.contains(_normalizeDate(day));
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                  ),
                ),
                                
                                      // 蟾ｦ荳奇ｼ壼ｷｦ遘ｻ蜍輔・繧ｿ繝ｳ
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                                        setState(() {});
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                      // 蜿ｳ荳奇ｼ壼承遘ｻ蜍輔・繧ｿ繝ｳ
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                                        setState(() {});
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                      // 蟾ｦ遏｢蜊ｰ繧｢繧､繧ｳ繝ｳ縺ｮ蜿ｳ蛛ｴ・夊牡螟画峩繧｢繧､繧ｳ繝ｳ
                                Positioned(
                                  top: 12,
                                        left: 60,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _changeDayColor,
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.palette,
                                          color: Colors.purple,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                                  ),
                            ),
                          ),
                        ),
                        
                          const SizedBox(height: 12),
                          
                          // 莉頑律縺ｮ譛咲畑迥ｶ豕∬｡ｨ遉ｺ
              if (_selectedDay != null)
                _buildMedicationStats(),
                          
              const SizedBox(height: 8),
                          
                          // 譛咲畑險倬鹸繧ｻ繧ｯ繧ｷ繝ｧ繝ｳ
              if (_selectedDay != null)
                _buildMedicationRecords(),
                          
              const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ),
          ),
          ],
        );
      },
    );
  }

  // 笨・竭｢竭｣ 繧ｫ繝ｬ繝ｳ繝繝ｼ縺ｮ譌･莉倥そ繝ｫ・域屆譌･繝槭・繧ｯ繝ｻ繝√ぉ繝・け繝槭・繧ｯ陦ｨ遉ｺ・・  Widget _buildCalendarDay(DateTime day, {bool isSelected = false, bool isToday = false}) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    // 竭｢譛咲畑繝｡繝｢縺ｧ險ｭ螳壹＆繧後◆譖懈律縺九メ繧ｧ繝・け
    final hasScheduledMemo = _medicationMemos.any((memo) => 
      memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)
    );
    
    // 竭｣譛咲畑險倬鹸縺・00%縺九メ繧ｧ繝・け
    final stats = _calculateDayMedicationStats(day);
    final total = stats['total'] ?? 0;
    final taken = stats['taken'] ?? 0;
    final isComplete = total > 0 && taken == total;
    
    // 繧ｫ繧ｹ繧ｿ繝濶ｲ蜿門ｾ・    final customColor = _dayColors[dateStr];
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: customColor ?? 
          (isSelected 
            ? const Color(0xFFff6b6b)
            : isToday 
              ? const Color(0xFF4ecdc4)
              : Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
        border: hasScheduledMemo 
          ? Border.all(color: Colors.amber, width: 2)
          : null,
        boxShadow: isSelected || isToday
          ? [
              BoxShadow(
                color: (customColor ?? (isSelected ? const Color(0xFFff6b6b) : const Color(0xFF4ecdc4))).withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
      ),
      child: Stack(
        children: [
          // 譌･莉・          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          
          // 竭｢譖懈律繝槭・繧ｯ・亥ｷｦ荳奇ｼ・          if (hasScheduledMemo)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          
          // 竭｣螳御ｺ・メ繧ｧ繝・け繝槭・繧ｯ・亥承荳具ｼ・          if (isComplete)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 譌･蛻･縺ｮ譛咲畑邨ｱ險医ｒ險育ｮ・  Map<String, int> _calculateDayMedicationStats(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・邨ｱ險・    if (_medicationData.containsKey(dateStr)) {
      final dayData = _medicationData[dateStr]!;
      totalMedications += dayData.length;
      takenMedications += dayData.values.where((info) => info.checked).length;
    }
    
    // 譛咲畑繝｡繝｢縺ｮ邨ｱ險・    for (final memo in _medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications += memo.dosageFrequency;
        final checkedCount = _getMedicationMemoCheckedCountForDate(memo.id, dateStr);
        takenMedications += checkedCount;
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  // 謖・ｮ壽律縺ｮ繝｡繝｢縺ｮ譛咲畑貂医∩蝗樊焚繧貞叙蠕・  int _getMedicationMemoCheckedCountForDate(String memoId, String dateStr) {
    final doseStatus = _weekdayMedicationDoseStatus[dateStr]?[memoId];
    if (doseStatus == null) return 0;
    return doseStatus.values.where((isChecked) => isChecked).length;
  }

  // 譌･莉倥・濶ｲ繧貞､画峩縺吶ｋ繝｡繧ｽ繝・ラ
  void _changeDayColor() {
    if (_selectedDay == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final colors = [
      {'color': const Color(0xFFff6b6b), 'name': '襍､'},
      {'color': const Color(0xFF4ecdc4), 'name': '髱堤ｷ・},
      {'color': const Color(0xFF45b7d1), 'name': '髱・},
      {'color': const Color(0xFFf9ca24), 'name': '鮟・牡'},
      {'color': const Color(0xFFf0932b), 'name': '繧ｪ繝ｬ繝ｳ繧ｸ'},
      {'color': const Color(0xFFeb4d4b), 'name': '繝斐Φ繧ｯ'},
      {'color': const Color(0xFF6c5ce7), 'name': '邏ｫ'},
      {'color': const Color(0xFFa29bfe), 'name': '阮・ｴｫ'},
      {'color': const Color(0xFF00d2d3), 'name': '繧ｿ繝ｼ繧ｳ繧､繧ｺ'},
      {'color': const Color(0xFF1e3799), 'name': '豼・ｴｺ'},
      {'color': const Color(0xFFe55039), 'name': '繝医・繝・},
      {'color': const Color(0xFF2ecc71), 'name': '繧ｨ繝｡繝ｩ繝ｫ繝・},
    ];
    
    // 濶ｲ驕ｸ謚槭ム繧､繧｢繝ｭ繧ｰ繧定｡ｨ遉ｺ
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '繧ｫ繝ｬ繝ｳ繝繝ｼ縺ｮ濶ｲ繧帝∈謚・,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // 鬮倥＆繧貞宛髯・            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(), // 繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ蜿ｯ閭ｽ
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 13.7,
                childAspectRatio: 1,
              ),
              itemCount: colors.length + 1, // +1 for "濶ｲ繧偵Μ繧ｻ繝・ヨ"
              itemBuilder: (context, index) {
                if (index == colors.length) {
                  // 濶ｲ繧偵Μ繧ｻ繝・ヨ繝懊ち繝ｳ・医ョ繝輔か繝ｫ繝郁牡縺ｫ謌ｻ縺呻ｼ・                  return GestureDetector(
                    onTap: () async {
                      // 笨・霑ｽ蜉・壼､画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
                      await _saveSnapshotBeforeChange('繧ｫ繝ｬ繝ｳ繝繝ｼ濶ｲ繝ｪ繧ｻ繝・ヨ_$dateStr');
                      setState(() {
                        // 繝・ヵ繧ｩ繝ｫ繝郁牡・井ｽ輔ｂ謖・ｮ壹＠縺ｦ縺・↑縺・怙蛻昴・濶ｲ・峨↓謌ｻ縺・                        _dayColors.remove(dateStr);
                        _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
                      });
                      await _saveDayColors(); // 繝・・繧ｿ菫晏ｭ・                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey, width: 2),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.clear, color: Colors.grey, size: 32),
                          SizedBox(height: 4),
                          Text(
                            '繝ｪ繧ｻ繝・ヨ',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final colorData = colors[index];
                final color = colorData['color'] as Color;
                final name = colorData['name'] as String;
                final isSelected = _dayColors[dateStr] == color;
                
                return GestureDetector(
                  onTap: () async {
                    // 笨・霑ｽ蜉・壼､画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
                    await _saveSnapshotBeforeChange('繧ｫ繝ｬ繝ｳ繝繝ｼ濶ｲ螟画峩_${dateStr}_$name');
                    setState(() {
                      _dayColors[dateStr] = color;
                      _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
                    });
                    await _saveDayColors(); // 繝・・繧ｿ菫晏ｭ・                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 32,
                          )
                        else
                          const SizedBox(height: 32),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMedicationRecords() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 譛蟆上し繧､繧ｺ縺ｫ蛻ｶ髯・        children: [
          // 繝倥ャ繝繝ｼ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // 繝代ョ繧｣繝ｳ繧ｰ蜑頑ｸ・            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${DateFormat('yyyy蟷ｴM譛・譌･', 'ja_JP').format(_selectedDay!)}縺ｮ譛咲畑險倬鹸',
                  style: const TextStyle(
                    fontSize: 18, // 繝輔か繝ｳ繝医し繧､繧ｺ蜑頑ｸ・                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4), // 髢馴囈蜑頑ｸ・                Text(
                  '莉頑律縺ｮ譛咲畑迥ｶ豕√ｒ遒ｺ隱阪＠縺ｾ縺励ｇ縺・,
                  style: TextStyle(
                    fontSize: 12, // 繝輔か繝ｳ繝医し繧､繧ｺ蜑頑ｸ・                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 螳悟・縺ｫ菴懊ｊ逶ｴ縺輔ｌ縺滓恪逕ｨ險倬鹸繝ｪ繧ｹ繝・          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  // 繝｡繝｢驕ｸ謚樊凾縺ｯ驕ｸ謚槭＆繧後◆繝｡繝｢縺ｮ縺ｿ陦ｨ遉ｺ
                  if (_isMemoSelected && _selectedMemo != null) ...[
                    // 謌ｻ繧九・繧ｿ繝ｳ
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isMemoSelected = false;
                            _selectedMemo = null;
                          });
                        },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                    children: [
                                  Icon(Icons.arrow_back, color: Colors.blue, size: 16),
                                  const SizedBox(width: 8),
                            Text(
                                    '謌ｻ繧・,
                              style: TextStyle(
                                      color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                              ),
                        ),
                      ),
                    ],
                  ),
                    ),
                    _buildWeekdayMedicationRecord(_selectedMemo!)
                  ] else ...[
                    // 繧ｫ繝ｬ繝ｳ繝繝ｼ荳九・菴咲ｽｮ繝槭・繧ｫ繝ｼ
                    SizedBox(
                      key: _calendarBottomKey,
                      height: 1, // 隕九∴縺ｪ縺・・繝ｼ繧ｫ繝ｼ
                    ),
                    // 笨・菫ｮ豁｣・壽恪逕ｨ險倬鹸繝ｪ繧ｹ繝茨ｼ医・繝ｼ繧ｸ繧√￥繧頑婿蠑上・SizedBox・・                    _getMedicationListLength() == 0
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4, // MediaQuery菴ｿ逕ｨ
                            child: _buildNoMedicationMessage(),
                          )
                        : SizedBox(
                            height: 400, // 蝗ｺ螳夐ｫ倥＆繧定ｨｭ螳・                            child: PageView.builder(
                              controller: _medicationPageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentMedicationPage = index;
                                });
                              },
                              itemCount: _getMedicationListLength(),
                              itemBuilder: (context, index) {
                                return _buildMedicationItem(index);
                              },
                            ),
                          ),
                    // 譛咲畑謨ｰ縺ｮ陦ｨ遉ｺUI・医Γ繝｢0縺ｮ縺ｨ縺阪・陦ｨ遉ｺ縺励↑縺・ｼ・                    if (_getMedicationListLength() > 0 && _getMedicationListLength() != 1)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Text(
                          '${_currentMedicationPage + 1}/${_getMedicationListLength()} 譛咲畑縺ｮ謨ｰ',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // 繝壹・繧ｸ繧√￥繧翫・繧ｿ繝ｳ
                    if (_getMedicationListLength() > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _currentMedicationPage > 0 ? () {
                                  _medicationPageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentMedicationPage > 0 ? Colors.blue : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '蜑阪・\n譛咲畑蜀・ｮｹ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _currentMedicationPage < _getMedicationListLength() - 1 ? () {
                                  _medicationPageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentMedicationPage < _getMedicationListLength() - 1 ? Colors.blue : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '谺｡縺ｮ\n譛咲畑蜀・ｮｹ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
            ),
          ),
          // 繝輔ャ繧ｿ繝ｼ邨ｱ險茨ｼ亥炎髯､・・        ],
      ),
    );
  }

  // 螳牙・縺ｪ譛螟ｧ鬮倥＆繧定ｨ育ｮ励☆繧矩未謨ｰ

  // 譛咲畑險倬鹸繝ｪ繧ｹ繝医・髟ｷ縺輔ｒ蜿門ｾ・  int _getMedicationListLength() {
    final addedCount = _addedMedications.length;
    final memoCount = _getMedicationsForSelectedDay().length;
    final hasNoData = addedCount == 0 && memoCount == 0;
    return addedCount + memoCount + (hasNoData ? 1 : 0);
  }

  // 譛咲畑險倬鹸繧｢繧､繝・Β繧呈ｧ狗ｯ・  Widget _buildMedicationItem(int index) {
    final addedCount = _addedMedications.length;
    final memoCount = _getMedicationsForSelectedDay().length;
    
    if (index < addedCount) {
      // 霑ｽ蜉縺輔ｌ縺溯脈
      return _buildAddedMedicationRecord(_addedMedications[index]);
    } else if (index < addedCount + memoCount) {
      // 譛咲畑繝｡繝｢
      final memoIndex = index - addedCount;
      return _buildMedicationMemoCheckbox(_getMedicationsForSelectedDay()[memoIndex]);
    } else {
      // 繝・・繧ｿ縺ｪ縺励Γ繝・そ繝ｼ繧ｸ
      return _buildNoMedicationMessage();
    }
  }

  // 譛咲畑繝｡繝｢縺梧悴霑ｽ蜉縺ｮ蝣ｴ蜷医・繝｡繝・そ繝ｼ繧ｸ陦ｨ遉ｺ
  Widget _buildNoMedicationMessage() {
    return Container(
      height: 450, // 鬮倥＆繧・50px縺ｫ險ｭ螳・      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '譛咲畑繝｡繝｢縺九ｉ譛咲畑繧ｹ繧ｱ繧ｸ繝･繝ｼ繝ｫ\n(豈取律縲∵屆譌･)繧帝∈謚槭＠縺ｦ縺上□縺輔＞',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '譛咲畑繝｡繝｢繧ｿ繝悶〒阮ｬ蜩√ｄ繧ｵ繝励Μ繝｡繝ｳ繝医ｒ霑ｽ蜉縺励※縺九ｉ縲―n繧ｫ繝ｬ繝ｳ繝繝ｼ繝壹・繧ｸ縺ｧ譛咲畑繧ｹ繧ｱ繧ｸ繝･繝ｼ繝ｫ繧堤ｮ｡逅・〒縺阪∪縺吶・,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // 譛咲畑繝｡繝｢繧ｿ繝悶↓蛻・ｊ譖ｿ縺・              _tabController.animateTo(1);
            },
            icon: const Icon(Icons.add),
            label: const Text('譛咲畑繝｡繝｢繧定ｿｽ蜉'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 譛咲畑繝｡繝｢縺ｮ繝√ぉ繝・け繝懊ャ繧ｯ繧ｹ・医き繝ｬ繝ｳ繝繝ｼ繝壹・繧ｸ逕ｨ繝ｻ諡｡螟ｧ迚茨ｼ・  Widget _buildMedicationMemoCheckbox(MedicationMemo memo) {
    final isSelected = _isMemoSelected && _selectedMemo?.id == memo.id;
    // 譛咲畑蝗樊焚縺ｫ蠢懊§縺溘メ繧ｧ繝・け迥ｶ豕√ｒ蜿門ｾ・    final checkedCount = _getMedicationMemoCheckedCountForSelectedDay(memo.id);
    final totalCount = memo.dosageFrequency;
    
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.blue 
                : checkedCount == totalCount 
                    ? Colors.green 
                    : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : checkedCount == totalCount ? 1.5 : 1,
          ),
          color: isSelected 
              ? Colors.blue.withOpacity(0.1)
              : checkedCount == totalCount 
                  ? Colors.green.withOpacity(0.05) 
                  : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 荳企Κ・壹い繧､繧ｳ繝ｳ縲∬脈蜷阪∵恪逕ｨ蝗樊焚諠・ｱ
              Row(
                children: [
                  // 螟ｧ縺阪↑繧｢繧､繧ｳ繝ｳ
                  CircleAvatar(
                    backgroundColor: memo.color,
                    radius: 20,
                    child: Icon(
                      memo.type == '繧ｵ繝励Μ繝｡繝ｳ繝・ ? Icons.eco : Icons.medication,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 阮ｬ蜷阪→遞ｮ鬘・                        Text(
                          memo.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: checkedCount == totalCount ? Colors.green : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: checkedCount == totalCount ? Colors.green.withOpacity(0.2) : memo.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            memo.type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: checkedCount == totalCount ? Colors.green : memo.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 譛咲畑蝗樊焚縺ｫ蠢懊§縺溘メ繧ｧ繝・け繝懊ャ繧ｯ繧ｹ
              const SizedBox(height: 12),
              Row(
                children: List.generate(totalCount, (index) {
                  final isChecked = _getMedicationMemoDoseStatusForSelectedDay(memo.id, index);
                  return Expanded(
                    child: Semantics(
                      label: '${memo.name}縺ｮ譛咲畑險倬鹸 ${index + 1}蝗樒岼',
                      hint: '繧ｿ繝・・縺励※譛咲畑迥ｶ諷九ｒ蛻・ｊ譖ｿ縺・,
                    child: GestureDetector(
                      onTap: () async {
                        if (_selectedDay != null) {
                          // 笨・霑ｽ蜉・壼､画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
                          await _saveSnapshotBeforeChange('譛咲畑蝗樊焚繝√ぉ繝・け_${memo.name}_${index + 1}蝗樒岼_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                          final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
                          setState(() {
                            // 譌･莉伜挨縺ｮ譛咲畑繝｡繝｢迥ｶ諷九ｒ譖ｴ譁ｰ
                            _weekdayMedicationStatus.putIfAbsent(dateStr, () => {});
                            _weekdayMedicationDoseStatus.putIfAbsent(dateStr, () => {});
                            _weekdayMedicationDoseStatus[dateStr]!.putIfAbsent(memo.id, () => {});
                            _weekdayMedicationDoseStatus[dateStr]![memo.id]![index] = !isChecked;
                            
                            // 蜈ｨ菴薙・譛咲畑迥ｶ豕√ｒ譖ｴ譁ｰ・亥・蝗樊焚螳御ｺ・凾縺ｫ譛咲畑貂医∩・・                            final checkedCount = _getMedicationMemoCheckedCountForSelectedDay(memo.id);
                            final totalCount = memo.dosageFrequency;
                            _weekdayMedicationStatus[dateStr]![memo.id] = checkedCount == totalCount;
                            _medicationMemoStatus[memo.id] = checkedCount == totalCount;
                          });
                          // 繝・・繧ｿ菫晏ｭ・                          await _saveAllData();
                          // 邨ｱ險医ｒ蜀崎ｨ育ｮ・                          await _calculateAdherenceStats();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isChecked ? Colors.green : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isChecked ? Colors.green : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isChecked ? Colors.white : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${index + 1}蝗樒岼',
                              style: TextStyle(
                                fontSize: 10,
                                color: isChecked ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // 譛咲畑蝗樊焚諠・ｱ
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '譛咲畑蝗樊焚: ${memo.dosageFrequency}蝗・(${checkedCount}/${totalCount})',
                      style: TextStyle(
                        fontSize: 14,
                        color: checkedCount == totalCount ? Colors.green : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (memo.dosageFrequency >= 6) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _showWarningDialog(context);
                        },
                        child: const Icon(Icons.warning, size: 16, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),
              // 逕ｨ驥乗ュ蝣ｱ
              if (memo.dosage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.straighten, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '逕ｨ驥・ ${memo.dosage}',
                        style: TextStyle(
                          fontSize: 14,
                          color: checkedCount == totalCount ? Colors.green : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // 繝｡繝｢諠・ｱ・医ち繝・・蜿ｯ閭ｽ・・              if (memo.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    _showMemoDetailDialog(context, memo.name, memo.notes);
                  },
                  child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.note, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            '繝｡繝｢',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        memo.notes,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                          maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                        const SizedBox(height: 4),
                        Text(
                          '繧ｿ繝・・縺励※繝｡繝｢繧定｡ｨ遉ｺ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }

  // 繝｡繝｢隧ｳ邏ｰ繝繧､繧｢繝ｭ繧ｰ繧定｡ｨ遉ｺ
  void _showMemoDetailDialog(BuildContext context, String medicationName, String memo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 繝倥ャ繝繝ｼ
              Row(
                children: [
                  const Icon(Icons.note, size: 24, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$medicationName 縺ｮ繝｡繝｢',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 20),
              // 繝｡繝｢蜀・ｮｹ
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Text(
                      memo,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 繝輔ャ繧ｿ繝ｼ繝懊ち繝ｳ
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('髢峨§繧・),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 繝壹・繧ｸ繝阪・繧ｷ繝ｧ繝ｳ讖溯・・亥､ｧ驥上ョ繝ｼ繧ｿ蟇ｾ蠢懶ｼ・  static const int _pageSize = 20; // 1繝壹・繧ｸ縺ゅ◆繧翫・莉ｶ謨ｰ
  int _currentPage = 0;
  List<MedicationMemo> _displayedMemos = [];
  bool _isLoadingMore = false;
  final ScrollController _memoScrollController = ScrollController();
  
  // 繧｢繝ｩ繝ｼ繝蛻ｶ髯先ｩ溯・
  static const int maxAlarms = 100; // 繧｢繝ｩ繝ｼ繝荳企剞
  static const int maxMemos = 1000; // 繝｡繝｢荳企剞

  // Hive譛驕ｩ蛹悶ョ繝ｼ繧ｿ繝吶・繧ｹ繧ｵ繝ｼ繝薙せ・亥､ｧ驥上ョ繝ｼ繧ｿ蟇ｾ蠢懶ｼ・  static Box<MedicationMemo>? _memoBox;
  
  static Future<Box<MedicationMemo>> get _getMemoBox async {
    if (_memoBox != null) return _memoBox!;
    _memoBox = await Hive.openBox<MedicationMemo>('medication_memos');
    return _memoBox!;
  }
  
  // 繝壹・繧ｸ繝阪・繧ｷ繝ｧ繝ｳ莉倥″繝｡繝｢蜿門ｾ・  static Future<List<MedicationMemo>> getMemos({
    int limit = 20,
    int offset = 0,
  }) async {
    final box = await _getMemoBox;
    final allMemos = box.values.toList();
    allMemos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allMemos.skip(offset).take(limit).toList();
  }
  
  // 讀懃ｴ｢讖溯・
  static Future<List<MedicationMemo>> searchMemos(String keyword) async {
    final box = await _getMemoBox;
    return box.values
        .where((memo) => memo.name.toLowerCase().contains(keyword.toLowerCase()))
        .take(50)
        .toList();
  }
  
  // 繝｡繝｢菫晏ｭ・  static Future<void> saveMemo(MedicationMemo memo) async {
    final box = await _getMemoBox;
    await box.put(memo.id, memo);
  }
  
  // 繝｡繝｢蜑企勁
  static Future<void> deleteMemo(String id) async {
    final box = await _getMemoBox;
    await box.delete(id);
  }
  
  // 繝ｪ繧｢繧ｯ繝・ぅ繝悶せ繝医Μ繝ｼ繝
  static Stream<List<MedicationMemo>> watchMemos() async* {
    final box = await _getMemoBox;
    yield box.values.toList();
    yield* box.watch().map((_) => box.values.toList());
  }

  // 邨ｱ荳繝・・繧ｿ繧ｵ繝ｼ繝薙せ・磯㍾隍・炎髯､・・  Future<void> _saveAllDataUnified() async {
    try {
      await Future.wait([
        _saveMedicationData(),
        _saveMemoStatus(),
        _saveAlarmData(),
        _saveUserPreferences(),
        _saveAppSettings(),
      ]);
      debugPrint('邨ｱ荳繝・・繧ｿ繧ｵ繝ｼ繝薙せ: 蜈ｨ繝・・繧ｿ菫晏ｭ伜ｮ御ｺ・);
    } catch (e) {
      debugPrint('邨ｱ荳繝・・繧ｿ繧ｵ繝ｼ繝薙せ菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  Future<void> _loadAllDataUnified() async {
    try {
      await Future.wait([
        _loadMedicationData(),
        _loadMemoStatus(),
        _loadAlarmData(),
        _loadUserPreferences(),
        _loadAppSettings(),
      ]);
      debugPrint('邨ｱ荳繝・・繧ｿ繧ｵ繝ｼ繝薙せ: 蜈ｨ繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・);
    } catch (e) {
      debugPrint('邨ｱ荳繝・・繧ｿ繧ｵ繝ｼ繝薙せ隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
    }
  }

  // 繝壹・繧ｸ繝阪・繧ｷ繝ｧ繝ｳ讖溯・縺ｮ螳溯｣・  Future<void> _loadMoreMemos() async {
    if (_isLoadingMore || _currentPage * _pageSize >= _medicationMemos.length) return;
    
    setState(() => _isLoadingMore = true);
    
    // 繝壹・繧ｸ繝ｳ繧ｰ縺ｧ荳驛ｨ縺縺題ｪｭ縺ｿ霎ｼ縺ｿ
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, _medicationMemos.length);
      
      if (startIndex < _medicationMemos.length) {
        final newMemos = _medicationMemos.sublist(startIndex, endIndex);
        
        setState(() {
          _displayedMemos.addAll(newMemos);
          _currentPage++;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
    }
  }
  
  // 繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ逶｣隕悶・蛻晄悄蛹・  void _initializeScrollListener() {
    _memoScrollController.addListener(() {
      if (_memoScrollController.position.pixels >= 
          _memoScrollController.position.maxScrollExtent * 0.8) {
        _loadMoreMemos();
      }
    });
  }
  
  // 繧｢繝ｩ繝ｼ繝蛻ｶ髯舌メ繧ｧ繝・け
  bool _canAddAlarm() {
    return _alarmList.length < maxAlarms;
  }
  
  // 繝｡繝｢蛻ｶ髯舌メ繧ｧ繝・け
  bool _canAddMemo() {
    return _medicationMemos.length < maxMemos;
  }
  
  // 蛻ｶ髯舌ム繧､繧｢繝ｭ繧ｰ陦ｨ遉ｺ
  void _showLimitDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text('${type}荳企剞'),
          ],
        ),
        content: Text('${type}縺ｯ譛螟ｧ${type == '繧｢繝ｩ繝ｼ繝' ? maxAlarms : maxMemos}莉ｶ縺ｾ縺ｧ險ｭ螳壹〒縺阪∪縺吶・n荳崎ｦ√↑${type}繧貞炎髯､縺励※縺上□縺輔＞縲・),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('莠・ｧ｣'),
          ),
        ],
      ),
    );
  }

  // 譛咲畑貂医∩縺ｫ霑ｽ蜉・育ｰ｡邏蛹也沿・・  void _addToTakenMedications(MedicationMemo memo) {
    if (_selectedDay == null) return;
    
    // 驥崎､・メ繧ｧ繝・け
    final existingIndex = _addedMedications.indexWhere((med) => med['id'] == memo.id);
    
    if (existingIndex == -1) {
      // 譁ｰ隕剰ｿｽ蜉
      _addedMedications.add({
        'id': memo.id,
        'name': memo.name,
        'type': memo.type,
        'dosage': memo.dosage,
        'color': memo.color,
        'taken': true,
        'takenTime': DateTime.now(),
        'notes': memo.notes,
      });
    } else {
      // 譌｢蟄倥・繧ゅ・繧呈峩譁ｰ
      _addedMedications[existingIndex]['taken'] = true;
      _addedMedications[existingIndex]['takenTime'] = DateTime.now();
    }
    
    // 繝｡繝｢縺ｮ迥ｶ諷九ｒ譖ｴ譁ｰ
    _medicationMemoStatus[memo.id] = true;
    
    // 繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ繧定ｿｽ蜉・域恪逕ｨ迥ｶ豕√↓蜿肴丐・・    if (_selectedDay != null) {
      if (!_selectedDates.contains(_selectedDay!)) {
        _selectedDates.add(_selectedDay!);
      }
    }
    
    // 繝・・繧ｿ菫晏ｭ倥・縺ｿ
    _saveAllData();
  }
  
  // 譛咲畑貂医∩縺九ｉ蜑企勁・育ｰ｡邏蛹也沿・・  void _removeFromTakenMedications(String memoId) {
    _addedMedications.removeWhere((med) => med['id'] == memoId);
    
    // 縺昴・譌･縺ｮ譛咲畑繝｡繝｢縺後☆縺ｹ縺ｦ繝√ぉ繝・け縺輔ｌ縺ｦ縺・↑縺・ｴ蜷医√き繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ繧貞炎髯､
    if (_selectedDay != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      final hasCheckedMemos = _medicationMemoStatus.values.any((status) => status);
      if (!hasCheckedMemos && _addedMedications.isEmpty) {
        _selectedDates.remove(dateStr);
      }
    }
    
    // 繝・・繧ｿ菫晏ｭ倥・縺ｿ
    _saveAllData();
  }
  
  // 譛咲畑繝｡繝｢縺ｮ迥ｶ諷九ｒ譖ｴ譁ｰ
  void _updateMedicationMemoStatus(String memoId, bool isChecked) {
    setState(() {
      _medicationMemoStatus[memoId] = isChecked;
    });
    // 繝・・繧ｿ菫晏ｭ・    _saveAllData();
  }
  
  // 縺薙・縺輔ｓ豬・ｼ壽恪逕ｨ繝・・繧ｿ繧剃ｿ晏ｭ假ｼ育｢ｺ螳溘↑繝・・繧ｿ菫晄戟・・  Future<void> _saveMedicationData() async {
    try {
      if (_selectedDay != null) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final medicationData = <String, MedicationInfo>{};
        
        // _addedMedications縺九ｉMedicationInfo繧剃ｽ懈・
        for (final med in _addedMedications) {
          final name = med['name']?.toString() ?? '';
          final taken = med['taken'] is bool ? med['taken'] as bool : false;
          final takenTime = med['takenTime'] is DateTime ? med['takenTime'] as DateTime? : null;
          final notes = med['notes']?.toString() ?? '';
          
          medicationData[name] = MedicationInfo(
            checked: taken,
            medicine: name,
            actualTime: takenTime,
            notes: notes,
          );
        }
        
        // 縺薙・縺輔ｓ豬・ｼ啾wait繧堤｢ｺ螳溘↓莉倥￠縺ｦ菫晏ｭ・        await MedicationService.saveMedicationData({dateStr: medicationData});
        await _saveToSharedPreferences(dateStr, medicationData);
        await _saveMemoStatus();
        await _saveAdditionalBackup(dateStr, medicationData);
        
        // 譛咲畑阮ｬ繝・・繧ｿ繧ゆｿ晏ｭ・        await _saveMedicationList();
        
        // 繧｢繝ｩ繝ｼ繝繝・・繧ｿ繧ゆｿ晏ｭ・        await _saveAlarmData();
        
        debugPrint('蜈ｨ繝・・繧ｿ菫晏ｭ伜ｮ御ｺ・ $dateStr・医％縺ｱ縺輔ｓ豬・ｼ・);
      }
    } catch (e) {
      debugPrint('繝・・繧ｿ菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 霑ｽ蜉縺ｮ繝舌ャ繧ｯ繧｢繝・・菫晏ｭ・  Future<void> _saveAdditionalBackup(String dateStr, Map<String, MedicationInfo> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = <String, dynamic>{};
      
      for (final entry in data.entries) {
        dataJson[entry.key] = entry.value.toJson();
      }
      
      // 隍・焚縺ｮ繝舌ャ繧ｯ繧｢繝・・繧ｭ繝ｼ縺ｧ菫晏ｭ・      await prefs.setString('medication_backup_$dateStr', jsonEncode(dataJson));
      await prefs.setString('medication_backup_latest', jsonEncode(dataJson));
      await prefs.setString('last_save_date', dateStr);
      await prefs.setString('last_save_timestamp', DateTime.now().toIso8601String());
      
      // 蠑ｷ蛻ｶ逧・↓繝輔Λ繝・す繝･
      await prefs.commit();
      
      debugPrint('霑ｽ蜉繝舌ャ繧ｯ繧｢繝・・菫晏ｭ伜ｮ御ｺ・ $dateStr');
    } catch (e) {
      debugPrint('霑ｽ蜉繝舌ャ繧ｯ繧｢繝・・菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 縺薙・縺輔ｓ豬・ｼ壽恪逕ｨ阮ｬ繝・・繧ｿ繧剃ｿ晏ｭ假ｼ育｢ｺ螳溘↑繝・・繧ｿ菫晄戟・・  Future<void> _saveMedicationList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medicationListJson = <String, dynamic>{};
      
      // 譛咲畑阮ｬ繝ｪ繧ｹ繝医ｒ菫晏ｭ・      for (int i = 0; i < _addedMedications.length; i++) {
        final med = _addedMedications[i];
        medicationListJson['medication_$i'] = {
          'id': med['id'],
          'name': med['name'],
          'type': med['type'],
          'dosage': med['dosage'],
          'color': med['color'],
          'taken': med['taken'],
          'takenTime': med['takenTime']?.toIso8601String(),
          'notes': med['notes'],
        };
      }
      
      // 縺薙・縺輔ｓ豬・ｼ啾wait繧堤｢ｺ螳溘↓莉倥￠縺ｦ菫晏ｭ・      await prefs.setString('medicationList', jsonEncode(medicationListJson));
      await prefs.setString('medicationList_backup', jsonEncode(medicationListJson));
      await prefs.setInt('medicationList_count', _addedMedications.length);
      
      debugPrint('譛咲畑阮ｬ繝・・繧ｿ菫晏ｭ伜ｮ御ｺ・ ${_addedMedications.length}莉ｶ・医％縺ｱ縺輔ｓ豬・ｼ・);
    } catch (e) {
      debugPrint('譛咲畑阮ｬ繝・・繧ｿ菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 遒ｺ螳溘↑繧｢繝ｩ繝ｼ繝繝・・繧ｿ菫晏ｭ假ｼ域欠螳壹ヱ繧ｹ譁ｹ蠑上ｒ謗｡逕ｨ・・  Future<void> _saveAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 繧｢繝ｩ繝ｼ繝謨ｰ繧剃ｿ晏ｭ・      await prefs.setInt('alarm_count', _alarmList.length);
      
      // 蜷・い繝ｩ繝ｼ繝縺ｮ繝・・繧ｿ繧貞句挨縺ｫ菫晏ｭ假ｼ域欠螳壹ヱ繧ｹ譁ｹ蠑擾ｼ・      for (int i = 0; i < _alarmList.length; i++) {
        final alarm = _alarmList[i];
        await prefs.setString('alarm_${i}_name', alarm['name'] ?? '');
        await prefs.setString('alarm_${i}_time', alarm['time'] ?? '00:00');
        await prefs.setString('alarm_${i}_repeat', alarm['repeat'] ?? '荳蠎ｦ縺縺・);
        await prefs.setBool('alarm_${i}_enabled', alarm['enabled'] ?? true);
        await prefs.setString('alarm_${i}_alarmType', alarm['alarmType'] ?? 'sound');
        await prefs.setInt('alarm_${i}_volume', alarm['volume'] ?? 80);
        await prefs.setString('alarm_${i}_message', alarm['message'] ?? '阮ｬ繧呈恪逕ｨ縺吶ｋ譎る俣縺ｧ縺・);
      }
      
      // 繝舌ャ繧ｯ繧｢繝・・繧ゆｿ晏ｭ・      await prefs.setString('alarm_backup_count', _alarmList.length.toString());
      await prefs.setString('alarm_last_save', DateTime.now().toIso8601String());
      
      debugPrint('繧｢繝ｩ繝ｼ繝繝・・繧ｿ菫晏ｭ伜ｮ御ｺ・ ${_alarmList.length}莉ｶ・域欠螳壹ヱ繧ｹ譁ｹ蠑擾ｼ・);
    } catch (e) {
      debugPrint('繧｢繝ｩ繝ｼ繝繝・・繧ｿ菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // SharedPreferences縺ｫ繝舌ャ繧ｯ繧｢繝・・菫晏ｭ・  Future<void> _saveToSharedPreferences(String dateStr, Map<String, MedicationInfo> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = <String, dynamic>{};
      
      for (final entry in data.entries) {
        dataJson[entry.key] = entry.value.toJson();
      }
      
      await prefs.setString('medication_backup_$dateStr', jsonEncode(dataJson));
      await prefs.setString('last_save_date', dateStr);
      debugPrint('SharedPreferences繝舌ャ繧ｯ繧｢繝・・菫晏ｭ伜ｮ御ｺ・ $dateStr');
    } catch (e) {
      debugPrint('SharedPreferences菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 閥 譛驥崎ｦ・ｼ壹Γ繝｢縺ｮ迥ｶ諷九ｒ菫晏ｭ假ｼ亥ｮ悟・迚茨ｼ・  Future<void> _saveMemoStatus() async {
    try {
      final memoStatusJson = <String, dynamic>{};
      
      for (final entry in _medicationMemoStatus.entries) {
        memoStatusJson[entry.key] = entry.value;
      }
      
      // 閥 譛驥崎ｦ・ｼ啾wait繧堤｢ｺ螳溘↓莉倥￠縺ｦ菫晏ｭ・      await AppPreferences.saveString('medicationMemoStatus', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('medication_memo_status', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('memo_status_backup', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('last_memo_save', DateTime.now().toIso8601String());
      
      debugPrint('繝｡繝｢迥ｶ諷倶ｿ晏ｭ伜ｮ御ｺ・ ${memoStatusJson.length}莉ｶ・亥ｮ悟・迚茨ｼ・);
    } catch (e) {
      debugPrint('繝｡繝｢迥ｶ諷倶ｿ晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }
  
  // 閥 譛驥崎ｦ・ｼ壹Γ繝｢縺ｮ迥ｶ諷九ｒ隱ｭ縺ｿ霎ｼ縺ｿ・亥ｮ悟・迚茨ｼ・  Future<void> _loadMemoStatus() async {
    try {
      String? memoStatusStr;
      
      // 閥 譛驥崎ｦ・ｼ夊､・焚繧ｭ繝ｼ縺九ｉ隱ｭ縺ｿ霎ｼ縺ｿ・亥━蜈磯・ｽ堺ｻ倥″・・      final keys = ['medicationMemoStatus', 'medication_memo_status', 'memo_status_backup'];
      
      for (final key in keys) {
        memoStatusStr = AppPreferences.getString(key);
        if (memoStatusStr != null && memoStatusStr.isNotEmpty) {
          debugPrint('繝｡繝｢迥ｶ諷玖ｪｭ縺ｿ霎ｼ縺ｿ謌仙粥: $key・亥ｮ悟・迚茨ｼ・);
          break;
        }
      }
      
      if (memoStatusStr != null && memoStatusStr.isNotEmpty) {
        final memoStatusJson = jsonDecode(memoStatusStr) as Map<String, dynamic>;
        _medicationMemoStatus = memoStatusJson.map((key, value) => MapEntry(key, value as bool));
        debugPrint('繝｡繝｢迥ｶ諷玖ｪｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ ${_medicationMemoStatus.length}莉ｶ');
        
        // 閥 譛驥崎ｦ・ｼ啅I縺ｫ蜿肴丐
        if (mounted) {
    setState(() {
            // 菫晏ｭ倥＆繧後◆蛟､縺後≠繧後・縺昴ｌ繧剃ｽｿ縺・          });
        }
      } else {
        debugPrint('繝｡繝｢迥ｶ諷九ョ繝ｼ繧ｿ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ・亥・譛溷､繧剃ｽｿ逕ｨ・・);
        _medicationMemoStatus = {};
      }
    } catch (e) {
      debugPrint('繝｡繝｢迥ｶ諷玖ｪｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ: $e');
      _medicationMemoStatus = {};
    }
  }

  // 譛咲畑繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ諷九ｒ蜿門ｾ・  bool _getMedicationMemoStatus(String memoId) {
    return _medicationMemoStatus[memoId] ?? false;
  }
  
  // 驕ｸ謚槭＆繧後◆譌･莉倥・譛咲畑繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ諷九ｒ蜿門ｾ・  bool _getMedicationMemoStatusForSelectedDay(String memoId) {
    if (_selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    return _weekdayMedicationStatus[dateStr]?[memoId] ?? false;
  }
  
  // 謖・ｮ壽律縺ｮ繝｡繝｢縺ｮ譛咲畑蝗樊焚蛻･繝√ぉ繝・け迥ｶ豕√ｒ蜿門ｾ・  bool _getMedicationMemoDoseStatusForSelectedDay(String memoId, int doseIndex) {
    if (_selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    return _weekdayMedicationDoseStatus[dateStr]?[memoId]?[doseIndex] ?? false;
  }
  
  // 謖・ｮ壽律縺ｮ繝｡繝｢縺ｮ譛咲畑貂医∩蝗樊焚繧貞叙蠕・  int _getMedicationMemoCheckedCountForSelectedDay(String memoId) {
    if (_selectedDay == null) return 0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final doseStatus = _weekdayMedicationDoseStatus[dateStr]?[memoId];
    if (doseStatus == null) return 0;
    return doseStatus.values.where((isChecked) => isChecked).length;
  }
  
  // 繧｢繝励Μ蜀崎ｵｷ蜍墓凾縺ｮ繝・・繧ｿ陦ｨ遉ｺ繧堤｢ｺ螳溘↓縺吶ｋ
  Future<void> _ensureDataDisplayOnRestart() async {
    try {
      // 繝・・繧ｿ隱ｭ縺ｿ霎ｼ縺ｿ螳御ｺ・ｒ蠕・▽
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 驕ｸ謚槭＆繧後◆譌･莉倥・繝・・繧ｿ繧堤｢ｺ隱・      if (_selectedDay != null) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        debugPrint('蜀崎ｵｷ蜍募ｾ後ョ繝ｼ繧ｿ陦ｨ遉ｺ遒ｺ隱・ $dateStr');
        
        // 譛咲畑繝｡繝｢縺ｮ迥ｶ諷九ｒ蜀咲｢ｺ隱・        for (final memo in _medicationMemos) {
          if (!_medicationMemoStatus.containsKey(memo.id)) {
            _medicationMemoStatus[memo.id] = false;
          }
        }
        
        // UI繧貞ｼｷ蛻ｶ譖ｴ譁ｰ
        if (mounted) {
    setState(() {
            // 繝・・繧ｿ陦ｨ遉ｺ繧堤｢ｺ螳溘↓縺吶ｋ
          });
        }
        
        debugPrint('蜀崎ｵｷ蜍募ｾ後ョ繝ｼ繧ｿ陦ｨ遉ｺ螳御ｺ・ 繝｡繝｢${_medicationMemos.length}莉ｶ, 迥ｶ諷・{_medicationMemoStatus.length}莉ｶ');
      }
    } catch (e) {
      debugPrint('蜀崎ｵｷ蜍募ｾ後ョ繝ｼ繧ｿ陦ｨ遉ｺ繧ｨ繝ｩ繝ｼ: $e');
    }
  }


  // 螳悟・縺ｫ菴懊ｊ逶ｴ縺輔ｌ縺滓恪逕ｨ險倬鹸繝ｪ繧ｹ繝・  Widget _buildAddedMedicationRecord(Map<String, dynamic> medication) {
    final isChecked = medication['isChecked'] ?? false;
    final medicationName = medication['name'] ?? '';
    final medicationType = medication['type'] ?? '';
    final medicationColor = medication['color'] ?? Colors.blue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isChecked
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: isChecked 
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isChecked
              ? LinearGradient(
                  colors: [Colors.green.withOpacity(0.05), Colors.green.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24), // 繝代ョ繧｣繝ｳ繧ｰ繧貞｢怜刈
          child: Row(
            children: [
              // 螳悟・縺ｫ菴懊ｊ逶ｴ縺輔ｌ縺滓恪逕ｨ貂医∩繝√ぉ繝・け繝懊ャ繧ｯ繧ｹ
              GestureDetector(
                onTap: () async {
                  // 笨・霑ｽ蜉・壼､画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ・育憾諷句､画峩蜑搾ｼ・                  if (_selectedDay != null) {
                    await _saveSnapshotBeforeChange('譛咲畑繝√ぉ繝・け_${medicationName}_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                  }
                  
                  // 蠑ｷ蛻ｶ逧・↓迥ｶ諷九ｒ譖ｴ譁ｰ
                  setState(() {
                    medication['isChecked'] = !isChecked;
                  });
                  
                  // 繝・・繧ｿ繧貞叉蠎ｧ縺ｫ菫晏ｭ假ｼ磯≦蟒ｶ縺ｪ縺暦ｼ・                  _saveCurrentData();
                  
                  // 繧ｫ繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ繧呈峩譁ｰ
                  _updateCalendarMarks();
                  
                  // 邨ｱ險医ｒ蠑ｷ蛻ｶ蜀崎ｨ育ｮ・                  setState(() {
                    // 邨ｱ險医ｒ蠑ｷ蛻ｶ蜀崎ｨ育ｮ・                  });
                },
                child: Container(
                  width: 60, // 繧ｵ繧､繧ｺ繧貞､ｧ縺阪￥
                  height: 60,
                  decoration: BoxDecoration(
                    color: isChecked ? Colors.green : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isChecked
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isChecked ? Colors.white : Colors.grey,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 24), // 髢馴囈繧貞ｺ・￥
              // 阮ｬ縺ｮ諠・ｱ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          medicationType == '繧ｵ繝励Μ繝｡繝ｳ繝・ ? Icons.eco : Icons.medication,
                          color: isChecked ? Colors.green : medicationColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          medicationName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isChecked ? Colors.green : const Color(0xFF2196F3),
                          ),
                        ),
                        if (isChecked) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '譛咲畑貂医∩',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      medicationType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 蜑企勁繝懊ち繝ｳ
              IconButton(
                onPressed: () async {
                  // 笨・霑ｽ蜉・壼､画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
                  if (_selectedDay != null) {
                    await _saveSnapshotBeforeChange('譛咲畑險倬鹸蜑企勁_${medicationName}_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                  }
                  setState(() {
                    _addedMedications.remove(medication);
                  });
                  // 繝・・繧ｿ繧貞叉蠎ｧ縺ｫ菫晏ｭ假ｼ磯≦蟒ｶ縺ｪ縺暦ｼ・                  _saveCurrentData();
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: '蜑企勁',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineTab() {
    return Padding(
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.max, // 譛螟ｧ鬮倥＆繧剃ｽｿ逕ｨ
              children: [
                Text(
                  '譛咲畑繝｡繝｢',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
            // 譛咲畑繝｡繝｢繝ｪ繧ｹ繝茨ｼ育┌髯舌せ繧ｯ繝ｭ繝ｼ繝ｫ蟇ｾ蠢懊・鬮倥＆譛驕ｩ蛹厄ｼ・            Expanded(
              flex: 1, // 谿九ｊ縺ｮ鬮倥＆繧貞・縺ｦ菴ｿ逕ｨ
              child: _medicationMemos.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_alt_outlined, size: 72, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                '譛咲畑繝｡繝｢縺後∪縺縺ゅｊ縺ｾ縺帙ｓ',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '蜿ｳ荳九・+繝槭・繧ｯ縺九ｉ譁ｰ縺励＞繝｡繝｢繧定ｿｽ蜉縺ｧ縺阪∪縺吶・,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _memoScrollController,
                          physics: const BouncingScrollPhysics(),
                      itemCount: _medicationMemos.length,
                          // 辟｡髯舌せ繧ｯ繝ｭ繝ｼ繝ｫ逕ｨ縺ｮ譛驕ｩ蛹冶ｨｭ螳・                          cacheExtent: 1000, // 繧ｭ繝｣繝・す繝･遽・峇繧呈僑蠑ｵ・医ヱ繝輔か繝ｼ繝槭Φ繧ｹ蜷台ｸ奇ｼ・                          addAutomaticKeepAlives: true, // 閾ｪ蜍慕噪縺ｫKeepAlive繧定ｿｽ蜉
                          addRepaintBoundaries: true, // 蜀肴緒逕ｻ蠅・阜繧定ｿｽ蜉
                          addSemanticIndexes: true, // 繧ｻ繝槭Φ繝・ぅ繝・け繧､繝ｳ繝・ャ繧ｯ繧ｹ繧定ｿｽ蜉
                          // 繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ蜍穂ｽ懊・譛驕ｩ蛹・                          shrinkWrap: true, // 繧ｳ繝ｳ繝・Φ繝・↓蠢懊§縺ｦ鬮倥＆繧定ｪｿ謨ｴ
                          primary: false, // 鬮倥＆辟｡蛻ｶ髯舌・縺溘ａfalse縺ｫ險ｭ螳・                          itemBuilder: (context, index) {
                        final memo = _medicationMemos[index];
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
                                    // 繧｢繧､繧ｳ繝ｳ縺ｨ蜷榊燕繧剃ｸ翫↓驟咲ｽｮ
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: memo.color,
                                          radius: 24,
                                          child: Icon(
                                            memo.type == '繧ｵ繝励Μ繝｡繝ｳ繝・ ? Icons.eco : Icons.medication,
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
                                                  color: memo.type == '繧ｵ繝励Μ繝｡繝ｳ繝・
                                                      ? Colors.green.withOpacity(0.1)
                                                      : Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: memo.type == '繧ｵ繝励Μ繝｡繝ｳ繝・
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
                                                        : (memo.type == '繧ｵ繝励Μ繝｡繝ｳ繝・ ? Colors.green : Colors.blue),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // 繧｢繧ｯ繧ｷ繝ｧ繝ｳ繝懊ち繝ｳ繧貞承荳翫↓驟咲ｽｮ
                                        PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            // 繝医Λ繧､繧｢繝ｫ蛻ｶ髯舌メ繧ｧ繝・け
                                            final isExpired = await TrialService.isTrialExpired();
                                  if (isExpired) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => TrialLimitDialog(featureName: '譛咲畑繝｡繝｢'),
                                    );
                                    return;
                                  }
                                  switch (value) {
                                    case 'taken':
                                      _markAsTaken(memo);
                                      break;
                                    case 'edit':
                                      _editMemo(memo);
                                      break;
                                    case 'delete':
                                      _deleteMemo(memo.id);
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
                                        Text('譛咲畑險倬鹸'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('邱ｨ髮・),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('蜑企勁'),
                                      ],
                                    ),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // 隧ｳ邏ｰ諠・ｱ繧剃ｸ九↓驟咲ｽｮ
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 譛咲畑蝗樊焚諠・ｱ
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
                                      '譛咲畑蝗樊焚: ${memo.dosageFrequency}蝗・,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    if (memo.dosageFrequency >= 6) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          _showWarningDialog(context);
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
                                        '逕ｨ驥・ ${memo.dosage}',
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
                              // 笨・謾ｹ蝟・沿・壽屆譌･譛ｪ險ｭ螳壹・隴ｦ蜻願｡ｨ遉ｺ・育岼遶九▽繝・じ繧､繝ｳ・・                              if (memo.selectedWeekdays.isEmpty)
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
                                                  '笞・・譛咲畑繧ｹ繧ｱ繧ｸ繝･繝ｼ繝ｫ譛ｪ險ｭ螳・,
                                                  style: TextStyle(
                                                    fontSize: 18, 
                                                    color: Colors.red, 
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '譖懈律繧定ｨｭ螳壹＠縺ｦ縺上□縺輔＞',
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
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '繝｡繝｢繧堤ｷｨ髮・＠縺ｦ縲梧恪逕ｨ繧ｹ繧ｱ繧ｸ繝･繝ｼ繝ｫ縲阪°繧・豈取律縲∵屆譌･)繧帝∈謚槭＠縺ｦ縺上□縺輔＞',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[800],
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
                                        '譛蠕後・譛咲畑:\n${DateFormat('yyyy/MM/dd HH:mm').format(memo.lastTaken!)}',
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
                    },
                  ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmTab() {
    return FutureBuilder<bool>(
      future: TrialService.isTrialExpired(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final isExpired = snapshot.data ?? false;
        
        if (isExpired) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.orange),
                  SizedBox(height: 24),
                  Text(
                    '繝医Λ繧､繧｢繝ｫ譛滄俣縺檎ｵゆｺ・＠縺ｾ縺励◆',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '繧｢繝ｩ繝ｼ繝讖溯・縺ｯ蛻ｶ髯舌＆繧後※縺・∪縺・,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await TrialService.getPurchaseLink();
                      // 繝ｪ繝ｳ繧ｯ繧帝幕縺丞・逅・ｼ亥ｾ後〒螳溯｣・ｼ・                    },
                    icon: Icon(Icons.shopping_cart),
                    label: Text('痩 讖溯・隗｣髯､縺ｯ縺薙■繧・),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return KeyedSubtree(
          key: _alarmTabKey,  // 笨・繧ｭ繝ｼ繧定ｨｭ螳・          child: const SimpleAlarmApp(),
        );
      },
    );
  }


  Widget _buildStatsTab() {
    return FutureBuilder<bool>(
      future: TrialService.isTrialExpired(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final isExpired = snapshot.data ?? false;
        
        if (isExpired) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.orange),
                  SizedBox(height: 24),
                  Text(
                    '繝医Λ繧､繧｢繝ｫ譛滄俣縺檎ｵゆｺ・＠縺ｾ縺励◆',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '邨ｱ險域ｩ溯・縺ｯ蛻ｶ髯舌＆繧後※縺・∪縺・,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await TrialService.getPurchaseLink();
                      // 繝ｪ繝ｳ繧ｯ繧帝幕縺丞・逅・ｼ亥ｾ後〒螳溯｣・ｼ・                    },
                    icon: Icon(Icons.shopping_cart),
                    label: Text('痩 讖溯・隗｣髯､縺ｯ縺薙■繧・),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max, // 譛螟ｧ鬮倥＆繧剃ｽｿ逕ｨ
            children: [
              const Text(
                '譛崎脈驕ｵ螳育紫',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                flex: 1, // 谿九ｊ縺ｮ鬮倥＆繧貞・縺ｦ菴ｿ逕ｨ
                child: SingleChildScrollView(
                  controller: _statsScrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                  children: [
                    // 驕ｵ螳育紫繧ｰ繝ｩ繝・                    _buildAdherenceChart(),
                    const SizedBox(height: 20),
                    // 阮ｬ蜩∝挨菴ｿ逕ｨ迥ｶ豕√げ繝ｩ繝・                    _buildMedicationUsageChart(),
                    const SizedBox(height: 20),
                    // 譛滄俣蛻･驕ｵ螳育紫繧ｫ繝ｼ繝・                    ..._adherenceRates.entries.map((entry) => _buildStatCard(entry.key, entry.value)).toList(),
                      const SizedBox(height: 20),
                      // 莉ｻ諢上・譌･謨ｰ縺ｮ驕ｵ螳育紫繧ｫ繝ｼ繝・                    _buildCustomAdherenceCard(),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
  Widget _buildStatCard(String period, double rate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(period, style: const TextStyle(fontSize: 18)),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: rate >= 80 ? Colors.green : rate >= 60 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 笨・莉ｻ諢上・譌･謨ｰ縺ｮ驕ｵ螳育紫繧ｫ繝ｼ繝会ｼ亥挨逕ｻ髱｢縺ｸ縺ｮ繝翫ン繧ｲ繝ｼ繧ｷ繝ｧ繝ｳ・・  Widget _buildCustomAdherenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
              '莉ｻ諢上・譌･謨ｰ縺ｮ驕ｵ螳育紫',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
                      Text(
                        '謖・ｮ壹＠縺滓悄髢薙・驕ｵ螳育紫繧貞・譫・,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showCustomAdherenceDialog();
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text('蛻・梵'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_customAdherenceResult != null) ...[
            const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _customAdherenceResult! >= 80
                      ? Colors.green.withOpacity(0.1)
                      : _customAdherenceResult! >= 60
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _customAdherenceResult! >= 80
                        ? Colors.green
                        : _customAdherenceResult! >= 60
                            ? Colors.orange
                            : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
              children: [
                    Text(
                      '${_customDaysResult}譌･髢薙・驕ｵ螳育紫',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_customAdherenceResult!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _customAdherenceResult! >= 80
                            ? Colors.green
                            : _customAdherenceResult! >= 60
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // 笨・繧ｫ繧ｹ繧ｿ繝驕ｵ螳育紫繝繧､繧｢繝ｭ繧ｰ陦ｨ遉ｺ
  void _showCustomAdherenceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '莉ｻ諢上・譌･謨ｰ縺ｮ驕ｵ螳育紫',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '蛻・梵縺励◆縺・悄髢薙・譌･謨ｰ繧貞・蜉帙＠縺ｦ縺上□縺輔＞',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                    controller: _customDaysController,
                      focusNode: _customDaysFocusNode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: '譌･謨ｰ・・-365譌･・・,
                        hintText: '萓・ 30',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                        helperText: '驕主悉菴墓律髢薙・繝・・繧ｿ繧貞・譫舌＠縺ｾ縺吶°・・,
                    ),
                    onChanged: (value) {
                        // 蜈･蜉帛､縺ｮ讀懆ｨｼ
                      },
                    ),
                    const SizedBox(height: 20),
            if (_customAdherenceResult != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _customAdherenceResult! >= 80
                      ? Colors.green.withOpacity(0.1)
                      : _customAdherenceResult! >= 60
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _customAdherenceResult! >= 80
                        ? Colors.green
                        : _customAdherenceResult! >= 60
                            ? Colors.orange
                            : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_customDaysResult}譌･髢薙・驕ｵ螳育紫',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_customAdherenceResult!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _customAdherenceResult! >= 80
                            ? Colors.green
                            : _customAdherenceResult! >= 60
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final days = int.tryParse(_customDaysController.text);
                    if (days != null && days >= 1 && days <= 365) {
                      _calculateCustomAdherence(days);
                      setDialogState(() {}); // 繝繧､繧｢繝ｭ繧ｰ蜀・・迥ｶ諷九ｒ譖ｴ譁ｰ
                    } else {
                      _showSnackBar('1縺九ｉ365縺ｮ遽・峇縺ｧ譌･謨ｰ繧貞・蜉帙＠縺ｦ縺上□縺輔＞');
                    }
                  },
                  child: const Text('蛻・梵螳溯｡・),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // 笨・繧ｫ繧ｹ繧ｿ繝驕ｵ螳育紫險育ｮ・  void _calculateCustomAdherence(int days) async {
    try {
      // 迴ｾ蝨ｨ縺ｮ繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ菴咲ｽｮ繧剃ｿ晏ｭ・      final currentScrollPosition = _statsScrollController.hasClients 
          ? _statsScrollController.offset 
          : 0.0;
      
      // 繧ｭ繝ｼ繝懊・繝峨ｒ髢峨§繧・      _customDaysFocusNode.unfocus();
      FocusScope.of(context).unfocus();
      
      final now = DateTime.now();
      int totalDoses = 0;
      int takenDoses = 0;
      
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dayData = _medicationData[dateStr];
        
        // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・邨ｱ險・        if (dayData != null) {
          for (final timeSlot in dayData.values) {
            if (timeSlot.medicine.isNotEmpty) {
              totalDoses++;
              if (timeSlot.checked) takenDoses++;
            }
          }
        }
        
        // 譛咲畑繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ豕√ｒ邨ｱ險医↓蜿肴丐
        final weekday = date.weekday % 7; // 0=譌･譖懈律, 1=譛域屆譌･, ..., 6=蝨滓屆譌･
        final weekdayMemos = _medicationMemos.where((memo) => memo.selectedWeekdays.contains(weekday)).toList();
        
        for (final memo in weekdayMemos) {
          totalDoses++;
          // 譌･莉伜挨縺ｮ譛咲畑繝｡繝｢迥ｶ諷九ｒ遒ｺ隱・          if (_weekdayMedicationStatus[dateStr]?[memo.id] == true) {
            takenDoses++;
          }
        }
      }
      
      // 繝・・繧ｿ縺後↑縺・ｴ蜷医・隴ｦ蜻・      if (totalDoses == 0) {
        _showSnackBar('謖・ｮ壹＠縺滓悄髢薙↓譛崎脈繝・・繧ｿ縺後≠繧翫∪縺帙ｓ');
        return;
      }
      
      final rate = (takenDoses / totalDoses * 100);
     
      // 邨先棡繧偵き繝ｼ繝牙・縺ｫ陦ｨ遉ｺ
      setState(() {
        _customAdherenceResult = rate;
        _customDaysResult = days;
      });
      
      // 繝繧､繧｢繝ｭ繧ｰ繧帝哩縺倥ｋ
      Navigator.of(context).pop();
      
      // 繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ菴咲ｽｮ繧貞ｾｩ蜈・ｼ育ｵｱ險医・繝ｼ繧ｸ縺ｮ荳逡ｪ荳九↓謌ｻ繧具ｼ・      if (_statsScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _statsScrollController.animateTo(
            _statsScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        });
      }
      
    } catch (e) {
      _showSnackBar('繧ｫ繧ｹ繧ｿ繝驕ｵ螳育紫縺ｮ險育ｮ励↓螟ｱ謨励＠縺ｾ縺励◆: $e');
    }
  }
  
  // 驕ｵ螳育紫繧ｰ繝ｩ繝・  Widget _buildAdherenceChart() {
    if (_adherenceRates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                '驕ｵ螳育紫繧ｰ繝ｩ繝・,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                '繝・・繧ｿ縺後≠繧翫∪縺帙ｓ',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    final chartData = _adherenceRates.entries.toList();
    final maxValue = chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = chartData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '驕ｵ螳育紫繧ｰ繝ｩ繝・,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250, // 鬮倥＆繧貞｢怜刈
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50, // 莠育ｴ・し繧､繧ｺ繧貞｢怜刈
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30, // 莠育ｴ・し繧､繧ｺ繧定ｿｽ蜉
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                chartData[value.toInt()].key,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: minValue - 10,
                  maxY: maxValue + 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // 阮ｬ蜩∝挨菴ｿ逕ｨ迥ｶ豕√げ繝ｩ繝・  Widget _buildMedicationUsageChart() {
    // 阮ｬ蜩√・菴ｿ逕ｨ蝗樊焚繧帝寔險茨ｼ域恪逕ｨ繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ諷九ｂ蜷ｫ繧√ｋ・・    Map<String, int> medicationCount = {};
    
    // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・邨ｱ險・    for (final dayData in _medicationData.values) {
      for (final timeSlot in dayData.values) {
        if (timeSlot.medicine.isNotEmpty) {
          medicationCount[timeSlot.medicine] = (medicationCount[timeSlot.medicine] ?? 0) + 1;
        }
      }
    }
    
    // 譛咲畑繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ諷九ｒ邨ｱ險医↓蜿肴丐・域律莉伜挨・・    for (final entry in _weekdayMedicationStatus.entries) {
      final dateStr = entry.key;
      final dayStatus = entry.value;
      
      for (final memo in _medicationMemos) {
        if (dayStatus[memo.id] == true) {
          medicationCount[memo.name] = (medicationCount[memo.name] ?? 0) + 1;
        }
      }
    }
    if (medicationCount.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                '縺上☆繧翫√し繝励Μ蛻･菴ｿ逕ｨ迥ｶ豕・,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                '繝・・繧ｿ縺後≠繧翫∪縺帙ｓ',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    final sortedMedications = medicationCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '縺上☆繧翫√し繝励Μ蛻･菴ｿ逕ｨ迥ｶ豕・,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sortedMedications.asMap().entries.map((entry) {
                    final index = entry.key;
                    final medication = entry.value;
                    final colors = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                      Colors.teal,
                      Colors.pink,
                      Colors.indigo,
                    ];
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: medication.value.toDouble(),
                      title: '${medication.key}\n${medication.value}蝗・,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _applyBulkCheck() async {
    try {
      if (_selectedDates.isEmpty) {
        _showSnackBar('譌･莉倥ｒ驕ｸ謚槭＠縺ｦ縺九ｉ螳溯｡後＠縺ｦ縺上□縺輔＞縲・);
        return;
      }
      bool hasData = false;
      // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・繝√ぉ繝・け
      if (_addedMedications.isNotEmpty) {
        hasData = true;
      }
      if (!hasData) {
        _showSnackBar('阮ｬ蜷阪∪縺溘・譛崎脈迥ｶ豕√ｒ蜈･蜉帙＠縺ｦ縺上□縺輔＞縲・);
        return;
      }
      for (final date in _selectedDates) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        _medicationData.putIfAbsent(dateStr, () => {});
        // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・繧ｳ繝斐・
        for (final medication in _addedMedications) {
          final medicine = medication['name'] as String;
          final checked = medication['isChecked'] as bool;
          _medicationData[dateStr]!['added_medication_${medication.hashCode}'] = MedicationInfo(
            checked: checked,
            medicine: medicine,
            actualTime: checked ? DateTime.now() : null,
          );
          await MedicationService.saveCsvRecord(dateStr, 'added_medication', medicine, checked ? '譛崎脈貂医∩' : '譛ｪ譛崎脈');
        }
      }
      await MedicationService.saveMedicationData(_medicationData);
      // 騾夂衍險ｭ螳壹・邁｡邏蛹・      final notificationTimes = <String, List<TimeOfDay>>{};
      final notificationTypes = <String, NotificationType>{};
      await NotificationService.scheduleNotifications(notificationTimes, _medicationData, notificationTypes);
      setState(() {
        _selectedDates.clear();
        _selectedDay = null;
      });
      _updateMedicineInputsForSelectedDate();
      _showSnackBar('笨・荳諡ｬ險ｭ螳壹ｒ驕ｩ逕ｨ縺励∪縺励◆縲・);
    } catch (e) {
      _showSnackBar('荳諡ｬ險ｭ螳壹・驕ｩ逕ｨ縺ｫ螟ｱ謨励＠縺ｾ縺励◆: $e');
    }
  }
  Future<void> _applyBulkUncheck() async {
    try {
      if (_selectedDates.isEmpty) {
        _showSnackBar('譌･莉倥ｒ驕ｸ謚槭＠縺ｦ縺九ｉ螳溯｡後＠縺ｦ縺上□縺輔＞縲・);
        return;
      }
      for (final date in _selectedDates) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        _medicationData.putIfAbsent(dateStr, () => {});
        // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・繧ｳ繝斐・
        for (final medication in _addedMedications) {
          final medicine = medication['name'] as String;
          _medicationData[dateStr]!['added_medication_${medication.hashCode}'] = MedicationInfo(
            checked: false,
            medicine: medicine,
            actualTime: null,
          );
          await MedicationService.saveCsvRecord(dateStr, 'added_medication', medicine, '譛ｪ譛崎脈');
        }
      }
      await MedicationService.saveMedicationData(_medicationData);
      // 騾夂衍險ｭ螳壹・邁｡邏蛹・      final notificationTimes = <String, List<TimeOfDay>>{};
      final notificationTypes = <String, NotificationType>{};
      await NotificationService.scheduleNotifications(notificationTimes, _medicationData, notificationTypes);
      setState(() {
        _selectedDates.clear();
        _selectedDay = null;
      });
      _updateMedicineInputsForSelectedDate();
      _showSnackBar('笶・荳諡ｬ隗｣髯､繧帝←逕ｨ縺励∪縺励◆縲・);
    } catch (e) {
      _showSnackBar('荳諡ｬ隗｣髯､縺ｮ驕ｩ逕ｨ縺ｫ螟ｱ謨励＠縺ｾ縺励◆: $e');
    }
  }
  Future<void> _deleteMedicine(String name) async {
    try {
      await MedicationService.deleteMedicine(name);
      setState(() {
        _medicines.removeWhere((medicine) => medicine.name == name);
      });
      _showSnackBar('阮ｬ蜩√ｒ蜑企勁縺励∪縺励◆');
    } catch (e) {
      _showSnackBar('阮ｬ蜩√・蜑企勁縺ｫ螟ｱ謨励＠縺ｾ縺励◆: $e');
    }
  }
  void _addMemo() {
    showDialog(
      context: context,
      builder: (context) => _MemoDialog(
        existingMemos: _medicationMemos,
        onMemoAdded: (memo) async {
          // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
          await _saveSnapshotBeforeChange('繝｡繝｢霑ｽ蜉_${memo.name.isEmpty ? '辟｡鬘・ : memo.name}');
          try {
            // 繧ｿ繧､繝医Ν縺檎ｩｺ縺ｪ繧芽・蜍暮｣逡ｪ縺ｧ陬懷ｮ・            MedicationMemo memoToSave = memo;
            final rawTitle = memo.name.trim();
            if (rawTitle.isEmpty) {
              final titles = _medicationMemos.map((m) => m.name).toList();
              final autoTitle = _generateDefaultTitle(titles);
              memoToSave = MedicationMemo(
                id: memo.id,
                name: autoTitle,
                type: memo.type,
                dosage: memo.dosage,
                notes: memo.notes,
                createdAt: memo.createdAt,
                lastTaken: memo.lastTaken,
                color: memo.color,
                selectedWeekdays: memo.selectedWeekdays,
              );
            }

            // 笨・謾ｹ蝟・沿・壹Γ繝｢繧剃ｿ晏ｭ假ｼ亥､夐㍾繝舌ャ繧ｯ繧｢繝・・莉倥″・・            await _saveMedicationMemoWithBackup(memoToSave);
            
            // UI繧呈峩譁ｰ・医ョ繝ｼ繧ｿ蜀崎ｪｭ縺ｿ霎ｼ縺ｿ縺ｯ荳崎ｦ・ｼ・          setState(() {
            _medicationMemos.add(memoToSave);
              // 譁ｰ縺励￥霑ｽ蜉縺輔ｌ縺溘Γ繝｢繧定｡ｨ遉ｺ繝ｪ繧ｹ繝医↓繧りｿｽ蜉
              _displayedMemos.add(memoToSave);
          });
            
            // 繝・・繧ｿ繧剃ｿ晏ｭ・            await _saveAllData();
            
            _showSnackBar('譛咲畑繝｡繝｢繧定ｿｽ蜉縺励∪縺励◆');
          } catch (e) {
            _showSnackBar('繝｡繝｢縺ｮ霑ｽ蜉縺ｫ螟ｱ謨励＠縺ｾ縺励◆: $e');
          }
        },
      ),
    );
  }
  void _editMemo(MedicationMemo memo) {
    showDialog(
      context: context,
      builder: (context) => _MemoDialog(
        initialMemo: memo,
        existingMemos: _medicationMemos,
        onMemoAdded: (updatedMemo) async {
          // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
          await _saveSnapshotBeforeChange('繝｡繝｢邱ｨ髮・${memo.name.isEmpty ? '辟｡鬘・ : memo.name}');
          // 繧ｿ繧､繝医Ν縺檎ｩｺ縺ｪ繧芽・蜍暮｣逡ｪ縺ｧ陬懷ｮ・          MedicationMemo memoToSave = updatedMemo;
          final rawTitle = updatedMemo.name.trim();
          if (rawTitle.isEmpty) {
            final titles = _medicationMemos.where((m) => m.id != memo.id).map((m) => m.name).toList();
            final autoTitle = _generateDefaultTitle(titles);
            memoToSave = MedicationMemo(
              id: updatedMemo.id,
              name: autoTitle,
              type: updatedMemo.type,
              dosage: updatedMemo.dosage,
              notes: updatedMemo.notes,
              createdAt: updatedMemo.createdAt,
              lastTaken: updatedMemo.lastTaken,
              color: updatedMemo.color,
              selectedWeekdays: updatedMemo.selectedWeekdays,
            );
          }

          // 笨・謾ｹ蝟・沿・壹Γ繝｢繧剃ｿ晏ｭ假ｼ亥､夐㍾繝舌ャ繧ｯ繧｢繝・・莉倥″・・          await _saveMedicationMemoWithBackup(memoToSave);

          setState(() {
            final index = _medicationMemos.indexWhere((m) => m.id == memo.id);
            if (index != -1) {
              _medicationMemos[index] = memoToSave;
            }
            // 陦ｨ遉ｺ繝ｪ繧ｹ繝医ｂ譖ｴ譁ｰ
            final displayedIndex = _displayedMemos.indexWhere((m) => m.id == memo.id);
            if (displayedIndex != -1) {
              _displayedMemos[displayedIndex] = memoToSave;
            }
          });
          
          _showSnackBar('譛咲畑繝｡繝｢繧呈峩譁ｰ縺励∪縺励◆');
        },
      ),
    );
  }
  void _markAsTaken(MedicationMemo memo) async {
    final updatedMemo = MedicationMemo(
      id: memo.id,
      name: memo.name,
      type: memo.type,
      dosage: memo.dosage,
      notes: memo.notes,
      createdAt: memo.createdAt,
      lastTaken: DateTime.now(),
      color: memo.color,
      selectedWeekdays: memo.selectedWeekdays,
    );
    
    // 笨・謾ｹ蝟・沿・壹Γ繝｢繧剃ｿ晏ｭ假ｼ亥､夐㍾繝舌ャ繧ｯ繧｢繝・・莉倥″・・    await _saveMedicationMemoWithBackup(updatedMemo);
    
    setState(() {
      final index = _medicationMemos.indexWhere((m) => m.id == memo.id);
      if (index != -1) {
        _medicationMemos[index] = updatedMemo;
      }
    });
    
    _showSnackBar('${memo.name}縺ｮ譛咲畑繧定ｨ倬鹸縺励∪縺励◆');
  }
  void _deleteMemo(String id) async {
    // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ
    final target = _medicationMemos.firstWhere(
      (m) => m.id == id,
      orElse: () => MedicationMemo(
        id: id,
        name: '辟｡鬘・,
        type: '阮ｬ蜩・,
        createdAt: DateTime.now(),
      ),
    );
    await _saveSnapshotBeforeChange('繝｡繝｢蜑企勁_${target.name}');
    try {
      // 笨・謾ｹ蝟・沿・壹Γ繝｢繧貞炎髯､・亥､夐㍾繝舌ャ繧ｯ繧｢繝・・莉倥″・・      await _deleteMedicationMemoWithBackup(id);
      
      // UI繧呈峩譁ｰ
    setState(() {
      _medicationMemos.removeWhere((memo) => memo.id == id);
        _displayedMemos.removeWhere((memo) => memo.id == id);
        // 髢｢騾｣繝・・繧ｿ繧ょ炎髯､
        _medicationMemoStatus.remove(id);
        _weekdayMedicationStatus.remove(id);
        // 譌･莉伜挨縺ｮ譛咲畑迥ｶ諷九ｂ蜑企勁
        for (final dateStr in _weekdayMedicationDoseStatus.keys) {
          _weekdayMedicationDoseStatus[dateStr]?.remove(id);
        }
      });
      
      // 繝・・繧ｿ繧剃ｿ晏ｭ・      await _saveAllData();
      
    _showSnackBar('繝｡繝｢繧貞炎髯､縺励∪縺励◆');
    } catch (e) {
      _showSnackBar('蜑企勁縺ｫ螟ｱ謨励＠縺ｾ縺励◆: $e');
    }
  }

  // 遨ｺ繧ｿ繧､繝医Ν譎ゅ・閾ｪ蜍暮｣逡ｪ逕滓・
  String _generateDefaultTitle(List<String> existingTitles) {
    const int maxCount = 999;
    int count = 1;
    while (count <= maxCount && existingTitles.contains('繝｡繝｢$count')) {
      count++;
    }
    return '繝｡繝｢$count';
  }

  // CSV蜈ｱ譛画ｩ溯・縺ｮ蠑ｷ蛹厄ｼ域悴菴ｿ逕ｨ・・  Future<void> _exportToCSV() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/medication_data_$timestamp.csv');
     
      final csvContent = StringBuffer();
     
      // 繝倥ャ繝繝ｼ陦・      csvContent.writeln('譌･莉・譎る俣,阮ｬ蜷・譛崎脈迥ｶ豕・螳滄圀縺ｮ譛崎脈譎る俣,驕・ｻｶ譎る俣(蛻・,驕ｵ螳育紫');
     
      // 邨ｱ險域ュ蝣ｱ繧定ｨ育ｮ暦ｼ域恪逕ｨ繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ諷九ｂ蜷ｫ繧√ｋ・・      int totalDoses = 0;
      int takenDoses = 0;
      final Map<String, int> medicationCount = {};
      final Map<String, int> medicationTakenCount = {};
     
      // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・邨ｱ險・      for (final entry in _medicationData.entries) {
        final date = entry.key;
        final dayData = entry.value;
       
        for (final timeSlot in dayData.entries) {
          final time = timeSlot.key;
          final info = timeSlot.value;
         
          if (info.medicine.isNotEmpty) {
            totalDoses++;
            if (info.checked) takenDoses++;
           
            // 阮ｬ蜩∝挨繧ｫ繧ｦ繝ｳ繝・            medicationCount[info.medicine] = (medicationCount[info.medicine] ?? 0) + 1;
            if (info.checked) {
              medicationTakenCount[info.medicine] = (medicationTakenCount[info.medicine] ?? 0) + 1;
            }
          }
        }
      }
      
      // 譛咲畑繝｡繝｢縺ｮ繝√ぉ繝・け迥ｶ諷九ｒ邨ｱ險医↓蜿肴丐・域律莉伜挨・・      for (final entry in _weekdayMedicationStatus.entries) {
        final dateStr = entry.key;
        final dayStatus = entry.value;
        
        for (final memo in _medicationMemos) {
          if (dayStatus[memo.id] == true) {
            totalDoses++;
            takenDoses++;
            medicationCount[memo.name] = (medicationCount[memo.name] ?? 0) + 1;
            medicationTakenCount[memo.name] = (medicationTakenCount[memo.name] ?? 0) + 1;
          }
        }
      }
     
      // 邨ｱ險医し繝槭Μ繝ｼ繧定ｿｽ蜉
      csvContent.writeln('');
      csvContent.writeln('=== 邨ｱ險医し繝槭Μ繝ｼ ===');
      csvContent.writeln('邱乗恪阮ｬ蝗樊焚,$totalDoses');
      csvContent.writeln('譛崎脈貂医∩蝗樊焚,$takenDoses');
      csvContent.writeln('蜈ｨ菴馴・螳育紫,${totalDoses > 0 ? (takenDoses / totalDoses * 100).toStringAsFixed(1) : 0}%');
      csvContent.writeln('');
      csvContent.writeln('=== 阮ｬ蜩∝挨邨ｱ險・===');
      csvContent.writeln('阮ｬ蜩∝錐,邱丞屓謨ｰ,譛崎脈貂医∩蝗樊焚,驕ｵ螳育紫');
     
      for (final medication in medicationCount.keys) {
        final total = medicationCount[medication]!;
        final taken = medicationTakenCount[medication] ?? 0;
        final rate = total > 0 ? (taken / total * 100) : 0;
        csvContent.writeln('$medication,$total,$taken,${rate.toStringAsFixed(1)}%');
      }
     
      await file.writeAsString(csvContent.toString());
     
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: '譛崎脈繝・・繧ｿ繧偵お繧ｯ繧ｹ繝昴・繝医＠縺ｾ縺励◆・育ｵｱ險域ュ蝣ｱ莉倥″・・);
     
      _showSnackBar('CSV繝輔ぃ繧､繝ｫ繧偵お繧ｯ繧ｹ繝昴・繝医＠縺ｾ縺励◆・育ｵｱ險域ュ蝣ｱ莉倥″・・);
    } catch (e) {
      _showSnackBar('CSV繧ｨ繧ｯ繧ｹ繝昴・繝医↓螟ｱ謨励＠縺ｾ縺励◆: $e');
    }
  }
 
  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  void _selectAllDates() {
    setState(() {
      _selectedDates.clear();
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);
      
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final date = startDate.add(Duration(days: i));
        _selectedDates.add(_normalizeDate(date));
      }
      
      if (_selectedDates.isNotEmpty) {
        _selectedDay = _selectedDates.first;
      }
    });
    _updateMedicineInputsForSelectedDate();
    _showSnackBar('莉頑怦縺ｮ縺吶∋縺ｦ縺ｮ譌･莉倥ｒ驕ｸ謚槭＠縺ｾ縺励◆');
  }

  void _clearAllSelections() {
    setState(() {
      _selectedDates.clear();
      _selectedDay = null;
    });
    _updateMedicineInputsForSelectedDate();
    _showSnackBar('縺吶∋縺ｦ縺ｮ驕ｸ謚槭ｒ隗｣髯､縺励∪縺励◆');
  }

  // 驕ｸ謚槭＆繧後◆譌･莉倥・譖懈律縺ｫ蝓ｺ縺･縺・※譛咲畑繝｡繝｢繧貞叙蠕・  List<MedicationMemo> _getMedicationsForSelectedDay() {
    if (_selectedDay == null) return [];
    
    final weekday = _selectedDay!.weekday % 7; // 0=譌･譖懈律, 1=譛域屆譌･, ..., 6=蝨滓屆譌･
    return _medicationMemos.where((memo) => memo.selectedWeekdays.contains(weekday)).toList();
  }

  // 譖懈律險ｭ螳壹＆繧後◆阮ｬ縺ｮ譛咲畑迥ｶ豕√ｒ蜿門ｾ・  bool _getWeekdayMedicationStatus(String memoId) {
    if (_selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    return _weekdayMedicationStatus[dateStr]?[memoId] ?? false;
  }

  // 譖懈律險ｭ螳壹＆繧後◆阮ｬ縺ｮ譛咲畑迥ｶ豕√ｒ譖ｴ譁ｰ
  void _updateWeekdayMedicationStatus(String memoId, bool isTaken) {
    if (_selectedDay == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    _weekdayMedicationStatus.putIfAbsent(dateStr, () => {});
    _weekdayMedicationStatus[dateStr]![memoId] = isTaken;
  }

  // 譖懈律險ｭ螳壹＆繧後◆阮ｬ繧定｡ｨ遉ｺ縺吶ｋ繧ｦ繧｣繧ｸ繧ｧ繝・ヨ
  Widget _buildWeekdayMedicationRecord(MedicationMemo memo) {
    final isChecked = _getWeekdayMedicationStatus(memo.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20), // 髢馴囈繧貞ｺ・￥
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isChecked
            ? Border.all(color: memo.color, width: 2)
            : Border.all(color: memo.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: isChecked 
                ? memo.color.withOpacity(0.2)
                : memo.color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isChecked
              ? LinearGradient(
                  colors: [memo.color.withOpacity(0.1), memo.color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [memo.color.withOpacity(0.05), memo.color.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24), // 繝代ョ繧｣繝ｳ繧ｰ繧貞｢怜刈
          child: Row(
            children: [
              // 譛咲畑貂医∩繝√ぉ繝・け繝懊ャ繧ｯ繧ｹ
              GestureDetector(
                onTap: () async {
                  // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ・域恪逕ｨ繝｡繝｢縺ｮ繝√ぉ繝・け蛻・崛・・                  await _saveSnapshotBeforeChange('譛咲畑繝√ぉ繝・け_${memo.name}');
                  setState(() {
                    _updateWeekdayMedicationStatus(memo.id, !isChecked);
                  });
                  _saveCurrentDataDebounced();
                  _updateCalendarMarks();
                },
                child: Container(
                  width: 60, // 繧ｵ繧､繧ｺ繧貞､ｧ縺阪￥
                  height: 60,
                  decoration: BoxDecoration(
                    color: isChecked ? memo.color : memo.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isChecked
                        ? [
                            BoxShadow(
                              color: memo.color.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isChecked ? Colors.white : memo.color,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 24), // 髢馴囈繧貞ｺ・￥
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          memo.type == '繧ｵ繝励Μ繝｡繝ｳ繝・ ? Icons.eco : Icons.medication,
                          color: memo.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            memo.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: memo.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: memo.color.withOpacity(0.3)),
                          ),
                          child: Text(
                            memo.type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: memo.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (memo.dosage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '逕ｨ驥・ ${memo.dosage}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    if (memo.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        memo.notes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _addMedicationToTimeSlot(String medicationName) {
    // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ・磯撼蜷梧悄縺縺悟ｾ・◆縺壹↓螳溯｡鯉ｼ・    _saveSnapshotBeforeChange('阮ｬ霑ｽ蜉_$medicationName');
    // 繝｡繝｢蛻ｶ髯舌メ繧ｧ繝・け
    if (!_canAddMemo()) {
      _showLimitDialog('繝｡繝｢');
      return;
    }
    
    // 譛咲畑繝｡繝｢縺九ｉ阮ｬ縺ｮ隧ｳ邏ｰ諠・ｱ繧貞叙蠕・    final memo = _medicationMemos.firstWhere(
      (memo) => memo.name == medicationName,
      orElse: () {
        // 遨ｺ繧ｿ繧､繝医Ν縺ｸ縺ｮ蟇ｾ蠢・ 閾ｪ蜍暮｣逡ｪ繧貞牡繧雁ｽ薙※
        final titles = _medicationMemos.map((m) => m.name).toList();
        final autoTitle = _generateDefaultTitle(titles);
        return MedicationMemo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: medicationName.trim().isEmpty ? autoTitle : medicationName,
        type: '阮ｬ',
        color: Colors.blue,
        dosage: '',
        notes: '',
        createdAt: DateTime.now(),
        );
      },
    );
    
    // 譁ｰ縺励＞阮ｬ繧偵Μ繧ｹ繝医↓霑ｽ蜉
    setState(() {
      _addedMedications.add({
        'name': memo.name,
        'type': memo.type,
        'color': memo.color,
        'dosage': memo.dosage,
        'notes': memo.notes,
        'isChecked': false,
      });
    });
    
    _saveCurrentDataDebounced();
    _showSnackBar('$medicationName 繧呈恪逕ｨ險倬鹸縺ｫ霑ｽ蜉縺励∪縺励◆');
  }

  // 螳悟・縺ｫ菴懊ｊ逶ｴ縺輔ｌ縺溘き繝ｬ繝ｳ繝繝ｼ繝槭・繧ｯ譖ｴ譁ｰ
  void _updateCalendarMarks() {
    if (_selectedDay == null) return;
    
    // 蠑ｷ蛻ｶ逧・↓繧ｫ繝ｬ繝ｳ繝繝ｼ繧呈峩譁ｰ
    setState(() {
      // 繧ｫ繝ｬ繝ｳ繝繝ｼ縺ｮ繝槭・繧ｯ繧貞ｼｷ蛻ｶ譖ｴ譁ｰ
    });
  }

  // 霆ｽ驥丞喧縺輔ｌ縺溽ｵｱ險郁ｨ育ｮ励Γ繧ｽ繝・ラ
  Map<String, int> _calculateMedicationStats() {
    if (_selectedDay == null) return {'total': 0, 'taken': 0};
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・邨ｱ險・    totalMedications += _addedMedications.length;
    takenMedications += _addedMedications.where((med) => med['isChecked'] == true).length;
    
    // 譛咲畑繝｡繝｢縺ｮ邨ｱ險茨ｼ郁ｻｽ驥丞喧・・    final weekday = _selectedDay!.weekday % 7;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    
    for (final memo in _medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications++;
        if (_medicationMemoStatus[memo.id] == true) {
          takenMedications++;
        }
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  Widget _buildMedicationStats() {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    // 螳悟・縺ｫ菴懊ｊ逶ｴ縺輔ｌ縺溽ｵｱ險郁ｨ育ｮ・    int totalMedications = 0;
    int takenMedications = 0;
    
    // 蜍慕噪阮ｬ繝ｪ繧ｹ繝医・邨ｱ險・    totalMedications += _addedMedications.length;
    takenMedications += _addedMedications.where((med) => med['isChecked'] == true).length;
    
    // 譛咲畑繝｡繝｢縺ｮ邨ｱ險茨ｼ井ｻ頑律縺ｮ譖懈律縺ｫ隧ｲ蠖薙☆繧九ｂ縺ｮ縺ｮ縺ｿ・・    final weekday = _selectedDay!.weekday % 7;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    
    for (final memo in _medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications++;
        if (_medicationMemoStatus[memo.id] == true) {
          takenMedications++;
        }
      }
    }
    
    final progress = totalMedications > 0 ? takenMedications / totalMedications : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: progress == 1.0 
            ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
            : [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress == 1.0 ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      progress == 1.0 ? Icons.check_circle : Icons.schedule,
                      color: progress == 1.0 ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '莉頑律縺ｮ譛咲畑迥ｶ豕・,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: progress == 1.0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$takenMedications / $totalMedications 譛咲畑貂医∩',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0 ? Colors.green : Colors.orange,
                  ),
                ),
                if (totalMedications > 0) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: progress == 1.0 ? Colors.green : Colors.orange,
              boxShadow: [
                BoxShadow(
                  color: (progress == 1.0 ? Colors.green : Colors.orange).withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 笨・菫ｮ豁｣・壹が繝ｼ繝舌・繝輔Ο繝ｼ繧帝亟縺舌◆繧√↓Flexible繧剃ｽｿ逕ｨ
        Row(
          children: [
            Icon(Icons.note_alt, color: Colors.blue, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
              '莉頑律縺ｮ繝｡繝｢',
              style: TextStyle(
                fontSize: 14, // 繝輔か繝ｳ繝医し繧､繧ｺ蜑頑ｸ・                fontWeight: FontWeight.bold,
                color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis, // 繝・く繧ｹ繝医が繝ｼ繝舌・繝輔Ο繝ｼ蟇ｾ遲・              ),
            ),
            const Spacer(),
            if (_memoController.text.isNotEmpty)
              Flexible(
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 繝代ョ繧｣繝ｳ繧ｰ蜑頑ｸ・                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8), // 隗剃ｸｸ蜑頑ｸ・                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Text(
                  '菫晏ｭ俶ｸ医∩',
                  style: TextStyle(
                    fontSize: 10, // 繝輔か繝ｳ繝医し繧､繧ｺ蜑頑ｸ・                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6), // 髢馴囈蜑頑ｸ・        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // 隗剃ｸｸ蜑頑ｸ・            border: Border.all(
              color: _isMemoFocused ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
              width: _isMemoFocused ? 1.5 : 1,
            ),
            boxShadow: _isMemoFocused ? [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: ValueListenableBuilder<String>(
            valueListenable: _memoTextNotifier,
            builder: (context, memoText, _) {
              _memoController.value = _memoController.value.copyWith(text: memoText, selection: TextSelection.collapsed(offset: memoText.length));
              return TextField(
            controller: _memoController,
            focusNode: _memoFocusNode,
            maxLines: 2, // 2陦瑚｡ｨ遉ｺ縺ｫ蝗ｺ螳・            minLines: 2, // 譛蟆剰｡梧焚繧・縺ｫ螟画峩
            decoration: InputDecoration(
              hintText: '蜑ｯ菴懃畑縲∫羅髯｢縲・夐劼險倬鹸縺ｪ縺ｩ',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 12, // 繝輔か繝ｳ繝医し繧､繧ｺ蜑頑ｸ・              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12), // 繝代ョ繧｣繝ｳ繧ｰ蜑頑ｸ・              suffixIcon: (_memoController.text.isNotEmpty)
                  ? IconButton(
                      onPressed: () async {
                        // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ・医Γ繝｢繧ｯ繝ｪ繧｢・・                        if (_selectedDay != null) {
                          await _saveSnapshotBeforeChange('繝｡繝｢繧ｯ繝ｪ繧｢_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                        }
                        _memoTextNotifier.value = '';
                        _saveMemo();
                      },
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 16),
                    )
                  : null,
            ),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.lightGreen[300] 
                  : Colors.black87,
            ),
            onTap: () async {
              // 繝医Λ繧､繧｢繝ｫ蛻ｶ髯舌メ繧ｧ繝・け
              final isExpired = await TrialService.isTrialExpired();
              if (isExpired) {
                showDialog(
                  context: context,
                  builder: (context) => TrialLimitDialog(featureName: '繝｡繝｢'),
                );
                FocusScope.of(context).unfocus();
                return;
              }
              setState(() {
                _isMemoFocused = true;
              });
            },
            onChanged: (value) {
              // 繝・ヰ繧ｦ繝ｳ繧ｹ蜃ｦ逅・〒繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ倥ｒ蛻ｶ髯・              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () async {
                // 繝・ヰ繧ｦ繝ｳ繧ｹ蠕後↓繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ假ｼ・蝗槭□縺托ｼ・                if (_selectedDay != null && !_memoSnapshotSaved) {
                await _saveSnapshotBeforeChange('繝｡繝｢螟画峩_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                  _memoSnapshotSaved = true;
              }
                _memoTextNotifier.value = value;
                _saveMemo();
              });
              // 蜊ｳ蠎ｧ縺ｫUI繧呈峩譁ｰ
              _memoTextNotifier.value = value;
            },
            onSubmitted: (value) {
              // 繧ｭ繝ｼ繝懊・繝峨・豎ｺ螳壹・繧ｿ繝ｳ縺ｧ螳御ｺ・              _completeMemo();
            },
            onEditingComplete: () {
              _completeMemo();
            },
              );
            },
          ),
        ),
        // 繝｡繝｢蜈･蜉帶凾縺ｮ螳御ｺ・・繧ｿ繝ｳ・医さ繝ｳ繝代け繝亥喧・・        if (_isMemoFocused) ...[
          const SizedBox(height: 8), // 髢馴囈蜑頑ｸ・          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _completeMemo();
                },
                icon: const Icon(Icons.save, size: 16), // 繧｢繧､繧ｳ繝ｳ繧ｵ繧､繧ｺ蜑頑ｸ・                label: const Text('菫晏ｭ・, style: TextStyle(fontSize: 12)), // 繝輔か繝ｳ繝医し繧､繧ｺ蜑頑ｸ・                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 繝代ョ繧｣繝ｳ繧ｰ蜑頑ｸ・                  minimumSize: const Size(0, 32), // 譛蟆上し繧､繧ｺ險ｭ螳・                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ・医Γ繝｢繧ｯ繝ｪ繧｢・・                  if (_selectedDay != null) {
                    await _saveSnapshotBeforeChange('繝｡繝｢繧ｯ繝ｪ繧｢_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                  }
                  setState(() {
                    _memoController.clear();
                    _isMemoFocused = false;
                  });
                  _saveMemo();
                  FocusScope.of(context).unfocus();
                },
                icon: const Icon(Icons.clear, size: 16), // 繧｢繧､繧ｳ繝ｳ繧ｵ繧､繧ｺ蜑頑ｸ・                label: const Text('繧ｯ繝ｪ繧｢', style: TextStyle(fontSize: 12)), // 繝輔か繝ｳ繝医し繧､繧ｺ蜑頑ｸ・                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 繝代ョ繧｣繝ｳ繧ｰ蜑頑ｸ・                  minimumSize: const Size(0, 32), // 譛蟆上し繧､繧ｺ險ｭ螳・                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _saveMemo() async {
    try {
      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('memo_$dateStr', _memoController.text);
      }
    } catch (e) {
    }
  }
  
  void _completeMemo() {
    setState(() {
      _isMemoFocused = false;
      _memoSnapshotSaved = false; // 繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ倥ヵ繝ｩ繧ｰ繧偵Μ繧ｻ繝・ヨ
    });
    // 繧ｫ繝ｼ繧ｽ繝ｫ縺ｮ驕ｸ謚槭ｒ螟悶☆
    FocusScope.of(context).unfocus();
    _saveMemo().then((_) {
      if (_memoController.text.isNotEmpty) {
        _showSnackBar('繝｡繝｢繧剃ｿ晏ｭ倥＠縺ｾ縺励◆');
      } else {
        _showSnackBar('繝｡繝｢繧偵け繝ｪ繧｢縺励∪縺励◆');
      }
    });
  }

  // 繝医Λ繧､繧｢繝ｫ迥ｶ諷玖｡ｨ遉ｺ繝繧､繧｢繝ｭ繧ｰ
  Future<void> _showTrialStatus() async {
    final status = await TrialService.getPurchaseStatus();
    final remainingMinutes = await TrialService.getRemainingMinutes();
    
    if (!mounted) return;
    
    // 迥ｶ諷九↓蠢懊§縺溘い繧､繧ｳ繝ｳ縺ｨ濶ｲ繧定ｨｭ螳・    IconData statusIcon;
    Color statusColor;
    String statusText;
    
    switch (status) {
      case TrialService.trialStatus:
        statusIcon = Icons.timer;
        statusColor = Colors.blue;
        statusText = '繝医Λ繧､繧｢繝ｫ荳ｭ';
        break;
      case TrialService.expiredStatus:
        statusIcon = Icons.warning;
        statusColor = Colors.red;
        statusText = '譛滄剞蛻・ｌ';
        break;
      case TrialService.purchasedStatus:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = '雉ｼ蜈･貂医∩';
        break;
      default:
        statusIcon = Icons.timer;
        statusColor = Colors.blue;
        statusText = '繝医Λ繧､繧｢繝ｫ荳ｭ';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 12),
            const Text('雉ｼ蜈･迥ｶ諷・),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('迴ｾ蝨ｨ縺ｮ迥ｶ諷・, statusText, statusColor),
            if (status == TrialService.trialStatus) ...[
            const SizedBox(height: 12),
            _buildStatusRow('谿九ｊ譎る俣', 
                  '${(remainingMinutes / (24 * 60)).ceil()}譌･',
                  Colors.orange),
            ],
            if (status == TrialService.expiredStatus) ...[
              const SizedBox(height: 12),
              _buildStatusRow('譛滄剞', '7譌･髢鍋ｵゆｺ・, Colors.red),
            ],
            if (status == TrialService.purchasedStatus) ...[
              const SizedBox(height: 12),
              _buildStatusRow('譛牙柑譛滄剞', '辟｡蛻ｶ髯・, Colors.green),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('髢峨§繧・),
          ),
          if (status == TrialService.expiredStatus)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _showPurchaseLinkDialog();
              },
              child: const Text('雉ｼ蜈･縺吶ｋ'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
  
  // 隴ｦ蜻翫ム繧､繧｢繝ｭ繧ｰ繧定｡ｨ遉ｺ縺吶ｋ繝｡繧ｽ繝・ラ
  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('豕ｨ諢・),
          ],
        ),
        content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              '譛咲畑蝗樊焚縺悟､壹＞縺溘ａ縲・,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              '蛹ｻ蟶ｫ縺ｮ謖・､ｺ縺ｫ蠕薙▲縺ｦ縺上□縺輔＞',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('莠・ｧ｣'),
          ),
        ],
      ),
    );
    
    // 3遘貞ｾ後↓閾ｪ蜍輔〒髢峨§繧・    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
  
  // 雉ｼ蜈･迥ｶ諷九↓險ｭ螳壹☆繧九Γ繧ｽ繝・ラ
  Future<void> _setPurchasedStatus() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('雉ｼ蜈･迥ｶ諷九↓險ｭ螳・),
          ],
        ),
        content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              '繧｢繝励Μ繧定ｳｼ蜈･貂医∩迥ｶ諷九↓險ｭ螳壹＠縺ｾ縺吶°・・,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '險ｭ螳壼ｾ後・莉･荳九・讖溯・縺檎┌蛻ｶ髯舌〒菴ｿ逕ｨ縺ｧ縺阪∪縺呻ｼ・,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text('窶｢ 繝｡繝｢縺ｮ霑ｽ蜉繝ｻ邱ｨ髮・),
            Text('窶｢ 繧｢繝ｩ繝ｼ繝讖溯・'),
            Text('窶｢ 邨ｱ險域ｩ溯・'),
            Text('窶｢ 繧ｫ繝ｬ繝ｳ繝繝ｼ讖溯・'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
          ),
          ElevatedButton(
            onPressed: () async {
              await TrialService.setPurchaseStatus(TrialService.purchasedStatus);
              Navigator.of(context).pop();
              
              // 螳滄圀縺ｮ雉ｼ蜈･譎ゅ→蜷後§繝｡繝・そ繝ｼ繧ｸ繧定｡ｨ遉ｺ
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 32),
                      SizedBox(width: 12),
                      Text('雉ｼ蜈･螳御ｺ・ｼ・),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '蝠・刀雉ｼ蜈･蠕後∵悄髯舌′辟｡譛滄剞縺ｫ縺ｪ繧翫∪縺励◆・・,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                        child: const Column(
                  children: [
                            Text(
                              '脂 繝励Ξ繝溘い繝讖溯・縺梧怏蜉ｹ縺ｫ縺ｪ繧翫∪縺励◆・・,
                      style: TextStyle(
                            fontSize: 16,
                        fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                            SizedBox(height: 8),
                            Text(
                              '窶｢ 繝｡繝｢縺ｮ霑ｽ蜉繝ｻ邱ｨ髮・n窶｢ 繧｢繝ｩ繝ｼ繝讖溯・\n窶｢ 邨ｱ險域ｩ溯・\n窶｢ 繧ｫ繝ｬ繝ｳ繝繝ｼ讖溯・',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('縺ゅｊ縺後→縺・＃縺悶＞縺ｾ縺呻ｼ・),
                    ),
                  ],
                ),
              );
            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
            ),
            child: const Text('雉ｼ蜈･貂医∩縺ｫ險ｭ螳・),
          ),
        ],
      ),
    );
  }

  // 繝医Λ繧､繧｢繝ｫ迥ｶ諷九↓險ｭ螳・  Future<void> _setTrialStatus() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('繝医Λ繧､繧｢繝ｫ迥ｶ諷九↓'),
                  Text('險ｭ螳・),
                  ],
                ),
              ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '繧｢繝励Μ繧偵ヨ繝ｩ繧､繧｢繝ｫ迥ｶ諷九↓險ｭ螳壹＠縺ｾ縺吶°・・,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '險ｭ螳壼ｾ後・莉･荳九・蛻ｶ髯舌′驕ｩ逕ｨ縺輔ｌ縺ｾ縺呻ｼ・,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text('窶｢ 繝医Λ繧､繧｢繝ｫ譛滄俣: 7譌･髢・),
            Text('窶｢ 譛滄剞蛻・ｌ蠕後・讖溯・蛻ｶ髯・),
            Text('窶｢ 雉ｼ蜈･縺ｧ蛻ｶ髯占ｧ｣髯､'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 繝医Λ繧､繧｢繝ｫ繧偵Μ繧ｻ繝・ヨ縺励※譁ｰ縺励＞繝医Λ繧､繧｢繝ｫ繧帝幕蟋・              await TrialService.resetTrial();
              await TrialService.initializeTrial();
              await TrialService.setPurchaseStatus(TrialService.trialStatus);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('繝医Λ繧､繧｢繝ｫ迥ｶ諷九↓險ｭ螳壹＠縺ｾ縺励◆・・譌･髢難ｼ・),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('繝医Λ繧､繧｢繝ｫ縺ｫ險ｭ螳・),
          ),
        ],
      ),
    );
  }



  // 繧｢繝励Μ蜀・ｪｲ驥代ム繧､繧｢繝ｭ繧ｰ繧定｡ｨ遉ｺ
  Future<void> _showPurchaseLinkDialog() async {
    if (!mounted) return;
    
    // 蝠・刀諠・ｱ繧貞叙蠕・    final ProductDetails? product = await InAppPurchaseService.getProductDetails();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.green),
            SizedBox(width: 12),
            Text('繧｢繝励Μ蜀・ｪｲ驥・),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 蝠・刀諠・ｱ陦ｨ遉ｺ
              if (product != null) ...[
              Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                          const Icon(Icons.shopping_bag, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                            '繝励Ξ繝溘い繝讖溯・',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                              color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
                      Text(
                        '蝠・刀蜷・ ${product.title}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '隱ｬ譏・ ${product.description}',
                        style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                      Text(
                        '萓｡譬ｼ: ${product.price}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
          ),
        ],
      ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 讖溯・隱ｬ譏・                    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                        const Icon(Icons.info, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
          const Text(
                          '繝励Ξ繝溘い繝讖溯・',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                            color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
                      '雉ｼ蜈･蠕後・莉･荳九・讖溯・縺檎┌蛻ｶ髯舌〒菴ｿ逕ｨ縺ｧ縺阪∪縺呻ｼ・,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
                    const SizedBox(height: 8),
                    const Text('窶｢ 繝｡繝｢縺ｮ霑ｽ蜉繝ｻ邱ｨ髮・),
                    const Text('窶｢ 繧｢繝ｩ繝ｼ繝讖溯・'),
                    const Text('窶｢ 邨ｱ險域ｩ溯・'),
                    const Text('窶｢ 繧ｫ繝ｬ繝ｳ繝繝ｼ讖溯・'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 雉ｼ蜈･繝懊ち繝ｳ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '繧｢繝励Μ蜀・ｪｲ驥代〒雉ｼ蜈･',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
                      onPressed: product != null ? () async {
                        Navigator.of(context).pop();
                        await _startPurchase(product);
                      } : null,
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(product != null ? '${product.price}縺ｧ雉ｼ蜈･' : '蝠・刀諠・ｱ繧貞叙蠕嶺ｸｭ...'),
            style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
              foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await InAppPurchaseService.restorePurchases();
                        
                        // 雉ｼ蜈･螻･豁ｴ蠕ｩ蜈・・邨先棡繧堤｢ｺ隱・                        final isPurchased = await InAppPurchaseService.isPurchased();
                        if (isPurchased) {
                          // 雉ｼ蜈･螻･豁ｴ縺悟ｾｩ蜈・＆繧後◆蝣ｴ蜷医・迚ｹ蛻･縺ｪ繝｡繝・そ繝ｼ繧ｸ
    showDialog(
      context: context,
                            barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
                                  Icon(Icons.restore, color: Colors.blue, size: 32),
            SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('雉ｼ蜈･螻･豁ｴ蠕ｩ蜈・),
                                        Text('螳御ｺ・ｼ・),
                  ],
                ),
              ),
                                ],
                              ),
                              content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                                    '蝠・刀雉ｼ蜈･蠕後∵悄髯舌′辟｡譛滄剞縺ｫ縺ｪ繧翫∪縺励◆・・,
              style: TextStyle(
                                      fontSize: 18,
                fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '驕主悉縺ｮ雉ｼ蜈･螻･豁ｴ縺悟ｾｩ蜈・＆繧後√・繝ｬ繝溘い繝讖溯・縺梧怏蜉ｹ縺ｫ縺ｪ繧翫∪縺励◆縲・,
                                    style: TextStyle(fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('縺ゅｊ縺後→縺・＃縺悶＞縺ｾ縺呻ｼ・),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('雉ｼ蜈･螻･豁ｴ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ縺ｧ縺励◆')),
                          );
                        }
                      },
                      child: const Text('雉ｼ蜈･螻･豁ｴ繧貞ｾｩ蜈・),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('髢峨§繧・),
          ),
        ],
      ),
    );
  }



  // 雉ｼ蜈･繧帝幕蟋・  Future<void> _startPurchase(ProductDetails product) async {
    // 雉ｼ蜈･邨先棡縺ｮ逶｣隕悶ｒ髢句ｧ・    InAppPurchaseService.startPurchaseListener((success, error) {
      if (success) {
        // 雉ｼ蜈･謌仙粥譎ゅ・迚ｹ蛻･縺ｪ繝｡繝・そ繝ｼ繧ｸ繧定｡ｨ遉ｺ
    showDialog(
      context: context,
          barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
                Text('雉ｼ蜈･螳御ｺ・ｼ・),
          ],
        ),
            content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                const Text(
                  '蝠・刀雉ｼ蜈･蠕後∵悄髯舌′辟｡譛滄剞縺ｫ縺ｪ繧翫∪縺励◆・・,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
            Text(
                        '脂 繝励Ξ繝溘い繝讖溯・縺梧怏蜉ｹ縺ｫ縺ｪ繧翫∪縺励◆・・,
              style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '窶｢ 繝｡繝｢縺ｮ霑ｽ蜉繝ｻ邱ｨ髮・n窶｢ 繧｢繝ｩ繝ｼ繝讖溯・\n窶｢ 邨ｱ險域ｩ溯・\n窶｢ 繧ｫ繝ｬ繝ｳ繝繝ｼ讖溯・',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ],
              ),
            ),
          ],
        ),
        actions: [
              ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('縺ゅｊ縺後→縺・＃縺悶＞縺ｾ縺呻ｼ・),
          ),
        ],
      ),
    );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('雉ｼ蜈･縺ｫ螟ｱ謨励＠縺ｾ縺励◆: ${error ?? "荳肴・縺ｪ繧ｨ繝ｩ繝ｼ"}'),
            backgroundColor: Colors.red,
      ),
    );
  }
    });
    
    // 雉ｼ蜈･繧帝幕蟋・    final success = await InAppPurchaseService.purchaseProduct();
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('雉ｼ蜈･縺ｮ髢句ｧ九↓螟ｱ謨励＠縺ｾ縺励◆'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 笨・繝舌ャ繧ｯ繧｢繝・・讖溯・繧貞ｮ溯｣・  Future<void> _showBackupDialog() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.orange),
            SizedBox(width: 8),
            Text('繝舌ャ繧ｯ繧｢繝・・'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '竢ｱ 繝舌ャ繧ｯ繧｢繝・・髢馴囈\n\n'
                  '繝ｻ豈取律豺ｱ螟・:00・郁・蜍包ｼ・ 繝輔Ν繝舌ャ繧ｯ繧｢繝・・\n'
                  '繝ｻ謫堺ｽ懷ｾ・蛻・ｻ･蜀・ｼ郁・蜍包ｼ・ 蟾ｮ蛻・ヰ繝・け繧｢繝・・\n'
                  '繝ｻ謇句虚菫晏ｭ假ｼ井ｻｻ諢擾ｼ・ 莉ｻ諢上ち繧､繝溘Φ繧ｰ縺ｧ菫晏ｭ・,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _createManualBackup();
                },
                icon: const Icon(Icons.save),
                label: const Text('謇句虚繝舌ャ繧ｯ繧｢繝・・繧剃ｽ懈・'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _showBackupHistory();
                },
                icon: const Icon(Icons.history),
                label: const Text('菫晏ｭ伜ｱ･豁ｴ繧定ｦ九ｋ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<bool>(
                future: _hasUndoAvailable(),
                builder: (context, snapshot) {
                  final available = snapshot.data ?? false;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: available
                          ? () async {
                              Navigator.of(context).pop();
                              await _undoLastChange();
                            }
                          : null,
                      icon: const Icon(Icons.undo),
                      label: const Text('1縺､蜑阪・迥ｶ諷九↓蠕ｩ蜈・),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: available ? Colors.teal : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final prefs = await SharedPreferences.getInstance();
                    // 笨・譛譁ｰ繝輔Ν繝舌ャ繧ｯ繧｢繝・・繧貞盾辣ｧ
                    final key = prefs.getString('last_full_backup_key');
                    if (key != null) {
                      await _restoreBackup(key);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('繝輔Ν繝舌ャ繧ｯ繧｢繝・・縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.restore_page),
                  label: const Text('繝輔Ν繝舌ャ繧ｯ繧｢繝・・繧貞ｾｩ蜈・ｼ域怙譁ｰ・・),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('髢峨§繧・),
          ),
        ],
      ),
    );
  }

  // 笨・逶ｴ蜑阪・螟画峩縺悟ｭ伜惠縺吶ｋ縺具ｼ医せ繝翫ャ繝励す繝ｧ繝・ヨ譛臥┌・・  Future<bool> _hasUndoAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastKey = prefs.getString('last_snapshot_key');
      if (lastKey == null) {
        debugPrint('笞・・last_snapshot_key 縺・null');
        return false;
      }
      final data = prefs.getString(lastKey);
      final available = data != null;
      if (!available) {
        debugPrint('笞・・繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ螳滉ｽ薙′隕九▽縺九ｊ縺ｾ縺帙ｓ: $lastKey');
      }
      return available;
    } catch (e) {
      debugPrint('笶・繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ遒ｺ隱阪お繝ｩ繝ｼ: $e');
      return false;
    }
  }

  // 笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ・  Future<void> _saveSnapshotBeforeChange(String operationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final snapshotData = await _createSafeBackupData('螟画峩蜑浩$operationType');
      final jsonString = await _safeJsonEncode(snapshotData);
      final encryptedData = await _encryptDataAsync(jsonString);
      final snapshotKey = 'snapshot_before_$timestamp';
      final ok1 = await prefs.setString(snapshotKey, encryptedData);
      final ok2 = await prefs.setString('last_snapshot_key', snapshotKey);
      if (!(ok1 && ok2)) {
        debugPrint('笞・・繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ倥ヵ繝ｩ繧ｰ縺掲alse: $ok1, $ok2');
      }
      debugPrint('笨・螟画峩蜑阪せ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ伜ｮ御ｺ・ $operationType (key: $snapshotKey)');
    } catch (e) {
      debugPrint('笶・繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ菫晏ｭ倥お繝ｩ繝ｼ: $e');
    }
  }

  // 笨・1縺､蜑阪・迥ｶ諷九↓蠕ｩ蜈・ｼ域怙譁ｰ繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ縺九ｉ・・  Future<void> _undoLastChange() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSnapshotKey = prefs.getString('last_snapshot_key');
      if (lastSnapshotKey == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('蠕ｩ蜈・〒縺阪ｋ螻･豁ｴ縺後≠繧翫∪縺帙ｓ'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _restoreBackup(lastSnapshotKey);
      // 蠕ｩ蜈・↓菴ｿ逕ｨ縺励◆繧ｹ繝翫ャ繝励す繝ｧ繝・ヨ縺ｯ蜑企勁・・蝗樔ｽｿ縺・・繧奇ｼ・      await prefs.remove(lastSnapshotKey);
      await prefs.remove('last_snapshot_key');
      if (mounted) {
        setState(() {
          _focusedDay = _selectedDay ?? DateTime.now();
          // 笨・霑ｽ蜉・壹Γ繝｢繝輔ぅ繝ｼ繝ｫ繝峨ｒ蜀榊酔譛・          if (_selectedDay != null) {
            final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
            // 逶ｴ霑代・菫晏ｭ伜・螳ｹ繧貞渚譏
            SharedPreferences.getInstance().then((p) {
              final memo = p.getString('memo_$dateStr');
              _memoController.text = memo ?? '';
              _memoTextNotifier.value = memo ?? '';
            });
          }
          // 笨・霑ｽ蜉・壹い繝ｩ繝ｼ繝繧ｿ繝悶・螳悟・蜀肴ｧ狗ｯ・          _alarmTabKey = UniqueKey();
          // 笨・霑ｽ蜉・壹き繝ｬ繝ｳ繝繝ｼ濶ｲ縺ｮ蜀榊酔譛・          _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
        });
        // 笨・霑ｽ蜉・壹き繝ｬ繝ｳ繝繝ｼ縺ｨ蜈･蜉帙ｒ蜀崎ｩ穂ｾ｡
        await _updateMedicineInputsForSelectedDate();
        await _loadMemoForSelectedDate();
        // 笨・霑ｽ蜉・夂ｵｱ險医・蜀崎ｨ育ｮ・        await _calculateAdherenceStats();
        // 笨・霑ｽ蜉・壽恪逕ｨ險倬鹸縺ｮ陦ｨ遉ｺ繧貞ｼｷ蛻ｶ譖ｴ譁ｰ
        _updateCalendarMarks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('笨・1縺､蜑阪・迥ｶ諷九↓蠕ｩ蜈・＠縺ｾ縺励◆'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('笶・蠕ｩ蜈・お繝ｩ繝ｼ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('蠕ｩ蜈・↓螟ｱ謨励＠縺ｾ縺励◆: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBackupRecommendation(String timing, String content, String reason, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(timing, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(content, style: const TextStyle(fontSize: 12)),
          Text(reason, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // 笨・謇句虚繝舌ャ繧ｯ繧｢繝・・菴懈・讖溯・
  Future<void> _createManualBackup() async {
    if (!mounted) return;
    
    // 菫晏ｭ伜錐蜈･蜉帙ム繧､繧｢繝ｭ繧ｰ
    final TextEditingController nameController = TextEditingController();
    final now = DateTime.now();
    nameController.text = '${DateFormat('yyyy-MM-dd_HH-mm').format(now)}_謇句虚菫晏ｭ・;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('繝舌ャ繧ｯ繧｢繝・・蜷阪ｒ蜈･蜉・),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '萓・ 2024-01-15_14-30_謇句虚菫晏ｭ・,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('菫晏ｭ・),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await _performBackup(result);
    }
  }

  // 笨・邨ｱ蜷医＆繧後◆繝舌ャ繧ｯ繧｢繝・・菴懈・繝｡繧ｽ繝・ラ・・蝗槭〒螳御ｺ・ｼ・  Future<void> _performBackup(String backupName) async {
    if (!mounted) return;
    
    // 繝ｭ繝ｼ繝・ぅ繝ｳ繧ｰ陦ｨ遉ｺ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text('繝舌ャ繧ｯ繧｢繝・・繧剃ｽ懈・荳ｭ...'),
            ],
          ),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. 繝舌ャ繧ｯ繧｢繝・・繝・・繧ｿ繧堤峩謗･菴懈・・亥梛螳牙・縺ｪ螟画鋤・・      final backupData = await _createSafeBackupData(backupName);
      
      // 2. JSON繧ｨ繝ｳ繧ｳ繝ｼ繝会ｼ医お繝ｩ繝ｼ繝上Φ繝峨Μ繝ｳ繧ｰ莉倥″・・      final jsonString = await _safeJsonEncode(backupData);
      
      // 3. 證怜捷蛹厄ｼ磯撼蜷梧悄・・      final encryptedData = await _encryptDataAsync(jsonString);
      
      // 4. 菫晏ｭ假ｼ・蝗槭〒螳御ｺ・ｼ・      await prefs.setString(backupKey, encryptedData);
      
      // 5. 螻･豁ｴ譖ｴ譁ｰ
      await _updateBackupHistory(backupName, backupKey);
      
      if (!mounted) return;
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('笨・繝舌ャ繧ｯ繧｢繝・・縲・backupName縲阪ｒ菴懈・縺励∪縺励◆'),
            backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      debugPrint('繝舌ャ繧ｯ繧｢繝・・菴懈・繧ｨ繝ｩ繝ｼ: $e');
      if (!mounted) return;
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('繝舌ャ繧ｯ繧｢繝・・縺ｮ菴懈・縺ｫ螟ｱ謨励＠縺ｾ縺励◆: ${e.toString()}'),
            backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 笨・蝙句ｮ牙・縺ｪ繝舌ャ繧ｯ繧｢繝・・繝・・繧ｿ菴懈・
  Future<Map<String, dynamic>> _createSafeBackupData(String backupName) async {
      return {
        'name': backupName,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'manual',
      'version': '1.0.0', // 繝舌・繧ｸ繝ｧ繝ｳ諠・ｱ繧定ｿｽ蜉
      
      // 譛咲畑繝｡繝｢髢｢騾｣・・SON螳牙・・・        'medicationMemos': _medicationMemos.map((memo) => memo.toJson()).toList(),
      'addedMedications': _addedMedications.map((med) => {
        'id': med['id'],
        'name': med['name'],
        'type': med['type'],
        'dosage': med['dosage'],
        'color': (med['color'] as Color).value, // Color 竊・int
        'notes': med['notes'],
        'isChecked': med['isChecked'] ?? false,
        'takenTime': med['takenTime']?.toIso8601String(),
      }).toList(),
      
      // 阮ｬ蜩√ョ繝ｼ繧ｿ・・SON螳牙・・・        'medicines': _medicines.map((medicine) => medicine.toJson()).toList(),
      
      // 譛咲畑繝・・繧ｿ・・edicationInfo 竊・JSON・・        'medicationData': _medicationData.map((dateKey, dayData) {
        return MapEntry(
          dateKey,
          dayData.map((medKey, medInfo) {
            return MapEntry(medKey, medInfo.toJson());
          }),
        );
      }),
      
      // 繝√ぉ繝・け迥ｶ諷矩未騾｣・医・繝ｪ繝溘ユ繧｣繝門梛縺ｮ縺ｿ・・        'weekdayMedicationStatus': _weekdayMedicationStatus,
      'weekdayMedicationDoseStatus': _weekdayMedicationDoseStatus.map((dateKey, memoStatus) {
        return MapEntry(
          dateKey,
          memoStatus.map((memoId, doseStatus) {
            return MapEntry(
              memoId,
              doseStatus.map((doseIndex, isChecked) {
                return MapEntry(doseIndex.toString(), isChecked);
              }),
            );
          }),
        );
      }),
        'medicationMemoStatus': _medicationMemoStatus,
      
      // 繧ｫ繝ｬ繝ｳ繝繝ｼ濶ｲ・・olor 竊・int・・        'dayColors': _dayColors.map((key, value) => MapEntry(key, value.value)),
      
      // 繧｢繝ｩ繝ｼ繝髢｢騾｣・亥ｿ・ｦ√↑蜈ｨ繝輔ぅ繝ｼ繝ｫ繝峨ｒ菫晏ｭ假ｼ・      'alarmList': _alarmList.map((alarm) => {
        'name': alarm['name']?.toString(),
        'time': alarm['time']?.toString(),
        'repeat': alarm['repeat']?.toString(),
        'enabled': (alarm['enabled'] as bool?) ?? true,
        'alarmType': alarm['alarmType']?.toString(),
        'volume': (alarm['volume'] is int)
            ? alarm['volume'] as int
            : int.tryParse(alarm['volume']?.toString() ?? '80') ?? 80,
        'message': alarm['message']?.toString(),
        'isRepeatEnabled': (alarm['isRepeatEnabled'] as bool?) ?? false,
        'selectedDays': (alarm['selectedDays'] is List)
            ? List<bool>.from((alarm['selectedDays'] as List).map((e) => e == true))
            : [false, false, false, false, false, false, false],
      }).toList(),
      'alarmSettings': Map<String, dynamic>.from(_alarmSettings),
      
      // 邨ｱ險医ョ繝ｼ繧ｿ
        'adherenceRates': _adherenceRates,
      };
  }

  // 笨・螳牙・縺ｪJSON繧ｨ繝ｳ繧ｳ繝ｼ繝会ｼ医お繝ｩ繝ｼ繝上Φ繝峨Μ繝ｳ繧ｰ・・  Future<String> _safeJsonEncode(Map<String, dynamic> data) async {
    try {
      return jsonEncode(data);
      } catch (e) {
        debugPrint('JSON繧ｨ繝ｳ繧ｳ繝ｼ繝峨お繝ｩ繝ｼ: $e');
      debugPrint('蝠城｡後・縺ゅｋ繝・・繧ｿ: ${data.keys}');
      
      // 繧ｨ繝ｩ繝ｼ縺檎匱逕溘＠縺溷ｴ蜷医∝撫鬘後・縺ゅｋ繝輔ぅ繝ｼ繝ｫ繝峨ｒ迚ｹ螳・    final safeData = <String, dynamic>{};
      for (final entry in data.entries) {
      try {
          jsonEncode({entry.key: entry.value}); // 蛟句挨縺ｫ繝・せ繝・        safeData[entry.key] = entry.value;
        } catch (fieldError) {
          debugPrint('繝輔ぅ繝ｼ繝ｫ繝・${entry.key} 縺ｧ繧ｨ繝ｩ繝ｼ: $fieldError');
          safeData[entry.key] = null; // 蝠城｡後・縺ゅｋ繝輔ぅ繝ｼ繝ｫ繝峨・null縺ｫ
        }
      }
      
      return jsonEncode(safeData);
    }
  }

  // 笨・髱槫酔譛滓囓蜿ｷ蛹・  Future<String> _encryptDataAsync(String data) async {
    // XOR證怜捷蛹・      final key = 'medication_app_backup_key_2024';
      final encrypted = StringBuffer();
      for (int i = 0; i < data.length; i++) {
        encrypted.write(String.fromCharCode(
          data.codeUnitAt(i) ^ key.codeUnitAt(i % key.length)
        ));
      }
      return encrypted.toString();
  }

  // 笨・髱槫酔譛溷ｾｩ蜿ｷ蛹・  Future<String> _decryptDataAsync(String encryptedData) async {
    // XOR證怜捷蛹悶・蠕ｩ蜿ｷ蛹・    final key = 'medication_app_backup_key_2024';
    final decrypted = StringBuffer();
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted.write(String.fromCharCode(
        encryptedData.codeUnitAt(i) ^ key.codeUnitAt(i % key.length)
      ));
    }
    return decrypted.toString();
  }

  // 笨・繝・・繧ｿ蠕ｩ蜿ｷ蛹匁ｩ溯・
  String _decryptData(String encryptedData) {
    // XOR證怜捷蛹悶・蠕ｩ蜿ｷ蛹・    final key = 'medication_app_backup_key_2024';
    final decrypted = StringBuffer();
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted.write(String.fromCharCode(
        encryptedData.codeUnitAt(i) ^ key.codeUnitAt(i % key.length)
      ));
    }
    return decrypted.toString();
  }

  // 笨・髱槫酔譛溘ョ繝ｼ繧ｿ蠕ｩ蜈・ｼ域怙驕ｩ蛹也沿・・  Future<void> _restoreDataAsync(Map<String, dynamic> backupData) async {
    try {
      // 繝舌・繧ｸ繝ｧ繝ｳ繝√ぉ繝・け
      final version = backupData['version'] as String?;
      if (version == null) {
        debugPrint('隴ｦ蜻・ 繝舌ャ繧ｯ繧｢繝・・繝舌・繧ｸ繝ｧ繝ｳ諠・ｱ縺後≠繧翫∪縺帙ｓ');
      }
      
      // 1. 譛咲畑繝｡繝｢縺ｮ蠕ｩ蜈・      final restoredMemos = (backupData['medicationMemos'] as List? ?? [])
          .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // 2. 霑ｽ蜉阮ｬ蜩√・蠕ｩ蜈・ｼ・olor螟画鋤・・      final restoredAddedMedications = (backupData['addedMedications'] as List? ?? [])
          .map((med) => {
            'id': med['id'],
            'name': med['name'],
            'type': med['type'],
            'dosage': med['dosage'],
            'color': Color(med['color'] as int), // int 竊・Color
            'notes': med['notes'],
            'isChecked': med['isChecked'] ?? false,
            'takenTime': med['takenTime'] != null 
                ? DateTime.parse(med['takenTime'] as String)
                : null,
          })
          .cast<Map<String, dynamic>>()
          .toList();
      
      // 3. 阮ｬ蜩√ョ繝ｼ繧ｿ縺ｮ蠕ｩ蜈・      final restoredMedicines = (backupData['medicines'] as List? ?? [])
          .map((json) => MedicineData.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // 4. 譛咲畑繝・・繧ｿ縺ｮ蠕ｩ蜈・ｼ・SON 竊・MedicationInfo・・      final restoredMedicationData = <String, Map<String, MedicationInfo>>{};
      if (backupData['medicationData'] != null) {
        final medicationDataMap = backupData['medicationData'] as Map<String, dynamic>;
        for (final entry in medicationDataMap.entries) {
          final dateKey = entry.key;
          final dayData = entry.value as Map<String, dynamic>;
          final medicationInfoMap = <String, MedicationInfo>{};
          
          for (final medEntry in dayData.entries) {
            final medKey = medEntry.key;
            final medData = medEntry.value as Map<String, dynamic>;
            medicationInfoMap[medKey] = MedicationInfo.fromJson(medData);
          }
          
          restoredMedicationData[dateKey] = medicationInfoMap;
        }
      }
      
      // 5. 繝√ぉ繝・け迥ｶ諷九・蠕ｩ蜈・      final restoredWeekdayStatus = <String, Map<String, bool>>{};
      if (backupData['weekdayMedicationStatus'] != null) {
        final statusMap = backupData['weekdayMedicationStatus'] as Map<String, dynamic>;
        for (final entry in statusMap.entries) {
          restoredWeekdayStatus[entry.key] = Map<String, bool>.from(entry.value as Map);
        }
      }
      
      final restoredWeekdayDoseStatus = <String, Map<String, Map<int, bool>>>{};
      if (backupData['weekdayMedicationDoseStatus'] != null) {
        final doseStatusMap = backupData['weekdayMedicationDoseStatus'] as Map<String, dynamic>;
        for (final dateEntry in doseStatusMap.entries) {
          final dateKey = dateEntry.key;
          final memoStatusMap = dateEntry.value as Map<String, dynamic>;
          final memoStatus = <String, Map<int, bool>>{};
          
          for (final memoEntry in memoStatusMap.entries) {
            final memoId = memoEntry.key;
            final doseStatusMap = memoEntry.value as Map<String, dynamic>;
            final doseStatus = <int, bool>{};
            
            for (final doseEntry in doseStatusMap.entries) {
              final doseIndex = int.parse(doseEntry.key);
              doseStatus[doseIndex] = doseEntry.value as bool;
            }
            
            memoStatus[memoId] = doseStatus;
          }
          
          restoredWeekdayDoseStatus[dateKey] = memoStatus;
        }
      }
      
      final restoredMemoStatus = backupData['medicationMemoStatus'] != null
          ? Map<String, bool>.from(backupData['medicationMemoStatus'] as Map)
          : <String, bool>{};
      
      // 6. 繧ｫ繝ｬ繝ｳ繝繝ｼ濶ｲ縺ｮ蠕ｩ蜈・ｼ・nt 竊・Color・・      final restoredDayColors = <String, Color>{};
      if (backupData['dayColors'] != null) {
        final colorsMap = backupData['dayColors'] as Map<String, dynamic>;
        for (final entry in colorsMap.entries) {
          restoredDayColors[entry.key] = Color(entry.value as int);
        }
      }
      
      // 7. 繧｢繝ｩ繝ｼ繝縺ｮ蠕ｩ蜈・      final restoredAlarmList = (backupData['alarmList'] as List? ?? [])
          .map((alarm) => Map<String, dynamic>.from(alarm as Map))
          .toList();
      
      final restoredAlarmSettings = backupData['alarmSettings'] != null
          ? Map<String, dynamic>.from(backupData['alarmSettings'] as Map)
          : <String, dynamic>{};
      
      // 8. 邨ｱ險医ョ繝ｼ繧ｿ縺ｮ蠕ｩ蜈・      final restoredAdherenceRates = backupData['adherenceRates'] != null
          ? Map<String, double>.from(backupData['adherenceRates'] as Map)
          : <String, double>{};
      
      // 9. 繧｢繝ｩ繝ｼ繝繧担haredPreferences縺ｫ菫晏ｭ・      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('alarm_count', restoredAlarmList.length);
      
      for (int i = 0; i < restoredAlarmList.length; i++) {
        final alarm = restoredAlarmList[i];
        await prefs.setString('alarm_${i}_name', alarm['name']?.toString() ?? '繧｢繝ｩ繝ｼ繝');
        await prefs.setString('alarm_${i}_time', alarm['time']?.toString() ?? '00:00');
        await prefs.setString('alarm_${i}_repeat', alarm['repeat']?.toString() ?? '荳蠎ｦ縺縺・);
        await prefs.setString('alarm_${i}_alarmType', alarm['alarmType']?.toString() ?? 'sound');
        await prefs.setBool('alarm_${i}_enabled', alarm['enabled'] as bool? ?? true);
        await prefs.setBool('alarm_${i}_isRepeatEnabled', alarm['isRepeatEnabled'] as bool? ?? false);
        await prefs.setInt('alarm_${i}_volume', alarm['volume'] as int? ?? 80);
        
        // 譖懈律繝・・繧ｿ・亥梛螳牙・縺ｫ蠕ｩ蜈・ｼ・        final dynamic selectedDaysRaw = alarm['selectedDays'];
        final List<bool> selectedDays = selectedDaysRaw is List
            ? List<bool>.from(selectedDaysRaw.map((e) => e == true))
            : <bool>[false, false, false, false, false, false, false];
        for (int j = 0; j < 7; j++) {
          await prefs.setBool('alarm_${i}_day_$j', j < selectedDays.length ? selectedDays[j] : false);
        }
      }
      
      // 10. 荳諡ｬsetState・・蝗槭・縺ｿ・・      if (!mounted) return;
      
      setState(() {
        _medicationMemos = restoredMemos;
        _addedMedications = restoredAddedMedications;
        _medicines = restoredMedicines;
        _medicationData = restoredMedicationData;
        _weekdayMedicationStatus = restoredWeekdayStatus;
        _weekdayMedicationDoseStatus = restoredWeekdayDoseStatus;
        _medicationMemoStatus = restoredMemoStatus;
        _dayColors = restoredDayColors;
        _alarmList = restoredAlarmList;
        _alarmSettings = restoredAlarmSettings;
        _adherenceRates = restoredAdherenceRates;
        
        // 笨・SimpleAlarmApp繧貞ｮ悟・縺ｫ蜀肴ｧ狗ｯ・        _alarmTabKey = UniqueKey();  // 譁ｰ縺励＞繧ｭ繝ｼ縺ｧ蠑ｷ蛻ｶ蜀肴ｧ狗ｯ・      });
      
      // 11. 繝・・繧ｿ菫晏ｭ假ｼ亥ｾｩ蜈・ｾ鯉ｼ・      await _saveAllData();
      
      debugPrint('繧｢繝ｩ繝ｼ繝蠕ｩ蜈・ｮ御ｺ・ｼ亥ｼｷ蛻ｶ蜀肴ｧ狗ｯ会ｼ・ ${restoredAlarmList.length}莉ｶ');
      debugPrint('繝舌ャ繧ｯ繧｢繝・・蠕ｩ蜈・ｮ御ｺ・ ${restoredMemos.length}莉ｶ縺ｮ繝｡繝｢');
    } catch (e) {
      debugPrint('繝・・繧ｿ蠕ｩ蜈・お繝ｩ繝ｼ: $e');
      rethrow;
    }
  }




  // 笨・繝舌ャ繧ｯ繧｢繝・・螻･豁ｴ縺ｮ譖ｴ譁ｰ・・莉ｶ蛻ｶ髯撰ｼ・  Future<void> _updateBackupHistory(String backupName, String backupKey, {String type = 'manual'}) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('backup_history') ?? '[]';
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson) as List);
    
    history.add({
      'name': backupName,
      'key': backupKey,
      'createdAt': DateTime.now().toIso8601String(),
      'type': type,
    });
    
    // 蜿､縺・・↓閾ｪ蜍募炎髯､・域怙螟ｧ5莉ｶ縺ｾ縺ｧ菫晄戟・・    if (history.length > 5) {
      // 蜿､縺・ヰ繝・け繧｢繝・・繝・・繧ｿ繧貞炎髯､
      final oldBackup = history.removeAt(0);
      await prefs.remove(oldBackup['key'] as String);
    }
    
    await prefs.setString('backup_history', jsonEncode(history));
  }

  // 笨・繝舌ャ繧ｯ繧｢繝・・螻･豁ｴ陦ｨ遉ｺ讖溯・・亥ｼｷ蛹也沿・・  Future<void> _showBackupHistory() async {
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('backup_history') ?? '[]';
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson) as List);
    
    // 閾ｪ蜍輔ヰ繝・け繧｢繝・・繧ょ性繧√※蜈ｨ縺ｦ縺ｮ繝舌ャ繧ｯ繧｢繝・・繧貞叙蠕・    final allBackups = <Map<String, dynamic>>[];
    
    // 謇句虚繝舌ャ繧ｯ繧｢繝・・螻･豁ｴ繧定ｿｽ蜉
    for (final backup in history) {
      allBackups.add({
        ...backup,
        'type': 'manual',
        'source': '螻･豁ｴ',
      });
    }
    
    // 閾ｪ蜍輔ヰ繝・け繧｢繝・・繧定ｿｽ蜉
    final autoBackupKey = prefs.getString('last_auto_backup_key');
    if (autoBackupKey != null) {
      allBackups.add({
        'name': '閾ｪ蜍輔ヰ繝・け繧｢繝・・・域怙譁ｰ・・,
        'key': autoBackupKey,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'auto',
        'source': '閾ｪ蜍・,
      });
    }
    
    if (allBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('繝舌ャ繧ｯ繧｢繝・・縺後≠繧翫∪縺帙ｓ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.blue),
            SizedBox(width: 8),
            Text('繝舌ャ繧ｯ繧｢繝・・荳隕ｧ'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: ListView.builder(
            itemCount: allBackups.length,
            itemBuilder: (context, index) {
              final backup = allBackups[allBackups.length - 1 - index]; // 譁ｰ縺励＞鬆・↓陦ｨ遉ｺ
              final createdAt = DateTime.parse(backup['createdAt'] as String);
              final isAuto = backup['type'] == 'auto';
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isAuto ? Icons.schedule : Icons.backup,
                    color: isAuto ? Colors.green : Colors.orange,
                  ),
                  title: Text(backup['name'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('yyyy-MM-dd HH:mm').format(createdAt)),
                      Text(
                        '${backup['source']}繝舌ャ繧ｯ繧｢繝・・',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAuto ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'restore':
                          await _restoreBackup(backup['key'] as String);
                          break;
                        case 'delete':
                          if (!isAuto) {
                            await _deleteBackup(backup['key'] as String, index);
                          }
                          break;
                        case 'preview':
                          await _previewBackup(backup['key'] as String);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restore, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('蠕ｩ蜈・),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.green),
                            SizedBox(width: 8),
                            Text('繝励Ξ繝薙Η繝ｼ'),
                          ],
                        ),
                      ),
                      if (!isAuto) const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('蜑企勁'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('髢峨§繧・),
          ),
        ],
      ),
    );
  }

  // 笨・繝舌ャ繧ｯ繧｢繝・・繝励Ξ繝薙Η繝ｼ讖溯・
  Future<void> _previewBackup(String backupKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = prefs.getString(backupKey);
      
      if (encryptedData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('繝舌ャ繧ｯ繧｢繝・・繝・・繧ｿ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final decryptedData = await _decryptDataAsync(encryptedData);
      final backupData = jsonDecode(decryptedData);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('繝舌ャ繧ｯ繧｢繝・・繝励Ξ繝薙Η繝ｼ'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('蜷榊燕: ${backupData['name'] as String}'),
                  Text('菴懈・譌･譎・ ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(backupData['createdAt']))}'),
                  const SizedBox(height: 8),
                  const Text('投 繝舌ャ繧ｯ繧｢繝・・蜀・ｮｹ:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('繝ｻ譛咲畑繝｡繝｢謨ｰ: ${(backupData['medicationMemos'] as List).length}莉ｶ'),
                  Text('繝ｻ霑ｽ蜉阮ｬ蜩∵焚: ${(backupData['addedMedications'] as List).length}莉ｶ'),
                  Text('繝ｻ阮ｬ蜩√ョ繝ｼ繧ｿ謨ｰ: ${(backupData['medicines'] as List).length}莉ｶ'),
                  Text('繝ｻ繧｢繝ｩ繝ｼ繝謨ｰ: ${(backupData['alarmList'] as List).length}莉ｶ'),
                  Text('繝ｻ繧ｫ繝ｬ繝ｳ繝繝ｼ濶ｲ險ｭ螳・ ${(backupData['dayColors'] as Map).length}譌･蛻・),
                  Text('繝ｻ繝√ぉ繝・け迥ｶ諷・ ${(backupData['weekdayMedicationStatus'] as Map).length}譌･蛻・),
                  Text('繝ｻ譛咲畑邇・ョ繝ｼ繧ｿ: ${(backupData['adherenceRates'] as Map).length}莉ｶ'),
                  const SizedBox(height: 16),
                  const Text('縺薙・繝舌ャ繧ｯ繧｢繝・・繧貞ｾｩ蜈・＠縺ｾ縺吶°・・),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _restoreBackup(backupKey);
                },
                child: const Text('蠕ｩ蜈・☆繧・),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('繝励Ξ繝薙Η繝ｼ縺ｮ陦ｨ遉ｺ縺ｫ螟ｱ謨励＠縺ｾ縺励◆: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 笨・繝舌ャ繧ｯ繧｢繝・・蠕ｩ蜈・ｩ溯・・域怙驕ｩ蛹也沿・・  Future<void> _restoreBackup(String backupKey) async {
    // 繝ｭ繝ｼ繝・ぅ繝ｳ繧ｰ陦ｨ遉ｺ
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('繝舌ャ繧ｯ繧｢繝・・繧貞ｾｩ蜈・ｸｭ...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    try {
      // 髱槫酔譛溘〒繝舌ャ繧ｯ繧｢繝・・繝・・繧ｿ繧定ｪｭ縺ｿ霎ｼ縺ｿ
      final backupData = await _loadBackupDataAsync(backupKey);
      
      if (backupData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('繝舌ャ繧ｯ繧｢繝・・繝・・繧ｿ縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // 笨・譁ｰ縺励＞譛驕ｩ蛹悶＆繧後◆蠕ｩ蜈・・逅・ｒ菴ｿ逕ｨ
      await _restoreDataAsync(backupData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('繝舌ャ繧ｯ繧｢繝・・繧貞ｾｩ蜈・＠縺ｾ縺励◆'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('繝舌ャ繧ｯ繧｢繝・・縺ｮ蠕ｩ蜈・↓螟ｱ謨励＠縺ｾ縺励◆: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 笨・髱槫酔譛溘〒繝舌ャ繧ｯ繧｢繝・・繝・・繧ｿ繧定ｪｭ縺ｿ霎ｼ縺ｿ
  Future<Map<String, dynamic>?> _loadBackupDataAsync(String backupKey) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(backupKey);
    
    if (encryptedData == null) return null;
    
    // 髱槫酔譛溘〒蠕ｩ蜿ｷ蛹・    final decryptedData = await _decryptDataAsync(encryptedData);
    return jsonDecode(decryptedData);
  }



  // 笨・繝舌ャ繧ｯ繧｢繝・・蜑企勁讖溯・
  Future<void> _deleteBackup(String backupKey, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 繝舌ャ繧ｯ繧｢繝・・繝・・繧ｿ繧貞炎髯､
      await prefs.remove(backupKey);
      
      // 螻･豁ｴ縺九ｉ蜑企勁
      final historyJson = prefs.getString('backup_history') ?? '[]';
      final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson) as List);
      history.removeAt(history.length - 1 - index);
      await prefs.setString('backup_history', jsonEncode(history));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('繝舌ャ繧ｯ繧｢繝・・繧貞炎髯､縺励∪縺励◆'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('繝舌ャ繧ｯ繧｢繝・・縺ｮ蜑企勁縺ｫ螟ｱ謨励＠縺ｾ縺励◆: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // 繧ｭ繝ｼ繝懊・繝芽｡ｨ遉ｺ譎ゅ・繧ｪ繝ｼ繝舌・繝輔Ο繝ｼ繧帝亟豁｢
        appBar: AppBar(
          title: const Text(
            '繧ｵ繝励Μ・・♀縺上☆繧翫せ繧ｱ繧ｸ繝･繝ｼ繝ｫ邂｡逅・ｸｳ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          titleSpacing: 0,
          actions: [
            // 雉ｼ蜈･迥ｶ諷玖ｨｭ螳壹Γ繝九Η繝ｼ
              PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                  case 'purchase_status':
                    _showTrialStatus();
                      break;
                  case 'set_purchase_link':
                    _showPurchaseLinkDialog();
                      break;
                  case 'backup':
                    _showBackupDialog();
                      break;
                  // 髢狗匱逕ｨ: 謇句虚縺ｧ雉ｼ蜈･迥ｶ諷・繝医Λ繧､繧｢繝ｫ迥ｶ諷九ｒ蛻・ｊ譖ｿ縺医ｋ繝｡繝九Η繝ｼ・域悽逡ｪ縺ｧ縺ｯ辟｡蜉ｹ・・                  // case 'set_purchased':
                  //   _setPurchasedStatus();
                  //     break;
                  // case 'set_trial':
                  //   _setTrialStatus();
                  //     break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                  value: 'purchase_status',
                    child: Row(
                      children: [
                      const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                      const Text('雉ｼ蜈･迥ｶ諷・),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                  value: 'set_purchase_link',
                    child: Row(
                      children: [
                      const Icon(Icons.payment, color: Colors.green),
                        const SizedBox(width: 8),
                      const Text('隱ｲ驥第ュ蝣ｱ'),
                      ],
                    ),
                  ),
                  // 笨・菫ｮ豁｣・壹ヰ繝・け繧｢繝・・讖溯・繧定ｿｽ蜉
                  PopupMenuItem(
                    value: 'backup',
                    child: Row(
                      children: [
                        const Icon(Icons.backup, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('繝舌ャ繧ｯ繧｢繝・・'),
                      ],
                    ),
                  ),
                  // 髢狗匱逕ｨ: 謇句虚蛻・崛繝｡繝九Η繝ｼ・域悽逡ｪ縺ｧ縺ｯ繧ｳ繝｡繝ｳ繝医い繧ｦ繝茨ｼ・                  // PopupMenuItem(
                  // value: 'set_purchased',
                  //   child: Row(
                  //     children: [
                  //     const Icon(Icons.check_circle, color: Colors.green),
                  //       const SizedBox(width: 8),
                  //     const Text('雉ｼ蜈･迥ｶ諷九↓縺吶ｋ・磯幕逋ｺ逕ｨ・・),
                  //     ],
                  //   ),
                  // ),
                  // PopupMenuItem(
                  // value: 'set_trial',
                  //   child: Row(
                  //     children: [
                  //     const Icon(Icons.timer, color: Colors.blue),
                  //       const SizedBox(width: 8),
                  //     const Text('繝医Λ繧､繧｢繝ｫ迥ｶ諷九↓縺吶ｋ・磯幕逋ｺ逕ｨ・・),
                  //     ],
                  //   ),
                  // ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.calendar_month), text: '繧ｫ繝ｬ繝ｳ繝繝ｼ'),
              Tab(icon: Icon(Icons.medication), text: '譛咲畑繝｡繝｢'),
              Tab(icon: Icon(Icons.alarm), text: '繧｢繝ｩ繝ｼ繝'),
              Tab(icon: Icon(Icons.analytics), text: '邨ｱ險・),
            ],
          ),
        ),
        body: _isInitialized
          ? Card(
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.02, // 逕ｻ髱｢蟷・・2%
                vertical: 8,
              ),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 繧ｫ繝ｬ繝ｳ繝繝ｼ繧ｿ繝・                    _buildCalendarTab(),
                    // 阮ｬ蜩√ち繝・                    _buildMedicineTab(),
                    // 譛咲畑繧｢繝ｩ繝ｼ繝繧ｿ繝・                    _buildAlarmTab(),
                    // 邨ｱ險医ち繝・                    _buildStatsTab(),
                  ],
                ),
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '繧｢繝励Μ繧貞・譛溷喧荳ｭ...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
        ),
        // 譛咲畑繝｡繝｢繧ｿ繝悶〒縺ｮ縺ｿFloatingActionButton繧定｡ｨ遉ｺ
        floatingActionButton: _tabController.index == 1 
          ? FloatingActionButton(
              onPressed: _addMemo,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      ),
    );
  }

  // 繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ荳顔ｫｯ縺ｫ蛻ｰ驕斐＠縺滓凾縺ｮ蜃ｦ逅・ｼ育判髱｢驕ｷ遘ｻ縺ｪ縺暦ｼ・  void _onScrollToTop() {
    debugPrint('譛咲畑險倬鹸繝ｪ繧ｹ繝井ｸ顔ｫｯ縺ｫ蛻ｰ驕・);
    // 逕ｻ髱｢驕ｷ遘ｻ繧貞炎髯､ - 繝ｦ繝ｼ繧ｶ繝ｼ縺梧焔蜍輔〒繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ縺ｧ縺阪ｋ繧医≧縺ｫ縺吶ｋ
  }

  // 繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ荳狗ｫｯ縺ｫ蛻ｰ驕斐＠縺滓凾縺ｮ蜃ｦ逅・ｼ育判髱｢驕ｷ遘ｻ縺ｪ縺暦ｼ・  void _onScrollToBottom() {
    debugPrint('譛咲畑險倬鹸繝ｪ繧ｹ繝井ｸ狗ｫｯ縺ｫ蛻ｰ驕・);
    // 逕ｻ髱｢驕ｷ遘ｻ繧貞炎髯､ - 繝ｦ繝ｼ繧ｶ繝ｼ縺梧焔蜍輔〒荳翫↓繧ｹ繧ｯ繝ｭ繝ｼ繝ｫ縺ｧ縺阪ｋ繧医≧縺ｫ縺吶ｋ
  }





  // 荳顔ｫｯ縺ｧ縺ｮ繝翫ン繧ｲ繝ｼ繧ｷ繝ｧ繝ｳ繝偵Φ繝郁｡ｨ遉ｺ
  void _showTopNavigationHint() {
    // 霆ｽ縺・ワ繝励ユ繧｣繝・け繝輔ぅ繝ｼ繝峨ヰ繝・け縺ｧ荳顔ｫｯ蛻ｰ驕斐ｒ騾夂衍
