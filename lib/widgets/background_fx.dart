import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';

class _Star {
  _Star(this.x, this.y, this.radius, this.speed, this.phase);
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
}

/// Animated starfield + CRT scanline overlay used behind the whole app.
/// Purely decorative — sits behind everything via a [Positioned.fill].
///
/// Performance notes: the starfield lives in its own repaint boundary and is
/// driven by a [ValueNotifier] (no widget rebuilds), throttled to ~30 fps;
/// the static scanlines get their own boundary so they are rasterized once.
class BackgroundFx extends StatefulWidget {
  const BackgroundFx({super.key});

  @override
  State<BackgroundFx> createState() => _BackgroundFxState();
}

class _BackgroundFxState extends State<BackgroundFx>
    with SingleTickerProviderStateMixin {
  static const _frameGapMs = 33;

  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);
  int _lastFrameMs = -_frameGapMs;
  final _random = Random();
  List<_Star> _stars = [];
  Size _lastSize = Size.zero;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final ms = elapsed.inMilliseconds;
      if (ms - _lastFrameMs < _frameGapMs) return;
      _lastFrameMs = ms;
      _time.value = ms / 1000.0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) {
      _ticker.stop();
      _time.value = 0;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  void _ensureStars(Size size) {
    if (size == _lastSize && _stars.isNotEmpty) return;
    _lastSize = size;
    final count = ((size.width * size.height) / 12000).clamp(30, 140).round();
    _stars = List.generate(count, (_) {
      return _Star(
        _random.nextDouble() * size.width,
        _random.nextDouble() * size.height,
        _random.nextDouble() * 1.4 + 0.4,
        _random.nextDouble() * 18 + 4,
        _random.nextDouble() * pi * 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppSettings.instance.isDark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 400,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 800,
        );
        _ensureStars(size);
        return Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: AppColors.bg)),
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _StarfieldPainter(
                    _stars,
                    _time,
                    color: AppColors.text,
                    dim: dark ? 1 : 0.35,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _ScanlinesPainter(dark: dark),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter(
    this.stars,
    this.time, {
    required this.color,
    required this.dim,
  }) : super(repaint: time);

  final List<_Star> stars;
  final ValueNotifier<double> time;
  final Color color;
  final double dim;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final paint = Paint();
    for (final star in stars) {
      final y = (star.y + t * star.speed) % size.height;
      final twinkle = (0.5 + 0.3 * sin(t + star.phase)).clamp(0.15, 0.9);
      paint.color = color.withOpacity(twinkle * dim);
      canvas.drawCircle(Offset(star.x, y), star.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) =>
      old.stars != stars || old.color != color || old.dim != dim;
}

class _ScanlinesPainter extends CustomPainter {
  _ScanlinesPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (dark ? Colors.white : Colors.black).withOpacity(0.025)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter old) => old.dark != dark;
}
