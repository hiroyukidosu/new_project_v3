import 'package:flutter/material.dart';
import 'enhanced_purchase_verification.dart';
import 'secure_storage_implementation.dart';
import 'security_audit_system.dart';
import '../utils/logger.dart';

/// セキュリティ統合実装 - 包括的なセキュリティ機能
class SecurityIntegration {
  
  /// セキュリティ機能の初期化
  static Future<void> initializeSecurity() async {
    try {
      Logger.info('セキュリティ機能の初期化を開始');
      
      // セキュリティ監査システムの初期化
      await SecurityAuditSystem.initializeSecurityAudit();
      
      // デバイスセキュリティの検証
      final isDeviceSecure = await ThreatDetectionSystem.verifyDeviceSecurity();
      if (!isDeviceSecure) {
        Logger.warning('デバイスセキュリティの検証に失敗');
      }
      
      // セキュリティ設定の読み込み
      final config = await SecurityConfigManager.loadSecurityConfig() ?? 
                    SecurityConfigManager.getDefaultSecurityConfig();
      
      Logger.info('セキュリティ機能の初期化完了');
    } catch (e) {
      Logger.error('セキュリティ機能の初期化エラー', e);
    }
  }
  
  /// セキュアなデータ保存
  static Future<void> saveSecureData(String key, Map<String, dynamic> data) async {
    try {
      // データアクセスの監査
      await SecurityAuditSystem.auditDataAccess(
        dataType: key,
        operation: 'save',
        userId: 'current_user',
        metadata: {'dataSize': data.toString().length},
      );
      
      // セキュアなデータ保存
      await SensitiveDataManager.saveMedicationDataSecure(data);
      
      Logger.info('セキュアデータ保存完了: $key');
    } catch (e) {
      Logger.error('セキュアデータ保存エラー: $key', e);
      rethrow;
    }
  }
  
  /// セキュアなデータ読み込み
  static Future<Map<String, dynamic>?> loadSecureData(String key) async {
    try {
      // データアクセスの監査
      await SecurityAuditSystem.auditDataAccess(
        dataType: key,
        operation: 'load',
        userId: 'current_user',
      );
      
      // セキュアなデータ読み込み
      final data = await SensitiveDataManager.loadMedicationDataSecure();
      
      Logger.info('セキュアデータ読み込み完了: $key');
      return data;
    } catch (e) {
      Logger.error('セキュアデータ読み込みエラー: $key', e);
      return null;
    }
  }
  
  /// セキュアな課金検証
  static Future<bool> verifyPurchaseSecurely({
    required String purchaseToken,
    required String productId,
    required String packageName,
  }) async {
    try {
      // 課金検証の監査
      await SecurityAuditSystem.auditPurchaseEvent(
        eventType: 'verification_start',
        productId: productId,
        userId: 'current_user',
      );
      
      // 総合的な課金検証
      final result = await EnhancedPurchaseVerification.verifyPurchaseComprehensive(
        purchaseToken: purchaseToken,
        productId: productId,
        packageName: packageName,
      );
      
      // 検証結果の監査
      await SecurityAuditSystem.auditPurchaseEvent(
        eventType: 'verification_complete',
        productId: productId,
        userId: 'current_user',
        success: result.isValid,
        errorMessage: result.error,
      );
      
      // セキュアな課金状態の保存
      if (result.isValid) {
        await SecurePurchaseStateManager.savePurchaseState(
          productId: productId,
          isPurchased: true,
          verificationResult: result,
        );
      }
      
      Logger.info('セキュア課金検証完了: $productId - ${result.isValid}');
      return result.isValid;
    } catch (e) {
      Logger.error('セキュア課金検証エラー: $productId', e);
      return false;
    }
  }
  
  /// セキュリティレポートの生成
  static Future<Map<String, dynamic>> generateSecurityReport() async {
    try {
      final report = await SecurityReportGenerator.generateSecurityReport();
      
      // レポート生成の監査
      await SecurityAuditSystem.auditDataAccess(
        dataType: 'security_report',
        operation: 'generate',
        userId: 'system',
        metadata: {'reportSize': report.toString().length},
      );
      
      Logger.info('セキュリティレポート生成完了');
      return report;
    } catch (e) {
      Logger.error('セキュリティレポート生成エラー', e);
      return {};
    }
  }
}

/// セキュアなメディケーションホームページの実装例
class SecureMedicationHomePage extends StatefulWidget {
  const SecureMedicationHomePage({super.key});
  
  @override
  State<SecureMedicationHomePage> createState() => _SecureMedicationHomePageState();
}

class _SecureMedicationHomePageState extends State<SecureMedicationHomePage> {
  Map<String, dynamic>? _medicationData;
  bool _isLoading = false;
  String? _securityStatus;
  
  @override
  void initState() {
    super.initState();
    _initializeSecureApp();
  }
  
  Future<void> _initializeSecureApp() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // セキュリティ機能の初期化
      await SecurityIntegration.initializeSecurity();
      
      // セキュアなデータの読み込み
      _medicationData = await SecurityIntegration.loadSecureData('medication_data');
      
      // セキュリティ状態の確認
      _securityStatus = await _checkSecurityStatus();
      
      setState(() {
        _isLoading = false;
      });
      
      Logger.info('セキュアアプリの初期化完了');
    } catch (e) {
      Logger.error('セキュアアプリの初期化エラー', e);
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<String> _checkSecurityStatus() async {
    try {
      // デバイスセキュリティの確認
      final isDeviceSecure = await ThreatDetectionSystem.verifyDeviceSecurity();
      
      // セキュリティ統計の取得
      final securityStats = await SecurityAuditManager.getSecurityStats();
      
      if (isDeviceSecure && securityStats['totalEvents'] < 100) {
        return 'セキュア';
      } else if (securityStats['totalEvents'] < 500) {
        return '注意が必要';
      } else {
        return 'リスクあり';
      }
    } catch (e) {
      Logger.error('セキュリティ状態確認エラー', e);
      return '不明';
    }
  }
  
  Future<void> _saveMedicationData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // セキュアなデータ保存
      await SecurityIntegration.saveSecureData('medication_data', {
        'medications': _medicationData?['medications'] ?? [],
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('データを安全に保存しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('データ保存エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _verifyPurchase() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // セキュアな課金検証
      final isValid = await SecurityIntegration.verifyPurchaseSecurely(
        purchaseToken: 'sample_token',
        productId: 'premium_upgrade',
        packageName: 'com.hirochaso.medicationcalendar',
      );
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isValid ? '課金検証成功' : '課金検証失敗'),
          backgroundColor: isValid ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('課金検証エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _showSecurityReport() async {
    try {
      final report = await SecurityIntegration.generateSecurityReport();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('セキュリティレポート'),
          content: SingleChildScrollView(
            child: Text('レポート:\n${report.toString()}'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('レポート生成エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('セキュア服薬管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _showSecurityReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // セキュリティ状態の表示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: _getSecurityStatusColor(),
                  child: Text(
                    'セキュリティ状態: $_securityStatus',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // メインコンテンツ
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'セキュアな服薬管理アプリ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'このアプリは以下のセキュリティ機能を提供します:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        _buildSecurityFeature('データ暗号化', '全ての機密データが暗号化されます'),
                        _buildSecurityFeature('課金検証', 'サーバー側での厳格な課金検証'),
                        _buildSecurityFeature('脅威検出', '不正アクセスの自動検出'),
                        _buildSecurityFeature('監査ログ', '全ての操作が記録されます'),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _saveMedicationData,
                              child: const Text('データ保存'),
                            ),
                            ElevatedButton(
                              onPressed: _verifyPurchase,
                              child: const Text('課金検証'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSecurityFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getSecurityStatusColor() {
    switch (_securityStatus) {
      case 'セキュア':
        return Colors.green;
      case '注意が必要':
        return Colors.orange;
      case 'リスクあり':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
