import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// チュートリアルラッパー
/// アプリの初回起動時にチュートリアルを表示する
class TutorialWrapper extends StatefulWidget {
  final Widget child;

  const TutorialWrapper({
    super.key,
    required this.child,
  });

  @override
  State<TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends State<TutorialWrapper> {
  bool _showTutorial = true;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool('tutorialShown') ?? false;
    if (tutorialShown) {
      setState(() => _showTutorial = false);
    }
  }

  void _onTutorialComplete() {
    setState(() => _showTutorial = false);
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('tutorialShown', true));
  }

  @override
  Widget build(BuildContext context) {
    if (_showTutorial) {
      return TutorialPage(onComplete: _onTutorialComplete);
    }
    return widget.child;
  }
}

/// チュートリアルページ
/// アプリの使い方を説明する画面
class TutorialPage extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _tutorialPages = [
    {
      'title': '薬の管理を簡単に',
      'description': '服用する薬やサプリメントを登録して、スケジュールを管理できます。',
      'color': Colors.blue,
      'icon': Icons.medication,
      'features': [
        '薬の登録と編集',
        '服用スケジュール設定',
        '服用履歴の記録',
      ],
    },
    {
      'title': 'カレンダーで視覚的に',
      'description': 'カレンダーで服用状況を一目で確認できます。',
      'color': Colors.green,
      'icon': Icons.calendar_today,
      'features': [
        '日別服用状況表示',
        'カレンダーマーク機能',
        '統計情報の確認',
      ],
    },
    {
      'title': 'アラームで忘れずに',
      'description': '設定した時間に通知で服用を忘れません。',
      'color': Colors.orange,
      'icon': Icons.alarm,
      'features': [
        'カスタムアラーム設定',
        '複数時間の通知',
        'アラームのオン/オフ',
      ],
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
                        Icon(
                          page['icon'] as IconData,
                          size: 120,
                          color: page['color'] as Color,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page['title'] as String,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['description'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ...(page['features'] as List<String>).map((feature) => 
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: page['color'] as Color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  feature,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _tutorialPages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Colors.blue
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentPage < _tutorialPages.length - 1 ? '次へ' : '始める',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
