import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The scalloped "cookie" from Material 3 Expressive: the app's signature
/// shape. It turns slowly while work is running.
class CookieShape extends StatefulWidget {
  const CookieShape({
    super.key,
    required this.size,
    required this.color,
    this.lobes = 9,
    this.depth = 0.08,
    this.spinning = false,
    this.child,
  });

  final double size;
  final Color color;
  final int lobes;

  /// Scallop depth as a share of the radius.
  final double depth;
  final bool spinning;
  final Widget? child;

  @override
  State<CookieShape> createState() => _CookieShapeState();
}

class _CookieShapeState extends State<CookieShape>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CookieShape old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final animate = widget.spinning && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!animate && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _spin,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _CookiePainter(widget.color, widget.lobes, widget.depth),
            ),
          ),
          ?widget.child,
        ],
      ),
    );
  }
}

class _CookiePainter extends CustomPainter {
  _CookiePainter(this.color, this.lobes, this.depth);

  final Color color;
  final int lobes;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 / (1 + depth);
    final path = Path();
    const steps = 144;
    for (var i = 0; i <= steps; i++) {
      final t = 2 * math.pi * i / steps;
      final rr = r * (1 + depth * math.cos(lobes * t));
      final p = c + Offset(rr * math.cos(t), rr * math.sin(t));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CookiePainter old) =>
      old.color != color || old.lobes != lobes || old.depth != depth;
}
