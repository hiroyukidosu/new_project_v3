// lib/simple_alarm_app.dart
// アプリケーションのエントリーポイント

import 'package:flutter/material.dart';
import 'screens/alarm_home_screen.dart';

class SimpleAlarmApp extends StatelessWidget {
  const SimpleAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '服用時間のアラーム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AlarmHomeScreen(),
    );
  }
}
