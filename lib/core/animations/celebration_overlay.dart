// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A celebration overlay with confetti animation for correct answers
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({required this.isVisible, this.child, super.key});

  final bool isVisible;
  final Widget? child;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _fadeController;
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _generateParticles();
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible && !oldWidget.isVisible) {
      _showCelebration();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _hideCelebration();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _generateParticles() {
    final random = math.Random();
    _particles = List.generate(30, (index) {
      return ConfettiParticle(
        x: random.nextDouble(),
        y: -0.1,
        color: _getRandomColor(random),
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
        velocityX: (random.nextDouble() - 0.5) * 0.5,
        velocityY: random.nextDouble() * 0.3 + 0.2,
        gravity: random.nextDouble() * 0.1 + 0.05,
      );
    });
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[random.nextInt(colors.length)];
  }

  void _showCelebration() {
    _generateParticles();
    _fadeController.forward();
    _confettiController.forward().then((_) {
      if (mounted) {
        _hideCelebration();
      }
    });
  }

  void _hideCelebration() {
    _fadeController.reverse();
    _confettiController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        if (widget.isVisible)
          IgnorePointer(  // Ensure celebration doesn't block touch events
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(opacity: _fadeController.value, child: child);
              },
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class ConfettiParticle {
  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.velocityX,
    required this.velocityY,
    required this.gravity,
  });

  double x;
  double y;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;
  final double velocityX;
  double velocityY;
  final double gravity;

  void update(double progress) {
    x += velocityX * 0.02;
    y += velocityY * 0.02;
    velocityY += gravity * 0.02;
    rotation += rotationSpeed * 0.02;
  }
}

class ConfettiPainter extends CustomPainter {
  ConfettiPainter({required this.particles, required this.progress});

  final List<ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Update particle position based on progress
      final updatedParticle = ConfettiParticle(
        x: particle.x + particle.velocityX * progress,
        y:
            particle.y +
            particle.velocityY * progress +
            particle.gravity * progress * progress * 0.5,
        color: particle.color,
        size: particle.size,
        rotation: particle.rotation + particle.rotationSpeed * progress,
        rotationSpeed: particle.rotationSpeed,
        velocityX: particle.velocityX,
        velocityY: particle.velocityY,
        gravity: particle.gravity,
      );

      // Only draw particles that are visible
      if (updatedParticle.y < 1.2) {
        final paint = Paint()
          ..color = updatedParticle.color.withValues(
            alpha: (1.0 - progress * 0.7).clamp(0.0, 1.0),
          );

        final center = Offset(
          updatedParticle.x * size.width,
          updatedParticle.y * size.height,
        );

        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(updatedParticle.rotation);

        // Draw different shapes for variety
        final shapeType = updatedParticle.size.toInt() % 3;
        switch (shapeType) {
          case 0:
            // Circle
            canvas.drawCircle(Offset.zero, updatedParticle.size * 0.5, paint);
            break;
          case 1:
            // Square
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset.zero,
                width: updatedParticle.size,
                height: updatedParticle.size,
              ),
              paint,
            );
            break;
          case 2:
            // Triangle
            final path = Path();
            final radius = updatedParticle.size * 0.5;
            path.moveTo(0, -radius);
            path.lineTo(radius * 0.866, radius * 0.5);
            path.lineTo(-radius * 0.866, radius * 0.5);
            path.close();
            canvas.drawPath(path, paint);
            break;
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
