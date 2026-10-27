import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Material 3 Expressive wavy progress line. Without [value] the wave runs
/// across the whole width as an indeterminate indicator.
class WavyProgress extends StatefulWidget {
  const WavyProgress({super.key, this.value, this.color, this.trackColor});

  final double? value;
  final Color? color;
  final Color? trackColor;

  @override
  State<WavyProgress> createState() => _WavyProgressState();
}

class _WavyProgressState extends State<WavyProgress>
    with SingleTickerProviderStateMixin {
  late final _phase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _phase.stop();
    } else if (!_phase.isAnimating) {
      _phase.repeat();
    }
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.commonWorking,
      value: widget.value == null ? null : '${(widget.value! * 100).round()}%',
      child: SizedBox(
        height: 12,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _phase,
          builder: (context, _) => CustomPaint(
            painter: _WavePainter(
              value: widget.value,
              phase: _phase.value,
              color: widget.color ?? scheme.primary,
              track: widget.trackColor ?? scheme.secondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.value,
    required this.phase,
    required this.color,
    required this.track,
  });

  final double? value;
  final double phase;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    const wavelength = 20.0;
    const amp = 3.0;
    final y = size.height / 2;
    final end = (value ?? 1).clamp(0.0, 1.0) * size.width;
    final paint = Paint()
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (value != null && end < size.width - stroke * 2) {
      canvas.drawLine(
        Offset(end + stroke * 2, y),
        Offset(size.width - stroke / 2, y),
        paint..color = track,
      );
    }
    final wave = Path();
    for (var x = stroke / 2; x <= end - stroke / 2; x += 1) {
      final dy = amp * math.sin(2 * math.pi * (x / wavelength - phase));
      x == stroke / 2 ? wave.moveTo(x, y + dy) : wave.lineTo(x, y + dy);
    }
    canvas.drawPath(wave, paint..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.phase != phase || old.value != value || old.color != color;
}
