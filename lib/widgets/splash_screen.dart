// lib/widgets/splash_screen.dart
// 最適化されたスプラッシュ画面（UI早期表示対応）

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../core/app_initializer.dart';
import '../utils/performance_monitor.dart';
import '../screens/medication_alarm_app.dart';

/// 最適化されたスプラッシュ画面
/// UIを早期表示し、バックグラウンドで初期化を実行
class OptimizedSplashScreen extends StatefulWidget {
  final Future<void> Function()? onInitializationComplete;

  const OptimizedSplashScreen({
    super.key,
    this.onInitializationComplete,
  });

  @override
  State<OptimizedSplashScreen> createState() => _OptimizedSplashScreenState();
}

class _OptimizedSplashScreenState extends State<OptimizedSplashScreen> {
  late Future<void> _criticalInit;
  bool _isCriticalDone = false;
  double _progress = 0.0;
  String _statusMessage = '初期化中...';

  @override
  void initState() {
    super.initState();
    // 改善: critical_initとessential_initを並列実行（_initializeCritical内で実装）
    _criticalInit = _initializeCritical();
    // 遅延初期化もバックグラウンドで実行（3-5秒後に実行）
    AppInitializer.initializeDeferred();
  }

  /// クリティカルな初期化（UI表示に必要）
  /// Hive初期化を最優先で実行
  /// 改善: critical_initとessential_initを並列実行
  Future<void> _initializeCritical() async {
    try {
      // フレームを確保
      await SchedulerBinding.instance.endOfFrame;
      
      if (mounted) {
        setState(() {
          _statusMessage = 'データベースを初期化中...';
        });
      }
      
      // 改善: critical_initとessential_initを並列実行（高速化）
      // Hive初期化後、可能な部分を並列実行
      await _processWithFrameDistribution(() async {
        await AppInitializer.initializeCriticalAndEssential();
      });
      
      if (mounted) {
        setState(() {
          _progress = 0.5;
          _statusMessage = 'データを読み込み中...';
        });
      }
      
      if (mounted) {
        setState(() {
          _progress = 0.9; // 進捗を更新
          _statusMessage = '準備完了...';
        });
        // 少し待ってから完了フラグを立てる（スムーズな遷移のため）
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _isCriticalDone = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'エラーが発生しました: $e';
          _isCriticalDone = true; // エラー時もUIを表示
        });
      }
      if (kDebugMode) {
        debugPrint('❌ クリティカル初期化エラー: $e');
      }
    }
  }


  /// フレーム分散で処理を実行（UIスレッドの負荷を軽減）
  Future<void> _processWithFrameDistribution(Future<void> Function() task) async {
    // 現在のフレームが終了するまで待機
    await SchedulerBinding.instance.endOfFrame;
    // タスクを実行
    await task();
    // 次のフレームまで待機（UIスレッドに制御を返す）
    await SchedulerBinding.instance.endOfFrame;
    // さらに1フレーム待機（UIスレッドの負荷を分散）
    await Future.delayed(Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilderで初期化完了を待たずにUIを表示
    return FutureBuilder<void>(
      future: _criticalInit,
      builder: (context, snapshot) {
        // クリティカルな初期化が完了したらメインアプリに遷移
        if (_isCriticalDone || snapshot.connectionState == ConnectionState.done) {
          // スプラッシュ画面を少し長めに表示（フリーズ感の解消）
          // 最低500msは表示してから遷移
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const MedicationAlarmApp(),
                    ),
                  );
                }
              });
            }
          });
        }

        // スプラッシュ画面を表示
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2196F3),
                  Color(0xFF1976D2),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.medication,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'サプリ＆おくすり\nスケジュール管理帳',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
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
}

