import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/medication_info.dart';
import '../models/medicine_data.dart';
import '../models/adapters/medication_info_adapter.dart';
import '../models/adapters/medicine_data_adapter.dart';

/// 薬物データのサービス
/// Hiveデータベースを使って薬物データを管理
class MedicationService {
  static Box<Map>? _medicationBox;
  static Box<MedicineData>? _medicineDatabase;
  static Box<Map>? _adherenceStats;
  static Box<dynamic>? _settingsBox;
  static bool _isInitialized = false;
  static const String _csvFileName = '服薬記録.csv';
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(directory.path);
      
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MedicationInfoAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MedicineDataAdapter());
      }
      
      _medicationBox = await Hive.openBox<Map>('medicationData');
      _medicineDatabase = await Hive.openBox<MedicineData>('medicineDatabase');
      _adherenceStats = await Hive.openBox<Map>('adherenceStats');
      _settingsBox = await Hive.openBox('settings');
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }
  
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  static Future<Map<String, Map<String, MedicationInfo>>> loadMedicationData() async {
    try {
      await _ensureInitialized();
      if (_medicationBox == null) return {};
      return _medicationBox!.toMap().cast<String, Map>().map(
            (key, value) => MapEntry(
              key,
              value.map((k, v) => MapEntry(k, MedicationInfo.fromJson(Map<String, dynamic>.from(v)))),
            ),
          );
    } catch (e) {
      return {};
    }
  }
  
  static Future<List<MedicineData>> loadMedicines() async {
    try {
      await _ensureInitialized();
      if (_medicineDatabase == null) return [];
      return _medicineDatabase!.values.toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<Map<String, double>> loadAdherenceStats() async {
    try {
      await _ensureInitialized();
      if (_adherenceStats == null) return {};
      return Map<String, double>.from(_adherenceStats!.get('rates') ?? {});
    } catch (e) {
      return {};
    }
  }
  
  static Future<void> saveMedicationData(Map<String, Map<String, MedicationInfo>> data) async {
    try {
      await _ensureInitialized();
      if (_medicationBox == null) return;
      await _medicationBox!.putAll(
        data.map((key, value) => MapEntry(key, value.map((k, v) => MapEntry(k, v.toJson())))),
      );
      await _medicationBox!.flush();
    } catch (e) {
      // エラー処理
    }
  }
  
  static Future<void> saveMedicine(MedicineData medicine) async {
    try {
      await _ensureInitialized();
      if (_medicineDatabase == null) return;
      await _medicineDatabase!.put(medicine.name, medicine);
      await _medicineDatabase!.flush();
    } catch (e) {
      // エラー処理
    }
  }
  
  static Future<void> deleteMedicine(String name) async {
    try {
      await _ensureInitialized();
      if (_medicineDatabase == null) return;
      await _medicineDatabase!.delete(name);
      await _medicineDatabase!.flush();
    } catch (e) {
      // エラー処理
    }
  }
  
  static Future<void> saveAdherenceStats(Map<String, double> stats) async {
    try {
      await _ensureInitialized();
      if (_adherenceStats == null) return;
      await _adherenceStats!.put('rates', stats);
      await _adherenceStats!.flush();
    } catch (e) {
      // エラー処理
    }
  }
  
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      await _ensureInitialized();
      if (_settingsBox == null) return;
      await _settingsBox!.putAll(settings);
      await _settingsBox!.flush();
    } catch (e) {
      // エラー処理
    }
  }
  
  static Future<Map<String, dynamic>> loadSettings() async {
    try {
      await _ensureInitialized();
      if (_settingsBox == null) return {};
      return Map<String, dynamic>.from(_settingsBox!.toMap());
    } catch (e) {
      return {};
    }
  }
  
  static Future<void> saveCsvRecord(String dateStr, String timeSlot, String medicine, String status) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_csvFileName');
      final now = DateFormat('yyyy年MM月d日 HH:mm:ss', 'ja_JP').format(DateTime.now());
      final record = '$dateStr,$timeSlot,${medicine.isEmpty ? "薬なし" : medicine},$status,$now\n';
      
      if (!await file.exists()) {
        await file.writeAsString('日付,時間帯,薬の名前,服用状態,記録時間\n');
      }
      await file.writeAsString(record, mode: FileMode.append);
    } catch (e) {
      // エラー処理
    }
  }
}
