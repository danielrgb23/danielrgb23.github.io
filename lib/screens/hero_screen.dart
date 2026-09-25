import 'package:flutter/material.dart';
import '../state/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_toast.dart';

class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _pulseController;
  late final AnimationController _titleController;
  late final Animation<double> _titleOpacity;

  int _avatarTaps = 0;
  DateTime? _firstTap;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _titleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    ]).animate(_titleController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _glowController.stop();
        _pulseController.stop();
        _titleController.value = 1;
      } else {
        _titleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _handleAvatarTap() {
    final now = DateTime.now();
    if (_firstTap == null ||
        now.difference(_firstTap!) > const Duration(seconds: 2)) {
      _firstTap = now;
      _avatarTaps = 1;
    } else {
      _avatarTaps++;
    }
    if (_avatarTaps >= 5) {
      _avatarTaps = 0;
      AchievementToast.show(context, S.easterEgg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.heroKicker,
            textAlign: TextAlign.center,
            style: AppText.kicker,
          ),
          const SizedBox(height: 26),
          GestureDetector(
            onTap: _handleAvatarTap,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glow = 0.3 + 0.25 * _glowController.value;
                return Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bgPanel,
                        blurRadius: 0,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: AppColors.gold.withOpacity(glow),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: ClipOval(
                child: Image.asset(
                  'assets/img/profile_image.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          FadeTransition(
            opacity: _titleOpacity,
            child: Text(
              'DANIEL AUGUSTO',
              textAlign: TextAlign.center,
              style: AppText.h1,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              S.heroBio,
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
          ),
          const SizedBox(height: 30),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glow = 0.15 + 0.4 * _pulseController.value;
              return Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(glow),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: OutlinedButton(
              onPressed: widget.onStart,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: BorderSide(color: AppColors.cyan, width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(S.pressStart, style: AppText.button),
            ),
          ),
        ],
      ),
    );
  }
}
