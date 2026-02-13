import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'main_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    setState(() => _loading = true);

    // 1. Request notifications (Android 13+)
    await Permission.notification.request();

    // 2. Request storage
    await Permission.storage.request();

    // 3. Request exact alarm (Android 12+ / API 31+)
    // On Android 12+, scheduleExactAlarm cannot be granted by a dialog —
    // the user MUST enable it manually in Settings > Apps > Alarms & Reminders.
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted) {
      // Try requesting it first
      final result = await Permission.scheduleExactAlarm.request();
      if (!result.isGranted && mounted) {
        // Must open settings for the user to enable "Alarms & Reminders"
        final shouldOpen = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Alarm Permission Required',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: const Text(
              'To set alarms, you need to enable "Alarms & Reminders" in the app settings.\n\nTap "Open Settings" and enable the permission.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Skip',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (shouldOpen == true) {
          await openAppSettings();
          // Wait a moment for the user to come back
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    // 4. Request battery optimization exemption — critical for alarm reliability
    await Permission.ignoreBatteryOptimizations.request();

    await StorageService.setPermissionsGranted(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // App icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFFA78BFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.neonStrongShadow,
                  ),
                  child:
                      const Icon(Icons.bolt, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Focus Forward',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your discipline companion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 48),
                // Permission items
                _buildPermissionItem(
                  Icons.notifications_outlined,
                  'Notifications',
                  'Get alerts for routines & alarms',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  Icons.alarm_outlined,
                  'Exact Alarms',
                  'Schedule precise alarm timings',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  Icons.folder_outlined,
                  'Storage',
                  'Save your data locally on device',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  Icons.battery_saver,
                  'Battery',
                  'Keep alarms running in background',
                ),
                const Spacer(flex: 3),
                // Grant button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppTheme.primaryGlow,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Grant Permissions & Start',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline,
              color: AppTheme.primary.withValues(alpha: 0.5), size: 22),
        ],
      ),
    );
  }
}
