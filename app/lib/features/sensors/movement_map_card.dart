import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sensor_models.dart';

class MovementMapCard extends StatelessWidget {
  const MovementMapCard({
    super.key,
    required this.title,
    required this.points,
    required this.description,
  });

  final String title;
  final List<MovementPoint> points;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.25,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                child: CustomPaint(
                  painter: _MovementMapPainter(
                    points: points,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              points.length >= 2
                  ? '已記錄 ${points.length} 個移動樣本'
                  : '移動樣本不足，請持續移動手機',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementMapPainter extends CustomPainter {
  const _MovementMapPainter({
    required this.points,
    required this.colorScheme,
  });

  final List<MovementPoint> points;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke;

    const gridSteps = 4;
    for (var i = 1; i < gridSteps; i += 1) {
      final dx = size.width * i / gridSteps;
      final dy = size.height * i / gridSteps;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    if (points.isEmpty) {
      return;
    }

    final minX = points.map((point) => point.x).reduce(math.min);
    final maxX = points.map((point) => point.x).reduce(math.max);
    final minY = points.map((point) => point.y).reduce(math.min);
    final maxY = points.map((point) => point.y).reduce(math.max);

    const padding = 20.0;
    final usableWidth = math.max(size.width - padding * 2, 1);
    final usableHeight = math.max(size.height - padding * 2, 1);
    final rangeX = math.max(maxX - minX, 1);
    final rangeY = math.max(maxY - minY, 1);
    final scale = math.min(usableWidth / rangeX, usableHeight / rangeY);
    final contentWidth = rangeX * scale;
    final contentHeight = rangeY * scale;
    final offsetX = padding + (usableWidth - contentWidth) / 2;
    final offsetY = padding + (usableHeight - contentHeight) / 2;

    Offset project(MovementPoint point) {
      final x = offsetX + (point.x - minX) * scale;
      final y = size.height - offsetY - (point.y - minY) * scale;
      return Offset(x, y);
    }

    final projected = points.map(project).toList(growable: false);
    final path = Path()..moveTo(projected.first.dx, projected.first.dy);
    for (final point in projected.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final trackPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, trackPaint);

    canvas.drawCircle(projected.first, 6, Paint()..color = colorScheme.secondary);
    canvas.drawCircle(projected.last, 7, Paint()..color = colorScheme.primary);

    final lastHeading = points.last.headingDegrees;
    if (lastHeading == null) {
      return;
    }

    final radians = (lastHeading - 90) * math.pi / 180;
    const arrowLength = 24.0;
    final tip =
        projected.last + Offset(math.cos(radians), math.sin(radians)) * arrowLength;
    final arrowPaint = Paint()
      ..color = colorScheme.tertiary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(projected.last, tip, arrowPaint);

    final leftWing =
        tip + Offset(math.cos(radians + 2.5), math.sin(radians + 2.5)) * 10;
    final rightWing =
        tip + Offset(math.cos(radians - 2.5), math.sin(radians - 2.5)) * 10;
    canvas.drawLine(tip, leftWing, arrowPaint);
    canvas.drawLine(tip, rightWing, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _MovementMapPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.colorScheme != colorScheme;
  }
}
