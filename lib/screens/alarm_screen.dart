import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../models/alarm_item.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<AlarmItem> _alarms = [];
  List<AlarmItem> _bedAlarms = [];
  bool _ultraModeEnabled = true;
  String _defaultSound = 'motivational_alarm';
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingSound;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    // Update clock every second for real-time display
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final alarms = await StorageService.getAlarms();
    final bedAlarms = await StorageService.getBedAlarms();
    final defaultSound = await StorageService.getDefaultSound();
    setState(() {
      _alarms = alarms;
      _bedAlarms = bedAlarms;
      _ultraModeEnabled = alarms.any((a) => a.isUltraMode);
      _defaultSound = defaultSound;
    });
    // Schedule all enabled alarms on load
    final allAlarms = [...alarms, ...bedAlarms];
    await NotificationService.scheduleAllAlarms(allAlarms);
  }

  /// Show a countdown popup: "Alarm in X hours, Y minutes"
  void _showAlarmCountdown(int hour, int minute) {
    if (!mounted) return;
    final now = DateTime.now();
    var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (alarmTime.isBefore(now) || alarmTime.isAtSameMomentAs(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }
    final diff = alarmTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    String message;
    if (hours > 0 && minutes > 0) {
      message = 'Alarm in $hours ${hours == 1 ? "hour" : "hours"}, $minutes ${minutes == 1 ? "minute" : "minutes"}';
    } else if (hours > 0) {
      message = 'Alarm in $hours ${hours == 1 ? "hour" : "hours"}';
    } else if (minutes > 0) {
      message = 'Alarm in $minutes ${minutes == 1 ? "minute" : "minutes"}';
    } else {
      message = 'Alarm in less than a minute';
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.alarm, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveAndScheduleAlarms() async {
    await StorageService.saveAlarms(_alarms);
    await StorageService.saveBedAlarms(_bedAlarms);

    // Warn if exact alarm permission is missing, but still schedule
    // (the plugin will fall back to inexact alarms)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Exact alarm permission not granted. Alarms may be slightly delayed. Tap to fix.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    final allAlarms = [..._alarms, ..._bedAlarms];
    await NotificationService.scheduleAllAlarms(allAlarms);
  }

  void _toggleAlarm(int index) {
    setState(() => _alarms[index].isEnabled = !_alarms[index].isEnabled);
    if (!_alarms[index].isEnabled) {
      NotificationService.cancelAlarm(_alarms[index].id);
    } else {
      _showAlarmCountdown(_alarms[index].hour, _alarms[index].minute);
    }
    _saveAndScheduleAlarms();
  }

  void _deleteAlarm(int index) {
    final alarm = _alarms[index];
    NotificationService.cancelAlarm(alarm.id);
    setState(() => _alarms.removeAt(index));
    _saveAndScheduleAlarms();
  }

  void _toggleBedAlarm(int index) {
    setState(() => _bedAlarms[index].isEnabled = !_bedAlarms[index].isEnabled);
    if (!_bedAlarms[index].isEnabled) {
      NotificationService.cancelAlarm(_bedAlarms[index].id);
    } else {
      _showAlarmCountdown(_bedAlarms[index].hour, _bedAlarms[index].minute);
    }
    _saveAndScheduleAlarms();
  }

  void _editBedAlarmTime(int index) async {
    final alarm = _bedAlarms[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: alarm.hour, minute: alarm.minute),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surfaceDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _bedAlarms[index].hour = picked.hour;
      _bedAlarms[index].minute = picked.minute;
    });
    if (_bedAlarms[index].isEnabled) {
      _showAlarmCountdown(picked.hour, picked.minute);
    }
    _saveAndScheduleAlarms();
  }

  Future<void> _previewSound(String sound) async {
    if (_playingSound == sound) {
      await _audioPlayer.stop();
      setState(() => _playingSound = null);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
      setState(() => _playingSound = sound);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingSound = null);
      });
    }
  }

  void _showDefaultSoundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Default Alarm Sound',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                    onPressed: () {
                      _audioPlayer.stop();
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...AlarmItem.availableSounds.map((sound) {
                final isSelected = _defaultSound == sound;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.cardBorder,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.2)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      AlarmItem.soundName(sound),
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _playingSound == sound
                                ? Icons.stop_circle
                                : Icons.play_circle,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                          onPressed: () {
                            _previewSound(sound);
                            setModalState(() {});
                          },
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppTheme.primary, size: 22),
                      ],
                    ),
                    onTap: () async {
                      await _audioPlayer.stop();
                      setState(() {
                        _defaultSound = sound;
                        _playingSound = null;
                      });
                      setModalState(() {});
                      await StorageService.setDefaultSound(sound);
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ).then((_) => _audioPlayer.stop());
  }

  void _addAlarm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddAlarmSheet(
        defaultSound: _defaultSound,
        audioPlayer: _audioPlayer,
        onSave: (alarm) {
          setState(() => _alarms.add(alarm));
          _showAlarmCountdown(alarm.hour, alarm.minute);
          _saveAndScheduleAlarms();
        },
      ),
    );
  }

  void _editAlarm(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddAlarmSheet(
        defaultSound: _defaultSound,
        audioPlayer: _audioPlayer,
        existingAlarm: _alarms[index],
        onSave: (alarm) {
          setState(() => _alarms[index] = alarm);
          _showAlarmCountdown(alarm.hour, alarm.minute);
          _saveAndScheduleAlarms();
        },
      ),
    );
  }

  void _toggleUltraMode() {
    setState(() {
      _ultraModeEnabled = !_ultraModeEnabled;
      for (var a in _alarms) {
        a.isUltraMode = _ultraModeEnabled;
      }
    });
    _saveAndScheduleAlarms();
  }

  @override
  Widget build(BuildContext context) {
    final now = _currentTime;
    final timeStr = DateFormat('hh:mm').format(now);
    final period = DateFormat('a').format(now);
    final dateStr = DateFormat('EEEE, MMM d').format(now);
    final secondStr = DateFormat('ss').format(now);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFFA78BFA)],
                          ).createShader(bounds),
                          child: const Text(
                            'Alarms',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Focus Forward',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showDefaultSoundPicker,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.cardBorder,
                          ),
                        ),
                        child: const Icon(Icons.settings,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Big time display ───
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            blurRadius: 50,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -2,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              ':$secondStr',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.5),
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(period,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(dateStr,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Bed Alarms Section ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bedtime, color: AppTheme.primary, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'BED ALARMS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Wake up card
                        Expanded(child: _buildBedAlarmCard(0, Icons.wb_sunny, const Color(0xFFFBBF24), 'Wake Up')),
                        const SizedBox(width: 10),
                        // Sleep card
                        Expanded(child: _buildBedAlarmCard(1, Icons.bedtime, const Color(0xFF818CF8), 'Sleep')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Ultra Alarm Mode ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt,
                                    color: AppTheme.primary, size: 16),
                                const SizedBox(width: 4),
                                const Text('Ultra Alarm Mode',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Volume ramps 10% → 100% over 2 min',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _ultraModeEnabled,
                        onChanged: (_) => _toggleUltraMode(),
                        activeTrackColor: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Regular Alarms ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ALARMS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 1.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: _addAlarm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: AppTheme.primary, size: 16),
                            SizedBox(width: 4),
                            Text('Add Alarm',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (_alarms.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.alarm_add,
                              color: Colors.grey[700], size: 32),
                          const SizedBox(height: 8),
                          Text('No alarms set',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text('Tap + Add Alarm to get started',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ),
                ),

              // Alarm cards
              ...List.generate(_alarms.length, (i) => _buildAlarmCard(i)),

              const SizedBox(height: 24),

              // ─── Volume Curve ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VOLUME CURVE',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Silent',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[500])),
                              Text('Max Volume',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[500])),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 60,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(20, (i) {
                                final h = (i + 1) / 20;
                                final alpha = 0.2 + (h * 0.8);
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withValues(alpha: alpha),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(2),
                                        topRight: Radius.circular(2),
                                      ),
                                      boxShadow: i >= 17
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primary
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    height: 60 * h,
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0s',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600])),
                              const Text('120s Ramp',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bed Alarm Card ───
  Widget _buildBedAlarmCard(int index, IconData icon, Color color, String title) {
    if (index >= _bedAlarms.length) return const SizedBox();
    final alarm = _bedAlarms[index];
    return GestureDetector(
      onTap: () => _editBedAlarmTime(index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: alarm.isEnabled
                ? color.withValues(alpha: 0.3)
                : AppTheme.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 6),
                    Text(title,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ],
                ),
                SizedBox(
                  height: 28,
                  child: Switch(
                    value: alarm.isEnabled,
                    onChanged: (_) => _toggleBedAlarm(index),
                    activeTrackColor: color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alarm.formattedTime,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: alarm.isEnabled ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to change',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Regular Alarm Card ───
  Widget _buildAlarmCard(int index) {
    final alarm = _alarms[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: alarm.isEnabled
              ? Border(
                  left: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: time, sound, toggle, delete
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editAlarm(index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alarm.formattedTime,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                            color: alarm.isEnabled
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(alarm.label,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: alarm.isEnabled
                                        ? AppTheme.primary
                                        : Colors.grey[600])),
                            Container(
                              width: 3,
                              height: 3,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                            Icon(Icons.music_note,
                                size: 11, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(alarm.soundDisplayName,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Switch(
                  value: alarm.isEnabled,
                  onChanged: (_) => _toggleAlarm(index),
                  activeTrackColor: AppTheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _deleteAlarm(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Day selector chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (d) {
                final day = d + 1; // 1=Mon, 7=Sun
                const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final isActive = alarm.repeatDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isActive) {
                        alarm.repeatDays = List.from(alarm.repeatDays)
                          ..remove(day);
                      } else {
                        alarm.repeatDays = List.from(alarm.repeatDays)
                          ..add(day)
                          ..sort();
                      }
                    });
                    _saveAndScheduleAlarms();
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withValues(alpha: 0.2)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.primary.withValues(alpha: 0.5)
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dayLabels[d],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          color:
                              isActive ? AppTheme.primary : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add/Edit Alarm Bottom Sheet ───
class _AddAlarmSheet extends StatefulWidget {
  final String defaultSound;
  final AudioPlayer audioPlayer;
  final AlarmItem? existingAlarm;
  final Function(AlarmItem) onSave;

  const _AddAlarmSheet({
    required this.defaultSound,
    required this.audioPlayer,
    required this.onSave,
    this.existingAlarm,
  });

  @override
  State<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<_AddAlarmSheet> {
  late TimeOfDay _time;
  late TextEditingController _labelCtrl;
  late List<int> _selectedDays;
  late String _selectedSound;
  String? _playingSound;

  @override
  void initState() {
    super.initState();
    if (widget.existingAlarm != null) {
      final a = widget.existingAlarm!;
      _time = TimeOfDay(hour: a.hour, minute: a.minute);
      _labelCtrl = TextEditingController(text: a.label);
      _selectedDays = List.from(a.repeatDays);
      _selectedSound = a.soundFile;
    } else {
      _time = TimeOfDay.now();
      _labelCtrl = TextEditingController();
      _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // all days by default
      _selectedSound = widget.defaultSound;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    widget.audioPlayer.stop();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surfaceDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _previewSound(String sound) async {
    if (_playingSound == sound) {
      await widget.audioPlayer.stop();
      setState(() => _playingSound = null);
    } else {
      await widget.audioPlayer.stop();
      await widget.audioPlayer.play(AssetSource('sounds/$sound.mp3'));
      setState(() => _playingSound = sound);
      widget.audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingSound = null);
      });
    }
  }

  void _save() {
    widget.audioPlayer.stop();
    final label = _labelCtrl.text.isEmpty ? 'Alarm' : _labelCtrl.text;
    final alarm = AlarmItem(
      id: widget.existingAlarm?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      hour: _time.hour,
      minute: _time.minute,
      label: label,
      repeatDays: _selectedDays,
      isEnabled: true,
      soundFile: _selectedSound,
    );
    widget.onSave(alarm);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAlarm != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(isEditing ? 'Edit Alarm' : 'New Alarm',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),

            // Time picker
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    _time.format(context),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Label
            TextField(
              controller: _labelCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Alarm label (e.g. Morning Routine)',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Day selection
            const Text('Repeat Days',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD1D5DB))),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (d) {
                final day = d + 1;
                const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final isActive = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isActive) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                        _selectedDays.sort();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withValues(alpha: 0.2)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: Text(
                      labels[d],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? AppTheme.primary : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Sound picker
            const Text('Alarm Sound',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD1D5DB))),
            const SizedBox(height: 8),
            ...AlarmItem.availableSounds.map((sound) {
              final isSelected = _selectedSound == sound;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.cardBorder,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.music_note,
                      color:
                          isSelected ? AppTheme.primary : Colors.grey[600],
                      size: 18),
                  title: Text(
                    AlarmItem.soundName(sound),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isSelected ? Colors.white : const Color(0xFFD1D5DB),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _previewSound(sound),
                        child: Icon(
                          _playingSound == sound
                              ? Icons.stop_circle
                              : Icons.play_circle,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle,
                              color: AppTheme.primary, size: 18),
                        ),
                    ],
                  ),
                  onTap: () => setState(() => _selectedSound = sound),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                ),
                child: Text(
                  isEditing ? 'Update Alarm' : 'Set Alarm',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
