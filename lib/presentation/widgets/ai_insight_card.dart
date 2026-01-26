import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../data/models/task.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/pattern_analysis_service.dart';
import '../providers/providers.dart';

class AIInsightCard extends ConsumerStatefulWidget {
  final List<Task> tasks;

  const AIInsightCard({super.key, required this.tasks});

  @override
  ConsumerState<AIInsightCard> createState() => _AIInsightCardState();
}

class _AIInsightCardState extends ConsumerState<AIInsightCard> {
  ProductivityInsight? _aiInsight;
  List<TaskPatternInsight> _localInsights = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final aiService = ref.read(aiServiceProvider);
    final patternService = ref.read(patternAnalysisServiceProvider);

    try {
      // 1. Load Local Pattern Analysis (Offline)
      _localInsights = patternService.analyzePatterns(widget.tasks);

      // 2. Load AI Insights if configured
      if (aiService.isConfigured) {
        _aiInsight = await aiService.getProductivityInsights(widget.tasks);
      }

      setState(() {});
    } catch (e) {
      // Trace
    } finally {
      // Done
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localInsights.isEmpty && _aiInsight == null) return const SizedBox();

    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.15),
              theme.colorScheme.secondary.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.cpu_charge,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Analysis',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _aiInsight != null
                            ? 'Global & Local Insights'
                            : 'Locally Analyzed Patterns',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Main Insight Description
            Text(
              _aiInsight?.summary ??
                  (_localInsights.isNotEmpty
                      ? _localInsights.first.description
                      : ''),
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
              ),
            ),

            // Expanded content
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              if (_localInsights.isNotEmpty) ...[
                Text(
                  'Your Activity Patterns',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._localInsights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight.title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              insight.description,
                              style:
                                  GoogleFonts.inter(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
              if (_aiInsight != null) ...[
                const SizedBox(height: 8),
                Text(
                  'AI Recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.lamp_on,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _aiInsight!.recommendation,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
