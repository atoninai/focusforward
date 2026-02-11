import 'dart:convert';

class Habit {
  final String id;
  final String name;
  final String icon;
  int streak;
  List<String> completedDates; // ISO date strings "yyyy-MM-dd"

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.streak = 0,
    List<String>? completedDates,
  }) : completedDates = completedDates ?? [];

  bool isCompletedToday() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return completedDates.contains(today);
  }

  void toggleToday() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (completedDates.contains(today)) {
      completedDates.remove(today);
      if (streak > 0) streak--;
    } else {
      completedDates.add(today);
      streak++;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'streak': streak,
        'completedDates': completedDates,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        streak: json['streak'] ?? 0,
        completedDates: List<String>.from(json['completedDates'] ?? []),
      );

  static String encode(List<Habit> habits) =>
      json.encode(habits.map((h) => h.toJson()).toList());

  static List<Habit> decode(String data) =>
      (json.decode(data) as List).map((item) => Habit.fromJson(item)).toList();
}
