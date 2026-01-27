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

            // Research & Privacy
            _sectionHeader('Research Contribution', theme),
            const SizedBox(height: 12),
            _settingsCard(
              theme,
              children: [
                _settingsTile(
                  theme,
                  icon: Iconsax.cloud_connection,
                  iconColor: Colors.blueAccent,
                  title: 'Continuous Learning',
                  subtitle: 'Automatically share anonymous training data',
                  trailing: Switch(
                    value: ref.watch(autoCollectProvider),
                    onChanged: (value) async {
                      ref.read(autoCollectProvider.notifier).toggle(value);
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Continuous learning enabled! Your data helps improve the model.')),
                        );
                        // Trigger immediate sync
                        final mlService = ref.read(localMLServiceProvider);
                        await mlService.syncTrainingData(ref);
                      }
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // AI Configuration
            _sectionHeader('Intelligence', theme),
            const SizedBox(height: 12),
            _settingsCard(
              theme,
              children: [
                _settingsTile(
                  theme,
                  icon: Iconsax.cpu,
                  iconColor: Colors.purpleAccent,
                  title: 'AI Mode',
                  subtitle: ref.watch(aiModeProvider)
                      ? 'Local LLM (Gemma 2B) - Offline'
                      : 'Classic (Rule-Based)',
                  trailing: Switch(
                    value: ref.watch(aiModeProvider),
                    onChanged: (value) {
                      ref.read(aiModeProvider.notifier).toggle(value);
                    },
                  ),
                ),
                Divider(color: theme.dividerColor, height: 1),
                _settingsTile(
                  theme,
                  icon: Iconsax.key,
                  iconColor: Colors.teal,
                  title: 'Gemini API Key',
                  subtitle: 'Required for Online Mode',
                  onTap: () => _showApiKeyDialog(context),
                  trailing: const Icon(Iconsax.arrow_right_3, size: 16),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

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

  void _showApiKeyDialog(BuildContext context) async {
    final aiService = ref.read(aiServiceProvider);
    final currentKey = await aiService.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Gemini API Key',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your Google Gemini API Key to enable the high-intelligence Online Mode.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                hintText: 'AIzaSy...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await aiService.setApiKey(controller.text.trim());
              if (context.mounted) Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key saved securely!')),
                );
              }
            },
            child: const Text('Save'),
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

**2. AI Data Usage**
When you use AI features (Task Parsing, Chatbot, Smart Suggestions), your input data (text prompts, task descriptions) is sent to our AI providers (OpenRouter/OpenAI) solely for the purpose of processing your request. 
- We do **not** use your data to train public AI models.
- Data is transmitted securely via encryption.
- We do not store your chat history on external servers; it is processed transiently.

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
