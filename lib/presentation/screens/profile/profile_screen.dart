import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

// Provider for username
final usernameProvider = StateNotifierProvider<UsernameNotifier, String>((ref) {
  return UsernameNotifier();
});

class UsernameNotifier extends StateNotifier<String> {
  UsernameNotifier() : super('Tech Master') {
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final box = await Hive.openBox('settings');
    state = box.get('username', defaultValue: 'Tech Master');
  }

  Future<void> setUsername(String name) async {
    final box = await Hive.openBox('settings');
    await box.put('username', name);
    state = name;
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final username = ref.watch(usernameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar Section
            _buildAvatarSection(context, theme, username, ref),

            const SizedBox(height: 32),

            // Stats Overview
            Text(
              'Statistics',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // GridView inside Consumer to watch task updates only for this part
            Consumer(
              builder: (context, ref, child) {
                final taskNotifier = ref.watch(tasksProvider.notifier);
                // Access statistics directly (getter)
                final stats = taskNotifier.statistics;

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatItem(
                      theme,
                      'Tech Master',
                      stats['total'].toString(),
                      Iconsax.task,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      theme,
                      'Completed',
                      stats['completed'].toString(),
                      Iconsax.tick_circle,
                      Colors.green,
                    ),
                    _buildStatItem(
                      theme,
                      'Pending',
                      stats['pending'].toString(),
                      Iconsax.clock,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      theme,
                      'Completion Rate',
                      '${(stats['completionRate'] as double).toStringAsFixed(1)}%',
                      Iconsax.chart_2,
                      Colors.purple,
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final userStats =
                            ref.watch(gamificationServiceProvider);
                        return _buildStatItem(
                          theme,
                          'Daily Streak',
                          '${userStats.streakDays} Days',
                          Iconsax.flash,
                          Colors.orange,
                        );
                      },
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
              },
            ),

            const SizedBox(height: 32),

            // Achievements (Placeholder since gamification is disabled)
            Text(
              'Achievements',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.cup,
                    size: 48,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Achievements Coming Soon',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(
      BuildContext context, ThemeData theme, String username, WidgetRef ref) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Iconsax.user, size: 50, color: Colors.white),
          ).animate().scale(curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                username,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Iconsax.edit_2, size: 20),
                onPressed: () =>
                    _showEditUsernameDialog(context, username, ref),
                tooltip: 'Edit username',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditUsernameDialog(
      BuildContext context, String currentUsername, WidgetRef ref) {
    final controller = TextEditingController(text: currentUsername);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Username',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(usernameProvider.notifier)
                    .setUsername(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
