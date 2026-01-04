import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../models/scan_item.dart';

class StorageService {
  static const _kHistoryKey = 'scan_history_v1';

  Future<List<ScanItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistoryKey);
    return ScanItem.listFromJson(raw);
  }

  Future<void> saveScan(ScanItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = ScanItem.listFromJson(prefs.getString(_kHistoryKey));

    // Prevent exact duplicates within short timeframe
    final existsNearby = list.isNotEmpty && list.first.content == item.content;
    if (existsNearby) return;

    list.insert(0, item);
    await prefs.setString(_kHistoryKey, ScanItem.listToJson(list));
  }

  Future<void> deleteScan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = ScanItem.listFromJson(prefs.getString(_kHistoryKey));
    list.removeWhere((e) => e.id == id);
    await prefs.setString(_kHistoryKey, ScanItem.listToJson(list));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }
}
