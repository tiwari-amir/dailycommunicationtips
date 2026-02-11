import 'dart:math' as math;

import 'package:flutter/material.dart';

class SegmentedCircularProgress extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final int segments;
  final double gapDegrees;
  final Duration duration;
  final Curve curve;
  final List<Color> gradientColors;
  final Color trackColor;
  final Color glowColor;
  final Widget? center;

  const SegmentedCircularProgress({
    super.key,
    required this.progress,
    this.size = 150,
    this.strokeWidth = 12,
    this.segments = 4,
    this.gapDegrees = 4,
    this.duration = const Duration(milliseconds: 850),
    this.curve = Curves.easeOutCubic,
    required this.gradientColors,
    required this.trackColor,
    required this.glowColor,
    this.center,
  });

  @override
  State<SegmentedCircularProgress> createState() =>
      _SegmentedCircularProgressState();
}

class _SegmentedCircularProgressState extends State<SegmentedCircularProgress>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _pulseController;
  late final AnimationController _sheenController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  double _currentProgress = 0;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.progress.clamp(0.0, 1.0);
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progressAnimation = AlwaysStoppedAnimation<double>(_currentProgress);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _progressController.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentProgress = _progressAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant SegmentedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.progress.clamp(0.0, 1.0);
    if ((target - _currentProgress).abs() > 0.0001) {
      _progressAnimation = Tween<double>(begin: _currentProgress, end: target)
          .animate(
            CurvedAnimation(parent: _progressController, curve: widget.curve),
          );
      _progressController.forward(from: 0);
    }

    final crossedComplete = oldWidget.progress < 1.0 && widget.progress >= 1.0;
    if (crossedComplete) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _sheenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1 + (0.03 * _pulseAnimation.value);
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _SegmentedRingPainter(
            progress: _currentProgress,
            segments: widget.segments,
            gapRadians: widget.gapDegrees * (math.pi / 180),
            strokeWidth: widget.strokeWidth,
            gradientColors: widget.gradientColors,
            trackColor: widget.trackColor,
            glowColor: widget.glowColor,
            pulseValue: _pulseAnimation.value,
            sheenValue: _sheenController.value,
          ),
          child: Center(child: widget.center),
        ),
      ),
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  final double progress;
  final int segments;
  final double gapRadians;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Color trackColor;
  final Color glowColor;
  final double pulseValue;
  final double sheenValue;

  const _SegmentedRingPainter({
    required this.progress,
    required this.segments,
    required this.gapRadians,
    required this.strokeWidth,
    required this.gradientColors,
    required this.trackColor,
    required this.glowColor,
    required this.pulseValue,
    required this.sheenValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ringRect = rect.deflate(strokeWidth / 2);
    const startAngle = -math.pi / 2;
    final segmentSweep = (2 * math.pi) / segments;
    final drawSweepPerSegment = math.max(0.0, segmentSweep - gapRadians);
    final totalDrawableSweep = drawSweepPerSegment * segments;
    final targetSweep = totalDrawableSweep * progress.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    for (var i = 0; i < segments; i++) {
      final segmentStart = startAngle + (i * segmentSweep) + (gapRadians / 2);
      canvas.drawArc(
        ringRect,
        segmentStart,
        drawSweepPerSegment,
        false,
        trackPaint,
      );
    }

    // Ambient subtle halo around ring for depth on dark backgrounds.
    final haloPaint = Paint()
      ..color = glowColor.withOpacity(0.06 + (0.04 * pulseValue))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(ringRect.center, (ringRect.width / 2) + 6, haloPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + (2 * math.pi),
        colors: gradientColors,
      ).createShader(ringRect);

    var remaining = targetSweep;
    for (var i = 0; i < segments && remaining > 0; i++) {
      final segmentStart = startAngle + (i * segmentSweep) + (gapRadians / 2);
      final drawSweep = math.min(drawSweepPerSegment, remaining);
      if (drawSweep > 0) {
        canvas.drawArc(ringRect, segmentStart, drawSweep, false, progressPaint);
      }
      remaining -= drawSweep;
    }

    // Subtle reflective sheen that moves slowly clockwise.
    final sheenAngle = startAngle + (2 * math.pi * sheenValue);
    final sheenPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.42
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: sheenAngle - 0.26,
        endAngle: sheenAngle + 0.26,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.28),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(ringRect);
    canvas.drawArc(ringRect, sheenAngle - 0.24, 0.48, false, sheenPaint);

    // Subtle outer markers communicate progress without noise.
    final markerCount = 20;
    final markerRadius = (ringRect.width / 2) + strokeWidth * 0.9;
    for (var i = 0; i < markerCount; i++) {
      final markerProgress = i / markerCount;
      final angle = startAngle + ((2 * math.pi) * markerProgress);
      final point = Offset(
        ringRect.center.dx + (markerRadius * math.cos(angle)),
        ringRect.center.dy + (markerRadius * math.sin(angle)),
      );
      final isActive = markerProgress < progress;
      final markerPaint = Paint()
        ..color = isActive
            ? glowColor.withOpacity(0.38)
            : trackColor.withOpacity(0.35);
      canvas.drawCircle(point, isActive ? 1.6 : 1.3, markerPaint);
    }

    if (targetSweep > 0) {
      final headAngle = _angleAtSweep(
        startAngle: startAngle,
        segmentSweep: segmentSweep,
        drawSweepPerSegment: drawSweepPerSegment,
        gapRadians: gapRadians,
        sweep: targetSweep,
        segments: segments,
      );
      final radius = ringRect.width / 2;
      final center = ringRect.center;
      final head = Offset(
        center.dx + (radius * math.cos(headAngle)),
        center.dy + (radius * math.sin(headAngle)),
      );

      final glowOpacity = (0.22 + (0.16 * pulseValue)).clamp(0.0, 1.0);
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(head, strokeWidth * 0.62, glowPaint);

      final corePaint = Paint()..color = glowColor.withOpacity(0.7);
      canvas.drawCircle(head, strokeWidth * 0.18, corePaint);
    }
  }

  static double _angleAtSweep({
    required double startAngle,
    required double segmentSweep,
    required double drawSweepPerSegment,
    required double gapRadians,
    required double sweep,
    required int segments,
  }) {
    var remaining = sweep;
    for (var i = 0; i < segments; i++) {
      final segmentStart = startAngle + (i * segmentSweep) + (gapRadians / 2);
      if (remaining <= drawSweepPerSegment) {
        return segmentStart + remaining;
      }
      remaining -= drawSweepPerSegment;
    }
    return startAngle + (2 * math.pi) - (gapRadians / 2);
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.sheenValue != sheenValue ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gapRadians != gapRadians ||
        oldDelegate.segments != segments ||
        oldDelegate.gradientColors != gradientColors;
  }
}
