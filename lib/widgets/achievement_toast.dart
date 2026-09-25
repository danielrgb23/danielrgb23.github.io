import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows a floating, arcade-styled "achievement unlocked" toast using an
/// [OverlayEntry]. Call [AchievementToast.show] from anywhere with a
/// [BuildContext] that has an [Overlay] above it (any screen inside the app
/// shell qualifies).
class AchievementToast {
  static OverlayEntry? _entry;
  static final _removed = Set<OverlayEntry>.identity();

  // An entry may be dismissed both by a newer toast and by its own timer;
  // OverlayEntry.remove() must only run once.
  static void _dismiss(OverlayEntry? entry) {
    if (entry == null || !_removed.add(entry)) return;
    entry.remove();
  }

  static void show(BuildContext context, String message) {
    _dismiss(_entry);
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (context) => _ToastWidget(message: message));
    _entry = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 3600), () {
      _dismiss(entry);
      if (identical(_entry, entry)) _entry = null;
    });
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({required this.message});
  final String message;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offset = Tween<Offset>(begin: const Offset(0, 1.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Center(
        child: SlideTransition(
          position: _offset,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgPanel,
              border: Border.all(color: AppColors.gold, width: 2),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.25),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: AppText.pixel.copyWith(
                fontSize: 11,
                color: AppColors.gold,
                height: 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
