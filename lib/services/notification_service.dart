import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
      },
    );

    // Create default notification channel
    const channel = AndroidNotificationChannel(
      'focus_forward_alarms',
      'Focus Forward Alarms',
      description: 'Alarm notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Create a channel per sound file
    for (final sound in ['motivational_alarm', 'loud_alarm_sound', 'extreme_alarm_clock']) {
      final soundChannel = AndroidNotificationChannel(
        'alarm_$sound',
        'Alarm - ${_soundDisplayName(sound)}',
        description: 'Alarm with $sound sound',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound(sound),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(soundChannel);
    }
  }

  static String _soundDisplayName(String file) {
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

  /// Schedule a single alarm. Uses the alarm's ID hash + day as notification ID.
  static Future<void> scheduleAlarm({
    required String alarmId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> repeatDays,
    required String soundFile,
  }) async {
    // Cancel existing notifications for this alarm first
    await cancelAlarm(alarmId);

    final channelId = 'alarm_$soundFile';
    final channelName = 'Alarm - ${_soundDisplayName(soundFile)}';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Alarm notification',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF8B5CF6),
        sound: RawResourceAndroidNotificationSound(soundFile),
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      ),
    );

    if (repeatDays.isEmpty) {
      // One-time alarm
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final notifId = alarmId.hashCode.abs() % 100000;

      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else {
      // Repeating alarm — schedule one per day of week
      for (final day in repeatDays) {
        final notifId = (alarmId.hashCode.abs() % 100000) + day;

        final now = DateTime.now();
        var scheduledDate = _nextDateForDay(day, hour, minute, now);

        await _plugin.zonedSchedule(
          notifId,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  /// Find the next occurrence of a specific day of week (1=Mon, 7=Sun)
  static DateTime _nextDateForDay(int day, int hour, int minute, DateTime from) {
    // Convert our day format (1=Mon, 7=Sun) to Dart's (1=Mon, 7=Sun — same!)
    var daysUntil = day - from.weekday;
    if (daysUntil < 0) daysUntil += 7;
    if (daysUntil == 0) {
      final todayAlarm = DateTime(from.year, from.month, from.day, hour, minute);
      if (todayAlarm.isBefore(from)) {
        daysUntil = 7;
      }
    }
    final target = from.add(Duration(days: daysUntil));
    return DateTime(target.year, target.month, target.day, hour, minute);
  }

  /// Cancel all notifications for a specific alarm
  static Future<void> cancelAlarm(String alarmId) async {
    final baseId = alarmId.hashCode.abs() % 100000;
    // Cancel the base (one-time) and all 7 possible day slots
    await _plugin.cancel(baseId);
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(baseId + day);
    }
  }

  /// Schedule all enabled alarms (call on app start)
  static Future<void> scheduleAllAlarms(List<dynamic> alarms) async {
    for (final alarm in alarms) {
      if (alarm.isEnabled) {
        await scheduleAlarm(
          alarmId: alarm.id,
          title: alarm.label,
          body: 'Focus Forward Alarm - ${alarm.formattedTime}',
          hour: alarm.hour,
          minute: alarm.minute,
          repeatDays: List<int>.from(alarm.repeatDays),
          soundFile: alarm.soundFile ?? 'motivational_alarm',
        );
      }
    }
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_forward_alarms',
          'Focus Forward Alarms',
          channelDescription: 'Alarm notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
