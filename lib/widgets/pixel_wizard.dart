import 'dart:math';
import 'package:flutter/material.dart';

/// A pixel-art wizard that loops: raises a hand, summons a cup of coffee
/// with his staff, catches it, takes a few sips, then dissolves the cup.
///
/// Everything is drawn with [Canvas.drawRect] on a virtual pixel grid, so the
/// sprite stays crisp at any scale. The wizard faces left (towards the
/// avatar next to it).
class PixelWizard extends StatefulWidget {
  const PixelWizard({super.key, this.scale = 4});
  final double scale;

  // Sprite space spans x in [-6, 24) and y in [0, 34).
  static const gridW = 30;
  static const gridH = 34;

  @override
  State<PixelWizard> createState() => _PixelWizardState();
}

class _PixelWizardState extends State<PixelWizard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 11),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _loop
        ..stop()
        ..value = 0.66; // a still frame: mid-sip
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      label: 'Pixel art wizard summoning and drinking a coffee',
      child: ExcludeSemantics(
        child: SizedBox(
          width: PixelWizard.gridW * s,
          height: PixelWizard.gridH * s,
          child: AnimatedBuilder(
            animation: _loop,
            builder: (context, _) => CustomPaint(
              painter: _WizardPainter(
                t: _loop.value,
                seconds: _loop.value * 11,
                scale: s,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- palette (fixed: pixel art looks the same in both themes) ---------------
const _hat = Color(0xFF5B3FD1);
const _hatDark = Color(0xFF3B2A8F);
const _gold = Color(0xFFFFCD3C);
const _skin = Color(0xFFF2C49B);
const _beard = Color(0xFFEDEDED);
const _beardShade = Color(0xFFBDB6D0);
const _ink = Color(0xFF1B0B3A);
const _wood = Color(0xFF8B5A2B);
const _orb = Color(0xFF2DE2FF);
const _boots = Color(0xFF2A1A55);
const _cupWhite = Color(0xFFF7F1E5);
const _cupShade = Color(0xFFCFC3AE);
const _coffee = Color(0xFF6B3A1E);
const _steam = Color(0xFFE9E2F7);

class _WizardPainter extends CustomPainter {
  _WizardPainter({required this.t, required this.seconds, required this.scale});
  final double t; // 0..1 position in the loop
  final double seconds;
  final double scale;

  late Canvas _c;
  final _paint = Paint()..isAntiAlias = false;

  // Draws one rect in sprite space (pixel grid units).
  void _px(num x, num y, Color color, {num w = 1, num h = 1, double a = 1}) {
    _paint.color = color.withOpacity(a);
    _c.drawRect(
      Rect.fromLTWH(x.floorToDouble() * scale, y.floorToDouble() * scale,
          w * scale, h * scale),
      _paint,
    );
  }

  // Pixel-perfect thick line (Bresenham), used for the arms.
  void _line(int x0, int y0, int x1, int y1, Color color, {int thick = 2}) {
    final dx = (x1 - x0).abs(), dy = -(y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    var err = dx + dy;
    while (true) {
      _px(x0, y0, color, w: thick, h: thick);
      if (x0 == x1 && y0 == y1) break;
      final e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }
    }
  }

  static double _seg(double v, double a, double b) =>
      ((v - a) / (b - a)).clamp(0.0, 1.0);
  static double _lerp(double a, double b, double k) => a + (b - a) * k;
  static Offset _lerpO(Offset a, Offset b, double k) =>
      Offset(_lerp(a.dx, b.dx, k), _lerp(a.dy, b.dy, k));

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    canvas.translate(6 * scale, 0); // sprite x=0 sits 6 pixels from the left

    // ---- timeline -----------------------------------------------------
    const summonStart = 0.12, summonEnd = 0.30;
    const catchEnd = 0.42, liftEnd = 0.56, sipEnd = 0.76;
    const lowerEnd = 0.86, fadeEnd = 0.95;

    const hover = Offset(-4, 7);
    const held = Offset(-4, 17);
    const mouth = Offset(1, 12);
    const restHand = Offset(2, 25);
    const raisedHand = Offset(-3, 14);

    // Cup top-left, visibility (0..1 = how much of it has materialized).
    var cup = hover;
    var vis = 0.0;
    if (t >= summonStart && t < fadeEnd) {
      if (t < summonEnd) {
        vis = _seg(t, summonStart + 0.03, summonEnd);
        cup = hover;
      } else if (t < catchEnd) {
        vis = 1;
        cup = _lerpO(hover, held, Curves.easeInOut.transform(_seg(t, summonEnd, catchEnd)));
      } else if (t < liftEnd) {
        vis = 1;
        cup = _lerpO(held, mouth, Curves.easeInOut.transform(_seg(t, catchEnd, liftEnd)));
      } else if (t < sipEnd) {
        vis = 1;
        // Three gulps: the cup tips up a pixel and comes back.
        final k = _seg(t, liftEnd, sipEnd);
        final gulp = (sin(k * pi * 6) > 0.35) ? -1.0 : 0.0;
        cup = mouth + Offset(0, gulp);
      } else if (t < lowerEnd) {
        vis = 1;
        cup = _lerpO(mouth, held, Curves.easeInOut.transform(_seg(t, sipEnd, lowerEnd)));
      } else {
        vis = 1 - _seg(t, lowerEnd, fadeEnd);
        cup = held;
      }
    }
    final cupPos = Offset(cup.dx.roundToDouble(), cup.dy.roundToDouble());
    final cupHand = Offset(cupPos.dx + 1, cupPos.dy + 5);
    final holding = t >= catchEnd - 0.04 && t < lowerEnd + 0.03;

    // Left hand target.
    Offset hand;
    if (t < summonStart) {
      hand = restHand;
    } else if (t < summonStart + 0.07) {
      hand = _lerpO(restHand, raisedHand, Curves.easeOut.transform(_seg(t, summonStart, summonStart + 0.07)));
    } else if (t < summonEnd + 0.02) {
      hand = raisedHand + Offset(0, sin(seconds * 9) > 0 ? -1 : 0);
    } else if (holding) {
      hand = _lerpO(raisedHand, cupHand, Curves.easeOut.transform(_seg(t, summonEnd + 0.02, catchEnd - 0.04)));
      if (t >= catchEnd - 0.04) hand = cupHand;
    } else {
      hand = _lerpO(cupHand, restHand, Curves.easeInOut.transform(_seg(t, lowerEnd + 0.03, fadeEnd + 0.03)));
    }
    final handPos = Offset(hand.dx.roundToDouble(), hand.dy.roundToDouble());

    final sipping = t >= liftEnd && t < sipEnd;
    final beardBob = sipping && sin(_seg(t, liftEnd, sipEnd) * pi * 6) > 0.35 ? 1 : 0;

    // ---- orb + staff glow ---------------------------------------------
    final summoning = t >= summonStart && t < summonEnd;
    final fading = t >= lowerEnd && t < fadeEnd;
    final pulse = 0.5 + 0.5 * sin(seconds * 3);
    final flash = (summoning || fading) ? 1.0 : 0.0;
    final glowR = (5 + 3 * pulse + 4 * flash) * scale;
    canvas.drawCircle(
      Offset(20 * scale, 3 * scale),
      glowR,
      Paint()
        ..color = _orb.withOpacity(0.25 + 0.25 * pulse + 0.25 * flash)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale * 3),
    );

    // ---- staff ---------------------------------------------------------
    _px(19, 5, _wood, w: 2, h: 29);
    _px(19, 5, const Color(0xFFB57C3E), w: 1, h: 29);
    _px(18, 1, _orb, w: 4, h: 4);
    _px(18, 1, Colors.white, w: 1, h: 1, a: 0.9);
    _px(17, 5, _wood, w: 1, h: 1);
    _px(22, 5, _wood, w: 1, h: 1);

    // ---- robe ----------------------------------------------------------
    for (var y = 16; y <= 31; y++) {
      final grow = ((y - 16) * 4) ~/ 15;
      final l = 5 - grow, r = 14 + grow;
      _px(l, y, _hat, w: r - l + 1);
      _px(r - 1, y, _hatDark, w: 2); // shaded right side
    }
    _px(4, 31, _hatDark, w: 14); // hem
    _px(5, 22, _gold, w: 10); // belt
    _px(9, 22, _ink, w: 2);
    // boots
    _px(3, 32, _boots, w: 5, h: 2);
    _px(12, 32, _boots, w: 5, h: 2);

    // ---- right arm holding the staff ------------------------------------
    _line(14, 18, 18, 21, _hat);
    _px(18, 21, _skin, w: 3, h: 2);

    // ---- hat -----------------------------------------------------------
    for (var y = 0; y <= 9; y++) {
      final half = y ~/ 2 + 1;
      _px(9 - half + 1, y, _hat, w: half * 2);
      _px(9 + half - 1, y, _hatDark, w: 1);
    }
    _px(5, 10, _gold, w: 10); // band
    _px(8, 5, _gold, w: 2, h: 2); // star
    _px(2, 11, _hatDark, w: 16); // brim
    _px(3, 11, _hat, w: 13);

    // ---- face + beard --------------------------------------------------
    _px(5, 12, _skin, w: 10, h: 3);
    _px(7, 13, _ink); // eyes (blink while sipping)
    _px(11, 13, _ink);
    if (sipping) {
      _px(7, 13, _skin);
      _px(11, 13, _skin);
      _px(7, 14, _ink);
      _px(11, 14, _ink);
    }
    final b = beardBob.toInt();
    _px(5, 15 + b, _beard, w: 10, h: 2);
    _px(6, 17 + b, _beard, w: 8, h: 2);
    _px(7, 19 + b, _beard, w: 6, h: 2);
    _px(8, 21 + b, _beard, w: 4, h: 1);
    _px(13, 15 + b, _beardShade, w: 1, h: 4);
    _px(5, 14, _beard, w: 2, h: 1);
    _px(13, 14, _beard, w: 2, h: 1);
    _px(9, 14, _skin, w: 2); // nose

    // ---- left arm (reaches for the cup) --------------------------------
    _line(5, 18, handPos.dx.toInt(), handPos.dy.toInt(), _hat);
    _px(handPos.dx, handPos.dy, _skin, w: 3, h: 2);

    // ---- sparkles + cup ------------------------------------------------
    if (summoning) {
      for (var k = 0; k < 9; k++) {
        final p = _seg(t, summonStart + k * 0.012, summonStart + 0.10 + k * 0.012);
        if (p <= 0 || p >= 1) continue;
        // Arc from the orb over to where the cup will appear.
        const from = Offset(19, 2), to = Offset(-2, 9);
        final pos = _lerpO(from, to, p) + Offset(0, -6 * sin(p * pi));
        _px(pos.dx, pos.dy, k.isEven ? _gold : _orb);
        if (p > 0.2 && p < 0.8) {
          final tail = _lerpO(from, to, p - 0.08) + Offset(0, -6 * sin((p - 0.08) * pi));
          _px(tail.dx, tail.dy, k.isEven ? _gold : _orb, a: 0.5);
        }
      }
    }
    if (vis > 0) _drawCup(cupPos, vis, sipping);
    if (fading || (t > summonEnd - 0.05 && t < summonEnd + 0.03)) {
      _burst(cupPos + const Offset(2, 2), (t - lowerEnd) * 20);
    }
  }

  void _drawCup(Offset p, double vis, bool sipping) {
    final x = p.dx, y = p.dy;
    // Materialize bottom-to-top (rows revealed by `vis`).
    final rows = (vis * 5).ceil();
    bool shown(int row) => (4 - row) < rows; // row 4 = bottom
    final partial = vis < 1 ? 0.75 : 1.0;
    void row(int r, void Function() draw) {
      if (shown(r)) draw();
    }

    // Dark outline so the cup reads on light backgrounds too.
    _px(x - 1, y + 4 - rows, _ink, w: 7, h: rows + 2, a: partial);

    row(0, () {
      _px(x, y, _cupWhite, w: 5, a: partial);
      _px(x + 1, y, _coffee, w: 3, a: partial); // coffee surface
    });
    row(1, () => _px(x, y + 1, _cupWhite, w: 5, a: partial));
    row(2, () => _px(x, y + 2, _cupWhite, w: 5, a: partial));
    row(3, () => _px(x + 1, y + 3, _cupShade, w: 4, a: partial));
    row(4, () => _px(x + 1, y + 4, _cupShade, w: 3, a: partial));
    // handle on the left
    if (shown(1)) _px(x - 1, y + 1, _cupShade, a: partial);
    if (shown(2)) _px(x - 2, y + 2, _cupShade, a: partial);
    if (shown(3)) _px(x - 1, y + 3, _cupShade, a: partial);
    _px(x + 3, y + 1, _cupShade, h: 2, a: partial); // shading

    // Steam.
    if (vis >= 1 && !sipping) {
      for (var k = 0; k < 3; k++) {
        final phase = (seconds * 0.9 + k * 0.33) % 1;
        final sx = x + 1 + k * 1.5 + sin(phase * pi * 2 + k) * 0.8;
        _px(sx, y - 2 - phase * 6, _steam, a: (1 - phase) * 0.8);
      }
    }
  }

  // A little ring of pixels flying outward.
  void _burst(Offset c, double k) {
    final kk = k.clamp(0.0, 1.0);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final r = 3 + kk * 5;
      _px(c.dx + cos(a) * r, c.dy + sin(a) * r, i.isEven ? _gold : _orb,
          a: 1 - kk * 0.7);
    }
  }

  @override
  bool shouldRepaint(covariant _WizardPainter old) =>
      old.t != t || old.scale != scale;
}
