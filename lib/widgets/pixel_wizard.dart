import 'dart:math';
import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import '../state/strings.dart';
import 'wizard_speech.dart';

/// A pixel-art wizard that loops: raises a hand, summons a cup of coffee
/// with his staff, catches it, takes a few sips, then dissolves the cup.
///
/// Tap the coffee or the staff to "steal" it and see how he reacts:
///  * coffee: he panics, gets furious and casts a spell that switches the
///    site to the light theme and the other language;
///  * staff: he looks puzzled, then conjures a brand-new one.
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

enum _Mode { loop, coffee, staff }

class _PixelWizardState extends State<PixelWizard>
    with TickerProviderStateMixin {
  static const _loopSeconds = 11;
  static const _reactSeconds = 7;

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _loopSeconds),
  );
  late final AnimationController _react = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _reactSeconds),
  )
    ..addListener(_onReact)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _endReaction();
    });
  final _clock = Stopwatch()..start();

  _Mode _mode = _Mode.loop;
  double _frozenT = 0;
  bool _fired = false;
  bool _spoke = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_mode != _Mode.loop) return;
    if (_reduceMotion) {
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
    _react.dispose();
    super.dispose();
  }

  void _start(_Mode mode) {
    if (_mode != _Mode.loop) return;
    setState(() {
      _mode = mode;
      _frozenT = _loop.value;
      _fired = false;
      _spoke = false;
    });
    _loop.stop();
    _react.forward(from: 0);
  }

  void _endReaction() {
    if (!mounted) return;
    setState(() => _mode = _Mode.loop);
    if (_reduceMotion) {
      _loop.value = 0.66;
    } else {
      _loop.forward(from: 0);
      _loop.repeat();
    }
  }

  void _onReact() {
    final rt = _react.value;
    if (_mode == _Mode.coffee) {
      if (!_fired && rt >= _WizardPainter.coffeeSpellAt) {
        _fired = true;
        // The spell: light theme + the other language, in one rebuild.
        final s = AppSettings.instance;
        s.apply(dark: false, lang: s.isEn ? AppLang.pt : AppLang.en);
      }
      if (!_spoke && rt >= _WizardPainter.coffeeSpellAt + 0.03) {
        _spoke = true;
        WizardSpeech.show(context, S.wizardCoffee);
      }
    } else if (_mode == _Mode.staff) {
      if (!_spoke && rt >= _WizardPainter.staffSpeakAt) {
        _spoke = true;
        WizardSpeech.show(context, S.wizardStaff);
      }
    }
  }

  void _onTapDown(TapDownDetails d) {
    final s = widget.scale;
    final x = d.localPosition.dx / s - 6; // sprite space
    if (x >= 16) {
      _start(_Mode.staff);
    } else if (_cupAt(_loop.value).vis > 0.6) {
      _start(_Mode.coffee);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      label: S.wizardHint,
      button: true,
      child: Tooltip(
        message: S.wizardHint,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _onTapDown,
            child: SizedBox(
              width: PixelWizard.gridW * s,
              height: PixelWizard.gridH * s,
              child: AnimatedBuilder(
                animation: Listenable.merge([_loop, _react]),
                builder: (context, _) => CustomPaint(
                  painter: _WizardPainter(
                    t: _mode == _Mode.loop ? _loop.value : _frozenT,
                    seconds: _clock.elapsedMilliseconds / 1000,
                    scale: s,
                    mode: _mode,
                    rt: _react.value,
                  ),
                ),
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
const _angrySkin = Color(0xFFE0524A);
const _beard = Color(0xFFEDEDED);
const _beardShade = Color(0xFFBDB6D0);
const _ink = Color(0xFF1B0B3A);
const _wood = Color(0xFF8B5A2B);
const _woodLight = Color(0xFFB57C3E);
const _orb = Color(0xFF2DE2FF);
const _rage = Color(0xFFFF3CAA);
const _boots = Color(0xFF2A1A55);
const _cupWhite = Color(0xFFF7F1E5);
const _cupShade = Color(0xFFCFC3AE);
const _coffee = Color(0xFF6B3A1E);
const _steam = Color(0xFFE9E2F7);

// --- loop timeline ----------------------------------------------------------
const _summonStart = 0.12, _summonEnd = 0.30;
const _catchEnd = 0.42, _liftEnd = 0.56, _sipEnd = 0.76;
const _lowerEnd = 0.86, _fadeEnd = 0.95;

const _hover = Offset(-4, 7);
const _held = Offset(-4, 17);
const _mouth = Offset(1, 12);
const _restHand = Offset(2, 25);
const _raisedHand = Offset(-3, 14);

double _seg(double v, double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);
double _lerp(double a, double b, double k) => a + (b - a) * k;
Offset _lerpO(Offset a, Offset b, double k) =>
    Offset(_lerp(a.dx, b.dx, k), _lerp(a.dy, b.dy, k));
Offset _round(Offset o) => Offset(o.dx.roundToDouble(), o.dy.roundToDouble());

/// Everything about the coffee cup at loop time [t].
class _Cup {
  const _Cup(this.pos, this.vis, this.sipping);
  final Offset pos; // top-left, sprite space
  final double vis; // 0..1: how much of it has materialized
  final bool sipping;
}

_Cup _cupAt(double t) {
  var cup = _hover;
  var vis = 0.0;
  var sipping = false;
  if (t >= _summonStart && t < _fadeEnd) {
    if (t < _summonEnd) {
      vis = _seg(t, _summonStart + 0.03, _summonEnd);
    } else if (t < _catchEnd) {
      vis = 1;
      cup = _lerpO(_hover, _held,
          Curves.easeInOut.transform(_seg(t, _summonEnd, _catchEnd)));
    } else if (t < _liftEnd) {
      vis = 1;
      cup = _lerpO(_held, _mouth,
          Curves.easeInOut.transform(_seg(t, _catchEnd, _liftEnd)));
    } else if (t < _sipEnd) {
      vis = 1;
      sipping = true;
      // Three gulps: the cup tips up a pixel and comes back.
      final k = _seg(t, _liftEnd, _sipEnd);
      cup = _mouth + Offset(0, sin(k * pi * 6) > 0.35 ? -1.0 : 0.0);
    } else if (t < _lowerEnd) {
      vis = 1;
      cup = _lerpO(_mouth, _held,
          Curves.easeInOut.transform(_seg(t, _sipEnd, _lowerEnd)));
    } else {
      vis = 1 - _seg(t, _lowerEnd, _fadeEnd);
      cup = _held;
    }
  }
  return _Cup(_round(cup), vis, sipping);
}

/// Position of the left hand (the one that reaches for the cup).
Offset _handAt(double t, _Cup cup, double seconds) {
  final cupHand = Offset(cup.pos.dx + 1, cup.pos.dy + 5);
  final holding = t >= _catchEnd - 0.04 && t < _lowerEnd + 0.03;
  Offset hand;
  if (t < _summonStart) {
    hand = _restHand;
  } else if (t < _summonStart + 0.07) {
    hand = _lerpO(_restHand, _raisedHand,
        Curves.easeOut.transform(_seg(t, _summonStart, _summonStart + 0.07)));
  } else if (t < _summonEnd + 0.02) {
    hand = _raisedHand + Offset(0, sin(seconds * 9) > 0 ? -1 : 0);
  } else if (holding) {
    hand = t >= _catchEnd - 0.04
        ? cupHand
        : _lerpO(_raisedHand, cupHand,
            Curves.easeOut.transform(_seg(t, _summonEnd + 0.02, _catchEnd - 0.04)));
  } else {
    hand = _lerpO(cupHand, _restHand,
        Curves.easeInOut.transform(_seg(t, _lowerEnd + 0.03, _fadeEnd + 0.03)));
  }
  return _round(hand);
}

class _WizardPainter extends CustomPainter {
  _WizardPainter({
    required this.t,
    required this.seconds,
    required this.scale,
    required this.mode,
    required this.rt,
  });
  final double t; // position in the idle loop (frozen during a reaction)
  final double seconds; // free-running clock, for steam/pulses
  final double scale;
  final _Mode mode;
  final double rt; // 0..1 progress of the current reaction

  // Reaction beats, as fractions of the reaction.
  static const coffeeSpellAt = 0.42;
  static const staffSpeakAt = 0.62;

  late Canvas _c;
  final _paint = Paint()..isAntiAlias = false;

  // Draws one rect in sprite space (pixel grid units).
  void _px(num x, num y, Color color, {num w = 1, num h = 1, double a = 1}) {
    _paint.color = color.withOpacity(a.clamp(0.0, 1.0));
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

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    canvas.translate(6 * scale, 0); // sprite x=0 sits 6 pixels from the left

    final coffee = mode == _Mode.coffee;
    final staff = mode == _Mode.staff;
    final cup = _cupAt(t);
    final hand = _handAt(t, cup, seconds);

    // ---- reaction state -------------------------------------------------
    var bodyDx = 0.0, bodyDy = 0.0;
    var angry = 0.0;
    var wideEyes = false;
    var exclaim = false, question = false;
    var cupFly = 0.0; // 0 = in hand, 1 = gone
    var staffFly = 0.0;
    var staffVis = 1.0; // fraction of the staff that exists
    var rightHandY = 21.0;
    var flash = 0.0;

    if (coffee) {
      cupFly = _seg(rt, 0, 0.10);
      final bump = _seg(rt, 0.10, 0.20);
      if (bump > 0 && bump < 1) bodyDy = -2 * sin(bump * pi);
      wideEyes = rt >= 0.10 && rt < 0.26;
      exclaim = rt >= 0.10 && rt < 0.40 && (seconds * 6).floor().isEven;
      angry = _seg(rt, 0.22, 0.40) * (1 - _seg(rt, 0.85, 1.0));
      if (angry > 0.5 && rt < 0.80) {
        bodyDx = (seconds * 28).floor().isEven ? 1 : -1;
      }
      // Casting pose: staff hand pumps up around the spell.
      if (rt >= coffeeSpellAt - 0.06 && rt < 0.62) rightHandY = 17;
      flash = (rt >= coffeeSpellAt - 0.04 && rt < coffeeSpellAt + 0.08) ? 1 : 0;
    } else if (staff) {
      // Only the old staff flies away; the conjured one appears in place.
      staffFly = rt < 0.12 ? _seg(rt, 0, 0.12) : 0;
      staffVis = rt < 0.12 ? 1 : (rt < 0.45 ? 0 : _seg(rt, 0.45, 0.66));
      question = rt >= 0.12 && rt < 0.42 && (seconds * 5).floor().isEven;
      wideEyes = rt >= 0.02 && rt < 0.14;
      if (rt >= 0.30 && rt < 0.72) rightHandY = 16;
      flash = (rt >= 0.62 && rt < 0.74) ? 1 : 0;
    }

    canvas.save();
    canvas.translate(bodyDx * scale, bodyDy * scale);

    // ---- orb + staff glow ---------------------------------------------
    final summoning = mode == _Mode.loop && t >= _summonStart && t < _summonEnd;
    final fading = mode == _Mode.loop && t >= _lowerEnd && t < _fadeEnd;
    final pulse = 0.5 + 0.5 * sin(seconds * 3);
    final orbColor = Color.lerp(_orb, _rage, angry)!;
    final orbFlash = (summoning || fading) ? 1.0 : flash;
    final staffAlpha = staff ? (1 - staffFly) : 1.0;
    final staffOff = staff
        ? Offset(7 * Curves.easeIn.transform(staffFly),
            -34 * Curves.easeIn.transform(staffFly))
        : Offset.zero;
    final orbVisible = !staff || staffVis > 0.9 || rt < 0.12;
    if (orbVisible) {
      canvas.drawCircle(
        Offset((20 + staffOff.dx) * scale, (3 + staffOff.dy) * scale),
        (5 + 3 * pulse + 4 * orbFlash + 3 * angry) * scale,
        Paint()
          ..color = orbColor.withOpacity(
            ((0.25 + 0.25 * pulse + 0.25 * orbFlash + 0.2 * angry) * staffAlpha)
                .clamp(0.0, 1.0),
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale * 3),
      );
    }

    // ---- staff ---------------------------------------------------------
    if (staffVis > 0) {
      final sx = staffOff.dx, sy = staffOff.dy;
      // While conjuring, the shaft grows upward from the ground.
      final grown = staff && rt >= 0.45 && staffVis < 1;
      final shaftH = grown ? (29 * staffVis).round() : 29;
      final shaftTop = 34 - shaftH;
      _px(19 + sx, shaftTop + sy, _wood, w: 2, h: shaftH, a: staffAlpha);
      _px(19 + sx, shaftTop + sy, _woodLight, w: 1, h: shaftH, a: staffAlpha);
      if (orbVisible) {
        _px(18 + sx, 1 + sy, orbColor, w: 4, h: 4, a: staffAlpha);
        _px(18 + sx, 1 + sy, Colors.white, a: 0.9 * staffAlpha);
        _px(17 + sx, 5 + sy, _wood, a: staffAlpha);
        _px(22 + sx, 5 + sy, _wood, a: staffAlpha);
      }
    }

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
    _px(3, 32, _boots, w: 5, h: 2);
    _px(12, 32, _boots, w: 5, h: 2);

    // ---- right arm (staff hand) -----------------------------------------
    _line(14, 18, 18, rightHandY.toInt(), _hat);
    _px(18, rightHandY, _skin, w: 3, h: 2);

    // ---- hat -----------------------------------------------------------
    for (var y = 0; y <= 9; y++) {
      final half = y ~/ 2 + 1;
      _px(9 - half + 1, y, _hat, w: half * 2);
      _px(9 + half - 1, y, _hatDark);
    }
    _px(5, 10, _gold, w: 10); // band
    _px(8, 5, _gold, w: 2, h: 2); // star
    _px(2, 11, _hatDark, w: 16); // brim
    _px(3, 11, _hat, w: 13);

    // ---- face + beard --------------------------------------------------
    final skin = Color.lerp(_skin, _angrySkin, angry)!;
    _px(5, 12, skin, w: 10, h: 3);
    final sipping = mode == _Mode.loop && cup.sipping;
    if (wideEyes) {
      _px(6, 12, Colors.white, w: 2, h: 2);
      _px(11, 12, Colors.white, w: 2, h: 2);
      _px(7, 13, _ink);
      _px(11, 13, _ink);
    } else if (angry > 0.4) {
      _px(7, 13, _ink);
      _px(11, 13, _ink);
      _px(6, 12, _ink, w: 2); // slanted brows
      _px(8, 13, _ink);
      _px(12, 12, _ink);
      _px(11, 12, _ink);
      _px(10, 13, _ink);
    } else if (sipping) {
      _px(7, 14, _ink); // eyes closed while sipping
      _px(11, 14, _ink);
    } else {
      _px(7, 13, _ink);
      _px(11, 13, _ink);
    }
    final gulp = sipping && sin(_seg(t, _liftEnd, _sipEnd) * pi * 6) > 0.35;
    final b = gulp ? 1 : 0;
    _px(5, 15 + b, _beard, w: 10, h: 2);
    _px(6, 17 + b, _beard, w: 8, h: 2);
    _px(7, 19 + b, _beard, w: 6, h: 2);
    _px(8, 21 + b, _beard, w: 4);
    _px(13, 15 + b, _beardShade, h: 4);
    _px(5, 14, _beard, w: 2);
    _px(13, 14, _beard, w: 2);
    _px(9, 14, skin, w: 2); // nose

    // ---- left arm (reaches for the cup) --------------------------------
    _line(5, 18, hand.dx.toInt(), hand.dy.toInt(), _hat);
    _px(hand.dx, hand.dy, _skin, w: 3, h: 2);

    // ---- emotes -----------------------------------------------------------
    if (exclaim) {
      _px(14, 0, _gold, w: 2, h: 4);
      _px(14, 5, _gold, w: 2, h: 2);
    }
    if (question) {
      _px(14, 0, _gold, w: 3);
      _px(16, 1, _gold, h: 2);
      _px(15, 3, _gold, w: 2);
      _px(14, 4, _gold);
      _px(14, 6, _gold);
    }

    // ---- effects ---------------------------------------------------------
    if (summoning) _summonSparkles();
    if (coffee) _coffeeEffects(cup, cupFly, angry);
    if (staff) _staffEffects();

    // ---- cup (idle loop) -----------------------------------------------
    if (!coffee || cupFly < 1) {
      final fly = Curves.easeIn.transform(cupFly);
      final pos = cup.pos + Offset(-26 * fly, -20 * fly);
      if (cup.vis > 0) {
        _drawCup(_round(pos), cup.vis, sipping, alpha: 1 - cupFly);
      }
    }
    if (fading || (mode == _Mode.loop && t > _summonEnd - 0.05 && t < _summonEnd + 0.03)) {
      _burst(cup.pos + const Offset(2, 2), (t - _lowerEnd) * 20);
    }

    canvas.restore();
  }

  void _summonSparkles() {
    for (var k = 0; k < 9; k++) {
      final p = _seg(t, _summonStart + k * 0.012, _summonStart + 0.10 + k * 0.012);
      if (p <= 0 || p >= 1) continue;
      // Arc from the orb over to where the cup will appear.
      const from = Offset(19, 2), to = Offset(-2, 9);
      final pos = _lerpO(from, to, p) + Offset(0, -6 * sin(p * pi));
      final color = k.isEven ? _gold : _orb;
      _px(pos.dx, pos.dy, color);
      if (p > 0.2 && p < 0.8) {
        final tail = _lerpO(from, to, p - 0.08) + Offset(0, -6 * sin((p - 0.08) * pi));
        _px(tail.dx, tail.dy, color, a: 0.5);
      }
    }
  }

  void _coffeeEffects(_Cup cup, double cupFly, double angry) {
    // Little smoke puff where the cup was snatched from.
    if (rt > 0.06 && rt < 0.22) {
      final k = _seg(rt, 0.06, 0.22);
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3 + 0.4;
        _px(cup.pos.dx + 2 + cos(a) * (2 + 5 * k), cup.pos.dy + 2 + sin(a) * (2 + 5 * k),
            _steam, a: 1 - k);
      }
    }
    // Rage sparks crackling around the orb, then the spell burst.
    if (angry > 0.3 && rt < 0.85) {
      final n = (seconds * 18).floor();
      for (var i = 0; i < 7; i++) {
        final h = (n * 31 + i * 17) % 100 / 100.0;
        final a = (n + i * 53) % 360 * pi / 180;
        final r = 3 + h * 7;
        _px(20 + cos(a) * r, 3 + sin(a) * r, i.isEven ? _rage : _gold);
      }
    }
    if (rt >= coffeeSpellAt - 0.02 && rt < coffeeSpellAt + 0.12) {
      _burst(const Offset(20, 3), _seg(rt, coffeeSpellAt - 0.02, coffeeSpellAt + 0.12), radius: 12);
    }
  }

  void _staffEffects() {
    // Whoosh trail while the staff is taken away.
    if (rt < 0.14) {
      final k = _seg(rt, 0, 0.14);
      for (var i = 1; i <= 4; i++) {
        final kk = (k - i * 0.05).clamp(0.0, 1.0);
        final e = Curves.easeIn.transform(kk);
        _px(19 + 7 * e, 12 - 34 * e + 8, _orb, a: (1 - i / 5) * (1 - k));
      }
    }
    // Sparkles spiral in around the empty hand, then the new staff appears.
    if (rt >= 0.30 && rt < 0.66) {
      final k = _seg(rt, 0.30, 0.66);
      for (var i = 0; i < 10; i++) {
        final a = seconds * 6 + i * pi / 5;
        final r = 9 * (1 - k) + 1;
        _px(19.5 + cos(a) * r, 24 + sin(a) * r * 1.3, i.isEven ? _gold : _orb);
      }
    }
    if (rt >= 0.62 && rt < 0.76) {
      _burst(const Offset(20, 3), _seg(rt, 0.62, 0.76), radius: 10);
    }
  }

  void _drawCup(Offset p, double vis, bool sipping, {double alpha = 1}) {
    final x = p.dx, y = p.dy;
    // Materialize bottom-to-top (rows revealed by `vis`).
    final rows = (vis * 5).ceil();
    bool shown(int row) => (4 - row) < rows; // row 4 = bottom
    final a = (vis < 1 ? 0.75 : 1.0) * alpha;

    // Dark outline so the cup reads on light backgrounds too.
    _px(x - 1, y + 4 - rows, _ink, w: 7, h: rows + 2, a: a);

    if (shown(0)) {
      _px(x, y, _cupWhite, w: 5, a: a);
      _px(x + 1, y, _coffee, w: 3, a: a); // coffee surface
    }
    if (shown(1)) _px(x, y + 1, _cupWhite, w: 5, a: a);
    if (shown(2)) _px(x, y + 2, _cupWhite, w: 5, a: a);
    if (shown(3)) _px(x + 1, y + 3, _cupShade, w: 4, a: a);
    if (shown(4)) _px(x + 1, y + 4, _cupShade, w: 3, a: a);
    // handle on the left
    if (shown(1)) _px(x - 1, y + 1, _cupShade, a: a);
    if (shown(2)) _px(x - 2, y + 2, _cupShade, a: a);
    if (shown(3)) _px(x - 1, y + 3, _cupShade, a: a);
    _px(x + 3, y + 1, _cupShade, h: 2, a: a); // shading

    // Steam.
    if (vis >= 1 && !sipping) {
      for (var k = 0; k < 3; k++) {
        final phase = (seconds * 0.9 + k * 0.33) % 1;
        final sx = x + 1 + k * 1.5 + sin(phase * pi * 2 + k) * 0.8;
        _px(sx, y - 2 - phase * 6, _steam, a: (1 - phase) * 0.8 * alpha);
      }
    }
  }

  // A little ring of pixels flying outward.
  void _burst(Offset c, double k, {double radius = 5}) {
    final kk = k.clamp(0.0, 1.0);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final r = 3 + kk * radius;
      _px(c.dx + cos(a) * r, c.dy + sin(a) * r, i.isEven ? _gold : _orb,
          a: 1 - kk * 0.7);
    }
  }

  @override
  bool shouldRepaint(covariant _WizardPainter old) => true;
}
