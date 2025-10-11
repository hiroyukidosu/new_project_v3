import 'package:flutter/material.dart';

/// アプリケーションのローカライゼーション
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  // サポートされているロケール
  static const List<Locale> supportedLocales = [
    Locale('ja', 'JP'), // 日本語
    Locale('en', 'US'), // 英語
    Locale('ko', 'KR'), // 韓国語
    Locale('zh', 'CN'), // 中国語
  ];
  
  // 日本語の翻訳
  String get medicationTitle => _getLocalizedString('medicationTitle');
  String get addMedication => _getLocalizedString('addMedication');
  String get editMedication => _getLocalizedString('editMedication');
  String get deleteMedication => _getLocalizedString('deleteMedication');
  String get medicationName => _getLocalizedString('medicationName');
  String get medicationDosage => _getLocalizedString('medicationDosage');
  String get medicationNotes => _getLocalizedString('medicationNotes');
  String get save => _getLocalizedString('save');
  String get cancel => _getLocalizedString('cancel');
  String get delete => _getLocalizedString('delete');
  String get confirm => _getLocalizedString('confirm');
  String get loading => _getLocalizedString('loading');
  String get error => _getLocalizedString('error');
  String get success => _getLocalizedString('success');
  String get warning => _getLocalizedString('warning');
  String get info => _getLocalizedString('info');
  String get settings => _getLocalizedString('settings');
  String get about => _getLocalizedString('about');
  String get help => _getLocalizedString('help');
  String get privacy => _getLocalizedString('privacy');
  String get terms => _getLocalizedString('terms');
  String get version => _getLocalizedString('version');
  String get developer => _getLocalizedString('developer');
  String get contact => _getLocalizedString('contact');
  String get feedback => _getLocalizedString('feedback');
  String get rate => _getLocalizedString('rate');
  String get share => _getLocalizedString('share');
  String get backup => _getLocalizedString('backup');
  String get restore => _getLocalizedString('restore');
  String get export => _getLocalizedString('export');
  String get import => _getLocalizedString('import');
  String get statistics => _getLocalizedString('statistics');
  String get calendar => _getLocalizedString('calendar');
  String get alarm => _getLocalizedString('alarm');
  String get notification => _getLocalizedString('notification');
  String get reminder => _getLocalizedString('reminder');
  String get schedule => _getLocalizedString('schedule');
  String get today => _getLocalizedString('today');
  String get yesterday => _getLocalizedString('yesterday');
  String get tomorrow => _getLocalizedString('tomorrow');
  String get thisWeek => _getLocalizedString('thisWeek');
  String get thisMonth => _getLocalizedString('thisMonth');
  String get thisYear => _getLocalizedString('thisYear');
  String get all => _getLocalizedString('all');
  String get none => _getLocalizedString('none');
  String get select => _getLocalizedString('select');
  String get deselect => _getLocalizedString('deselect');
  String get search => _getLocalizedString('search');
  String get filter => _getLocalizedString('filter');
  String get sort => _getLocalizedString('sort');
  String get refresh => _getLocalizedString('refresh');
  String get retry => _getLocalizedString('retry');
  String get close => _getLocalizedString('close');
  String get open => _getLocalizedString('open');
  String get edit => _getLocalizedString('edit');
  String get view => _getLocalizedString('view');
  String get add => _getLocalizedString('add');
  String get remove => _getLocalizedString('remove');
  String get update => _getLocalizedString('update');
  String get create => _getLocalizedString('create');
  String get destroy => _getLocalizedString('destroy');
  String get enable => _getLocalizedString('enable');
  String get disable => _getLocalizedString('disable');
  String get on => _getLocalizedString('on');
  String get off => _getLocalizedString('off');
  String get yes => _getLocalizedString('yes');
  String get no => _getLocalizedString('no');
  String get ok => _getLocalizedString('ok');
  String get back => _getLocalizedString('back');
  String get next => _getLocalizedString('next');
  String get previous => _getLocalizedString('previous');
  String get first => _getLocalizedString('first');
  String get last => _getLocalizedString('last');
  String get start => _getLocalizedString('start');
  String get stop => _getLocalizedString('stop');
  String get pause => _getLocalizedString('pause');
  String get resume => _getLocalizedString('resume');
  String get play => _getLocalizedString('play');
  String get record => _getLocalizedString('record');
  String get listen => _getLocalizedString('listen');
  String get speak => _getLocalizedString('speak');
  String get read => _getLocalizedString('read');
  String get write => _getLocalizedString('write');
  String get copy => _getLocalizedString('copy');
  String get paste => _getLocalizedString('paste');
  String get cut => _getLocalizedString('cut');
  String get undo => _getLocalizedString('undo');
  String get redo => _getLocalizedString('redo');
  String get clear => _getLocalizedString('clear');
  String get reset => _getLocalizedString('reset');
  String get restore => _getLocalizedString('restore');
  String get backup => _getLocalizedString('backup');
  String get sync => _getLocalizedString('sync');
  String get connect => _getLocalizedString('connect');
  String get disconnect => _getLocalizedString('disconnect');
  String get login => _getLocalizedString('login');
  String get logout => _getLocalizedString('logout');
  String get register => _getLocalizedString('register');
  String get unregister => _getLocalizedString('unregister');
  String get subscribe => _getLocalizedString('subscribe');
  String get unsubscribe => _getLocalizedString('unsubscribe');
  String get follow => _getLocalizedString('follow');
  String get unfollow => _getLocalizedString('unfollow');
  String get like => _getLocalizedString('like');
  String get unlike => _getLocalizedString('unlike');
  String get favorite => _getLocalizedString('favorite');
  String get unfavorite => _getLocalizedString('unfavorite');
  String get bookmark => _getLocalizedString('bookmark');
  String get unbookmark => _getLocalizedString('unbookmark');
  String get pin => _getLocalizedString('pin');
  String get unpin => _getLocalizedString('unpin');
  String get lock => _getLocalizedString('lock');
  String get unlock => _getLocalizedString('unlock');
  String get hide => _getLocalizedString('hide');
  String get show => _getLocalizedString('show');
  String get expand => _getLocalizedString('expand');
  String get collapse => _getLocalizedString('collapse');
  String get maximize => _getLocalizedString('maximize');
  String get minimize => _getLocalizedString('minimize');
  String get fullscreen => _getLocalizedString('fullscreen');
  String get windowed => _getLocalizedString('windowed');
  String get zoomIn => _getLocalizedString('zoomIn');
  String get zoomOut => _getLocalizedString('zoomOut');
  String get zoomReset => _getLocalizedString('zoomReset');
  String get fit => _getLocalizedString('fit');
  String get actual => _getLocalizedString('actual');
  String get preview => _getLocalizedString('preview');
  String get print => _getLocalizedString('print');
  String get download => _getLocalizedString('download');
  String get upload => _getLocalizedString('upload');
  String get send => _getLocalizedString('send');
  String get receive => _getLocalizedString('receive');
  String get forward => _getLocalizedString('forward');
  String get reply => _getLocalizedString('reply');
  String get replyAll => _getLocalizedString('replyAll');
  String get replyTo => _getLocalizedString('replyTo');
  String get replyToAll => _getLocalizedString('replyToAll');
  String get replyToSender => _getLocalizedString('replyToSender');
  String get replyToRecipients => _getLocalizedString('replyToRecipients');
  String get replyToAllRecipients => _getLocalizedString('replyToAllRecipients');
  String get replyToSenderAndRecipients => _getLocalizedString('replyToSenderAndRecipients');
  String get replyToSenderAndAllRecipients => _getLocalizedString('replyToSenderAndAllRecipients');
  String get replyToSenderAndRecipientsAndAllRecipients => _getLocalizedString('replyToSenderAndRecipientsAndAllRecipients');
  
  // パラメータ付きの翻訳
  String greeting(String name) => _getLocalizedString('greeting', {'name': name});
  String medicationCount(int count) => _getLocalizedString('medicationCount', {'count': count.toString()});
  String daysAgo(int days) => _getLocalizedString('daysAgo', {'days': days.toString()});
  String hoursAgo(int hours) => _getLocalizedString('hoursAgo', {'hours': hours.toString()});
  String minutesAgo(int minutes) => _getLocalizedString('minutesAgo', {'minutes': minutes.toString()});
  String secondsAgo(int seconds) => _getLocalizedString('secondsAgo', {'seconds': seconds.toString()});
  
  // ローカライズされた文字列の取得
  String _getLocalizedString(String key, [Map<String, String>? parameters]) {
    final translations = _getTranslations();
    String text = translations[key] ?? key;
    
    if (parameters != null) {
      parameters.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }
    
    return text;
  }
  
  // 翻訳データの取得
  Map<String, String> _getTranslations() {
    switch (locale.languageCode) {
      case 'ja':
        return _japaneseTranslations;
      case 'en':
        return _englishTranslations;
      case 'ko':
        return _koreanTranslations;
      case 'zh':
        return _chineseTranslations;
      default:
        return _englishTranslations;
    }
  }
  
  // 日本語の翻訳データ
  static const Map<String, String> _japaneseTranslations = {
    'medicationTitle': '服用メモ',
    'addMedication': 'メモ追加',
    'editMedication': 'メモ編集',
    'deleteMedication': 'メモ削除',
    'medicationName': '薬名',
    'medicationDosage': '用量',
    'medicationNotes': 'メモ',
    'save': '保存',
    'cancel': 'キャンセル',
    'delete': '削除',
    'confirm': '確認',
    'loading': '読み込み中...',
    'error': 'エラー',
    'success': '成功',
    'warning': '警告',
    'info': '情報',
    'settings': '設定',
    'about': 'について',
    'help': 'ヘルプ',
    'privacy': 'プライバシー',
    'terms': '利用規約',
    'version': 'バージョン',
    'developer': '開発者',
    'contact': 'お問い合わせ',
    'feedback': 'フィードバック',
    'rate': '評価',
    'share': '共有',
    'backup': 'バックアップ',
    'restore': '復元',
    'export': 'エクスポート',
    'import': 'インポート',
    'statistics': '統計',
    'calendar': 'カレンダー',
    'alarm': 'アラーム',
    'notification': '通知',
    'reminder': 'リマインダー',
    'schedule': 'スケジュール',
    'today': '今日',
    'yesterday': '昨日',
    'tomorrow': '明日',
    'thisWeek': '今週',
    'thisMonth': '今月',
    'thisYear': '今年',
    'all': 'すべて',
    'none': 'なし',
    'select': '選択',
    'deselect': '選択解除',
    'search': '検索',
    'filter': 'フィルター',
    'sort': '並び替え',
    'refresh': '更新',
    'retry': '再試行',
    'close': '閉じる',
    'open': '開く',
    'edit': '編集',
    'view': '表示',
    'add': '追加',
    'remove': '削除',
    'update': '更新',
    'create': '作成',
    'destroy': '破棄',
    'enable': '有効',
    'disable': '無効',
    'on': 'オン',
    'off': 'オフ',
    'yes': 'はい',
    'no': 'いいえ',
    'ok': 'OK',
    'back': '戻る',
    'next': '次へ',
    'previous': '前へ',
    'first': '最初',
    'last': '最後',
    'start': '開始',
    'stop': '停止',
    'pause': '一時停止',
    'resume': '再開',
    'play': '再生',
    'record': '録音',
    'listen': '聞く',
    'speak': '話す',
    'read': '読む',
    'write': '書く',
    'copy': 'コピー',
    'paste': '貼り付け',
    'cut': '切り取り',
    'undo': '元に戻す',
    'redo': 'やり直し',
    'clear': 'クリア',
    'reset': 'リセット',
    'restore': '復元',
    'backup': 'バックアップ',
    'sync': '同期',
    'connect': '接続',
    'disconnect': '切断',
    'login': 'ログイン',
    'logout': 'ログアウト',
    'register': '登録',
    'unregister': '登録解除',
    'subscribe': '購読',
    'unsubscribe': '購読解除',
    'follow': 'フォロー',
    'unfollow': 'フォロー解除',
    'like': 'いいね',
    'unlike': 'いいね解除',
    'favorite': 'お気に入り',
    'unfavorite': 'お気に入り解除',
    'bookmark': 'ブックマーク',
    'unbookmark': 'ブックマーク解除',
    'pin': 'ピン留め',
    'unpin': 'ピン留め解除',
    'lock': 'ロック',
    'unlock': 'ロック解除',
    'hide': '非表示',
    'show': '表示',
    'expand': '展開',
    'collapse': '折りたたみ',
    'maximize': '最大化',
    'minimize': '最小化',
    'fullscreen': '全画面',
    'windowed': 'ウィンドウ',
    'zoomIn': 'ズームイン',
    'zoomOut': 'ズームアウト',
    'zoomReset': 'ズームリセット',
    'fit': 'フィット',
    'actual': '実際のサイズ',
    'preview': 'プレビュー',
    'print': '印刷',
    'download': 'ダウンロード',
    'upload': 'アップロード',
    'send': '送信',
    'receive': '受信',
    'forward': '転送',
    'reply': '返信',
    'replyAll': '全員に返信',
    'replyTo': '返信先',
    'replyToAll': '全員に返信',
    'replyToSender': '送信者に返信',
    'replyToRecipients': '受信者に返信',
    'replyToAllRecipients': '全受信者に返信',
    'replyToSenderAndRecipients': '送信者と受信者に返信',
    'replyToSenderAndAllRecipients': '送信者と全受信者に返信',
    'replyToSenderAndRecipientsAndAllRecipients': '送信者と受信者と全受信者に返信',
    'greeting': 'こんにちは、{name}さん',
    'medicationCount': '{count}件のメディケーション',
    'daysAgo': '{days}日前',
    'hoursAgo': '{hours}時間前',
    'minutesAgo': '{minutes}分前',
    'secondsAgo': '{seconds}秒前',
  };
  
  // 英語の翻訳データ
  static const Map<String, String> _englishTranslations = {
    'medicationTitle': 'Medication Memo',
    'addMedication': 'Add Memo',
    'editMedication': 'Edit Memo',
    'deleteMedication': 'Delete Memo',
    'medicationName': 'Medication Name',
    'medicationDosage': 'Dosage',
    'medicationNotes': 'Notes',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'confirm': 'Confirm',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'warning': 'Warning',
    'info': 'Info',
    'settings': 'Settings',
    'about': 'About',
    'help': 'Help',
    'privacy': 'Privacy',
    'terms': 'Terms',
    'version': 'Version',
    'developer': 'Developer',
    'contact': 'Contact',
    'feedback': 'Feedback',
    'rate': 'Rate',
    'share': 'Share',
    'backup': 'Backup',
    'restore': 'Restore',
    'export': 'Export',
    'import': 'Import',
    'statistics': 'Statistics',
    'calendar': 'Calendar',
    'alarm': 'Alarm',
    'notification': 'Notification',
    'reminder': 'Reminder',
    'schedule': 'Schedule',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'tomorrow': 'Tomorrow',
    'thisWeek': 'This Week',
    'thisMonth': 'This Month',
    'thisYear': 'This Year',
    'all': 'All',
    'none': 'None',
    'select': 'Select',
    'deselect': 'Deselect',
    'search': 'Search',
    'filter': 'Filter',
    'sort': 'Sort',
    'refresh': 'Refresh',
    'retry': 'Retry',
    'close': 'Close',
    'open': 'Open',
    'edit': 'Edit',
    'view': 'View',
    'add': 'Add',
    'remove': 'Remove',
    'update': 'Update',
    'create': 'Create',
    'destroy': 'Destroy',
    'enable': 'Enable',
    'disable': 'Disable',
    'on': 'On',
    'off': 'Off',
    'yes': 'Yes',
    'no': 'No',
    'ok': 'OK',
    'back': 'Back',
    'next': 'Next',
    'previous': 'Previous',
    'first': 'First',
    'last': 'Last',
    'start': 'Start',
    'stop': 'Stop',
    'pause': 'Pause',
    'resume': 'Resume',
    'play': 'Play',
    'record': 'Record',
    'listen': 'Listen',
    'speak': 'Speak',
    'read': 'Read',
    'write': 'Write',
    'copy': 'Copy',
    'paste': 'Paste',
    'cut': 'Cut',
    'undo': 'Undo',
    'redo': 'Redo',
    'clear': 'Clear',
    'reset': 'Reset',
    'restore': 'Restore',
    'backup': 'Backup',
    'sync': 'Sync',
    'connect': 'Connect',
    'disconnect': 'Disconnect',
    'login': 'Login',
    'logout': 'Logout',
    'register': 'Register',
    'unregister': 'Unregister',
    'subscribe': 'Subscribe',
    'unsubscribe': 'Unsubscribe',
    'follow': 'Follow',
    'unfollow': 'Unfollow',
    'like': 'Like',
    'unlike': 'Unlike',
    'favorite': 'Favorite',
    'unfavorite': 'Unfavorite',
    'bookmark': 'Bookmark',
    'unbookmark': 'Unbookmark',
    'pin': 'Pin',
    'unpin': 'Unpin',
    'lock': 'Lock',
    'unlock': 'Unlock',
    'hide': 'Hide',
    'show': 'Show',
    'expand': 'Expand',
    'collapse': 'Collapse',
    'maximize': 'Maximize',
    'minimize': 'Minimize',
    'fullscreen': 'Fullscreen',
    'windowed': 'Windowed',
    'zoomIn': 'Zoom In',
    'zoomOut': 'Zoom Out',
    'zoomReset': 'Zoom Reset',
    'fit': 'Fit',
    'actual': 'Actual Size',
    'preview': 'Preview',
    'print': 'Print',
    'download': 'Download',
    'upload': 'Upload',
    'send': 'Send',
    'receive': 'Receive',
    'forward': 'Forward',
    'reply': 'Reply',
    'replyAll': 'Reply All',
    'replyTo': 'Reply To',
    'replyToAll': 'Reply To All',
    'replyToSender': 'Reply To Sender',
    'replyToRecipients': 'Reply To Recipients',
    'replyToAllRecipients': 'Reply To All Recipients',
    'replyToSenderAndRecipients': 'Reply To Sender And Recipients',
    'replyToSenderAndAllRecipients': 'Reply To Sender And All Recipients',
    'replyToSenderAndRecipientsAndAllRecipients': 'Reply To Sender And Recipients And All Recipients',
    'greeting': 'Hello, {name}',
    'medicationCount': '{count} medications',
    'daysAgo': '{days} days ago',
    'hoursAgo': '{hours} hours ago',
    'minutesAgo': '{minutes} minutes ago',
    'secondsAgo': '{seconds} seconds ago',
  };
  
  // 韓国語の翻訳データ
  static const Map<String, String> _koreanTranslations = {
    'medicationTitle': '복용 메모',
    'addMedication': '메모 추가',
    'editMedication': '메모 편집',
    'deleteMedication': '메모 삭제',
    'medicationName': '약물명',
    'medicationDosage': '용량',
    'medicationNotes': '메모',
    'save': '저장',
    'cancel': '취소',
    'delete': '삭제',
    'confirm': '확인',
    'loading': '로딩 중...',
    'error': '오류',
    'success': '성공',
    'warning': '경고',
    'info': '정보',
    'settings': '설정',
    'about': '정보',
    'help': '도움말',
    'privacy': '개인정보',
    'terms': '이용약관',
    'version': '버전',
    'developer': '개발자',
    'contact': '문의',
    'feedback': '피드백',
    'rate': '평가',
    'share': '공유',
    'backup': '백업',
    'restore': '복원',
    'export': '내보내기',
    'import': '가져오기',
    'statistics': '통계',
    'calendar': '캘린더',
    'alarm': '알람',
    'notification': '알림',
    'reminder': '리마인더',
    'schedule': '일정',
    'today': '오늘',
    'yesterday': '어제',
    'tomorrow': '내일',
    'thisWeek': '이번 주',
    'thisMonth': '이번 달',
    'thisYear': '올해',
    'all': '모두',
    'none': '없음',
    'select': '선택',
    'deselect': '선택 해제',
    'search': '검색',
    'filter': '필터',
    'sort': '정렬',
    'refresh': '새로고침',
    'retry': '재시도',
    'close': '닫기',
    'open': '열기',
    'edit': '편집',
    'view': '보기',
    'add': '추가',
    'remove': '제거',
    'update': '업데이트',
    'create': '생성',
    'destroy': '파괴',
    'enable': '활성화',
    'disable': '비활성화',
    'on': '켜기',
    'off': '끄기',
    'yes': '예',
    'no': '아니오',
    'ok': '확인',
    'back': '뒤로',
    'next': '다음',
    'previous': '이전',
    'first': '첫 번째',
    'last': '마지막',
    'start': '시작',
    'stop': '중지',
    'pause': '일시정지',
    'resume': '재개',
    'play': '재생',
    'record': '녹음',
    'listen': '듣기',
    'speak': '말하기',
    'read': '읽기',
    'write': '쓰기',
    'copy': '복사',
    'paste': '붙여넣기',
    'cut': '잘라내기',
    'undo': '실행 취소',
    'redo': '다시 실행',
    'clear': '지우기',
    'reset': '재설정',
    'restore': '복원',
    'backup': '백업',
    'sync': '동기화',
    'connect': '연결',
    'disconnect': '연결 해제',
    'login': '로그인',
    'logout': '로그아웃',
    'register': '등록',
    'unregister': '등록 해제',
    'subscribe': '구독',
    'unsubscribe': '구독 해제',
    'follow': '팔로우',
    'unfollow': '팔로우 해제',
    'like': '좋아요',
    'unlike': '좋아요 취소',
    'favorite': '즐겨찾기',
    'unfavorite': '즐겨찾기 해제',
    'bookmark': '북마크',
    'unbookmark': '북마크 해제',
    'pin': '고정',
    'unpin': '고정 해제',
    'lock': '잠금',
    'unlock': '잠금 해제',
    'hide': '숨기기',
    'show': '보이기',
    'expand': '확장',
    'collapse': '축소',
    'maximize': '최대화',
    'minimize': '최소화',
    'fullscreen': '전체화면',
    'windowed': '창 모드',
    'zoomIn': '확대',
    'zoomOut': '축소',
    'zoomReset': '확대/축소 리셋',
    'fit': '맞춤',
    'actual': '실제 크기',
    'preview': '미리보기',
    'print': '인쇄',
    'download': '다운로드',
    'upload': '업로드',
    'send': '보내기',
    'receive': '받기',
    'forward': '전달',
    'reply': '답장',
    'replyAll': '모두 답장',
    'replyTo': '답장 대상',
    'replyToAll': '모두 답장',
    'replyToSender': '보낸 사람에게 답장',
    'replyToRecipients': '받는 사람에게 답장',
    'replyToAllRecipients': '모든 받는 사람에게 답장',
    'replyToSenderAndRecipients': '보낸 사람과 받는 사람에게 답장',
    'replyToSenderAndAllRecipients': '보낸 사람과 모든 받는 사람에게 답장',
    'replyToSenderAndRecipientsAndAllRecipients': '보낸 사람과 받는 사람과 모든 받는 사람에게 답장',
    'greeting': '안녕하세요, {name}님',
    'medicationCount': '{count}개의 약물',
    'daysAgo': '{days}일 전',
    'hoursAgo': '{hours}시간 전',
    'minutesAgo': '{minutes}분 전',
    'secondsAgo': '{seconds}초 전',
  };
  
  // 中国語の翻訳データ
  static const Map<String, String> _chineseTranslations = {
    'medicationTitle': '用药备忘录',
    'addMedication': '添加备忘录',
    'editMedication': '编辑备忘录',
    'deleteMedication': '删除备忘录',
    'medicationName': '药物名称',
    'medicationDosage': '剂量',
    'medicationNotes': '备注',
    'save': '保存',
    'cancel': '取消',
    'delete': '删除',
    'confirm': '确认',
    'loading': '加载中...',
    'error': '错误',
    'success': '成功',
    'warning': '警告',
    'info': '信息',
    'settings': '设置',
    'about': '关于',
    'help': '帮助',
    'privacy': '隐私',
    'terms': '条款',
    'version': '版本',
    'developer': '开发者',
    'contact': '联系',
    'feedback': '反馈',
    'rate': '评分',
    'share': '分享',
    'backup': '备份',
    'restore': '恢复',
    'export': '导出',
    'import': '导入',
    'statistics': '统计',
    'calendar': '日历',
    'alarm': '闹钟',
    'notification': '通知',
    'reminder': '提醒',
    'schedule': '日程',
    'today': '今天',
    'yesterday': '昨天',
    'tomorrow': '明天',
    'thisWeek': '本周',
    'thisMonth': '本月',
    'thisYear': '今年',
    'all': '全部',
    'none': '无',
    'select': '选择',
    'deselect': '取消选择',
    'search': '搜索',
    'filter': '筛选',
    'sort': '排序',
    'refresh': '刷新',
    'retry': '重试',
    'close': '关闭',
    'open': '打开',
    'edit': '编辑',
    'view': '查看',
    'add': '添加',
    'remove': '移除',
    'update': '更新',
    'create': '创建',
    'destroy': '销毁',
    'enable': '启用',
    'disable': '禁用',
    'on': '开',
    'off': '关',
    'yes': '是',
    'no': '否',
    'ok': '确定',
    'back': '返回',
    'next': '下一步',
    'previous': '上一步',
    'first': '第一个',
    'last': '最后一个',
    'start': '开始',
    'stop': '停止',
    'pause': '暂停',
    'resume': '恢复',
    'play': '播放',
    'record': '录制',
    'listen': '听',
    'speak': '说',
    'read': '读',
    'write': '写',
    'copy': '复制',
    'paste': '粘贴',
    'cut': '剪切',
    'undo': '撤销',
    'redo': '重做',
    'clear': '清除',
    'reset': '重置',
    'restore': '恢复',
    'backup': '备份',
    'sync': '同步',
    'connect': '连接',
    'disconnect': '断开',
    'login': '登录',
    'logout': '登出',
    'register': '注册',
    'unregister': '注销',
    'subscribe': '订阅',
    'unsubscribe': '取消订阅',
    'follow': '关注',
    'unfollow': '取消关注',
    'like': '点赞',
    'unlike': '取消点赞',
    'favorite': '收藏',
    'unfavorite': '取消收藏',
    'bookmark': '书签',
    'unbookmark': '取消书签',
    'pin': '置顶',
    'unpin': '取消置顶',
    'lock': '锁定',
    'unlock': '解锁',
    'hide': '隐藏',
    'show': '显示',
    'expand': '展开',
    'collapse': '折叠',
    'maximize': '最大化',
    'minimize': '最小化',
    'fullscreen': '全屏',
    'windowed': '窗口',
    'zoomIn': '放大',
    'zoomOut': '缩小',
    'zoomReset': '重置缩放',
    'fit': '适应',
    'actual': '实际大小',
    'preview': '预览',
    'print': '打印',
    'download': '下载',
    'upload': '上传',
    'send': '发送',
    'receive': '接收',
    'forward': '转发',
    'reply': '回复',
    'replyAll': '全部回复',
    'replyTo': '回复给',
    'replyToAll': '全部回复',
    'replyToSender': '回复发送者',
    'replyToRecipients': '回复收件人',
    'replyToAllRecipients': '回复所有收件人',
    'replyToSenderAndRecipients': '回复发送者和收件人',
    'replyToSenderAndAllRecipients': '回复发送者和所有收件人',
    'replyToSenderAndRecipientsAndAllRecipients': '回复发送者和收件人和所有收件人',
    'greeting': '你好，{name}',
    'medicationCount': '{count}个药物',
    'daysAgo': '{days}天前',
    'hoursAgo': '{hours}小时前',
    'minutesAgo': '{minutes}分钟前',
    'secondsAgo': '{seconds}秒前',
  };
}

/// ローカライゼーションデリゲート
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any((supportedLocale) =>
        supportedLocale.languageCode == locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}