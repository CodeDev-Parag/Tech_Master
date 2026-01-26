import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';

import '../../providers/providers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/ai_insight_card.dart';
import '../task_list/task_list_screen.dart';
import '../add_task/add_task_screen.dart';
import '../focus/focus_screen.dart';
import '../settings/settings_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../profile/profile_screen.dart';
import '../notes/notes_screen.dart';
import '../procrastination/procrastination_screen.dart';

import '../../../data/models/timetable.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../college/timetable_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          TaskListScreen(),
          AIChatScreen(),
          FocusScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Iconsax.add, size: 28),
      )
          .animate()
          .scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(theme, isDark),
    );
  }

  Widget _buildBottomNav(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Iconsax.home_2, 'Home', 0, theme),
              _navItem(Iconsax.task_square, 'Tasks', 1, theme),
              _navItem(Iconsax.message_text, 'AI Chat', 2, theme),
              _navItem(Iconsax.timer_1, 'Focus', 3, theme),
              _navItem(Iconsax.setting_2, 'Settings', 4, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, ThemeData theme) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final taskNotifier = ref.read(tasksProvider.notifier);
    final aiService = ref.read(aiServiceProvider);
    final theme = Theme.of(context);

    final todaysTasks = taskNotifier.todaysTasks;
    final overdueTasks = taskNotifier.overdueTasks;
    final stats = taskNotifier.statistics;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMM d').format(DateTime.now()),
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen()),
                            );
                          },
                          icon: Icon(
                            Iconsax.user,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ].animate(interval: 100.ms).fadeIn().slideX(begin: -0.1),
              ),
            ),
          ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Today',
                      count: todaysTasks.length,
                      icon: Iconsax.calendar_1,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      title: 'Overdue',
                      count: overdueTasks.length,
                      icon: Iconsax.danger,
                      color: AppTheme.priorityUrgent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      title: 'Done',
                      count: stats['completed'] ?? 0,
                      icon: Iconsax.tick_circle,
                      color: AppTheme.statusCompleted,
                    ),
                  ),
                ]
                    .animate(interval: 100.ms)
                    .fadeIn()
                    .scale(begin: const Offset(0.9, 0.9)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'My Notes',
                      description: 'Write/Export',
                      icon: Iconsax.note_1,
                      color: Colors.blueAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotesScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Timetable',
                      description: 'Classes',
                      icon: Iconsax.teacher,
                      color: Colors.purpleAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TimetableScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'No Procr.',
                      description: 'Beat It',
                      icon: Iconsax.flash,
                      color: Colors.orangeAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ProcrastinationScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Up Next Class Widget
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _UpNextClassWidget(
                  repo: ref.watch(timetableRepositoryProvider)),
            ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // AI Insights Card
          if (aiService.isConfigured)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AIInsightCard(tasks: tasks),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Today's Tasks Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Tasks",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See All',
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ),

          // Today's Tasks List
          if (todaysTasks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.calendar_tick,
                      size: 64,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tasks for today',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a new task to get started',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = todaysTasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        task: task,
                        onToggle: () => ref
                            .read(tasksProvider.notifier)
                            .toggleTaskStatus(task.id),
                        onTap: () {
                          // Navigate to task detail
                        },
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (400 + index * 100).ms)
                        .slideX(begin: 0.1);
                  },
                  childCount: todaysTasks.length > 5 ? 5 : todaysTasks.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    if (hour >= 21 || hour < 5) return 'Good Night';
    return 'Hello';
  }
}

class _UpNextClassWidget extends StatelessWidget {
  final TimetableRepository repo;

  const _UpNextClassWidget({required this.repo});

  @override
  Widget build(BuildContext context) {
    final nextClass = repo.getNextClass();

    if (nextClass == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            nextClass.color.withValues(alpha: 0.8),
            nextClass.color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: nextClass.color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.book, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Up Next: ${nextClass.startTime.format(context)}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextClass.subjectName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (nextClass.roomNumber != null)
                  Text(
                    'Room: ${nextClass.roomNumber}',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Class',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
