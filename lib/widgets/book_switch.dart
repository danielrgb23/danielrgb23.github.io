import 'dart:math';
import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import '../state/strings.dart';
import '../theme/app_theme.dart';

/// A small open book. Tapping it riffles a few pages over, one after the
/// other, and switches the language when the first page is mid-air. The
/// visible right page shows the current language code.
class BookSwitch extends StatefulWidget {
  const BookSwitch({super.key, required this.onFlip});
  final VoidCallback onFlip;

  static const width = 76.0;
  static const height = 52.0;

  @override
  State<BookSwitch> createState() => _BookSwitchState();
}

class _BookSwitchState extends State<BookSwitch>
    with SingleTickerProviderStateMixin {
  static const _pageW = BookSwitch.width / 2;
  static const _pageH = BookSwitch.height - 8;
  static const _pages = 4;
  static const _stagger = 0.13;
  static const _pageSpan = 0.48;

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  // Language the book currently shows (its previous one while flipping).
  AppLang _from = AppSettings.instance.lang;
  AppLang _shown = AppSettings.instance.lang;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onLanguageChanged);
    _flip.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_flip.isAnimating) return;
    // The language change itself triggers the flip (see below), so the
    // animation and the switch happen together.
    widget.onFlip();
  }

  // Riffle the pages whenever the language changes, whoever changed it (the
  // book itself or, say, an angry wizard).
  void _onLanguageChanged() {
    final lang = AppSettings.instance.lang;
    if (lang == _shown) return;
    _from = _shown;
    _shown = lang;
    _flip.forward(from: 0);
  }

  static String _code(AppLang l) => l == AppLang.pt ? 'PT' : 'EN';

  /// Angle (0..pi) of page [i] at the current animation time.
  double _angle(int i) {
    final start = i * _stagger;
    final local = ((_flip.value - start) / _pageSpan).clamp(0.0, 1.0);
    return Curves.easeInOutCubic.transform(local) * pi;
  }

  Widget _page({
    String? code,
    required bool left,
    double shade = 0,
  }) {
    final base = AppColors.bgPanelAlt;
    return Container(
      width: _pageW,
      height: _pageH,
      decoration: BoxDecoration(
        color: Color.lerp(base, Colors.black, shade),
        border: Border.all(color: AppColors.cyan, width: 1.5),
        borderRadius: BorderRadius.horizontal(
          left: left ? const Radius.circular(3) : Radius.zero,
          right: left ? Radius.zero : const Radius.circular(3),
        ),
      ),
      alignment: Alignment.center,
      child: code != null
          ? Text(
              code,
              style:
                  AppText.pixel.copyWith(fontSize: 13, color: AppColors.gold),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 2.5),
                    width: _pageW - 14 - (i == 4 ? 10 : 0),
                    height: 2,
                    color: AppColors.border,
                  ),
              ],
            ),
    );
  }

  Widget _flyingPage(int i) {
    final angle = _angle(i);
    if (angle == 0 || angle == pi) return const SizedBox.shrink();
    final showBack = angle > pi / 2;
    // Darkest when edge-on, as if the page were catching less light.
    final shade = 0.35 * (1 - (angle - pi / 2).abs() / (pi / 2));
    return Positioned(
      right: 0,
      top: 4,
      child: Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.006)
          ..rotateY(-angle),
        child: showBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: _page(left: true, shade: shade),
              )
            : _page(
                // The top page still shows the old language; the ones under
                // it already show the new one, so the label never lags.
                code: _code(i == 0 ? _from : AppSettings.instance.lang),
                left: false,
                shade: shade,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = AppSettings.instance.lang;
    return Semantics(
      button: true,
      label: S.bookTooltip,
      child: Tooltip(
        message: S.bookTooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            child: AnimatedBuilder(
              animation: _flip,
              builder: (context, _) {
                final flying = _flip.isAnimating;
                // The book lifts slightly while its pages are riffling.
                final lift = flying ? sin(_flip.value * pi) : 0.0;
                // Left pages (already flipped) ascending, right ones
                // descending, so the stacks look right mid-flight.
                final order = List.generate(_pages, (i) => i)
                  ..sort((a, b) {
                    int key(int i) => _angle(i) > pi / 2 ? i : 10 - i;
                    return key(a).compareTo(key(b));
                  });
                return Transform.translate(
                  offset: Offset(0, -4 * lift),
                  child: Transform.scale(
                    scale: 1 + 0.12 * lift,
                    child: SizedBox(
                      width: BookSwitch.width,
                      height: BookSwitch.height,
                      child: Stack(
                        children: [
                          // Cover peeking out below the pages.
                          Positioned.fill(
                            top: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.magenta,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 4,
                            child: _page(left: true),
                          ),
                          Positioned(
                            right: 0,
                            top: 4,
                            child: _page(code: _code(current), left: false),
                          ),
                          if (flying)
                            for (final i in order) _flyingPage(i),
                          // Spine.
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                width: 2,
                                height: _pageH,
                                color: AppColors.cyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
