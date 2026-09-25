import 'package:flutter/material.dart';
import '../state/strings.dart';
import '../theme/app_theme.dart';

/// RPG-style dialogue box with a typewriter effect, shown at the bottom of
/// the screen through an [OverlayEntry] (same approach as
/// [AchievementToast]).
class WizardSpeech {
  static OverlayEntry? _entry;
  static final _removed = Set<OverlayEntry>.identity();

  static void _dismiss(OverlayEntry? entry) {
    if (entry == null || !_removed.add(entry)) return;
    entry.remove();
  }

  static void show(BuildContext context, String message) {
    _dismiss(_entry);
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _SpeechBox(message: message));
    _entry = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 6200), () {
      _dismiss(entry);
      if (identical(_entry, entry)) _entry = null;
    });
  }
}

class _SpeechBox extends StatefulWidget {
  const _SpeechBox({required this.message});
  final String message;

  @override
  State<_SpeechBox> createState() => _SpeechBoxState();
}

class _SpeechBoxState extends State<_SpeechBox>
    with SingleTickerProviderStateMixin {
  static const _charsPerSecond = 26;
  late final AnimationController _typing = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: widget.message.length * 1000 ~/ _charsPerSecond,
    ),
  )..forward();
  bool _fadeOut = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 5600), () {
      if (mounted) setState(() => _fadeOut = true);
    });
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            opacity: _fadeOut ? 0 : 1,
            duration: const Duration(milliseconds: 500),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              decoration: BoxDecoration(
                color: AppColors.bgPanel,
                border: Border.all(color: AppColors.magenta, width: 2),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.magenta.withOpacity(0.25),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_fix_high,
                          size: 16, color: AppColors.magenta),
                      const SizedBox(width: 8),
                      Text(
                        S.wizardName,
                        style: AppText.pixel.copyWith(
                          fontSize: 10,
                          color: AppColors.magenta,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _typing,
                    builder: (context, _) {
                      final n = (widget.message.length * _typing.value).ceil();
                      return Text(
                        widget.message.substring(0, n),
                        style: AppText.mono.copyWith(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.text,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
