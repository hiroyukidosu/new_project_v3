// Dart core imports
import 'dart:async';

// Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:shared_preferences/shared_preferences.dart';

// Local imports
import '../services/trial_service.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../screens/medication_home_page.dart';

class TutorialWrapper extends StatefulWidget {
  const TutorialWrapper({super.key});
  @override
  State<TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends State<TutorialWrapper> {
  bool _showTutorial = true;
  bool _showTrialMessage = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      await _checkTutorialStatus();
      // トライアル期間を初期化
      await TrialService.initializeTrial();
      await Future.wait([
        MedicationService.initialize().catchError((e) {
          return null;
        }),
        NotificationService.initialize().catchError((e) {
          return false;
        }),
      ]);
    } catch (e) {
    }
  }
  
  Future<void> _checkTutorialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('tutorialShown') ?? false) {
        setState(() => _showTutorial = false);
      }
    } catch (e) {
    }
  }
  
  void _onTutorialComplete() {
    setState(() {
      _showTutorial = false;
      _showTrialMessage = true;
    });
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('tutorialShown', true));
  }
  
  void _onTrialMessageComplete() {
    setState(() {
      _showTrialMessage = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_showTutorial) {
      return TutorialPage(onComplete: _onTutorialComplete);
    } else if (_showTrialMessage) {
      return TrialMessageScreen(onComplete: _onTrialMessageComplete);
    } else {
      return const MedicationHomePage();
    }
  }
}

/// チュートリアルページ
/// アプリの使い方を説明するページビュー
class TutorialPage extends StatefulWidget {
  final VoidCallback onComplete;
  const TutorialPage({super.key, required this.onComplete});
  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<Map<String, dynamic>> _tutorialPages = [
    {
      'icon': Icons.calendar_month,
      'title': 'カレンダー機能',
      'description': '日付をタップして服用記録を管理\n服用メモから服用スケジュール(毎日、曜日)を選択',
      'color': Colors.blue,
      'image': '📅',
      'features': ['日付選択', '服用記録', 'スケジュール管理'],
    },
    {
      'icon': Icons.medication,
      'title': '服用メモ',
      'description': '薬やサプリメントを登録\n曜日設定で服用スケジュール(毎日、曜日)を管理',
      'color': Colors.green,
      'image': '💊',
      'features': ['薬品登録', 'サプリメント登録', '曜日設定'],
    },
    {
      'icon': Icons.alarm,
      'title': 'アラーム',
      'description': '服用時間を忘れずにリマインド\n複数の通知時間を設定可能',
      'color': Colors.orange,
      'image': '⏰',
      'features': ['通知設定', 'リマインド', '複数時間'],
    },
    {
      'icon': Icons.analytics,
      'title': '統計',
      'description': '服用遵守率をグラフで可視化\n健康管理をデータでサポート',
      'color': Colors.purple,
      'image': '📊',
      'features': ['遵守率グラフ', 'データ分析', '健康管理'],
    },
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _tutorialPages.length,
                itemBuilder: (context, index) {
                  final page = _tutorialPages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 大きな図（絵文字）
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: page['color'] as Color,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              page['image'] as String,
                              style: const TextStyle(fontSize: 60),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // タイトル
                        Text(
                          page['title'],
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: page['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // 説明文
                        Text(
                          page['description'],
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // 機能一覧
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (page['color'] as Color).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '主な機能',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: page['color'] as Color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: (page['features'] as List<String>).map((feature) => 
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: page['color'] as Color,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      feature,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ボタンエリア（固定位置）
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ページインジケーター
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _tutorialPages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index 
                              ? _tutorialPages[_currentPage]['color'] as Color
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ボタンエリア
                  Row(
                    children: [
                      // スキップボタン（左側）
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onComplete,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'スキップ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 次へ/完了ボタン（右側）
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _tutorialPages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              widget.onComplete();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tutorialPages[_currentPage]['color'] as Color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _currentPage < _tutorialPages.length - 1 ? '次へ' : '完了',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
