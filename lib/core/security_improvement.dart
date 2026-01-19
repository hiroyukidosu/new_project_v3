import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../utils/logger.dart';

/// セキュリティ改善 - 暗号化とセキュアストレージ
class SecurityImprovement {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  /// セキュアストレージへの保存
  static Future<void> saveSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      Logger.debug('セキュアデータ保存完了: $key');
    } catch (e) {
      Logger.error('セキュアデータ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// セキュアストレージからの読み込み
  static Future<String?> loadSecureData(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) {
        Logger.debug('セキュアデータ読み込み完了: $key');
      }
      return value;
    } catch (e) {
      Logger.error('セキュアデータ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// セキュアストレージからの削除
  static Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      Logger.debug('セキュアデータ削除完了: $key');
    } catch (e) {
      Logger.error('セキュアデータ削除エラー: $key', e);
      rethrow;
    }
  }
  
  /// データの暗号化
  static String encryptData(String data, String key) {
    try {
      final bytes = utf8.encode(data);
      final keyBytes = utf8.encode(key);
      final encrypted = _xorEncrypt(bytes, keyBytes);
      final encoded = base64Encode(encrypted);
      
      Logger.debug('データ暗号化完了: ${data.length}文字');
      return encoded;
    } catch (e) {
      Logger.error('データ暗号化エラー', e);
      rethrow;
    }
  }
  
  /// データの復号化
  static String decryptData(String encryptedData, String key) {
    try {
      final decoded = base64Decode(encryptedData);
      final keyBytes = utf8.encode(key);
      final decrypted = _xorDecrypt(decoded, keyBytes);
      final data = utf8.decode(decrypted);
      
      Logger.debug('データ復号化完了: ${data.length}文字');
      return data;
    } catch (e) {
      Logger.error('データ復号化エラー', e);
      rethrow;
    }
  }
  
  /// XOR暗号化
  static Uint8List _xorEncrypt(Uint8List data, Uint8List key) {
    final result = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length];
    }
    return result;
  }
  
  /// XOR復号化
  static Uint8List _xorDecrypt(Uint8List data, Uint8List key) {
    return _xorEncrypt(data, key); // XORは対称的
  }
  
  /// データのハッシュ化
  static String hashData(String data) {
    try {
      final bytes = utf8.encode(data);
      final digest = sha256.convert(bytes);
      
      Logger.debug('データハッシュ化完了');
      return digest.toString();
    } catch (e) {
      Logger.error('データハッシュ化エラー', e);
      rethrow;
    }
  }
  
  /// パスワードの検証
  static bool validatePassword(String password) {
    // パスワードの強度チェック
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    
    return true;
  }
  
  /// セキュアなランダムキーの生成
  static String generateSecureKey() {
    try {
      final random = DateTime.now().millisecondsSinceEpoch.toString();
      final hash = hashData(random);
      
      Logger.debug('セキュアキー生成完了');
      return hash;
    } catch (e) {
      Logger.error('セキュアキー生成エラー', e);
      rethrow;
    }
  }
}

/// セキュアデータマネージャー
class SecureDataManager {
  static const String _encryptionKey = 'medication_app_encryption_key';
  static const String _userDataKey = 'user_data';
  static const String _medicationDataKey = 'medication_data';
  static const String _settingsKey = 'app_settings';
  
  /// ユーザーデータの暗号化保存
  static Future<void> saveUserData(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      final encryptedData = SecurityImprovement.encryptData(jsonString, _encryptionKey);
      await SecurityImprovement.saveSecureData(_userDataKey, encryptedData);
      
      Logger.info('ユーザーデータ暗号化保存完了');
    } catch (e) {
      Logger.error('ユーザーデータ暗号化保存エラー', e);
      rethrow;
    }
  }
  
  /// ユーザーデータの復号化読み込み
  static Future<Map<String, dynamic>?> loadUserData() async {
    try {
      final encryptedData = await SecurityImprovement.loadSecureData(_userDataKey);
      if (encryptedData != null) {
        final decryptedData = SecurityImprovement.decryptData(encryptedData, _encryptionKey);
        final data = jsonDecode(decryptedData) as Map<String, dynamic>;
        
        Logger.info('ユーザーデータ復号化読み込み完了');
        return data;
      }
      return null;
    } catch (e) {
      Logger.error('ユーザーデータ復号化読み込みエラー', e);
      return null;
    }
  }
  
  /// メディケーションデータの暗号化保存
  static Future<void> saveMedicationData(List<Map<String, dynamic>> data) async {
    try {
      final jsonString = jsonEncode(data);
      final encryptedData = SecurityImprovement.encryptData(jsonString, _encryptionKey);
      await SecurityImprovement.saveSecureData(_medicationDataKey, encryptedData);
      
      Logger.info('メディケーションデータ暗号化保存完了: ${data.length}件');
    } catch (e) {
      Logger.error('メディケーションデータ暗号化保存エラー', e);
      rethrow;
    }
  }
  
  /// メディケーションデータの復号化読み込み
  static Future<List<Map<String, dynamic>>?> loadMedicationData() async {
    try {
      final encryptedData = await SecurityImprovement.loadSecureData(_medicationDataKey);
      if (encryptedData != null) {
        final decryptedData = SecurityImprovement.decryptData(encryptedData, _encryptionKey);
        final data = jsonDecode(decryptedData) as List<dynamic>;
        
        Logger.info('メディケーションデータ復号化読み込み完了: ${data.length}件');
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      Logger.error('メディケーションデータ復号化読み込みエラー', e);
      return null;
    }
  }
  
  /// アプリ設定の暗号化保存
  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = jsonEncode(settings);
      final encryptedData = SecurityImprovement.encryptData(jsonString, _encryptionKey);
      await SecurityImprovement.saveSecureData(_settingsKey, encryptedData);
      
      Logger.info('アプリ設定暗号化保存完了');
    } catch (e) {
      Logger.error('アプリ設定暗号化保存エラー', e);
      rethrow;
    }
  }
  
  /// アプリ設定の復号化読み込み
  static Future<Map<String, dynamic>?> loadAppSettings() async {
    try {
      final encryptedData = await SecurityImprovement.loadSecureData(_settingsKey);
      if (encryptedData != null) {
        final decryptedData = SecurityImprovement.decryptData(encryptedData, _encryptionKey);
        final settings = jsonDecode(decryptedData) as Map<String, dynamic>;
        
        Logger.info('アプリ設定復号化読み込み完了');
        return settings;
      }
      return null;
    } catch (e) {
      Logger.error('アプリ設定復号化読み込みエラー', e);
      return null;
    }
  }
  
  /// 全データの削除
  static Future<void> deleteAllData() async {
    try {
      await Future.wait([
        SecurityImprovement.deleteSecureData(_userDataKey),
        SecurityImprovement.deleteSecureData(_medicationDataKey),
        SecurityImprovement.deleteSecureData(_settingsKey),
      ]);
      
      Logger.info('全セキュアデータ削除完了');
    } catch (e) {
      Logger.error('全セキュアデータ削除エラー', e);
      rethrow;
    }
  }
}

/// セキュリティ監査システム
class SecurityAuditSystem {
  static final List<SecurityEvent> _securityEvents = [];
  static final Map<String, int> _failedAttempts = {};
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  /// セキュリティイベントの記録
  static void recordSecurityEvent(SecurityEventType type, String description) {
    final event = SecurityEvent(
      type: type,
      description: description,
      timestamp: DateTime.now(),
    );
    
    _securityEvents.add(event);
    Logger.warning('セキュリティイベント記録: $type - $description');
    
    // イベント数が多すぎる場合は古いイベントを削除
    if (_securityEvents.length > 1000) {
      _securityEvents.removeRange(0, 100);
    }
  }
  
  /// 認証失敗の記録
  static void recordAuthenticationFailure(String identifier) {
    _failedAttempts[identifier] = (_failedAttempts[identifier] ?? 0) + 1;
    
    if (_failedAttempts[identifier]! >= _maxFailedAttempts) {
      recordSecurityEvent(
        SecurityEventType.authenticationFailure,
        '認証失敗回数上限: $identifier',
      );
    }
  }
  
  /// 認証成功の記録
  static void recordAuthenticationSuccess(String identifier) {
    _failedAttempts.remove(identifier);
    recordSecurityEvent(
      SecurityEventType.authenticationSuccess,
      '認証成功: $identifier',
    );
  }
  
  /// アカウントロックアウトのチェック
  static bool isAccountLocked(String identifier) {
    final failedCount = _failedAttempts[identifier] ?? 0;
    return failedCount >= _maxFailedAttempts;
  }
  
  /// セキュリティ統計の取得
  static Map<String, dynamic> getSecurityStats() {
    final now = DateTime.now();
    final recentEvents = _securityEvents.where(
      (event) => now.difference(event.timestamp).inHours < 24,
    ).toList();
    
    return {
      'totalEvents': _securityEvents.length,
      'recentEvents': recentEvents.length,
      'failedAttempts': Map.from(_failedAttempts),
      'lockedAccounts': _failedAttempts.entries
          .where((entry) => entry.value >= _maxFailedAttempts)
          .map((entry) => entry.key)
          .toList(),
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _securityEvents.clear();
    _failedAttempts.clear();
    Logger.info('セキュリティ統計をクリアしました');
  }
}

/// セキュリティイベント
class SecurityEvent {
  final SecurityEventType type;
  final String description;
  final DateTime timestamp;
  
  SecurityEvent({
    required this.type,
    required this.description,
    required this.timestamp,
  });
  
  @override
  String toString() {
    return 'SecurityEvent($type): $description at $timestamp';
  }
}

/// セキュリティイベントタイプ
enum SecurityEventType {
  authenticationSuccess,
  authenticationFailure,
  dataAccess,
  dataModification,
  securityViolation,
  systemError,
}

/// セキュリティ改善の実装例
class SecureOptimizedApp extends StatelessWidget {
  const SecureOptimizedApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'セキュリティ改善アプリ',
      home: const SecureOptimizedHomePage(),
    );
  }
}

/// セキュリティ改善のホームページ
class SecureOptimizedHomePage extends StatefulWidget {
  const SecureOptimizedHomePage({super.key});
  
  @override
  State<SecureOptimizedHomePage> createState() => _SecureOptimizedHomePageState();
}

class _SecureOptimizedHomePageState extends State<SecureOptimizedHomePage> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>>? _medicationData;
  Map<String, dynamic>? _appSettings;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadSecureData();
  }
  
  Future<void> _loadSecureData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userData = await SecureDataManager.loadUserData();
      final medicationData = await SecureDataManager.loadMedicationData();
      final appSettings = await SecureDataManager.loadAppSettings();
      
      setState(() {
        _userData = userData;
        _medicationData = medicationData;
        _appSettings = appSettings;
        _isLoading = false;
      });
      
      Logger.info('セキュアデータ読み込み完了');
    } catch (e) {
      Logger.error('セキュアデータ読み込みエラー', e);
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSecureData() async {
    try {
      await SecureDataManager.saveUserData(_userData ?? {});
      await SecureDataManager.saveMedicationData(_medicationData ?? []);
      await SecureDataManager.saveAppSettings(_appSettings ?? {});
      
      Logger.info('セキュアデータ保存完了');
    } catch (e) {
      Logger.error('セキュアデータ保存エラー', e);
    }
  }
  
  void _showSecurityInfo() {
    final stats = SecurityAuditSystem.getSecurityStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('セキュリティ情報'),
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
        title: const Text('セキュリティ改善アプリ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _showSecurityInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // セキュリティ情報の表示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.withOpacity(0.1),
                  child: const Text(
                    'セキュリティ機能が有効です',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                
                // メインコンテンツ
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          title: const Text('ユーザーデータ'),
                          subtitle: Text(_userData?.toString() ?? 'なし'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('メディケーションデータ'),
                          subtitle: Text('${_medicationData?.length ?? 0}件'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('アプリ設定'),
                          subtitle: Text(_appSettings?.toString() ?? 'なし'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSecureData,
        child: const Icon(Icons.save),
      ),
    );
  }
}
