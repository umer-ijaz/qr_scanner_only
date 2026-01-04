import 'dart:convert';

class ScanItem {
  final String id;
  final String content;
  final DateTime timestamp;
  final String type;

  ScanItem({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
      };

  static ScanItem fromJson(Map<String, dynamic> j) => ScanItem(
        id: j['id'] as String,
        content: j['content'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        type: j['type'] as String,
      );

  static List<ScanItem> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    final List parsed = json.decode(jsonString) as List;
    return parsed.map((e) => ScanItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<ScanItem> items) => json.encode(items.map((e) => e.toJson()).toList());
}
