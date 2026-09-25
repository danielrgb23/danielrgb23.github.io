import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Makes [front] behave like a Mario-style coin when [animation] runs 0 → 1:
/// it hops up, spins several times showing a golden coin on its back side,
/// lands, and a "+1" floats up with a burst of gold pixels.
class CoinFlip extends StatelessWidget {
  const CoinFlip({
    super.key,
    required this.animation,
    required this.size,
    required this.front,
    this.reduceMotion = false,
  });

  final Animation<double> animation;
  final double size;
  final Widget front;
  final bool reduceMotion;

  static const _turns = 3;
  static const _gold = Color(0xFFFFCD3C);

  static double _seg(double v, double a, double b) =>
      ((v - a) / (b - a)).clamp(0.0, 1.0);

  Widget _back() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE98A), Color(0xFFFFB800)],
        ),
        border: Border.all(color: const Color(0xFFC98A00), width: 3),
        boxShadow: [
          BoxShadow(color: AppColors.bgPanel, spreadRadius: 6),
          BoxShadow(color: _gold.withOpacity(0.6), blurRadius: 32),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size - 28,
        height: size - 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC98A00), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          'R23',
          style: AppText.pixel.copyWith(
            fontSize: 22,
            color: const Color(0xFF8A5A00),
            shadows: const [
              Shadow(color: Color(0xFFFFF3B8), offset: Offset(2, 2))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: front,
      builder: (context, child) {
        final t = animation.value;
        final running = t > 0 && t < 1;
        var angle = 0.0, hop = 0.0;
        if (!reduceMotion) {
          angle = Curves.easeOutCubic.transform(t) * 2 * pi * _turns;
          hop = -36 * sin(pi * Curves.easeOut.transform(t));
        }
        final showBack = cos(angle) < 0;
        final face = Transform.translate(
          offset: Offset(0, hop),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _back(),
                  )
                : child,
          ),
        );
        if (!running) return SizedBox(width: size, height: size, child: face);

        // "+1" rises and fades out; gold pixels burst from the coin.
        final rise = Curves.easeOut.transform(_seg(t, 0.2, 1));
        final label = _seg(t, 0.2, 0.32) * (1 - _seg(t, 0.72, 1));
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              face,
              IgnorePointer(
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _BurstPainter(t, size),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -size / 2 - 14 - 46 * rise),
                child: Opacity(
                  opacity: label,
                  child: Text(
                    '+1',
                    style: AppText.pixel.copyWith(
                      fontSize: 20,
                      color: _gold,
                      shadows: const [
                        Shadow(color: Color(0xFF1B0B3A), offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.size);
  final double t;
  final double size;

  @override
  void paint(Canvas canvas, Size s) {
    if (t < 0.08 || t > 0.7) return;
    final k = (t - 0.08) / 0.62;
    final paint = Paint()..isAntiAlias = false;
    final c = Offset(s.width / 2, s.height / 2);
    for (var i = 0; i < 12; i++) {
      final a = i * 2 * pi / 12 + 0.26;
      final r =
          size * 0.55 + 56 * Curves.easeOut.transform(k) * (i.isEven ? 1 : 0.7);
      paint.color = (i % 3 == 0 ? const Color(0xFFFFF3B8) : CoinFlip._gold)
          .withOpacity(1 - k);
      canvas.drawRect(
        Rect.fromCenter(
            center: c + Offset(cos(a), sin(a)) * r, width: 6, height: 6),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
