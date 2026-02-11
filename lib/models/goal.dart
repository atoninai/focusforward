import 'dart:convert';

class Goal {
  final String id;
  final String title;
  bool isCompleted;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        title: json['title'],
        isCompleted: json['isCompleted'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  static String encode(List<Goal> goals) =>
      json.encode(goals.map((g) => g.toJson()).toList());

  static List<Goal> decode(String data) =>
      (json.decode(data) as List).map((item) => Goal.fromJson(item)).toList();
}
