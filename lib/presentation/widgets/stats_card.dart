import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const StatsCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
