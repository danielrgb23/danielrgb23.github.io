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
class BackgroundFx extends StatefulWidget {
  const BackgroundFx({super.key});

  @override
  State<BackgroundFx> createState() => _BackgroundFxState();
}

class _BackgroundFxState extends State<BackgroundFx>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  final _random = Random();
  List<_Star> _stars = [];
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) setState(() => _elapsed = elapsed);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureStars(Size size) {
    if (size == _lastSize && _stars.isNotEmpty) return;
    _lastSize = size;
    final count = ((size.width * size.height) / 9000).clamp(30, 220).round();
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 400,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 800,
        );
        _ensureStars(size);
        final t = reduceMotion ? 0.0 : _elapsed.inMilliseconds / 1000.0;
        return Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: AppColors.bg)),
            Positioned.fill(
              child: CustomPaint(painter: _StarfieldPainter(_stars, t)),
            ),
            const Positioned.fill(child: IgnorePointer(child: _Scanlines())),
          ],
        );
      },
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter(this.stars, this.elapsedSeconds);
  final List<_Star> stars;
  final double elapsedSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      final y = (star.y + elapsedSeconds * star.speed) % size.height;
      final twinkle = (0.5 + 0.3 * sin(elapsedSeconds + star.phase)).clamp(
        0.15,
        0.9,
      );
      paint.color = AppColors.text.withOpacity(
        AppSettings.instance.isDark ? twinkle : twinkle * 0.35,
      );
      canvas.drawCircle(Offset(star.x, y), star.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => true;
}

class _Scanlines extends StatelessWidget {
  const _Scanlines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScanlinesPainter(), size: Size.infinite);
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (AppSettings.instance.isDark ? Colors.white : Colors.black)
          .withOpacity(0.025)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter oldDelegate) => false;
}
