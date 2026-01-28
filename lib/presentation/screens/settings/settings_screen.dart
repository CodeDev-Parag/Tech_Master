import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().slideX(begin: -0.1),

            const SizedBox(height: 24),

            _buildWhatsNewCard(theme),
            const SizedBox(height: 24),

            // Pro Features Section (New)
            _sectionHeader('Pro Features', theme),
            const SizedBox(height: 12),
            _settingsCard(
              theme,
              children: [
                _settingsTile(
                  theme,
                  icon: Iconsax.crown,
                  iconColor: Colors.amber,
                  title: 'Unlock Pro Mode',
                  subtitle: 'Advanced AI Planning & Schedule Awareness',
                  trailing: Switch(
                    value: ref.watch(proModeProvider),
                    onChanged: (value) {
                      ref.read(proModeProvider.notifier).toggle(value);
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Pro Mode Unlocked! Try asking "Plan my day".')),
                        );
                      }
                    },
                  ),
                ),
                Divider(color: theme.dividerColor, height: 1),
                _settingsTile(
                  theme,
                  icon: Iconsax.teacher,
                  iconColor: Colors.teal,
                  title: 'College Mode',
                  subtitle: 'Unlock Attendance Tracker',
                  trailing: Switch(
                    value: ref.watch(collegeModeProvider),
                    onChanged: (value) {
                      ref.read(collegeModeProvider.notifier).toggle(value);
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'College Mode Enabled! Attendance Tracker unlocked.')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // Appearance Section
            _sectionHeader('Appearance', theme),
            const SizedBox(height: 12),
            _settingsCard(
              theme,
              children: [
                _settingsTile(
                  theme,
                  icon: isDarkMode ? Iconsax.moon : Iconsax.sun_1,
                  iconColor: isDarkMode ? Colors.amber : AppTheme.primaryLight,
                  title: 'Dark Mode',
                  subtitle: isDarkMode ? 'On' : 'Off',
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).state = value;
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // Intelligence & Privacy
            _sectionHeader('Adaptive Intelligence', theme),
            const SizedBox(height: 12),
            _settingsCard(
              theme,
              children: [
                _settingsTile(
                  theme,
                  icon: Iconsax.cpu,
                  iconColor: Colors.purpleAccent,
                  title: 'On-Device Learning',
                  subtitle: 'Predict categories/priority from your patterns',
                  trailing: Switch(
                    value: ref.watch(autoCollectProvider),
                    onChanged: (value) async {
                      ref.read(autoCollectProvider.notifier).toggle(value);
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Adaptive local learning enabled! The system will now learn from your habits.')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Legal Section
            _sectionHeader('Legal', theme),
            const SizedBox(height: 12),
            _settingsCard(
              theme,
              children: [
                _settingsTile(
                  theme,
                  icon: Iconsax.shield_tick,
                  iconColor: AppTheme.statusCompleted,
                  title: 'Privacy Policy',
                  onTap: () => _showLegalDialog(
                    context,
                    'Privacy Policy',
                    _privacyPolicyText,
                  ),
                ),
                Divider(color: theme.dividerColor, height: 1),
                _settingsTile(
                  theme,
                  icon: Iconsax.document_text,
                  iconColor: theme.colorScheme.secondary,
                  title: 'Terms of Service',
                  onTap: () =>
                      _showLegalDialog(context, 'Terms of Service', _termsText),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // About Section
            _sectionHeader('About', theme),
            const SizedBox(height: 12),
            _settingsCard(
              theme,
              children: [
                _settingsTile(
                  theme,
                  icon: Iconsax.info_circle,
                  iconColor: AppTheme.primaryLight,
                  title: 'App Version',
                  subtitle: AppConstants.appVersion,
                ),
                Divider(color: theme.dividerColor, height: 1),
                _settingsTile(
                  theme,
                  icon: Iconsax.code,
                  iconColor: AppTheme.statusInProgress,
                  title: 'Built by',
                  subtitle: 'itz_techyparag',
                ),
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsNewCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.8),
            theme.colorScheme.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
              const Icon(Iconsax.magic_star, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                "What's New in 2.1.1",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _whatsNewItem(Iconsax.teacher, "College Mode",
              "Unlock Attendance Tracker with this mode."),
          _whatsNewItem(Iconsax.quote_up, "Daily Motivation",
              "Get inspired with a new quote every day."),
          _whatsNewItem(Iconsax.cpu, "Smarter Insights",
              "Context-aware productivity analysis."),
        ],
      ),
    ).animate().scale(delay: 50.ms).fadeIn();
  }

  Widget _whatsNewItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Text(desc,
                  style:
                      GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _settingsCard(ThemeData theme, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
              ),
            )
          : null,
      trailing: trailing,
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: GoogleFonts.inter(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  final String _privacyPolicyText = '''
**Privacy Policy**

**Last Updated: January 26, 2026**

Your privacy is important to us. It is Tech Master's policy to respect your privacy regarding any information we may collect from you across our application.

**1. Information We Collect**
We only ask for personal information when we truly need it to provide a service to you. We collect it by fair and lawful means, with your knowledge and consent. We also let you know why we’re collecting it and how it will be used.

**2. Local AI & Data Privacy**
Everything stays on your device. We use a custom, on-device Natural Language Processing (NLP) system and Naive Bayes machine learning to help you organize tasks.
- **No External Servers**: Your chat history and task descriptions are NOT sent to cloud AI providers.
- **Local Learning**: The "Adaptive Intelligence" system trains a local model on your device to improve category and priority predictions.
- **Data remains under your control.**

**3. Local Storage**
All your tasks, categories, and settings are stored locally on your device using the Hive database. This means you have full control over your data. If you delete the app, this data is removed from your device.

**4. Third-Party Services**
We may employ third-party companies and individuals due to the following reasons:
- To facilitate our Service;
- To provide the Service on our behalf;
- To perform Service-related services; or
- To assist us in analyzing how our Service is used.

**5. Security**
Values your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and we cannot guarantee its absolute security.

**6. Changes to This Policy**
We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page.
''';

  final String _termsText = '''
**Terms of Service**

**Last Updated: January 26, 2026**

**1. Acceptance of Terms**
By downloading or using the app, these terms will automatically apply to you – you should make sure therefore that you read them carefully before using the app. You’re not allowed to copy or modify the app, any part of the app, or our trademarks in any way.

**2. Use License**
Permission is granted to use Tech Master for personal, non-commercial purposes. This is the grant of a license, not a transfer of title, and under this license you may not:
- modify or copy the materials;
- use the materials for any commercial purpose, or for any public display (commercial or non-commercial);
- attempt to decompile or reverse engineer any software contained in Tech Master;
- remove any copyright or other proprietary notations from the materials; or
- transfer the materials to another person or "mirror" the materials on any other server.

**3. Disclaimer**
The materials on Tech Master are provided 'as is'. Tech Master makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.

**4. Limitations**
In no event shall Tech Master or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Tech Master, even if Tech Master or a Tech Master authorized representative has been notified orally or in writing of the possibility of such damage.

**5. Accuracy of Materials**
The materials appearing on Tech Master could include technical, typographical, or photographic errors. Tech Master does not warrant that any of the materials on its application are accurate, complete or current. We may make changes to the materials contained on its application at any time without notice.
''';
}
