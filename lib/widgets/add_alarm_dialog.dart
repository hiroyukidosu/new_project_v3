// lib/widgets/add_alarm_dialog.dart
// アラーム追加/編集ダイアログを分離

import 'package:flutter/material.dart';

class AddAlarmDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAlarmAdded;
  final Map<String, dynamic>? initialAlarm;

  const AddAlarmDialog({
    super.key,
    required this.onAlarmAdded,
    this.initialAlarm,
  });

  @override
  State<AddAlarmDialog> createState() => _AddAlarmDialogState();
}

class _AddAlarmDialogState extends State<AddAlarmDialog> {
  final _nameController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _repeatType = '一度だけ';
  String _selectedAlarmType = 'sound';
  int _volume = 80;
  bool _isRepeatEnabled = false;
  List<bool> _selectedDays = [false, false, false, false, false, false, false]; // 月〜日

  @override
  void initState() {
    super.initState();
    if (widget.initialAlarm != null) {
      _nameController.text = (widget.initialAlarm!['name'] as String?) ?? '';
      _selectedAlarmType = (widget.initialAlarm!['alarmType'] as String?) ?? 'sound';
      _volume = (widget.initialAlarm!['volume'] as int?) ?? 80;
      _isRepeatEnabled = (widget.initialAlarm!['isRepeatEnabled'] as bool?) ?? false;
      _selectedDays = List<bool>.from((widget.initialAlarm!['selectedDays'] as List?) ?? [false, false, false, false, false, false, false]);
      
      // 繰り返し設定の初期化
      final repeat = (widget.initialAlarm!['repeat'] as String?) ?? '一度だけ';
      if (_isRepeatEnabled && repeat != '一度だけ') {
        _repeatType = repeat;
      } else {
        _repeatType = '毎日'; // デフォルト値
      }
      
      // 時間の設定
      final timeStr = (widget.initialAlarm!['time'] as String?) ?? '00:00';
      final timeParts = timeStr.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialAlarm != null ? 'アラーム編集' : 'アラーム追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // アラーム名
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'アラーム名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            
            // 時間選択
            ListTile(
              title: const Text('時間'),
              subtitle: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // 繰り返し設定
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.repeat, color: Color(0xFF2196F3)),
                        const SizedBox(width: 8),
                        const Text('繰り返し', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Switch(
                          value: _isRepeatEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isRepeatEnabled = value;
                              if (!value) {
                                _repeatType = '一度だけ';
                              } else {
                                // 繰り返しが有効になった時はデフォルトで「毎日」を設定
                                if (_repeatType == '一度だけ') {
                                  _repeatType = '毎日';
                                }
                              }
                            });
                          },
                          activeColor: const Color(0xFF2196F3),
                        ),
                      ],
                    ),
                    if (_isRepeatEnabled) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _isRepeatEnabled ? _repeatType : '一度だけ',
                        decoration: const InputDecoration(
                          labelText: '繰り返しパターン',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: const [
                          DropdownMenuItem(value: '毎日', child: Text('毎日')),
                          DropdownMenuItem(value: '曜日', child: Text('曜日')),
                          DropdownMenuItem(value: '平日', child: Text('平日')),
                          DropdownMenuItem(value: '週末', child: Text('週末')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _repeatType = value!;
                          });
                        },
                      ),
                      if (_repeatType == '曜日') ...[
                        const SizedBox(height: 16),
                        const Text('曜日を選択', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildDaySelector(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // アラーム種類選択
            DropdownButtonFormField<String>(
              value: _selectedAlarmType,
              decoration: const InputDecoration(
                labelText: '服用アラーム種類',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications),
              ),
              items: const [
                DropdownMenuItem(value: 'sound', child: Text('🔊 音')),
                DropdownMenuItem(value: 'sound_vibration', child: Text('🔊📳 音＋バイブ')),
                DropdownMenuItem(value: 'vibration', child: Text('📳 バイブ')),
                DropdownMenuItem(value: 'silent', child: Text('🔇 サイレント')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAlarmType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 音量設定
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('音量', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$_volume%', style: const TextStyle(color: Color(0xFF2196F3))),
                      ],
                    ),
                    Slider(
                      value: _volume.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: const Color(0xFF2196F3),
                      onChanged: (value) {
                        setState(() {
                          _volume = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final alarm = <String, dynamic>{
              'name': _nameController.text.isEmpty ? 'アラーム' : _nameController.text,
              'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              'repeat': _isRepeatEnabled ? _repeatType : '一度だけ',
              'enabled': true,
              'alarmType': _selectedAlarmType,
              'volume': _volume,
              'isRepeatEnabled': _isRepeatEnabled,
              'selectedDays': _selectedDays,
            };
            debugPrint('アラーム追加ボタン押下: ${alarm.toString()}');
            widget.onAlarmAdded(alarm);
            debugPrint('アラーム追加コールバック呼び出し完了');
            Navigator.pop(context);
          },
          child: Text(widget.initialAlarm != null ? '更新' : '追加'),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    const days = ['月', '火', '水', '木', '金', '土', '日'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDays[index] = !_selectedDays[index];
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _selectedDays[index] 
                  ? const Color(0xFF2196F3) 
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedDays[index] 
                    ? const Color(0xFF2196F3) 
                    : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  color: _selectedDays[index] 
                      ? Colors.white 
                      : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

