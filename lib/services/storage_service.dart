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
  static const String _defaultSoundKey = 'default_alarm_sound';
  static const String _bedAlarmsKey = 'bed_alarms';

  // ─── Permissions ───
  static Future<bool> arePermissionsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsGrantedKey) ?? false;
  }

  static Future<void> setPermissionsGranted(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsGrantedKey, granted);
  }

  // ─── Default Alarm Sound ───
  static Future<String> getDefaultSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultSoundKey) ?? 'motivational_alarm';
  }

  static Future<void> setDefaultSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultSoundKey, sound);
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

  // ─── Alarms (regular) ───
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
      AlarmItem(id: '1', hour: 7, minute: 0, label: 'Daily Routine', repeatDays: [1, 2, 3, 4, 5, 6, 7], isEnabled: true, isUltraMode: true, alarmType: 'regular'),
    ];
  }

  // ─── Bed Alarms (wake up & sleep) ───
  static Future<List<AlarmItem>> getBedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_bedAlarmsKey);
    if (data == null) return _defaultBedAlarms();
    return AlarmItem.decode(data);
  }

  static Future<void> saveBedAlarms(List<AlarmItem> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bedAlarmsKey, AlarmItem.encode(alarms));
  }

  static List<AlarmItem> _defaultBedAlarms() {
    return [
      AlarmItem(id: 'bed_wakeup', hour: 6, minute: 0, label: 'Wake Up', repeatDays: [1, 2, 3, 4, 5, 6, 7], isEnabled: false, alarmType: 'wakeup'),
      AlarmItem(id: 'bed_sleep', hour: 22, minute: 0, label: 'Go to Sleep', repeatDays: [1, 2, 3, 4, 5, 6, 7], isEnabled: false, alarmType: 'sleep'),
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
