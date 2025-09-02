// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/navigation/adaptive_scaffold.dart';

/// A morphing FAB that changes based on the current screen
class MorphingFAB extends ConsumerWidget {
  const MorphingFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final destination = AppDestination.values[currentIndex];

    return _buildFABForDestination(context, ref, destination, currentIndex);
  }

  Widget _buildFABForDestination(
    BuildContext context,
    WidgetRef ref,
    AppDestination destination,
    int currentIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (destination) {
      case AppDestination.learn:
        return AnimatedFAB(
          icon: Icons.shuffle,
          label: 'Shuffle',
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          onPressed: () {
            HapticFeedback.mediumImpact();
            // TODO: Implement shuffle functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Shuffling flashcards!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        );

      case AppDestination.quiz:
        return AnimatedFAB(
          icon: Icons.refresh,
          label: 'Reset',
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          onPressed: () {
            HapticFeedback.mediumImpact();
            // TODO: Implement quiz reset
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quiz reset!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        );

      case AppDestination.review:
        return AnimatedFAB(
          icon: Icons.school,
          label: 'Study',
          backgroundColor: colorScheme.tertiary,
          foregroundColor: colorScheme.onTertiary,
          onPressed: () {
            HapticFeedback.mediumImpact();
            // Navigate to flashcards
            ref.read(navigationIndexProvider.notifier).state = 0;
          },
        );

      case AppDestination.progress:
        return AnimatedFAB(
          icon: Icons.timeline,
          label: 'Stats',
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showProgressDialog(context);
          },
        );

      case AppDestination.settings:
        return AnimatedFAB(
          icon: Icons.backup,
          label: 'Export',
          backgroundColor: colorScheme.surfaceContainer,
          foregroundColor: colorScheme.onSurface,
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showExportDialog(context);
          },
        );
    }
  }

  void _showProgressDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Learning Progress'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.flash_on, color: Colors.orange),
              title: Text('Flashcards Studied'),
              trailing: Text('127'),
            ),
            ListTile(
              leading: Icon(Icons.quiz, color: Colors.blue),
              title: Text('Quiz Questions'),
              trailing: Text('89'),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Correct Answers'),
              trailing: Text('76'),
            ),
            ListTile(
              leading: Icon(Icons.trending_up, color: Colors.purple),
              title: Text('Success Rate'),
              trailing: Text('85%'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Your learning progress is stored locally on this device. '
          'You can export your data for backup purposes, but remember '
          'that Octo Vocab is designed to be privacy-first with no cloud storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}

/// An animated floating action button with morphing capabilities
class AnimatedFAB extends StatefulWidget {
  const AnimatedFAB({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedFAB oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate rotation when icon changes
    if (widget.icon != oldWidget.icon) {
      _rotationController.forward().then((_) {
        _rotationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: FloatingActionButton.extended(
              onPressed: null, // Handled by GestureDetector
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              elevation: _isPressed ? 2 : 6,
              highlightElevation: 8,
              icon: AnimatedRotation(
                turns: _rotationAnimation.value,
                duration: const Duration(milliseconds: 300),
                child: Icon(widget.icon),
              ),
              label: Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// An integrated FAB that harmonizes with NavigationBar design
class IntegratedFAB extends ConsumerWidget {
  const IntegratedFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final destination = AppDestination.values[currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () => _handleFABAction(context, ref, destination, currentIndex),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 2,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              _getIconForDestination(destination),
              key: ValueKey(destination),
            ),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              _getLabelForDestination(destination),
              key: ValueKey(destination),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForDestination(AppDestination destination) {
    switch (destination) {
      case AppDestination.learn:
        return Icons.shuffle_rounded;
      case AppDestination.quiz:
        return Icons.refresh_rounded;
      case AppDestination.review:
        return Icons.school_rounded;
      case AppDestination.progress:
        return Icons.insights_rounded;
      case AppDestination.settings:
        return Icons.backup_rounded;
    }
  }

  String _getLabelForDestination(AppDestination destination) {
    switch (destination) {
      case AppDestination.learn:
        return 'Shuffle Cards';
      case AppDestination.quiz:
        return 'Reset Quiz';
      case AppDestination.review:
        return 'Start Study';
      case AppDestination.progress:
        return 'View Stats';
      case AppDestination.settings:
        return 'Export Data';
    }
  }

  void _handleFABAction(
    BuildContext context,
    WidgetRef ref,
    AppDestination destination,
    int currentIndex,
  ) {
    HapticFeedback.mediumImpact();
    
    switch (destination) {
      case AppDestination.learn:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🔀 Flashcards shuffled!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
      case AppDestination.quiz:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🔄 Quiz reset!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
      case AppDestination.review:
        // Navigate to Learn tab
        ref.read(navigationIndexProvider.notifier).state = 0;
        
      case AppDestination.progress:
        _showProgressDialog(context);
        
      case AppDestination.settings:
        _showExportDialog(context);
    }
  }

  void _showProgressDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Learning Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow(
              icon: Icons.flash_on_rounded,
              label: 'Flashcards Studied',
              value: '127',
              color: Colors.orange,
            ),
            _buildStatRow(
              icon: Icons.quiz_rounded,
              label: 'Quiz Questions',
              value: '89',
              color: Colors.blue,
            ),
            _buildStatRow(
              icon: Icons.check_circle_rounded,
              label: 'Correct Answers',
              value: '76',
              color: Colors.green,
            ),
            _buildStatRow(
              icon: Icons.trending_up_rounded,
              label: 'Success Rate',
              value: '85%',
              color: Colors.purple,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📤 Export Data'),
        content: const Text(
          'Your learning progress is stored locally on this device. '
          'You can export your data for backup purposes, but remember '
          'that Octo Vocab is designed to be privacy-first with no cloud storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('📦 Export feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
