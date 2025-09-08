// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An animated quiz option with visual feedback
class AnimatedQuizOption extends StatefulWidget {
  const AnimatedQuizOption({
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
    this.index = 0,
    super.key,
  });

  final String option;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;
  final int index;

  @override
  State<AnimatedQuizOption> createState() => _AnimatedQuizOptionState();
}

class _AnimatedQuizOptionState extends State<AnimatedQuizOption>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _resultController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _resultAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for tap feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Result reveal animation
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Pulse animation for correct answer
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _resultAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Add entrance animation with staggered delay
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _resultController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedQuizOption oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger result animation when showing results
    if (widget.showResult && !oldWidget.showResult) {
      _animateResult();
    }

    // Reset animations when moving to next question
    if (!widget.showResult && oldWidget.showResult) {
      _resultController.forward();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _resultController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _animateResult() {
    if (widget.isCorrect) {
      // Pulse animation for correct answer
      _pulseController.repeat(reverse: true);
      // Haptic feedback for correct answer
      HapticFeedback.mediumImpact();
    } else if (widget.isSelected) {
      // Shake animation for incorrect selected answer
      HapticFeedback.heavyImpact();
    }
  }

  void _handleTap() {
    if (widget.showResult) return;

    HapticFeedback.lightImpact();
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on state
    Color? backgroundColor;
    Color? borderColor;
    Color? textColor;
    IconData? resultIcon;
    Color? iconColor;

    if (widget.showResult) {
      if (widget.isCorrect) {
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        textColor = Colors.green.shade800;
        resultIcon = Icons.check_circle;
        iconColor = Colors.green;
      } else if (widget.isSelected) {
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red;
        textColor = Colors.red.shade800;
        resultIcon = Icons.cancel;
        iconColor = Colors.red;
      } else {
        backgroundColor = colorScheme.surface;
        borderColor = colorScheme.outline.withValues(alpha: 0.3);
        textColor = colorScheme.onSurface.withValues(alpha: 0.6);
      }
    } else {
      if (widget.isSelected) {
        backgroundColor = colorScheme.primaryContainer.withValues(alpha: 0.3);
        borderColor = colorScheme.primary;
        textColor = colorScheme.onPrimaryContainer;
      } else {
        backgroundColor = colorScheme.surface;
        borderColor = colorScheme.outline.withValues(alpha: 0.3);
        textColor = colorScheme.onSurface;
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _resultAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        final scale = widget.showResult && widget.isCorrect
            ? _pulseAnimation.value
            : _scaleAnimation.value;

        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor ?? Colors.transparent,
                width: 2,
              ),
              boxShadow: widget.isSelected || widget.showResult
                  ? [
                      BoxShadow(
                        color: (borderColor ?? colorScheme.primary).withValues(
                          alpha: 0.2,
                        ),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style:
                              theme.textTheme.bodyLarge?.copyWith(
                                color: textColor,
                                fontWeight:
                                    widget.isSelected || widget.showResult
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ) ??
                              const TextStyle(),
                          child: Text(widget.option),
                        ),
                      ),
                      if (widget.showResult && resultIcon != null)
                        AnimatedScale(
                          scale: _resultAnimation.value,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          child: Icon(resultIcon, color: iconColor, size: 28),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
