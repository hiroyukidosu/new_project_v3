import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/medication_provider.dart';
import 'providers/statistics_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ログを無効化（無限ループ防止）
  StatisticsProvider.disableLogs();
  MedicationProvider.disableLogs();
  
  await initializeDateFormatting('ja_JP', null);
  try {
    final directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(directory.path);
    Hive.registerAdapter(MemoAdapter());
    await Hive.openBox<Memo>('memos');
  } catch (e) {
    debugPrint('Hive初期化エラー: $e');
  }
  runApp(const MemoApp());
}

class MemoAdapter extends TypeAdapter<Memo> {
  @override
  final int typeId = 0;

  @override
  Memo read(BinaryReader reader) {
    return Memo(
      id: reader.readString(),
      title: reader.readString(),
      content: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, Memo obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
  }
}

class MemoApp extends StatelessWidget {
  const MemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // プロバイダーの初期化
    final medicationProvider = MedicationProvider();
    final statisticsProvider = StatisticsProvider();
    statisticsProvider.setMedicationProvider(medicationProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => medicationProvider),
        ChangeNotifierProvider(create: (_) => statisticsProvider),
      ],
      child: MaterialApp(
        title: 'メモアプリ',
        locale: const Locale('ja', 'JP'),
        theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196F3),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16.0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196F3),
        scaffoldBackgroundColor: Colors.grey[900],
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16.0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MemoHomePage(),
      debugShowCheckedModeBanner: false,
      ),
    );
  }

  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('fontSize') ?? 16.0;
  }
}

class Memo {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Memo({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Memo.fromJson(Map<String, dynamic> json) => Memo(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );

  Memo copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return Memo(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MemoHomePage extends StatefulWidget {
  const MemoHomePage({super.key});

  @override
  State<MemoHomePage> createState() => _MemoHomePageState();
}

class _MemoHomePageState extends State<MemoHomePage> {
  late Box<Memo> _memoBox;
  List<Memo> _memos = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initHive();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initHive() async {
    try {
      _memoBox = Hive.box<Memo>('memos');
      await _loadMemos();
    } catch (e) {
      debugPrint('Hive読み込みエラー: $e');
      _showSnackBar('データベースの初期化に失敗しました。');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _memoBox.close();
    super.dispose();
  }

  Future<void> _loadMemos() async {
    try {
      final memos = _memoBox.values.toList();
      setState(() {
        _memos = memos;
      });
    } catch (e) {
      debugPrint('メモ読み込みエラー: $e');
      _showSnackBar('メモの読み込みに失敗しました。');
    }
  }

  void _onSearchChanged() {
      setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<Memo> get _filteredMemos {
    if (_searchQuery.isEmpty) {
      return _memos;
    }
    return _memos.where((memo) {
      return memo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             memo.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _addMemo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemoEditPage()),
    );
    if (result == true) {
      await _loadMemos();
    }
  }

  Future<void> _editMemo(Memo memo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MemoEditPage(memo: memo)),
    );
    if (result == true) {
      await _loadMemos();
    }
  }

  Future<void> _deleteMemo(Memo memo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを削除'),
        content: const Text('このメモを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _memoBox.delete(memo.id);
        await _loadMemos();
        _showSnackBar('メモを削除しました。');
    } catch (e) {
        debugPrint('メモ削除エラー: $e');
        _showSnackBar('メモの削除に失敗しました。');
      }
    }
  }

  void _showSnackBar(String message) async {
    final fontSize = await MemoApp.getFontSize();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(fontSize: fontSize)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _showFontSizeDialog() async {
    final controller = TextEditingController(text: (await MemoApp.getFontSize()).toString());
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フォントサイズを設定'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'フォントサイズ (12-24)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              final size = double.tryParse(controller.text) ?? 16.0;
              if (size >= 12 && size <= 24) {
                Navigator.pop(context, size);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('12〜24の範囲で入力してください')),
                );
              }
            },
            child: const Text('設定'),
          ),
        ],
      ),
    );
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontSize', result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
        title: const Text('メモアプリ'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.text_fields),
                tooltip: 'フォントサイズを変更',
                onPressed: _showFontSizeDialog,
              ),
            ],
          ),
      body: Column(
              children: [
          // 検索バー
                  Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'メモを検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[800] 
                    : Colors.grey[100],
              ),
            ),
          ),
          // メモ一覧
                          Expanded(
            child: _filteredMemos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.note_add : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'メモがありません\n右下のボタンからメモを追加してください'
                              : '検索結果がありません',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredMemos.length,
                    itemBuilder: (context, index) {
                      final memo = _filteredMemos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            memo.title.isEmpty ? '無題のメモ' : memo.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              if (memo.content.isNotEmpty)
                                Text(
                                  memo.content.length > 100 
                                      ? '${memo.content.substring(0, 100)}...'
                                      : memo.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '更新: ${DateFormat('yyyy/MM/dd HH:mm').format(memo.updatedAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                            ),
                        ],
                      ),
                          onTap: () => _editMemo(memo),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                      children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('編集'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                              children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('削除', style: TextStyle(color: Colors.red)),
                                  ],
                              ),
                            ),
                          ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editMemo(memo);
                              } else if (value == 'delete') {
                                _deleteMemo(memo);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemo,
        child: const Icon(Icons.add),
      ),
    );
  }

}

class MemoEditPage extends StatefulWidget {
  final Memo? memo;

  const MemoEditPage({super.key, this.memo});

  @override
  State<MemoEditPage> createState() => _MemoEditPageState();
}

class _MemoEditPageState extends State<MemoEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Box<Memo> _memoBox;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memo?.title ?? '');
    _contentController = TextEditingController(text: widget.memo?.content ?? '');
    _memoBox = Hive.box<Memo>('memos');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveMemo() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルまたは内容を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final memo = widget.memo != null
          ? widget.memo!.copyWith(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              updatedAt: now,
            )
          : Memo(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              createdAt: now,
              updatedAt: now,
            );

      await _memoBox.put(memo.id, memo);
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('メモ保存エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メモの保存に失敗しました')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memo != null ? 'メモを編集' : '新しいメモ'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveMemo,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
                  ),
                ],
              ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
      child: Column(
            children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: 'メモのタイトルを入力',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
              Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  hintText: 'メモの内容を入力',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
          ),
        ],
      ),
      ),
    );
  }
}