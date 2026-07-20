import 'package:flutter/material.dart';
import 'dart:math';

class PowerArc extends StatelessWidget {
  final int value; // 0 to 100
  final String label;

  const PowerArc({
    super.key,
    required this.value,
    this.label = 'Power',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeValue = value.clamp(0, 100);

    Color arcColor;
    if (safeValue >= 70) {
      arcColor = Colors.green;
    } else if (safeValue >= 40) {
      arcColor = Colors.orange;
    } else {
      arcColor = Colors.red;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: safeValue.toDouble()),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, animValue, _) {
              return CustomPaint(
                painter: ArcPainter(
                  value: animValue,
                  color: arcColor,
                  bgColor: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    '${animValue.toInt()}',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: arcColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color bgColor;

  ArcPainter({
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    // Draw background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Draw filled arc
    final fillSweep = (value / 100) * sweepAngle;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fillSweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(ArcPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
