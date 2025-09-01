// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';
import 'package:flutter_saas_template/features/flashcards/flashcards_screen.dart';
import 'package:flutter_saas_template/features/progress/progress_screen.dart';
import 'package:flutter_saas_template/features/quiz/quiz_screen.dart';
import 'package:flutter_saas_template/features/review/review_screen.dart';

/// Navigation destinations for the app
enum AppDestination {
  learn(
    icon: Icons.style,
    selectedIcon: Icons.style,
    label: 'Learn',
  ),
  quiz(
    icon: Icons.quiz_outlined,
    selectedIcon: Icons.quiz,
    label: 'Quiz',
  ),
  review(
    icon: Icons.refresh_outlined,
    selectedIcon: Icons.refresh,
    label: 'Review',
  ),
  progress(
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
    label: 'Progress',
  ),
  settings(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  );

  const AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
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
      case AppDestination.review:
        return const ReviewScreen();
      case AppDestination.progress:
        return const ProgressScreen();
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
              destinations: AppDestination.values
                  .map(
                    (dest) => NavigationRailDestination(
                      icon: Icon(dest.icon),
                      selectedIcon: Icon(dest.selectedIcon),
                      label: Text(dest.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _buildBody(currentIndex),
            ),
          ],
        ),
      );
    } else {
      // Phone layout with BottomNavigationBar
      return Scaffold(
        body: _buildBody(currentIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            ref.read(navigationIndexProvider.notifier).state = index;
          },
          destinations: AppDestination.values
              .map(
                (dest) => NavigationDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(dest.selectedIcon),
                  label: dest.label,
                ),
              )
              .toList(),
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final dataService = await ref.read(localDataServiceProvider.future);
      final success = await dataService.resetAllData();
      
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

  void _showPrivacyInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Compliance'),
        content: const SingleChildScrollView(
          child: Text(
            '🔒 PRIVACY-FIRST DESIGN\n'
            '• No user accounts or registration\n'
            '• No data collection or tracking\n'
            '• All progress stored only on your device\n'
            '• No internet connection required\n\n'
            '👨‍⚖️ COMPLIANCE\n'
            '• COPPA compliant (safe for students under 13)\n'
            '• FERPA compliant (educational privacy)\n'
            '• GDPR compliant (EU privacy rights)\n\n'
            '🛡️ YOUR DATA RIGHTS\n'
            '• You control all your data\n'
            '• Delete everything with one tap\n'
            '• No hidden data collection\n'
            '• No third-party tracking\n\n'
            'Octo Vocab respects student privacy and gives you '
            'complete control over your learning data.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Selection
            const Card(
              child: ListTile(
                leading: Icon(Icons.language),
                title: Text('Language'),
                subtitle: Text('Select your learning language'),
                trailing: LanguageSwitcherAction(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Privacy Section
            const Text(
              'Privacy & Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.green),
                title: const Text('Privacy Protection'),
                subtitle: const Text('COPPA/FERPA compliant • No data collection'),
                onTap: () => _showPrivacyInfo(context),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Reset My Data'),
                subtitle: const Text('Delete all progress and preferences'),
                onTap: () => _showResetDataDialog(context, ref),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // About Section
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('About Octo Vocab'),
                subtitle: Text('Privacy-first vocabulary learning'),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
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
}