import 'package:flutter/material.dart';
import 'package:knoq_app/core/constants/app_colors.dart';

class BatZoneDiagram extends StatefulWidget {
  final String? activeZone;
  final Map<String, double>? zoneDistribution;
  
  const BatZoneDiagram({
    super.key,
    this.activeZone,
    this.zoneDistribution,
  });

  @override
  State<BatZoneDiagram> createState() => _BatZoneDiagramState();
}

class _BatZoneDiagramState extends State<BatZoneDiagram> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _currentActive;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
    
    if (widget.activeZone != null) {
      _triggerHit(widget.activeZone!);
    }
  }

  @override
  void didUpdateWidget(BatZoneDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeZone != oldWidget.activeZone && widget.activeZone != null) {
      _triggerHit(widget.activeZone!);
    }
  }

  void _triggerHit(String zone) {
    setState(() {
      _currentActive = zone;
    });
    _fadeController.reset();
    _fadeController.forward().then((_) {
      if (mounted) {
        setState(() {
          _currentActive = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 300),
          painter: BatDiagramPainter(
            context: context,
            activeZone: _currentActive,
            fadeValue: _currentActive != null ? _fadeAnimation.value : 0.0,
            distribution: widget.zoneDistribution,
          ),
        );
      },
    );
  }
}

class BatDiagramPainter extends CustomPainter {
  final BuildContext context;
  final String? activeZone;
  final double fadeValue;
  final Map<String, double>? distribution;

  BatDiagramPainter({
    required this.context,
    this.activeZone,
    required this.fadeValue,
    this.distribution,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseFill = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final strokeColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    
    final paintStroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Defines regions (simplified geometric interpretation)
    // Handle, Top, Sweet, Left, Right, Bottom
    final w = size.width;
    final h = size.height;

    // Draw Handle
    final handleRect = Rect.fromLTWH(w * 0.4, 0, w * 0.2, h * 0.2);
    canvas.drawRect(handleRect, Paint()..color = baseFill);
    canvas.drawRect(handleRect, paintStroke);

    // Blade
    final bladeRect = Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.6, h * 0.8);
    final bladeRRect = RRect.fromRectAndRadius(bladeRect, const Radius.circular(8));
    
    canvas.drawRRect(bladeRRect, Paint()..color = baseFill);
    canvas.drawRRect(bladeRRect, paintStroke);

    // Zones partitioning within blade
    _drawZone(canvas, 'Top', Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.6, h * 0.2), baseFill);
    _drawZone(canvas, 'Left', Rect.fromLTWH(w * 0.2, h * 0.4, w * 0.2, h * 0.3), baseFill);
    _drawZone(canvas, 'Sweet', Rect.fromLTWH(w * 0.4, h * 0.4, w * 0.2, h * 0.3), baseFill);
    _drawZone(canvas, 'Right', Rect.fromLTWH(w * 0.6, h * 0.4, w * 0.2, h * 0.3), baseFill);
    _drawZone(canvas, 'Bottom', Rect.fromLTWH(w * 0.2, h * 0.7, w * 0.6, h * 0.3), baseFill);
  }

  void _drawZone(Canvas canvas, String zone, Rect rect, Color baseColor) {
    Color fill = baseColor;
    double opacity = 1.0;

    if (distribution != null && distribution!.containsKey(zone)) {
      final intensity = distribution![zone]!;
      fill = AppColors.getZoneColor(context, zone);
      opacity = 0.2 + (intensity * 0.8); // 20% to 100% opacity
    }

    if (zone.toLowerCase() == activeZone?.toLowerCase()) {
      fill = AppColors.getZoneColor(context, zone);
      opacity = fadeValue; // Pulse hit
    }

    if (fill != baseColor) {
      canvas.drawRect(rect, Paint()..color = fill.withValues(alpha: opacity));
    }
  }

  @override
  bool shouldRepaint(BatDiagramPainter oldDelegate) {
    return oldDelegate.activeZone != activeZone || 
           oldDelegate.fadeValue != fadeValue ||
           oldDelegate.distribution != distribution;
  }
}
