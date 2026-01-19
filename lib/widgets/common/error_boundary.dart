import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../utils/logger.dart';

/// エラーバウンダリーウィジェット
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({Key? key, required this.child}) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('エラーが発生しました'),
                ElevatedButton(
                  onPressed: () => setState(() => _hasError = false),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      try {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } catch (e) {
        Logger.warning('Crashlyticsエラー: $e');
      }
      
      // 安全なsetState()の呼び出し
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
    };
  }
}

