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
