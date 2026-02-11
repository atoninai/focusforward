import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// Top-level background handler — MUST be a top-level function (not a method)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  final actionId = response.actionId;
  if (actionId == 'stop_alarm') {
    // Dismissed
  } else if (actionId == 'snooze_alarm') {
    // Snooze handled in foreground callback
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();

    // Set local timezone to device timezone
    try {
      final now = DateTime.now();
      final localOffset = now.timeZoneOffset;
      // Find matching timezone
      for (final loc in tz.timeZoneDatabase.locations.values) {
        final tzNow = tz.TZDateTime.now(loc);
        if (tzNow.timeZoneOffset == localOffset) {
          tz.setLocalLocation(loc);
          break;
        }
      }
    } catch (_) {
      // Fallback: keep UTC
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request notification permission (Android 13+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    // Create notification channels per alarm sound
    for (final sound in [
      'motivational_alarm',
      'loud_alarm_sound',
      'extreme_alarm_clock'
    ]) {
      final channel = AndroidNotificationChannel(
        'alarm_$sound',
        'Alarm - ${_soundDisplayName(sound)}',
        description: 'Alarm with $sound sound',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound(sound),
      );

      await androidPlugin?.createNotificationChannel(channel);
    }

    // Default channel
    const defaultChannel = AndroidNotificationChannel(
      'focus_forward_default',
      'Focus Forward',
      description: 'General notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin?.createNotificationChannel(defaultChannel);
  }

  /// Handle notification action taps in the foreground
  static void _onNotificationAction(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId == 'snooze_alarm') {
      _scheduleSnooze(response.id ?? 0);
    }
  }

  /// Schedule a snooze notification 5 min from now
  static Future<void> _scheduleSnooze(int originalId) async {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final snoozeId = originalId + 10000;

    await _plugin.zonedSchedule(
      snoozeId,
      '⏰ Snoozed Alarm',
      'Your snoozed alarm is going off! Time to get up!',
      tz.TZDateTime.from(snoozeTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_motivational_alarm',
          'Alarm - Motivational',
          channelDescription: 'Snoozed alarm',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF8B5CF6),
          sound: const RawResourceAndroidNotificationSound('motivational_alarm'),
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: true,
          styleInformation: const BigTextStyleInformation(
            'Your snoozed alarm is going off! Get up and stay disciplined! 💪',
            contentTitle: '⏰ Snoozed Alarm',
            summaryText: 'Focus Forward',
          ),
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'stop_alarm',
              '🛑 Stop',
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
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

  /// Schedule a single alarm
  static Future<void> scheduleAlarm({
    required String alarmId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> repeatDays,
    required String soundFile,
  }) async {
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
        ongoing: true,
        autoCancel: false,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          '$body\n\nStay disciplined! 💪🔥',
          contentTitle: '⏰ $title',
          summaryText: 'Focus Forward Alarm',
        ),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'stop_alarm',
            '🛑 Stop Alarm',
            cancelNotification: true,
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'snooze_alarm',
            '😴 Snooze 5 min',
            cancelNotification: true,
            showsUserInterface: false,
          ),
        ],
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
        '⏰ $title',
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else {
      // Repeating — one per day of week
      for (final day in repeatDays) {
        final notifId = (alarmId.hashCode.abs() % 100000) + day;
        final now = DateTime.now();
        final scheduledDate = _nextDateForDay(day, hour, minute, now);

        await _plugin.zonedSchedule(
          notifId,
          '⏰ $title',
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

  static DateTime _nextDateForDay(
      int day, int hour, int minute, DateTime from) {
    var daysUntil = day - from.weekday;
    if (daysUntil < 0) daysUntil += 7;
    if (daysUntil == 0) {
      final todayAlarm =
          DateTime(from.year, from.month, from.day, hour, minute);
      if (todayAlarm.isBefore(from)) {
        daysUntil = 7;
      }
    }
    final target = from.add(Duration(days: daysUntil));
    return DateTime(target.year, target.month, target.day, hour, minute);
  }

  static Future<void> cancelAlarm(String alarmId) async {
    final baseId = alarmId.hashCode.abs() % 100000;
    await _plugin.cancel(baseId);
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(baseId + day);
    }
    await _plugin.cancel(baseId + 10000);
  }

  /// Schedule all enabled alarms — call on app start
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
          'focus_forward_default',
          'Focus Forward',
          channelDescription: 'General notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF8B5CF6),
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
