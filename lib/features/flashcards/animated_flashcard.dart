// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_saas_template/core/models/word.dart';

/// An animated flashcard with flip animations and swipe gestures
class AnimatedFlashcard extends StatefulWidget {
  const AnimatedFlashcard({
    required this.word,
    required this.onKnown,
    required this.onUnknown,
    required this.onFlip,
    this.showBack = false,
    super.key,
  });

  final Word word;
  final VoidCallback onKnown;
  final VoidCallback onUnknown;
  final VoidCallback onFlip;
  final bool showBack;

  @override
  State<AnimatedFlashcard> createState() => _AnimatedFlashcardState();
}

class _AnimatedFlashcardState extends State<AnimatedFlashcard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _swipeController;
  late AnimationController _scaleController;
  late Animation<double> _flipAnimation;
  late Animation<double> _swipeAnimation;
  late Animation<double> _scaleAnimation;

  double _dragDelta = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    // Flip animation controller
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Swipe animation controller
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Scale animation controller for interactions
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _swipeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedFlashcard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate flip when showBack changes
    if (widget.showBack != oldWidget.showBack) {
      if (widget.showBack) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _swipeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _scaleController.forward();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDelta += details.delta.dx;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    const swipeThreshold = 100.0;

    setState(() {
      _isDragging = false;
    });

    _scaleController.reverse();

    if (_dragDelta.abs() > swipeThreshold) {
      // Provide haptic feedback
      HapticFeedback.lightImpact();

      // Determine swipe direction
      if (_dragDelta > 0) {
        // Swipe right - Known
        _animateSwipeAndCallback(true);
      } else {
        // Swipe left - Unknown
        _animateSwipeAndCallback(false);
      }
    } else {
      // Return to center
      setState(() {
        _dragDelta = 0;
      });
    }
  }

  void _animateSwipeAndCallback(bool isKnown) {
    _swipeController.forward().then((_) {
      if (isKnown) {
        widget.onKnown();
      } else {
        widget.onUnknown();
      }

      // Reset animations
      _swipeController.reset();
      setState(() {
        _dragDelta = 0;
      });
    });
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onFlip();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _handleTap,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _flipAnimation,
          _swipeAnimation,
          _scaleAnimation,
        ]),
        builder: (context, child) {
          final swipeOffset = _isDragging ? _dragDelta : 0.0;
          final swipeOpacity = 1.0 - (_swipeAnimation.value * 0.5);
          final cardScale = _scaleAnimation.value;

          return Transform.translate(
            offset: Offset(swipeOffset, 0),
            child: Transform.scale(
              scale: cardScale,
              child: Opacity(
                opacity: swipeOpacity,
                child: Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Swipe hint indicators
                      if (_isDragging) ...[
                        // Left indicator (Unknown)
                        Positioned(
                          left: 24,
                          top: 0,
                          bottom: 0,
                          child: AnimatedOpacity(
                            opacity: _dragDelta < -50 ? 1.0 : 0.3,
                            duration: const Duration(milliseconds: 100),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.red.shade700,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Right indicator (Known)
                        Positioned(
                          right: 24,
                          top: 0,
                          bottom: 0,
                          child: AnimatedOpacity(
                            opacity: _dragDelta > 50 ? 1.0 : 0.3,
                            duration: const Duration(milliseconds: 100),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.green.shade700,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Flashcard content
                      _buildFlashcardContent(context, theme),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlashcardContent(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(_flipAnimation.value * math.pi),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.surface, colorScheme.surfaceContainerLow],
            ),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: _flipAnimation.value < 0.5
              ? _buildFrontContent(theme)
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _buildBackContent(theme),
                ),
        ),
      ),
    );
  }

  Widget _buildFrontContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.translate,
            size: 48,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 24),
          Text(
            widget.word.latin,
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Tap to reveal meaning',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb,
            size: 48,
            color: theme.colorScheme.secondary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 24),
          Text(
            widget.word.english,
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.word.exampleLatin != null ||
              widget.word.exampleEnglish != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (widget.word.exampleLatin != null)
                    Text(
                      '"${widget.word.exampleLatin}"',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (widget.word.exampleLatin != null &&
                      widget.word.exampleEnglish != null)
                    const SizedBox(height: 8),
                  if (widget.word.exampleEnglish != null)
                    Text(
                      '— ${widget.word.exampleEnglish}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer
                            .withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swipe_left,
                size: 16,
                color: Colors.red.withValues(alpha: 0.6),
              ),
              Text(
                ' Unknown  •  Known ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Icon(
                Icons.swipe_right,
                size: 16,
                color: Colors.green.withValues(alpha: 0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
