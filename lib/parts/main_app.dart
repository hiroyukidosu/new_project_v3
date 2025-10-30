part of '../main.dart';

// アプリケーションのメインクラス
class MedicationAlarmApp extends StatelessWidget {
  const MedicationAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Alarm App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ErrorBoundary(
        child: TutorialWrapper(
          child: MedicationHomePage(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}