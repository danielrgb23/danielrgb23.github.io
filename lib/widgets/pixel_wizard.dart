import 'dart:math';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import '../state/game_state.dart';
import '../state/strings.dart';
import 'coin_strike.dart';
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

enum _Mode { loop, grab, coffee, staff }

enum _Item { cup, staff }

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
  // Springs a half-dragged item back to the wizard.
  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )
    ..addListener(() {
      setState(() {
        _dragOff = _snapFrom *
            (1 - Curves.elasticOut.transform(_snap.value)).clamp(-1.0, 1.0);
      });
    })
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _endReaction();
    });
  final _clock = Stopwatch()..start();

  _Mode _mode = _Mode.loop;
  double _frozenT = 0;
  bool _fired = false;
  bool _spoke = false;
  bool _reduceMotion = false;

  _Item? _dragItem; // item being dragged (grab) or flying away (reaction)
  Offset _dragOff = Offset.zero; // sprite units, relative to its rest place
  Offset _snapFrom = Offset.zero;
  Offset _flyDir = const Offset(0, -1);

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
    _snap.dispose();
    super.dispose();
  }

  // Local pixel position -> sprite space.
  Offset _toSprite(Offset p) =>
      Offset(p.dx / widget.scale - 6, p.dy / widget.scale);

  /// What is under the pointer, if it can be stolen.
  _Item? _hit(Offset local) {
    final p = _toSprite(local);
    if (p.dx >= 16.5) return _Item.staff;
    final cup = _cupAt(_loop.value);
    if (cup.vis > 0.6 &&
        Rect.fromLTWH(cup.pos.dx - 5, cup.pos.dy - 4, 14, 14).contains(p)) {
      return _Item.cup;
    }
    return null;
  }

  void _freeze(_Mode mode) {
    _frozenT = _loop.value;
    _loop.stop();
    _mode = mode;
  }

  void _onPanStart(DragStartDetails d) {
    if (_mode != _Mode.loop) return;
    final item = _hit(d.localPosition);
    if (item == null) return;
    setState(() {
      _freeze(_Mode.grab);
      _dragItem = item;
      _dragOff = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_mode != _Mode.grab) return;
    setState(() => _dragOff += d.delta / widget.scale);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_mode != _Mode.grab) return;
    final vel = d.velocity.pixelsPerSecond / widget.scale;
    final far = _dragOff.distance >= 7;
    if (far || vel.distance >= 40) {
      // Let go while pulling: the item keeps going in that direction.
      final dir = vel.distance > 25
          ? vel / vel.distance
          : (_dragOff.distance > 0
              ? _dragOff / _dragOff.distance
              : _defaultDir(_dragItem!));
      _steal(_dragItem!, dir);
    } else {
      _dropBack();
    }
  }

  void _onPanCancel() {
    if (_mode == _Mode.grab) _dropBack();
  }

  void _dropBack() {
    _snapFrom = _dragOff;
    _snap.forward(from: 0);
  }

  Offset _defaultDir(_Item item) =>
      item == _Item.cup ? const Offset(-0.8, -0.6) : const Offset(0.6, -0.8);

  void _onTapUp(TapUpDetails d) {
    if (_mode != _Mode.loop) return;
    final item = _hit(d.localPosition);
    if (item == null) return;
    setState(() {
      _freeze(_Mode.loop); // sets frozen t; mode is set by _steal
      _dragOff = Offset.zero;
    });
    _steal(item, _defaultDir(item));
  }

  void _steal(_Item item, Offset dir) {
    setState(() {
      if (_mode == _Mode.loop) _freeze(_Mode.loop);
      _mode = item == _Item.cup ? _Mode.coffee : _Mode.staff;
      _dragItem = item;
      _flyDir = dir;
      _fired = false;
      _spoke = false;
    });
    _react.forward(from: 0);
  }

  void _endReaction() {
    if (!mounted) return;
    setState(() {
      _mode = _Mode.loop;
      _dragItem = null;
      _dragOff = Offset.zero;
    });
    if (_reduceMotion) {
      _loop.value = 0.66;
    } else {
      _loop.forward(from: 0);
      _loop.repeat();
    }
  }

  /// Same fury, second target: a bolt from his staff to the coin counter,
  /// after which the coins fall off the screen (and the score resets).
  void _castCoinStrike() {
    if (_reduceMotion || GameState.coins.value <= 0) return;
    final hud = GameState.coinHudKey.currentContext?.findRenderObject();
    final me = context.findRenderObject();
    if (hud is! RenderBox || !hud.attached || me is! RenderBox) return;
    final to = hud.localToGlobal(Offset(7, hud.size.height / 2));
    // The orb sits at sprite (20, 3); sprite x=0 is 6 pixels into the box.
    final from = me.localToGlobal(Offset(
      (20 + 6) * widget.scale,
      3 * widget.scale,
    ));
    CoinStrike.show(
      context,
      from: from,
      to: to,
      coins: GameState.coins.value,
      onImpact: () => GameState.coins.value = 0,
    );
  }

  void _onReact() {
    final rt = _react.value;
    if (_mode == _Mode.coffee) {
      if (!_fired && rt >= _WizardPainter.coffeeSpellAt) {
        _fired = true;
        // The spell: light theme + the other language, in one rebuild.
        final s = AppSettings.instance;
        s.apply(dark: false, lang: s.isEn ? AppLang.pt : AppLang.en);
        _castCoinStrike();
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

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      label: S.wizardHint,
      button: true,
      child: Tooltip(
        message: S.wizardHint,
        child: MouseRegion(
          cursor: _mode == _Mode.grab
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Report where the finger went down, not where the slop ended.
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: _onTapUp,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanCancel: _onPanCancel,
            child: SizedBox(
              width: PixelWizard.gridW * s,
              height: PixelWizard.gridH * s,
              // Own layer: the wizard animates constantly and must not force
              // the rest of the page to repaint with him.
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_loop, _react]),
                  builder: (context, _) => CustomPaint(
                    // Items can be dragged/fly well outside the sprite box.
                    painter: _WizardPainter(
                      t: _mode == _Mode.loop ? _loop.value : _frozenT,
                      seconds: _clock.elapsedMilliseconds / 1000,
                      scale: s,
                      mode: _mode,
                      rt: _react.value,
                      item: _dragItem,
                      dragOff: _dragOff,
                      flyDir: _flyDir,
                    ),
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
const _ink = Color(0xFF1B0B3A);
const _hat = Color(0xFF5B3FD1);
const _hatLight = Color(0xFF7D62F2);
const _hatDark = Color(0xFF3B2A8F);
const _robe = Color(0xFF4B34C0);
const _robeLight = Color(0xFF6A4FE0);
const _robeDark = Color(0xFF33238C);
const _gold = Color(0xFFFFCD3C);
const _goldLight = Color(0xFFFFEE9A);
const _goldDark = Color(0xFFC9962B);
const _skin = Color(0xFFF2C49B);
const _skinShade = Color(0xFFD9A57C);
const _nose = Color(0xFFE39A78);
const _angrySkin = Color(0xFFE0524A);
const _beard = Color(0xFFF1EEF8);
const _beardShade = Color(0xFFB9B3D0);
const _wood = Color(0xFF8B5A2B);
const _woodLight = Color(0xFFB57C3E);
const _woodDark = Color(0xFF5E3A18);
const _orb = Color(0xFF2DE2FF);
const _orbDark = Color(0xFF16A6C4);
const _rage = Color(0xFFFF3CAA);
const _boot = Color(0xFF5A3A2A);
const _bootLight = Color(0xFF7D5540);
const _mugOutline = Color(0xFF3B2314);
const _mugWhite = Color(0xFFF7F1E5);
const _mugShade = Color(0xFFCFC3AE);
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

double _seg(double v, double a, double b) =>
    ((v - a) / (b - a)).clamp(0.0, 1.0);
double _lerp(double a, double b, double k) => a + (b - a) * k;
Offset _lerpO(Offset a, Offset b, double k) =>
    Offset(_lerp(a.dx, b.dx, k), _lerp(a.dy, b.dy, k));
Offset _round(Offset o) => Offset(o.dx.roundToDouble(), o.dy.roundToDouble());

/// Everything about the coffee cup at loop time [t].
class _Cup {
  const _Cup(this.pos, this.vis, this.sipping);
  final Offset pos; // top-left of the mug body, sprite space
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
  final cupHand = Offset(cup.pos.dx + 1, cup.pos.dy + 6);
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
        : _lerpO(
            _raisedHand,
            cupHand,
            Curves.easeOut
                .transform(_seg(t, _summonEnd + 0.02, _catchEnd - 0.04)));
  } else {
    hand = _lerpO(cupHand, _restHand,
        Curves.easeInOut.transform(_seg(t, _lowerEnd + 0.03, _fadeEnd + 0.03)));
  }
  return _round(hand);
}

// Mug sprite, 8x8. Handle on the left, body (cols 2..7) faces the wizard.
// o outline, w cream, s shade, c coffee, h handle.
const _mug = [
  '..oooooo',
  '..occcco',
  '.oowwwso',
  'ohowwwso',
  'ohowwwso',
  '.oowwsso',
  '...osso.',
  '....oo..',
];
const _mugColors = {
  'o': _mugOutline,
  'w': _mugWhite,
  's': _mugShade,
  'c': _coffee,
  'h': _mugShade,
};

/// A tiny pixel buffer for the wizard's body: layers are painted into it
/// and an outline is derived from the silhouette, which is what gives the
/// sprite its clean pixel-art edge.
class _Buf {
  static const w = 22, h = 38; // sprite x -1..20, y -1..36
  final cells = List<Color?>.filled(w * h, null);

  void set(int x, int y, Color c) {
    final gx = x + 1, gy = y + 1;
    if (gx < 0 || gx >= w || gy < 0 || gy >= h) return;
    cells[gy * w + gx] = c;
  }

  void rect(int x, int y, int rw, int rh, Color c) {
    for (var j = 0; j < rh; j++) {
      for (var i = 0; i < rw; i++) {
        set(x + i, y + j, c);
      }
    }
  }

  void outline(Color c) {
    final out = List<Color?>.of(cells);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (cells[y * w + x] != null) continue;
        bool filled(int dx, int dy) {
          final nx = x + dx, ny = y + dy;
          return nx >= 0 &&
              nx < w &&
              ny >= 0 &&
              ny < h &&
              cells[ny * w + nx] != null;
        }

        if (filled(1, 0) || filled(-1, 0) || filled(0, 1) || filled(0, -1)) {
          out[y * w + x] = c;
        }
      }
    }
    for (var i = 0; i < cells.length; i++) {
      cells[i] = out[i];
    }
  }
}

class _WizardPainter extends CustomPainter {
  _WizardPainter({
    required this.t,
    required this.seconds,
    required this.scale,
    required this.mode,
    required this.rt,
    required this.item,
    required this.dragOff,
    required this.flyDir,
  });
  final double t; // position in the idle loop (frozen outside of it)
  final double seconds; // free-running clock, for steam/pulses
  final double scale;
  final _Mode mode;
  final double rt; // 0..1 progress of the current reaction
  final _Item? item; // item being dragged / flying away
  final Offset dragOff; // sprite units
  final Offset flyDir; // unit vector

  // Reaction beats, as fractions of the reaction.
  static const coffeeSpellAt = 0.42;
  static const staffSpeakAt = 0.72;

  late Canvas _c;
  final _paint = Paint()..isAntiAlias = false;
  double _alpha = 1; // multiplies every pixel drawn (fading items)

  // Draws one rect in sprite space (pixel grid units).
  void _px(num x, num y, Color color, {num w = 1, num h = 1, double a = 1}) {
    _paint.color = color.withOpacity((a * _alpha).clamp(0.0, 1.0));
    _c.drawRect(
      Rect.fromLTWH(x.floorToDouble() * scale, y.floorToDouble() * scale,
          w * scale, h * scale),
      _paint,
    );
  }

  // Pixel-perfect thick line (Bresenham), used for the arms.
  void _line(int x0, int y0, int x1, int y1, Color color,
      {int thick = 2, int shift = 0}) {
    final dx = (x1 - x0).abs(), dy = -(y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    var err = dx + dy;
    while (true) {
      _px(x0 + shift, y0 + shift, color, w: thick, h: thick);
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

  void _limb(int x0, int y0, int x1, int y1) {
    _line(x0, y0, x1, y1, _ink, thick: 4, shift: -1); // outline underlay
    _line(x0, y0, x1, y1, _robe);
    _line(x0, y0, x1, y1, _robeLight, thick: 1);
  }

  void _hand(num x, num y) {
    _px(x - 1, y - 1, _ink, w: 5, h: 4);
    _px(x, y, _skin, w: 3, h: 2);
    _px(x, y + 1, _skinShade, w: 3);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    canvas.translate(6 * scale, 0); // sprite x=0 sits 6 pixels from the left

    final grab = mode == _Mode.grab;
    final coffee = mode == _Mode.coffee;
    final staff = mode == _Mode.staff;
    final cup = _cupAt(t);
    var hand = _handAt(t, cup, seconds);

    // ---- reaction state -------------------------------------------------
    var bodyDx = 0.0, bodyDy = 0.0;
    var angry = 0.0;
    var wideEyes = grab;
    var exclaim = grab && (seconds * 5).floor().isEven;
    var question = false;
    var rightHandY = 21.0;
    var flash = 0.0;
    var beam = 0.0;
    // Where each item is, relative to its rest place.
    var cupOff = Offset.zero, cupAlpha = 1.0;
    var staffOff = Offset.zero, staffAlpha = 1.0, staffShown = true;

    Offset flown(double k) =>
        dragOff + flyDir * (110 * Curves.easeIn.transform(k));

    if (grab) {
      if (item == _Item.cup) cupOff = dragOff;
      if (item == _Item.staff) staffOff = dragOff;
    } else if (coffee) {
      final k = _seg(rt, 0, 0.12);
      cupOff = flown(k);
      cupAlpha = 1 - k * k;
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
      // 1. the old staff is yanked away, 2. he looks puzzled, 3. he raises his
      // hand, 4. a new staff falls from the sky into it, 5. he lowers it.
      // The coffee is conjured magic: once the staff is gone it pops out of
      // existence ("plink") and his empty hand drops.
      if (cup.vis > 0) {
        cupAlpha = rt < 0.05 ? 1 : 0;
        hand = _round(_lerpO(
            hand, _restHand, Curves.easeInOut.transform(_seg(rt, 0.10, 0.28))));
      }
      if (rt < 0.12) {
        final k = _seg(rt, 0, 0.12);
        staffOff = flown(k);
        staffAlpha = 1 - k * k;
      } else if (rt < 0.46) {
        staffShown = false;
      } else {
        final fall = Curves.easeIn.transform(_seg(rt, 0.46, 0.60));
        final lower = Curves.easeInOut.transform(_seg(rt, 0.64, 0.74));
        staffOff = Offset(0, _lerp(-46, -11, fall) + 11 * lower);
      }
      wideEyes = rt >= 0.02 && rt < 0.14;
      question = rt >= 0.12 && rt < 0.34 && (seconds * 5).floor().isEven;
      if (rt >= 0.30 && rt < 0.46) {
        rightHandY =
            _lerp(21, 10, Curves.easeOut.transform(_seg(rt, 0.30, 0.46)));
      } else if (rt >= 0.46 && rt < 0.64) {
        rightHandY = 10;
      } else if (rt >= 0.64 && rt < 0.74) {
        rightHandY =
            _lerp(10, 21, Curves.easeInOut.transform(_seg(rt, 0.64, 0.74)));
      }
      beam = _seg(rt, 0.34, 0.46) * (1 - _seg(rt, 0.62, 0.74));
      flash = (rt >= 0.58 && rt < 0.68) ? 1 : 0;
    }

    canvas.save();
    canvas.translate(bodyDx * scale, bodyDy * scale);

    // ---- sky beam (behind everything) ------------------------------------
    if (beam > 0) _drawBeam(beam);

    // ---- staff ---------------------------------------------------------
    final summoning = mode == _Mode.loop && t >= _summonStart && t < _summonEnd;
    final fading = mode == _Mode.loop && t >= _lowerEnd && t < _fadeEnd;
    final pulse = 0.5 + 0.5 * sin(seconds * 3);
    final orbColor = Color.lerp(_orb, _rage, angry)!;
    final orbFlash = (summoning || fading) ? 1.0 : flash;
    if (staffShown) {
      canvas.save();
      canvas.translate(staffOff.dx * scale, staffOff.dy * scale);
      _alpha = staffAlpha;
      canvas.drawCircle(
        Offset(20 * scale, 3 * scale),
        (5 + 3 * pulse + 4 * orbFlash + 3 * angry) * scale,
        Paint()
          ..color = orbColor.withOpacity(
            ((0.25 + 0.25 * pulse + 0.25 * orbFlash + 0.2 * angry) * staffAlpha)
                .clamp(0.0, 1.0),
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale * 3),
      );
      _drawStaff(orbColor);
      _alpha = 1;
      canvas.restore();
    }

    // ---- body (hat, face, beard, robe, boots) with auto outline ---------
    _drawBody(
      angry: angry,
      wideEyes: wideEyes,
      sipping: mode == _Mode.loop && cup.sipping,
      gulp: mode == _Mode.loop &&
          cup.sipping &&
          sin(_seg(t, _liftEnd, _sipEnd) * pi * 6) > 0.35,
    );

    // ---- arms ----------------------------------------------------------
    _limb(14, 18, 18, rightHandY.toInt());
    _hand(18, rightHandY);
    _limb(5, 18, hand.dx.toInt(), hand.dy.toInt());
    _hand(hand.dx, hand.dy);

    // ---- emotes -----------------------------------------------------------
    if (exclaim) {
      _px(14, -1, _gold, w: 2, h: 4);
      _px(14, 4, _gold, w: 2, h: 2);
    }
    if (question) {
      _px(14, -1, _gold, w: 3);
      _px(16, 0, _gold, h: 2);
      _px(15, 2, _gold, w: 2);
      _px(14, 3, _gold);
      _px(14, 5, _gold);
    }

    // ---- effects ---------------------------------------------------------
    if (summoning) _summonSparkles();
    if (coffee) _coffeeEffects(cup, angry);
    if (staff) _staffEffects(cup);

    // ---- cup -----------------------------------------------------------
    if (cup.vis > 0 && cupAlpha > 0.02) {
      _alpha = cupAlpha;
      _drawCup(
          _round(cup.pos + cupOff), cup.vis, mode == _Mode.loop && cup.sipping);
      _alpha = 1;
    }
    if (fading ||
        (mode == _Mode.loop &&
            t > _summonEnd - 0.05 &&
            t < _summonEnd + 0.03)) {
      _burst(cup.pos + const Offset(3, 3), (t - _lowerEnd) * 20);
    }

    canvas.restore();
  }

  void _drawBody({
    required double angry,
    required bool wideEyes,
    required bool sipping,
    required bool gulp,
  }) {
    final b = _Buf();
    final skin = Color.lerp(_skin, _angrySkin, angry)!;
    final skinShade = Color.lerp(_skinShade, const Color(0xFFB83A34), angry)!;

    // Robe.
    for (var y = 16; y <= 31; y++) {
      final grow = ((y - 16) * 4) ~/ 15;
      final l = 5 - grow, r = 14 + grow;
      b.rect(l, y, r - l + 1, 1, _robe);
      b.set(l, y, _robeLight);
      b.set(r, y, _robeDark);
      b.set(r - 1, y, _robeDark);
      if (y >= 24) {
        b.set(7, y, _robeDark); // folds
        b.set(12, y, _robeDark);
      }
    }
    for (var x = 1; x <= 18; x++) {
      b.set(x, 30, x.isEven ? _goldDark : _robeDark);
      b.set(x, 31, x.isEven ? _gold : _goldDark); // gold hem trim
    }
    b.rect(4, 22, 12, 1, _gold); // belt
    b.rect(9, 22, 2, 2, _goldLight);
    b.set(9, 22, _goldDark);
    for (final s in const [(4, 27), (15, 26), (8, 29), (13, 28)]) {
      b.set(s.$1, s.$2, _gold); // little stars on the robe
    }
    b.set(4, 26, _goldLight);
    b.set(4, 28, _goldLight);

    // Boots.
    b.rect(3, 32, 6, 2, _boot);
    b.rect(11, 32, 6, 2, _boot);
    b.rect(2, 33, 1, 1, _boot);
    b.rect(3, 32, 6, 1, _bootLight);
    b.rect(11, 32, 6, 1, _bootLight);

    // Hat: a pointy cone that leans right at the tip.
    for (var y = 0; y <= 9; y++) {
      final half = y ~/ 2 + 1;
      final lean = ((9 - y) * 0.18).round();
      final l = 10 - half + lean, r = 9 + half + lean;
      b.rect(l, y, r - l + 1, 1, _hat);
      b.set(l, y, _hatLight);
      if (r - l > 2) b.set(l + 1, y, _hatLight);
      b.set(r, y, _hatDark);
      if (r - l > 3) b.set(r - 1, y, _hatDark);
    }
    b.set(12, 0, _hat); // floppy tip bending over
    b.set(13, 1, _hat);
    b.rect(4, 10, 12, 1, _gold); // band
    b.rect(9, 10, 2, 1, _goldLight);
    b.rect(5, 10, 1, 1, _goldDark);
    // star on the hat
    b.set(9, 5, _gold);
    b.rect(8, 6, 3, 1, _gold);
    b.set(9, 7, _gold);
    b.rect(1, 11, 18, 1, _hat); // brim
    b.rect(1, 11, 3, 1, _hatLight);
    b.rect(2, 12, 16, 1, _hatDark);

    // Face.
    b.rect(5, 13, 10, 3, skin);
    b.rect(5, 13, 10, 1, skinShade); // shadow under the brim
    b.set(4, 14, skin); // ears
    b.set(4, 15, skin);
    b.set(15, 14, skin);
    b.set(15, 15, skin);
    b.rect(9, 14, 2, 1, Color.lerp(_nose, _angrySkin, angry)!);

    // Beard (bobs down a pixel on each gulp).
    final bob = gulp ? 1 : 0;
    void beardRow(int y, int l, int r) {
      b.rect(l, y + (y > 15 ? bob : 0), r - l + 1, 1, _beard);
      b.set(r, y + (y > 15 ? bob : 0), _beardShade);
    }

    beardRow(15, 5, 14);
    beardRow(16, 5, 14);
    beardRow(17, 6, 13);
    beardRow(18, 6, 13);
    beardRow(19, 7, 12);
    beardRow(20, 7, 12);
    beardRow(21, 8, 11);
    beardRow(22, 8, 11);
    beardRow(23, 9, 10);
    b.rect(6, 15, 8, 1, _beard); // mustache
    b.set(9, 15, _beardShade);
    b.set(10, 15, _beardShade);
    b.set(9, 18 + bob, _beardShade); // strands
    b.set(10, 20 + bob, _beardShade);

    // Eyes and eyebrows.
    if (wideEyes) {
      b.rect(6, 13, 2, 2, Colors.white);
      b.rect(12, 13, 2, 2, Colors.white);
      b.set(7, 14, _ink);
      b.set(12, 14, _ink);
    } else if (angry > 0.4) {
      b.set(7, 14, _ink);
      b.set(12, 14, _ink);
      b.rect(6, 13, 2, 1, _ink); // slanted brows
      b.set(8, 14, _ink);
      b.rect(12, 13, 2, 1, _ink);
      b.set(11, 14, _ink);
    } else if (sipping) {
      b.rect(6, 14, 2, 1, _ink); // eyes closed
      b.rect(12, 14, 2, 1, _ink);
    } else {
      b.set(7, 14, _ink);
      b.set(12, 14, _ink);
      b.rect(6, 13, 3, 1, _beard); // bushy brows
      b.rect(11, 13, 3, 1, _beard);
    }

    b.outline(_ink);

    // Paint: merge horizontal runs of the same color into single rects.
    for (var y = 0; y < _Buf.h; y++) {
      var x = 0;
      while (x < _Buf.w) {
        final c = b.cells[y * _Buf.w + x];
        if (c == null) {
          x++;
          continue;
        }
        var run = 1;
        while (x + run < _Buf.w && b.cells[y * _Buf.w + x + run] == c) {
          run++;
        }
        _px(x - 1, y - 1, c, w: run);
        x += run;
      }
    }
  }

  void _drawStaff(Color orbColor) {
    // Shaft with outline, highlight and knots.
    _px(18, 4, _ink, w: 4, h: 31);
    _px(19, 5, _wood, w: 2, h: 29);
    _px(19, 5, _woodLight, w: 1, h: 29);
    for (final y in const [11, 19, 27]) {
      _px(19, y, _woodDark, w: 2);
    }
    // Claw holding the orb.
    _px(16, 3, _ink, w: 8, h: 4);
    _px(17, 4, _wood, w: 1, h: 2);
    _px(22, 4, _wood, w: 1, h: 2);
    _px(18, 5, _wood, w: 4, h: 1);
    // Orb.
    _px(17, 0, _ink, w: 6, h: 6);
    _px(18, 1, orbColor, w: 4, h: 4);
    _px(18, 4, Color.lerp(_orbDark, _rage, 0.5)!, w: 4, h: 1);
    _px(18, 1, Colors.white, a: 0.95);
    _px(19, 1, Colors.white, a: 0.5);
  }

  void _drawBeam(double a) {
    // A column of light dropping from the sky onto his raised hand.
    final flicker = 0.85 + 0.15 * sin(seconds * 25);
    _px(15, -50, _orb, w: 10, h: 62, a: 0.10 * a * flicker);
    _px(17, -50, _orb, w: 6, h: 62, a: 0.16 * a * flicker);
    _px(19, -50, Colors.white, w: 2, h: 62, a: 0.30 * a * flicker);
    // Motes of light sliding down the beam.
    for (var i = 0; i < 8; i++) {
      final y = -48 + ((seconds * 40 + i * 9) % 60);
      _px(16 + (i * 5) % 8, y, i.isEven ? _gold : Colors.white, a: a * 0.9);
    }
  }

  void _summonSparkles() {
    for (var k = 0; k < 9; k++) {
      final p =
          _seg(t, _summonStart + k * 0.012, _summonStart + 0.10 + k * 0.012);
      if (p <= 0 || p >= 1) continue;
      // Arc from the orb over to where the cup will appear.
      const from = Offset(19, 2), to = Offset(-2, 9);
      final pos = _lerpO(from, to, p) + Offset(0, -6 * sin(p * pi));
      final color = k.isEven ? _gold : _orb;
      _px(pos.dx, pos.dy, color);
      if (p > 0.2 && p < 0.8) {
        final tail =
            _lerpO(from, to, p - 0.08) + Offset(0, -6 * sin((p - 0.08) * pi));
        _px(tail.dx, tail.dy, color, a: 0.5);
      }
    }
  }

  void _coffeeEffects(_Cup cup, double angry) {
    // Little smoke puff where the cup was snatched from.
    if (rt > 0.02 && rt < 0.22) {
      final k = _seg(rt, 0.02, 0.22);
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3 + 0.4;
        _px(cup.pos.dx + 3 + cos(a) * (2 + 5 * k),
            cup.pos.dy + 3 + sin(a) * (2 + 5 * k), _steam,
            a: 1 - k);
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
      _burst(const Offset(20, 3),
          _seg(rt, coffeeSpellAt - 0.02, coffeeSpellAt + 0.12),
          radius: 12);
    }
  }

  void _staffEffects(_Cup cup) {
    // "Plink": the cup vanishes in a twinkle and a ring of sparkles.
    if (cup.vis > 0 && rt >= 0.05 && rt < 0.24) {
      final k = _seg(rt, 0.05, 0.24);
      final c = cup.pos + const Offset(3, 3);
      final arm = (3 * (1 - k)).round();
      if (arm > 0) {
        _px(c.dx - arm, c.dy, Colors.white, w: arm * 2 + 1);
        _px(c.dx, c.dy - arm, Colors.white, h: arm * 2 + 1);
      }
      _px(c.dx, c.dy, _goldLight);
      _burst(c, k, radius: 7);
    }
    // Whoosh trail while the staff is yanked away.
    if (rt < 0.14) {
      final k = _seg(rt, 0, 0.14);
      for (var i = 1; i <= 4; i++) {
        final kk = (k - i * 0.05).clamp(0.0, 1.0);
        final p = dragOff + flyDir * (110 * Curves.easeIn.transform(kk));
        _px(20 + p.dx, 10 + p.dy, _orb, a: (1 - i / 5) * (1 - k));
      }
    }
    // Crackling light gathering around the raised hand.
    if (rt >= 0.32 && rt < 0.5) {
      final k = _seg(rt, 0.32, 0.5);
      for (var i = 0; i < 8; i++) {
        final a = seconds * 7 + i * pi / 4;
        final r = 8 * (1 - k) + 2;
        _px(19.5 + cos(a) * r, 11 + sin(a) * r, i.isEven ? _gold : _orb);
      }
    }
    // Impact when the staff lands in his hand.
    if (rt >= 0.58 && rt < 0.72) {
      _burst(const Offset(19, 10), _seg(rt, 0.58, 0.72), radius: 10);
    }
  }

  void _drawCup(Offset p, double vis, bool sipping) {
    // Sprite origin so that the mug body's top-left lands on `p`.
    final ox = p.dx - 2, oy = p.dy - 1;
    // Materialize bottom-to-top.
    final rows = (vis * _mug.length).ceil();
    final a = vis < 1 ? 0.8 : 1.0;
    for (var r = 0; r < _mug.length; r++) {
      if (_mug.length - 1 - r >= rows) continue;
      final line = _mug[r];
      for (var c = 0; c < line.length; c++) {
        final color = _mugColors[line[c]];
        if (color != null) _px(ox + c, oy + r, color, a: a);
      }
    }
    // Steam.
    if (vis >= 1 && !sipping) {
      for (var k = 0; k < 3; k++) {
        final phase = (seconds * 0.9 + k * 0.33) % 1;
        final sx = p.dx + 1 + k * 1.6 + sin(phase * pi * 2 + k) * 0.8;
        _px(sx, p.dy - 3 - phase * 6, _steam, a: (1 - phase) * 0.8);
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
