import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/routine.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Routine> _routines = [];
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fillAnimation =
        CurvedAnimation(parent: _fillController, curve: Curves.easeOut);
    _loadData();
  }

  Future<void> _loadData() async {
    final routines = await StorageService.getRoutines();
    setState(() => _routines = routines);
    _fillController.forward();
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  int get completedCount => _routines.where((r) => r.isCompleted).length;
  double get progress =>
      _routines.isEmpty ? 0 : completedCount / _routines.length;

  void _toggleRoutine(int index) {
    setState(() {
      _routines[index].isCompleted = !_routines[index].isCompleted;
    });
    StorageService.saveRoutines(_routines);
  }

  void _addRoutine() {
    final nameCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Routine',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Routine name',
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
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Time (e.g. 8:00 AM)',
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
              ),
              readOnly: true,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                  final m = picked.minute.toString().padLeft(2, '0');
                  final p = picked.period == DayPeriod.am ? 'AM' : 'PM';
                  timeCtrl.text = '$h:$m $p';
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _routines.add(Routine(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text,
                    icon: 'check_circle',
                    time: timeCtrl.text.isEmpty ? 'All Day' : timeCtrl.text,
                  ));
                });
                StorageService.saveRoutines(_routines);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Focus Forward',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Color(0xFFD1D5DB), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, Color(0xFFA78BFA)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Daily Progress Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'DAILY PROGRESS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Octagon progress
                      AnimatedBuilder(
                        animation: _fillAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: 180,
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background octagon
                                ClipPath(
                                  clipper: OctagonClipper(),
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    color: Colors.grey[800]!.withValues(alpha: 0.5),
                                  ),
                                ),
                                // Inner octagon
                                ClipPath(
                                  clipper: OctagonClipper(),
                                  child: Container(
                                    width: 176,
                                    height: 176,
                                    color: AppTheme.surfaceDark,
                                    child: Stack(
                                      children: [
                                        // Fill
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 176 *
                                                progress *
                                                _fillAnimation.value,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  AppTheme.primary
                                                      .withValues(alpha: 0.4),
                                                  AppTheme.primary
                                                      .withValues(alpha: 0.1),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Border octagon
                                ClipPath(
                                  clipper: OctagonClipper(),
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            AppTheme.primary.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                // Text
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'COMPLETED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _statBadge(Icons.check_circle, Colors.green,
                              '$completedCount/${_routines.length} Done'),
                          const SizedBox(width: 32),
                          _statBadge(Icons.local_fire_department, Colors.orange,
                              '${completedCount > 0 ? completedCount : 1} Streak'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Current Routine
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Routine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: _addRoutine,
                      child: const Text(
                        '+ Add',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 145,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _routines.length,
                  itemBuilder: (ctx, i) {
                    final r = _routines[i];
                    final isFirst = i == 0;
                    return GestureDetector(
                      onTap: () => _toggleRoutine(i),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isFirst
                              ? const LinearGradient(
                                  colors: [AppTheme.primary, Color(0xFF6D28D9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isFirst ? null : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: isFirst
                              ? null
                              : Border.all(color: AppTheme.cardBorder),
                          boxShadow:
                              isFirst ? AppTheme.neonShadow : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isFirst)
                              Text(
                                r.isCompleted ? 'Done' : 'Now',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            if (!isFirst)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _getIconColor(r.icon)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getIconData(r.icon),
                                  size: 18,
                                  color: _getIconColor(r.icon),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              r.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isFirst
                                    ? Colors.white
                                    : (r.isCompleted
                                        ? Colors.grey
                                        : const Color(0xFFE5E7EB)),
                                decoration: r.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.schedule,
                                    size: 12,
                                    color: isFirst
                                        ? Colors.white70
                                        : const Color(0xFF9CA3AF)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    r.time,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isFirst
                                          ? Colors.white70
                                          : const Color(0xFF9CA3AF),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Activity Calendar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Activity',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month,
                                      size: 14, color: Color(0xFFEAB308)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${DateTime(now.year, now.month + 1, 0).day - now.day} days left in ${DateFormat('MMM').format(now)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFEAB308),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left,
                                    color: Color(0xFF9CA3AF), size: 20),
                                onPressed: () {},
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right,
                                    color: Color(0xFF9CA3AF), size: 20),
                                onPressed: () {},
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Day headers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .map((d) => SizedBox(
                                  width: 32,
                                  child: Text(
                                    d,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      // Calendar grid
                      _buildCalendarGrid(now),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBadge(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(DateTime now) {
    final firstDay = DateTime(now.year, now.month, 1);
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: 14, // Show 2 weeks
      itemBuilder: (ctx, index) {
        final dayNum = index - startWeekday + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          return const SizedBox();
        }
        final isToday = dayNum == now.day;
        return Container(
          decoration: isToday
              ? BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Center(
            child: isToday
                ? Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppTheme.neonShadow,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 12,
                      color: dayNum < now.day
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'book':
        return Icons.book;
      case 'fitness_center':
        return Icons.fitness_center;
      default:
        return Icons.check_circle;
    }
  }

  Color _getIconColor(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Colors.blue;
      case 'book':
        return Colors.blue;
      case 'fitness_center':
        return Colors.pink;
      default:
        return AppTheme.primary;
    }
  }
}
