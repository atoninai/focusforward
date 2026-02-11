import 'dart:convert';

class AlarmItem {
  final String id;
  final int hour;
  final int minute;
  final String label;
  final List<int> repeatDays; // 1=Mon, 7=Sun
  bool isEnabled;
  bool isUltraMode;

  AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    this.repeatDays = const [],
    this.isEnabled = true,
    this.isUltraMode = false,
  });

  String get formattedTime {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String get timeOnly {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m';
  }

  String get period => hour >= 12 ? 'PM' : 'AM';

  String get repeatText {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Everyday';
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => dayNames[d]).join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'repeatDays': repeatDays,
        'isEnabled': isEnabled,
        'isUltraMode': isUltraMode,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> json) => AlarmItem(
        id: json['id'],
        hour: json['hour'],
        minute: json['minute'],
        label: json['label'],
        repeatDays: List<int>.from(json['repeatDays'] ?? []),
        isEnabled: json['isEnabled'] ?? true,
        isUltraMode: json['isUltraMode'] ?? false,
      );

  static String encode(List<AlarmItem> alarms) =>
      json.encode(alarms.map((a) => a.toJson()).toList());

  static List<AlarmItem> decode(String data) =>
      (json.decode(data) as List).map((item) => AlarmItem.fromJson(item)).toList();
}
