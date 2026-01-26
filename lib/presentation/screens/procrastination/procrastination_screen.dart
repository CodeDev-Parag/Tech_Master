import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ProcrastinationScreen extends StatelessWidget {
  const ProcrastinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Beat Procrastination',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroSection(theme),
          const SizedBox(height: 24),
          _buildTechniqueCard(
            theme,
            title: 'The 5-Second Rule',
            icon: Iconsax.timer_1,
            color: Colors.orange,
            description:
                "If you have an impulse to act on a goal, you must physically move within 5 seconds or your brain will kill the idea. Count backwards 5-4-3-2-1-GO.",
          ),
          _buildTechniqueCard(
            theme,
            title: 'Pomodoro Technique',
            icon: Iconsax.clock,
            color: Colors.redAccent,
            description:
                "Work for 25 minutes, then take a 5-minute break. After four sessions, take a longer break (15-30 mins). It keeps your mind fresh and focused.",
          ),
          _buildTechniqueCard(
            theme,
            title: 'Eat the Frog',
            icon: Iconsax.flash,
            color: Colors.green,
            description:
                "Do your most difficult and important task first thing in the morning. Once it's done, the rest of the day will feel much easier.",
          ),
          _buildTechniqueCard(
            theme,
            title: 'Eisenhower Matrix',
            icon: Iconsax.grid_1,
            color: Colors.blue,
            description:
                "Categorize tasks by Urgency and Importance. Focus on what's Important but Not Urgent to prevent future stress.",
          ),
          _buildTechniqueCard(
            theme,
            title: '2-Minute Rule',
            icon: Iconsax.flash_1,
            color: Colors.purple,
            description:
                "If a task takes less than 2 minutes, do it immediately. Don't add it to a list, just finish it.",
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.medal, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            'Master Your Time',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Procrastination is often a fear of starting. Use these proven scientific techniques to break the cycle.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildTechniqueCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }
}
