import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/habit.dart';
import '../models/goal.dart';
import '../services/storage_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final habits = await StorageService.getHabits();
    final goals = await StorageService.getGoals();
    setState(() {
      _habits = habits;
      _goals = goals;
    });
  }

  int get completedHabitsToday =>
      _habits.where((h) => h.isCompletedToday()).length;
  double get progressPercent =>
      _habits.isEmpty ? 0 : completedHabitsToday / _habits.length;
  int get bestStreak =>
      _habits.isEmpty ? 1 : _habits.map((h) => h.streak).fold(0, (a, b) => a > b ? a : b);

  void _toggleHabit(int index) {
    setState(() => _habits[index].toggleToday());
    StorageService.saveHabits(_habits);
  }

  void _addHabit() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Habit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Meditate 10 min',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() {
                  _habits.add(Habit(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: ctrl.text,
                    icon: 'check_circle',
                  ));
                });
                StorageService.saveHabits(_habits);
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
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child:
                          const Icon(Icons.bolt, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Focus Forward',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Self-Discipline Tracker',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Today's Progress
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Octagon
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing glow
                          ClipPath(
                            clipper: OctagonClipper(),
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primary.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ClipPath(
                            clipper: OctagonClipper(),
                            child: Container(
                              width: 176,
                              height: 176,
                              color: AppTheme.backgroundDark,
                            ),
                          ),
                          ClipPath(
                            clipper: OctagonClipper(),
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                border: Border.all(
                                  color: const Color(0xFF1A1A1A),
                                  width: 6,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(progressPercent * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                        shadows: [
                                          Shadow(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.5),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      'COMPLETE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF9CA3AF),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'DAILY SCORE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statCircle(Icons.check, const Color(0xFF9CA3AF),
                            '$completedHabitsToday Done'),
                        const SizedBox(width: 32),
                        _statCircle(
                          Icons.local_fire_department,
                          Colors.orange,
                          '$bestStreak Streak',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Active Habits
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Active Habits',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addHabit,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Habit',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                            shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _habits.isEmpty
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(Icons.inventory_2,
                                    color: Colors.grey[600], size: 24),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No habits yet. Create your first habit to get started!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          )
                        : Column(
                            children: List.generate(_habits.length, (i) {
                              final habit = _habits[i];
                              final completed = habit.isCompletedToday();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: completed
                                        ? AppTheme.primary.withValues(alpha: 0.3)
                                        : AppTheme.cardBorder,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 2),
                                  leading: GestureDetector(
                                    onTap: () => _toggleHabit(i),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: completed
                                            ? AppTheme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: completed
                                              ? AppTheme.primary
                                              : const Color(0xFF4B5563),
                                          width: 2,
                                        ),
                                      ),
                                      child: completed
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 18)
                                          : null,
                                    ),
                                  ),
                                  title: Text(
                                    habit.name,
                                    style: TextStyle(
                                      color: completed
                                          ? Colors.grey[600]
                                          : Colors.white,
                                      decoration: completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.local_fire_department,
                                          color: Colors.orange[700], size: 16),
                                      const SizedBox(width: 4),
                                      Text('${habit.streak}',
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Activity Calendar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
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
                            const Text('Activity Calendar',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 12, color: Color(0xFFEAB308)),
                                const SizedBox(width: 4),
                                Text(
                                  '$daysLeft days left in ${DateFormat('MMMM').format(now)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFEAB308),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(now),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Day headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                          .map((d) => SizedBox(
                                width: 32,
                                child: Text(
                                  d,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF9CA3AF),
                                      letterSpacing: 0.5),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    _buildCalendar(now),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Daily Goals
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daily Goals',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        Text(
                          '${_goals.where((g) => g.isCompleted).length}/${_goals.length} completed',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _goals.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppTheme.cardBorder, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.add_task,
                                    color: Colors.grey[700], size: 28),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first daily goal',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: _goals.map((g) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      g.isCompleted
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: g.isCompleted
                                          ? AppTheme.primary
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      g.title,
                                      style: TextStyle(
                                        color: g.isCompleted
                                            ? Colors.grey[600]
                                            : Colors.white,
                                        decoration: g.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 10, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Resets at 12:00 AM',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
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

  Widget _statCircle(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFFD1D5DB),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(DateTime now) {
    final firstDay = DateTime(now.year, now.month, 1);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 14,
      itemBuilder: (ctx, index) {
        final dayNum = index - startWeekday + 1;
        if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();
        final isToday = dayNum == now.day;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isToday)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.neonShadow,
                ),
              ),
            Text(
              '$dayNum',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? Colors.white
                    : (dayNum > now.day
                        ? Colors.grey[700]
                        : Colors.grey[500]),
              ),
            ),
          ],
        );
      },
    );
  }
}
