import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import '../state/strings.dart';
import '../theme/app_theme.dart';

/// A pendant lamp hanging from the top of the screen. Pulling its chain
/// (tap, or drag down and release) toggles the light/dark theme: lamp on =
/// light theme, lamp off = dark theme.
class LampSwitch extends StatefulWidget {
  const LampSwitch({super.key, required this.onToggle});
  final VoidCallback onToggle;

  static const width = 56.0;
  static const height = 108.0;

  @override
  State<LampSwitch> createState() => _LampSwitchState();
}

class _LampSwitchState extends State<LampSwitch> with TickerProviderStateMixin {
  static const _maxPull = 18.0;

  late final AnimationController _down; // chain being pulled (tap only)
  late final AnimationController _spring; // chain springing back
  late final AnimationController _glow;
  double _pull = 0; // 0..1, how far the chain is pulled down
  double _pullFrom = 0;

  bool get _on => !AppSettings.instance.isDark;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      value: _on ? 1 : 0,
    );
    _down = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() {
        setState(() => _pull = Curves.easeOut.transform(_down.value));
      });
    _spring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() {
        setState(() {
          _pull = _pullFrom * (1 - Curves.elasticOut.transform(_spring.value));
        });
      });
    AppSettings.instance.addListener(_syncGlow);
  }

  void _syncGlow() {
    if (_on) {
      _glow.forward();
    } else {
      _glow.reverse();
    }
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_syncGlow);
    _down.dispose();
    _spring.dispose();
    _glow.dispose();
    super.dispose();
  }

  /// A plain click: pull the chain down slowly, flip the light at the
  /// bottom of the pull, then let the chain swing back.
  Future<void> _tap() async {
    if (_down.isAnimating || _spring.isAnimating) return;
    await _down.forward(from: 0);
    if (mounted) _release(toggle: true);
  }

  void _release({required bool toggle}) {
    _pullFrom = toggle ? 1 : _pull;
    _spring.forward(from: 0);
    if (toggle) widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: S.lampTooltip,
      child: Tooltip(
        message: S.lampTooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            onVerticalDragStart: (_) {
              _spring.stop();
              _down.stop();
            },
            onVerticalDragUpdate: (d) => setState(() {
              _pull = (_pull + d.delta.dy / _maxPull).clamp(0.0, 1.0);
            }),
            onVerticalDragEnd: (_) => _release(toggle: _pull > 0.6),
            // Flutter also fires "cancel" for a plain tap (drag rejected), so
            // only spring back if the chain was actually being dragged.
            onVerticalDragCancel: () {
              if (_pull > 0 && !_down.isAnimating) _release(toggle: false);
            },
            child: AnimatedBuilder(
              animation: _glow,
              builder: (context, _) => CustomPaint(
                size: const Size(LampSwitch.width, LampSwitch.height),
                painter: _LampPainter(
                  glow: _glow.value,
                  pull: _pull * _maxPull,
                  cord: AppColors.textDim,
                  shade: AppColors.magenta,
                  outline: AppColors.border,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LampPainter extends CustomPainter {
  _LampPainter({
    required this.glow,
    required this.pull,
    required this.cord,
    required this.shade,
    required this.outline,
  });
  final double glow; // 0 = off, 1 = on
  final double pull; // pixels the chain is pulled down
  final Color cord, shade, outline;

  @override
  void paint(Canvas canvas, Size size) {
    const cx = 24.0;
    final line = Paint()
      ..color = cord
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Warm halo, only visible when the lamp is on.
    if (glow > 0) {
      final halo = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFCD3C).withOpacity(0.55 * glow),
            const Color(0xFFFFCD3C).withOpacity(0),
          ],
        ).createShader(
            Rect.fromCircle(center: const Offset(cx, 40), radius: 54));
      canvas.drawCircle(const Offset(cx, 40), 54, halo);
    }

    // Power cord from the ceiling.
    canvas.drawLine(const Offset(cx, 0), const Offset(cx, 14), line);

    // Bulb (drawn before the shade so the shade overlaps its top).
    final bulbColor =
        Color.lerp(const Color(0xFF6F6390), const Color(0xFFFFE27A), glow)!;
    canvas.drawCircle(const Offset(cx, 38), 7, Paint()..color = bulbColor);
    if (glow > 0) {
      canvas.drawCircle(
        const Offset(cx, 38),
        7,
        Paint()
          ..color = Colors.white.withOpacity(0.7 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Shade.
    final shadePath = Path()
      ..moveTo(cx - 8, 14)
      ..lineTo(cx + 8, 14)
      ..lineTo(cx + 20, 36)
      ..lineTo(cx - 20, 36)
      ..close();
    canvas.drawPath(shadePath, Paint()..color = shade);
    canvas.drawPath(
      shadePath,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Pull chain: little beads hanging from the shade's edge, with a handle.
    const chainX = cx + 16;
    final endY = 62 + pull;
    canvas.drawLine(const Offset(chainX, 34), Offset(chainX, endY), line);
    final bead = Paint()..color = cord;
    for (double y = 40; y < endY; y += 6) {
      canvas.drawCircle(Offset(chainX, y), 1.6, bead);
    }
    canvas.drawCircle(
        Offset(chainX, endY + 4), 5, Paint()..color = const Color(0xFFFFCD3C));
    canvas.drawCircle(
      Offset(chainX, endY + 4),
      5,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _LampPainter old) =>
      old.glow != glow ||
      old.pull != pull ||
      old.cord != cord ||
      old.shade != shade ||
      old.outline != outline;
}
