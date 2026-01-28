import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../data/services/motivation_service.dart';

class MotivationCard extends ConsumerStatefulWidget {
  const MotivationCard({super.key});

  @override
  ConsumerState<MotivationCard> createState() => _MotivationCardState();
}

class _MotivationCardState extends ConsumerState<MotivationCard> {
  String _quote = "Loading motivation...";

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final service = ref.read(motivationServiceProvider);
    final quote = await service.getDailyQuote();
    if (mounted) {
      setState(() {
        _quote = quote;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.quote_up,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Motivation',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _quote,
            style: GoogleFonts.zillaSlab(
              // Using a serif font for quotes looks nice
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              height: 1.4,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
