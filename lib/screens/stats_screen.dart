import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Insights',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Last 7 Days',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today,
                          color: Color(0xFFD1D5DB), size: 20),
                    ),
                  ],
                ),
              ),

              // Discipline Score
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    // Octagon score
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow backgrounds
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF256AF4)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonPurple
                                      .withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  offset: const Offset(4, 4),
                                ),
                              ],
                            ),
                          ),
                          // Gradient border octagon
                          ClipPath(
                            clipper: OctagonClipper(),
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFF256AF4),
                                    AppTheme.neonPurple,
                                    AppTheme.neonCyan,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Inner octagon
                          ClipPath(
                            clipper: OctagonClipper(),
                            child: Container(
                              width: 176,
                              height: 176,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF256AF4)
                                        .withValues(alpha: 0.1),
                                    AppTheme.surfaceDark,
                                  ],
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '84',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -2,
                                    ),
                                  ),
                                  Text(
                                    'SCORE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF256AF4),
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        children: const [
                          TextSpan(text: 'Top '),
                          TextSpan(
                            text: '5%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonCyan,
                            ),
                          ),
                          TextSpan(text: ' of users this week'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF256AF4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              const Color(0xFF256AF4).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up,
                              size: 14, color: Color(0xFF256AF4)),
                          SizedBox(width: 4),
                          Text(
                            '+12% vs last week',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF256AF4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stat Counters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _statCounter(
                        Icons.local_fire_department,
                        Colors.orange,
                        '12',
                        'Streak',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCounter(
                        Icons.timer,
                        AppTheme.neonPurple,
                        '42h',
                        'Focused',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCounter(
                        Icons.alarm_on,
                        AppTheme.neonCyan,
                        '18',
                        'Beaten',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Weekly Focus Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WEEKLY FOCUS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Goal Completion Rate',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                '85%',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF256AF4),
                                ),
                              ),
                              Text('Avg',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildWeeklyChart(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Consistency Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CONSISTENCY GRID',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text('View All',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF256AF4)
                                      .withValues(alpha: 0.8))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildConsistencyGrid(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Less',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[600])),
                          const SizedBox(width: 6),
                          _gridDot(Colors.grey[800]!.withValues(alpha: 0.5)),
                          _gridDot(const Color(0xFF256AF4).withValues(alpha: 0.4)),
                          _gridDot(const Color(0xFF256AF4)),
                          _gridDot(AppTheme.neonCyan),
                          const SizedBox(width: 6),
                          Text('More',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
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

  Widget _statCounter(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final data = [0.4, 0.65, 0.85, 0.3, 0.95, 0.7, 0.5];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final isHighest = data[i] >= 0.9;
          final color = isHighest
              ? AppTheme.neonPurple
              : const Color(0xFF256AF4).withValues(alpha: (data[i] * 0.8) + 0.2);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: data[i],
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3),
                            ),
                            boxShadow: data[i] > 0.8
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        data[i] > 0.8 ? FontWeight.bold : FontWeight.w500,
                    color: data[i] > 0.8 ? Colors.white : Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConsistencyGrid() {
    // Static demo data matching HTML
    final colors = [
      Colors.grey[800]!.withValues(alpha: 0.5),
      const Color(0xFF256AF4).withValues(alpha: 0.2),
      const Color(0xFF256AF4).withValues(alpha: 0.4),
      const Color(0xFF256AF4),
      const Color(0xFF256AF4).withValues(alpha: 0.8),
      Colors.grey[800]!.withValues(alpha: 0.5),
      const Color(0xFF256AF4).withValues(alpha: 0.2),
      // Row 2
      const Color(0xFF256AF4).withValues(alpha: 0.6),
      const Color(0xFF256AF4),
      AppTheme.neonCyan,
      const Color(0xFF256AF4).withValues(alpha: 0.8),
      const Color(0xFF256AF4).withValues(alpha: 0.3),
      Colors.grey[800]!.withValues(alpha: 0.5),
      const Color(0xFF256AF4).withValues(alpha: 0.1),
      // Row 3
      const Color(0xFF256AF4).withValues(alpha: 0.9),
      const Color(0xFF256AF4).withValues(alpha: 0.5),
      Colors.grey[800]!.withValues(alpha: 0.5),
      const Color(0xFF256AF4).withValues(alpha: 0.2),
      AppTheme.neonPurple,
      const Color(0xFF256AF4),
      const Color(0xFF256AF4).withValues(alpha: 0.6),
      // Row 4
      const Color(0xFF256AF4).withValues(alpha: 0.4),
      const Color(0xFF256AF4).withValues(alpha: 0.3),
      Colors.grey[800]!.withValues(alpha: 0.5),
      const Color(0xFF256AF4).withValues(alpha: 0.1),
      const Color(0xFF256AF4).withValues(alpha: 0.9),
      const Color(0xFF256AF4),
      Colors.grey[800]!.withValues(alpha: 0.5),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: 28,
      itemBuilder: (ctx, i) {
        final color = colors[i];
        final isGlowing = color == const Color(0xFF256AF4) ||
            color == AppTheme.neonCyan ||
            color == AppTheme.neonPurple;
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: isGlowing
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                : null,
          ),
        );
      },
    );
  }

  Widget _gridDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
