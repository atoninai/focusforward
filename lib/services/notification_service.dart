import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

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

  // ─── Channel IDs ───
  static const String channelDefault = 'focus_forward_default';
  static const String channelBedtime = 'bedtime_reminder';
  static const String channelGoal = 'goal_reminder';

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();

    // Use flutter_native_timezone to get the REAL device timezone
    try {
      final String timezoneName =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      // Fallback: try offset matching as last resort
      try {
        final now = DateTime.now();
        final localOffset = now.timeZoneOffset;
        for (final loc in tz.timeZoneDatabase.locations.values) {
          final tzNow = tz.TZDateTime.now(loc);
          if (tzNow.timeZoneOffset == localOffset) {
            tz.setLocalLocation(loc);
            break;
          }
        }
      } catch (_) {
        // Keep UTC
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // ─── Create notification channels ───

    // Alarm channels (per sound)
    for (final sound in [
      'motivational_alarm',
      'loud_alarm_sound',
      'extreme_alarm_clock'
    ]) {
      final channel = AndroidNotificationChannel(
        'alarm_$sound',
        'Alarm - ${_soundDisplayName(sound)}',
        description: 'Alarm notifications with $sound sound',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound(sound),
      );
      await androidPlugin?.createNotificationChannel(channel);
    }

    // Bedtime / wake-up channel
    const bedtimeChannel = AndroidNotificationChannel(
      channelBedtime,
      'Bedtime Reminder',
      description: 'Wake-up and sleep time reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin?.createNotificationChannel(bedtimeChannel);

    // Goal reminder channel
    const goalChannel = AndroidNotificationChannel(
      channelGoal,
      'Goal Reminder',
      description: 'Notifications for your daily goals',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin?.createNotificationChannel(goalChannel);

    // Default channel
    const defaultChannel = AndroidNotificationChannel(
      channelDefault,
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
          sound: const RawResourceAndroidNotificationSound(
              'motivational_alarm'),
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

  /// Determine which channel to use based on alarm type
  static String _channelIdForAlarm(String alarmType, String soundFile) {
    switch (alarmType) {
      case 'wakeup':
      case 'sleep':
        return channelBedtime;
      case 'regular':
      default:
        return 'alarm_$soundFile';
    }
  }

  static String _channelNameForAlarm(String alarmType, String soundFile) {
    switch (alarmType) {
      case 'wakeup':
      case 'sleep':
        return 'Bedtime Reminder';
      case 'regular':
      default:
        return 'Alarm - ${_soundDisplayName(soundFile)}';
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
    String alarmType = 'regular',
  }) async {
    await cancelAlarm(alarmId);

    final channelId = _channelIdForAlarm(alarmType, soundFile);
    final channelName = _channelNameForAlarm(alarmType, soundFile);

    // Only use custom sound for regular alarms; bedtime uses default channel sound
    final bool useCustomSound = alarmType == 'regular';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: alarmType == 'regular'
            ? 'Alarm notification'
            : 'Bedtime reminder notification',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF8B5CF6),
        sound: useCustomSound
            ? RawResourceAndroidNotificationSound(soundFile)
            : null,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          '$body\n\nStay disciplined! 💪🔥',
          contentTitle: alarmType == 'sleep'
              ? '🌙 $title'
              : alarmType == 'wakeup'
                  ? '☀️ $title'
                  : '⏰ $title',
          summaryText: alarmType == 'regular'
              ? 'Focus Forward Alarm'
              : 'Focus Forward Bedtime',
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
      var scheduledDate =
          DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now) ||
          scheduledDate.isAtSameMomentAs(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final notifId = alarmId.hashCode.abs() % 100000;

      await _plugin.zonedSchedule(
        notifId,
        alarmType == 'sleep'
            ? '🌙 $title'
            : alarmType == 'wakeup'
                ? '☀️ $title'
                : '⏰ $title',
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
          alarmType == 'sleep'
              ? '🌙 $title'
              : alarmType == 'wakeup'
                  ? '☀️ $title'
                  : '⏰ $title',
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
          alarmType: alarm.alarmType ?? 'regular',
        );
      }
    }
  }

  /// Show a goal reminder notification
  static Future<void> showGoalNotification({
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
          channelGoal,
          'Goal Reminder',
          channelDescription: 'Notifications for your daily goals',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF8B5CF6),
          category: AndroidNotificationCategory.reminder,
        ),
      ),
    );
  }

  /// Show a bedtime reminder notification
  static Future<void> showBedtimeNotification({
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
          channelBedtime,
          'Bedtime Reminder',
          channelDescription: 'Wake-up and sleep time reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF818CF8),
        ),
      ),
    );
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
          channelDefault,
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
