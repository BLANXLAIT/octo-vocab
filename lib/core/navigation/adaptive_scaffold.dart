// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';
import 'package:flutter_saas_template/core/theme/dynamic_theme.dart';
import 'package:flutter_saas_template/features/flashcards/flashcards_screen.dart';
import 'package:flutter_saas_template/features/quiz/quiz_screen.dart';

/// Navigation destinations for the app
enum AppDestination {
  learn(
    icon: Icons.style,
    selectedIcon: Icons.style,
    label: 'Learn',
    semanticLabel: 'Learn with flashcards',
    accessibilityKey: 'learn_tab',
  ),
  quiz(
    icon: Icons.quiz_outlined,
    selectedIcon: Icons.quiz,
    label: 'Quiz',
    semanticLabel: 'Take vocabulary quiz',
    accessibilityKey: 'quiz_tab',
  ),
  settings(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
    semanticLabel: 'App settings and preferences',
    accessibilityKey: 'settings_tab',
  );

  const AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.semanticLabel,
    required this.accessibilityKey,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String semanticLabel;
  final String accessibilityKey;
}

/// Current navigation index provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Breakpoint for switching between phone and tablet layout
const double kTabletBreakpoint = 600;

class AdaptiveScaffold extends ConsumerWidget {
  const AdaptiveScaffold({super.key});

  Widget _buildBody(int index) {
    switch (AppDestination.values[index]) {
      case AppDestination.learn:
        return const FlashcardsScreen();
      case AppDestination.quiz:
        return const QuizScreen();
      case AppDestination.settings:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isWideScreen = MediaQuery.of(context).size.width >= kTabletBreakpoint;

    if (isWideScreen) {
      // Tablet layout with NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                ref.read(navigationIndexProvider.notifier).state = index;
              },
              labelType: NavigationRailLabelType.all,
              destinations: AppDestination.values.asMap().entries.map((entry) {
                final dest = entry.value;
                return NavigationRailDestination(
                  icon: Semantics(
                    identifier: dest.accessibilityKey,
                    label: dest.semanticLabel,
                    tooltip: dest.semanticLabel,
                    child: Icon(dest.icon),
                  ),
                  selectedIcon: Semantics(
                    identifier: dest.accessibilityKey,
                    label: dest.semanticLabel,
                    tooltip: dest.semanticLabel,
                    child: Icon(dest.selectedIcon),
                  ),
                  label: Semantics(
                    identifier: '${dest.accessibilityKey}_label',
                    label: '${dest.label} navigation tab',
                    child: Text(dest.label),
                  ),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _buildBody(currentIndex)),
          ],
        ),
      );
    } else {
      // Phone layout with BottomNavigationBar
      return Scaffold(
        body: _buildBody(currentIndex),
        bottomNavigationBar: Semantics(
          identifier: 'main_navigation_bar',
          label: 'Main navigation with 5 tabs',
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              ref.read(navigationIndexProvider.notifier).state = index;
            },
            destinations: AppDestination.values.asMap().entries.map((entry) {
              final dest = entry.value;
              return NavigationDestination(
                icon: Semantics(
                  identifier: dest.accessibilityKey,
                  label: dest.semanticLabel,
                  tooltip: dest.semanticLabel,
                  child: Icon(dest.icon),
                ),
                selectedIcon: Semantics(
                  identifier: dest.accessibilityKey,
                  label: dest.semanticLabel,
                  tooltip: dest.semanticLabel,
                  child: Icon(dest.selectedIcon),
                ),
                label: dest.label,
                tooltip: dest.semanticLabel,
              );
            }).toList(),
          ),
        ),
      );
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});


  Future<void> _showResetDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete all your learning progress, '
          'quiz scores, and preferences stored on this device.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final dataService = await LocalDataService.create();
      final success = await dataService.clearAllData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'All data has been deleted from this device'
                  : 'Failed to delete data. Please try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Theme Section
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            const ThemeSelectorCard(),

            const SizedBox(height: 16),

            // Privacy Section
            const Text(
              'Privacy & Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              key: const Key('privacy_info_card'),
              child: ExpansionTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.green),
                title: const Text('Privacy Protection'),
                subtitle: const Text(
                  'COPPA/FERPA compliant • No data collection',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Octo Vocab is designed with privacy as the foundation, ensuring complete compliance with educational privacy standards.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.shield,
                          'Privacy',
                          'No data collection, fully offline',
                        ),
                        _buildInfoRow(
                          Icons.school,
                          'COPPA',
                          'Safe for students under 13',
                        ),
                        _buildInfoRow(
                          Icons.gavel,
                          'FERPA',
                          'Educational privacy compliant',
                        ),
                        _buildInfoRow(
                          Icons.public_off,
                          'GDPR',
                          'EU privacy rights respected',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Your Data Rights:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• You control all your data\n'
                                '• Delete everything with one tap\n'
                                '• No hidden data collection\n'
                                '• No third-party tracking',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),


            Card(
              key: const Key('reset_data_card'),
              child: Semantics(
                label:
                    'Reset all learning data and preferences - this action cannot be undone',
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Reset My Data'),
                  subtitle: const Text('Delete all progress and preferences'),
                  onTap: () => _showResetDataDialog(context, ref),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Octo Vocab'),
                subtitle: const Text('Privacy-first vocabulary learning'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Octo Vocab is a privacy-first offline vocabulary learning app designed for students in grades 7-12 learning foreign languages.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.shield,
                          'Privacy',
                          'No data collection, fully offline',
                        ),
                        _buildInfoRow(
                          Icons.school,
                          'Education',
                          'Designed for grades 7-12',
                        ),
                        _buildInfoRow(
                          Icons.language,
                          'Languages',
                          'Latin & Spanish (more coming)',
                        ),
                        _buildInfoRow(Icons.code, 'Version', '1.0.0'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.code,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Source Code:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const SelectableText(
                                'github.com/BLANXLAIT/octo-vocab',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.bug_report,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Report Issues:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const SelectableText(
                                'github.com/BLANXLAIT/octo-vocab/issues',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Privacy Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your privacy is protected. All data stays on your '
                      'device and you can delete it anytime.',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}

/// Animated theme selector card with color preview
class ThemeSelectorCard extends ConsumerWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentVariant = ref.watch(themeVariantProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 12),
                const Text(
                  'Color Theme',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                // Current theme color indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: currentVariant.seedColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentVariant.seedColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose a color theme to personalize your learning experience',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Theme variant chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ThemeVariant.values.map((variant) {
                final isSelected = currentVariant == variant;
                return AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(variant.displayName),
                    avatar: isSelected
                        ? null
                        : Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: variant.seedColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                    selectedColor: variant.seedColor.withValues(alpha: 0.2),
                    checkmarkColor: variant.seedColor,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(themeVariantProvider.notifier).state = variant;
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
