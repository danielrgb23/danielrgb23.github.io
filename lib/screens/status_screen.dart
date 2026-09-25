import 'package:flutter/material.dart';
import '../data/portfolio_data.dart';
import '../state/strings.dart';
import '../theme/app_theme.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.value = MediaQuery.of(context).disableAnimations ? 1 : 0;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.statusKicker, style: AppText.kicker),
        const SizedBox(height: 8),
        Text('STATUS', style: AppText.h2),
        const SizedBox(height: 28),
        for (final skill in skills) ...[
          _SkillBar(skill: skill, controller: _controller),
          const SizedBox(height: 22),
        ],
        const SizedBox(height: 8),
        Text(
          S.statusNote,
          style: AppText.small,
        ),
      ],
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.skill, required this.controller});
  final SkillStat skill;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                skill.name,
                style: AppText.mono.copyWith(fontSize: 13, color: AppColors.text),
              ),
            ),
            Text(
              'Lv. ${skill.level}',
              style: AppText.mono.copyWith(fontSize: 13, color: AppColors.gold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: anim,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.bgPanel,
                  border: Border.all(color: AppColors.border),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (skill.progress * anim.value).clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.cyan, AppColors.magenta],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
