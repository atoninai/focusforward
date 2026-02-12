import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/goal.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await StorageService.getGoals();
    setState(() => _goals = goals);
  }

  int get completedCount => _goals.where((g) => g.isCompleted).length;

  void _toggleGoal(int index) {
    setState(() => _goals[index].isCompleted = !_goals[index].isCompleted);
    StorageService.saveGoals(_goals);
  }

  void _deleteGoal(int index) {
    setState(() => _goals.removeAt(index));
    StorageService.saveGoals(_goals);
  }

  void _addGoal() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Goal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'What\'s your goal?',
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
                final goalTitle = ctrl.text;
                setState(() {
                  _goals.add(Goal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: goalTitle,
                    createdAt: DateTime.now(),
                  ));
                });
                StorageService.saveGoals(_goals);
                // Fire goal notification
                NotificationService.showGoalNotification(
                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  title: '🎯 New Goal Set!',
                  body: goalTitle,
                );
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Goals',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount/${_goals.length} completed',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.add, color: Colors.white, size: 22),
                      onPressed: _addGoal,
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            if (_goals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${(_goals.isEmpty ? 0 : (completedCount / _goals.length * 100)).toInt()}%',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _goals.isEmpty
                              ? 0
                              : completedCount / _goals.length,
                          backgroundColor: const Color(0xFF374151),
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Goals list
            Expanded(
              child: _goals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _goals.length,
                      itemBuilder: (ctx, i) => _buildGoalTile(i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GestureDetector(
        onTap: _addGoal,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.cardBorder,
              width: 2,
              // Can't do dashed in Flutter easily, using solid border
            ),
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.surfaceDark.withValues(alpha: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_task,
                  color: Colors.grey[700], size: 40),
              const SizedBox(height: 12),
              Text(
                'Add your first daily goal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalTile(int index) {
    final goal = _goals[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goal.isCompleted
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.cardBorder,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () => _toggleGoal(index),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: goal.isCompleted
                  ? AppTheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: goal.isCompleted
                    ? AppTheme.primary
                    : const Color(0xFF4B5563),
                width: 2,
              ),
            ),
            child: goal.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        ),
        title: Text(
          goal.title,
          style: TextStyle(
            color: goal.isCompleted ? const Color(0xFF6B7280) : Colors.white,
            fontWeight: FontWeight.w500,
            decoration:
                goal.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF6B7280), size: 18),
          onPressed: () => _deleteGoal(index),
        ),
      ),
    );
  }
}
