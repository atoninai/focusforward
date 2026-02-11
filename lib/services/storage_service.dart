import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';
import '../models/goal.dart';
import '../models/alarm_item.dart';
import '../models/habit.dart';

class StorageService {
  static const String _routinesKey = 'routines';
  static const String _goalsKey = 'goals';
  static const String _alarmsKey = 'alarms';
  static const String _habitsKey = 'habits';
  static const String _permissionsGrantedKey = 'permissions_granted';

  // ─── Permissions ───
  static Future<bool> arePermissionsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsGrantedKey) ?? false;
  }

  static Future<void> setPermissionsGranted(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsGrantedKey, granted);
  }

  // ─── Routines ───
  static Future<List<Routine>> getRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_routinesKey);
    if (data == null) return _defaultRoutines();
    return Routine.decode(data);
  }

  static Future<void> saveRoutines(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routinesKey, Routine.encode(routines));
  }

  static List<Routine> _defaultRoutines() {
    return [
      Routine(id: '1', name: 'Drink Water', icon: 'water_drop', time: '10:00 AM', isActive: true),
      Routine(id: '2', name: 'Read 10 pages', icon: 'book', time: '2:00 PM'),
      Routine(id: '3', name: 'Gym Session', icon: 'fitness_center', time: '6:00 PM'),
    ];
  }

  // ─── Goals ───
  static Future<List<Goal>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_goalsKey);
    if (data == null) return [];
    return Goal.decode(data);
  }

  static Future<void> saveGoals(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalsKey, Goal.encode(goals));
  }

  // ─── Alarms ───
  static Future<List<AlarmItem>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_alarmsKey);
    if (data == null) return _defaultAlarms();
    return AlarmItem.decode(data);
  }

  static Future<void> saveAlarms(List<AlarmItem> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alarmsKey, AlarmItem.encode(alarms));
  }

  static List<AlarmItem> _defaultAlarms() {
    return [
      AlarmItem(id: '1', hour: 7, minute: 0, label: 'Daily Routine', repeatDays: [1, 2, 3, 4, 5, 6, 7], isEnabled: true, isUltraMode: true),
      AlarmItem(id: '2', hour: 8, minute: 30, label: 'Deep Work', repeatDays: [1, 3, 5], isEnabled: false),
      AlarmItem(id: '3', hour: 22, minute: 0, label: 'Wind Down', repeatDays: [1, 2, 3, 4, 5, 6, 7], isEnabled: false),
    ];
  }

  // ─── Habits ───
  static Future<List<Habit>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_habitsKey);
    if (data == null) return [];
    return Habit.decode(data);
  }

  static Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_habitsKey, Habit.encode(habits));
  }
}
