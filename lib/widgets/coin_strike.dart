import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The wizard's revenge: a magic bolt flies from his staff to the coin
/// counter, strikes it, and the coins tumble down the screen, bouncing on
/// the bottom edge before fading away.
///
/// Rendered in an [OverlayEntry] above the whole page (same approach as
/// `AchievementToast`); pointer events pass through it.
class CoinStrike {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required Offset from,
    required Offset to,
    required int coins,
    VoidCallback? onImpact,
  }) {
    _entry?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _StrikeLayer(
        key: const ValueKey('coin-strike'),
        from: from,
        to: to,
        coins: coins,
        onImpact: onImpact,
        onDone: () {
          if (entry.mounted) entry.remove();
          if (identical(_entry, entry)) _entry = null;
        },
      ),
    );
    _entry = entry;
    Overlay.of(context).insert(entry);
  }
}

class _FallingCoin {
  _FallingCoin(this.pos, this.vel, this.spin, this.phase);
  Offset pos;
  Offset vel;
  final double spin; // radians / second
  double phase;
  int bounces = 0;
}

class _StrikeLayer extends StatefulWidget {
  const _StrikeLayer({
    super.key,
    required this.from,
    required this.to,
    required this.coins,
    required this.onImpact,
    required this.onDone,
  });

  final Offset from, to;
  final int coins;
  final VoidCallback? onImpact;
  final VoidCallback onDone;

  @override
  State<_StrikeLayer> createState() => _StrikeLayerState();
}

class _StrikeLayerState extends State<_StrikeLayer>
    with SingleTickerProviderStateMixin {
  // Timeline, in seconds.
  static const _travel = 0.45; // the bolt reaches the counter
  static const _impact = 0.5; // coins are hit and start to fall
  static const _boltFade = 0.85; // bolt fully gone
  static const _life = 2.8; // coins live this long after impact
  static const _gravity = 1900.0;

  late final Ticker _ticker;
  final _random = Random(7);
  final _coins = <_FallingCoin>[];
  var _t = 0.0;
  var _last = 0.0;
  var _hit = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _spawnCoins() {
    final n = widget.coins.clamp(1, 16);
    for (var i = 0; i < n; i++) {
      _coins.add(_FallingCoin(
        widget.to + Offset(_random.nextDouble() * 12 - 6, 0),
        Offset(
            _random.nextDouble() * 420 - 120, -_random.nextDouble() * 520 - 80),
        (_random.nextDouble() * 10 + 6) * (_random.nextBool() ? 1 : -1),
        _random.nextDouble() * pi * 2,
      ));
    }
  }

  void _tick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - _last).clamp(0.0, 0.05);
    _last = now;
    _t = now;

    if (!_hit && _t >= _impact) {
      _hit = true;
      _spawnCoins();
      widget.onImpact?.call();
    }
    if (_hit) {
      final size = MediaQuery.of(context).size;
      final floor = size.height - 14;
      for (final c in _coins) {
        c.vel += Offset(0, _gravity * dt);
        c.pos += c.vel * dt;
        c.phase += c.spin * dt;
        if (c.pos.dy > floor) {
          c.pos = Offset(c.pos.dx, floor);
          c.vel = Offset(c.vel.dx * 0.8, -c.vel.dy * 0.5);
          c.bounces++;
        }
        if (c.pos.dx < 8 || c.pos.dx > size.width - 8) {
          c.pos = Offset(c.pos.dx.clamp(8.0, size.width - 8), c.pos.dy);
          c.vel = Offset(-c.vel.dx * 0.6, c.vel.dy);
        }
      }
    }
    setState(() {});
    if (_t > _impact + _life) {
      _ticker.stop();
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _StrikePainter(
            from: widget.from,
            to: widget.to,
            t: _t,
            coins: _coins,
            fade: _hit
                ? (1 - ((_t - _impact - (_life - 0.7)) / 0.7)).clamp(0.0, 1.0)
                : 1,
          ),
        ),
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  _StrikePainter({
    required this.from,
    required this.to,
    required this.t,
    required this.coins,
    required this.fade,
  });

  final Offset from, to;
  final double t;
  final List<_FallingCoin> coins;
  final double fade;

  static const _magenta = Color(0xFFFF3CAA);
  static const _cyan = Color(0xFF2DE2FF);
  static const _gold = Color(0xFFFFCD3C);
  static const _goldDark = Color(0xFFC98A00);

  @override
  void paint(Canvas canvas, Size size) {
    _paintBolt(canvas);
    _paintImpact(canvas);
    _paintCoins(canvas);
  }

  void _paintBolt(Canvas canvas) {
    const travel = _StrikeLayerState._travel;
    const fadeEnd = _StrikeLayerState._boltFade;
    if (t >= fadeEnd) return;
    final head = (t / travel).clamp(0.0, 1.0);
    final alpha = t < travel ? 1.0 : 1 - (t - travel) / (fadeEnd - travel);

    // Jagged path that re-rolls ~20 times a second, so it crackles.
    final seed = (t * 20).floor();
    final rnd = Random(seed * 97 + 3);
    final dir = to - from;
    final len = dir.distance;
    final normal = Offset(-dir.dy, dir.dx) / (len == 0 ? 1 : len);
    const segments = 16;
    final path = Path()..moveTo(from.dx, from.dy);
    for (var i = 1; i <= segments; i++) {
      final k = i / segments;
      if (k > head) break;
      final jitter = (i == segments ? 0.0 : (rnd.nextDouble() - 0.5) * 34);
      final p = from + dir * k + normal * jitter;
      path.lineTo(p.dx, p.dy);
    }
    if (head < 1) {
      final tip = from + dir * head;
      path.lineTo(tip.dx, tip.dy);
    }

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeJoin = StrokeJoin.round
      ..color = _magenta.withOpacity(0.35 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final mid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..color = _cyan.withOpacity(alpha);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(alpha);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, mid);
    canvas.drawPath(path, core);

    // Glowing head while it travels.
    if (t < travel) {
      final tip = from + dir * head;
      canvas.drawCircle(
        tip,
        10,
        Paint()
          ..color = _magenta.withOpacity(0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(tip, 4, Paint()..color = Colors.white);
    }
  }

  void _paintImpact(Canvas canvas) {
    const impact = _StrikeLayerState._impact;
    final k = (t - impact) / 0.45;
    if (k < 0 || k > 1) return;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _gold.withOpacity(1 - k);
    canvas.drawCircle(to, 8 + 46 * Curves.easeOut.transform(k), ring);
    canvas.drawCircle(
      to,
      16 * (1 - k),
      Paint()
        ..color = Colors.white.withOpacity(1 - k)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Gold pixels flying out.
    final px = Paint()..isAntiAlias = false;
    for (var i = 0; i < 10; i++) {
      final a = i * 2 * pi / 10;
      final r = 10 + 60 * Curves.easeOut.transform(k);
      px.color = (i.isEven ? _gold : Colors.white).withOpacity(1 - k);
      canvas.drawRect(
        Rect.fromCenter(
            center: to + Offset(cos(a), sin(a)) * r, width: 5, height: 5),
        px,
      );
    }
  }

  void _paintCoins(Canvas canvas) {
    for (final c in coins) {
      // A spinning coin: its width follows |cos(phase)|.
      final w = 8 + 8 * cos(c.phase).abs();
      final rect = Rect.fromCenter(center: c.pos, width: w, height: 16);
      canvas.drawOval(
        rect.inflate(2),
        Paint()..color = const Color(0xFF1B0B3A).withOpacity(fade),
      );
      canvas.drawOval(rect, Paint()..color = _goldDark.withOpacity(fade));
      canvas.drawOval(
        rect.deflate(2),
        Paint()..color = _gold.withOpacity(fade),
      );
      if (w > 11) {
        canvas.drawRect(
          Rect.fromCenter(center: c.pos.translate(-1, -2), width: 3, height: 3),
          Paint()..color = const Color(0xFFFFF3B8).withOpacity(fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrikePainter old) => true;
}
