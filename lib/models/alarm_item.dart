import 'dart:convert';

class AlarmItem {
  final String id;
  int hour;
  int minute;
  String label;
  List<int> repeatDays; // 1=Mon, 2=Tue, ..., 7=Sun
  bool isEnabled;
  bool isUltraMode;
  String soundFile; // e.g. 'motivational_alarm', 'loud_alarm_sound', 'extreme_alarm_clock'
  String alarmType; // 'regular', 'wakeup', 'sleep'

  AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    this.repeatDays = const [],
    this.isEnabled = true,
    this.isUltraMode = false,
    this.soundFile = 'motivational_alarm',
    this.alarmType = 'regular',
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
    final weekdays = [1, 2, 3, 4, 5];
    final weekend = [6, 7];
    if (repeatDays.length == 5 && weekdays.every((d) => repeatDays.contains(d))) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 && weekend.every((d) => repeatDays.contains(d))) {
      return 'Weekends';
    }
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => dayNames[d]).join(', ');
  }

  String get soundDisplayName {
    switch (soundFile) {
      case 'motivational_alarm':
        return 'Motivational';
      case 'loud_alarm_sound':
        return 'Loud Alarm';
      case 'extreme_alarm_clock':
        return 'Extreme';
      default:
        return soundFile;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'repeatDays': repeatDays,
        'isEnabled': isEnabled,
        'isUltraMode': isUltraMode,
        'soundFile': soundFile,
        'alarmType': alarmType,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> json) => AlarmItem(
        id: json['id'],
        hour: json['hour'],
        minute: json['minute'],
        label: json['label'],
        repeatDays: List<int>.from(json['repeatDays'] ?? []),
        isEnabled: json['isEnabled'] ?? true,
        isUltraMode: json['isUltraMode'] ?? false,
        soundFile: json['soundFile'] ?? 'motivational_alarm',
        alarmType: json['alarmType'] ?? 'regular',
      );

  static String encode(List<AlarmItem> alarms) =>
      json.encode(alarms.map((a) => a.toJson()).toList());

  static List<AlarmItem> decode(String data) =>
      (json.decode(data) as List).map((item) => AlarmItem.fromJson(item)).toList();

  static const List<String> availableSounds = [
    'motivational_alarm',
    'loud_alarm_sound',
    'extreme_alarm_clock',
  ];

  static String soundName(String file) {
    switch (file) {
      case 'motivational_alarm':
        return 'Motivational';
      case 'loud_alarm_sound':
        return 'Loud Alarm';
      case 'extreme_alarm_clock':
        return 'Extreme';
      default:
        return file;
    }
  }
}
