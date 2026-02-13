import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/permission_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize notifications (timezone + channels + plugin)
  await NotificationService.initialize();

  // DIAGNOSTIC: Fire an immediate notification right after init to verify pipeline
  // This runs BEFORE any permission checks to confirm notifications work at all
  try {
    await NotificationService.showInstantNotification(
      id: 88888,
      title: '✅ Focus Forward is ready!',
      body: 'Notifications are working on this device.',
    );
    debugPrint('[main] ✓ Diagnostic notification sent successfully');
  } catch (e) {
    debugPrint('[main] ✗ DIAGNOSTIC FAILED: $e');
  }

  // Only schedule alarms if permissions were already granted (not first launch).
  // On first launch, PermissionScreen handles granting + initial schedule.
  final permissionsGranted = await StorageService.arePermissionsGranted();
  if (permissionsGranted) {
    try {
      final alarms = await StorageService.getAlarms();
      final bedAlarms = await StorageService.getBedAlarms();
      final allAlarms = [...alarms, ...bedAlarms];
      debugPrint('[main] Scheduling ${allAlarms.length} saved alarms on startup');
      await NotificationService.scheduleAllAlarms(allAlarms);
    } catch (e) {
      debugPrint('[main] Error scheduling alarms on startup: $e');
    }
  } else {
    debugPrint('[main] Permissions not yet granted — skipping alarm scheduling');
  }

  runApp(const FocusForwardApp());
}

class FocusForwardApp extends StatelessWidget {
  const FocusForwardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Forward',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _loading = true;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await StorageService.arePermissionsGranted();
    if (!mounted) return;
    setState(() {
      _permissionsGranted = granted;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }
    return _permissionsGranted ? const MainScreen() : const PermissionScreen();
  }
}
