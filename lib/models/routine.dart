import 'dart:convert';

class Routine {
  final String id;
  final String name;
  final String icon;
  final String time;
  final bool isActive;
  bool isCompleted;

  Routine({
    required this.id,
    required this.name,
    required this.icon,
    required this.time,
    this.isActive = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'time': time,
        'isActive': isActive,
        'isCompleted': isCompleted,
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        time: json['time'],
        isActive: json['isActive'] ?? false,
        isCompleted: json['isCompleted'] ?? false,
      );

  static String encode(List<Routine> routines) =>
      json.encode(routines.map((r) => r.toJson()).toList());

  static List<Routine> decode(String data) =>
      (json.decode(data) as List).map((item) => Routine.fromJson(item)).toList();
}
